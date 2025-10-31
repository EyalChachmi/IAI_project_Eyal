#!/bin/bash

# Script to clean up EKS deployment and AWS resources

set -e

REGION="eu-north-1"
CLUSTER_NAME="iai-cluster"

echo "🧹 Starting cleanup of EKS resources..."
echo ""

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "⚠️  kubectl not configured. Configuring now..."
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME || {
        echo "❌ Failed to configure kubectl. Cluster may not exist."
        echo "Proceeding with Terraform destroy only..."
    }
fi

# Delete Kubernetes resources that block Terraform destroy
if kubectl cluster-info &> /dev/null; then
    echo "📦 Deleting Kubernetes resources that block Terraform destroy..."
    
    echo "  - Deleting Ingresses (this deletes the ALB)..."
    kubectl delete ingress --all -n backend --timeout=60s --ignore-not-found=true &
    kubectl delete ingress --all -n frontend --timeout=60s --ignore-not-found=true &
    kubectl delete ingress --all -n default --timeout=60s --ignore-not-found=true &
    
    echo "    Waiting for ingress deletion (max 60 seconds)..."
    wait
    
    # Force delete if they still exist (remove finalizers)
    echo "    Checking for stuck ingresses..."
    STUCK_INGRESSES=$(kubectl get ingress --all-namespaces -o json 2>/dev/null | jq -r '.items[] | select(.metadata.deletionTimestamp != null) | "\(.metadata.namespace)/\(.metadata.name)"' || echo "")
    
    if [ -n "$STUCK_INGRESSES" ]; then
        echo "    Found stuck ingresses, removing finalizers..."
        for ing in $STUCK_INGRESSES; do
            NAMESPACE=$(echo $ing | cut -d'/' -f1)
            NAME=$(echo $ing | cut -d'/' -f2)
            echo "      Force deleting: $NAMESPACE/$NAME"
            kubectl patch ingress $NAME -n $NAMESPACE -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        done
    fi
    
    echo "  - Waiting for LoadBalancers to be deleted..."
    echo "    Checking every 30 seconds (max 3 minutes)..."
    
    for i in {1..6}; do
        sleep 30
        echo "    Checking ALBs... (attempt $i/6)"
        
        ALB_COUNT=$(aws elbv2 describe-load-balancers --region $REGION \
            --query "LoadBalancers[?contains(LoadBalancerName, 'k8s-')].LoadBalancerArn" \
            --output text 2>/dev/null | wc -w || echo "0")
        
        if [ "$ALB_COUNT" -eq 0 ]; then
            echo "    ✅ All LoadBalancers deleted"
            break
        else
            echo "    ⏳ Still waiting... ($ALB_COUNT LoadBalancer(s) remaining)"
        fi
        
        if [ $i -eq 6 ]; then
            echo "    ⚠️  LoadBalancers still exist after 3 minutes"
            echo "    Checking for remaining AWS resources in VPC..."
            
            VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=iai-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
            if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
                echo "    VPC: $VPC_ID"
                
                # Check for remaining ALBs
                echo "    Checking for ALBs..."
                aws elbv2 describe-load-balancers --region $REGION \
                    --query "LoadBalancers[?VpcId=='$VPC_ID'].[LoadBalancerName,LoadBalancerArn]" \
                    --output table 2>/dev/null || echo "      No ALBs found"
                
                # Check for target groups
                echo "    Checking for Target Groups..."
                aws elbv2 describe-target-groups --region $REGION \
                    --query "TargetGroups[?VpcId=='$VPC_ID'].[TargetGroupName,TargetGroupArn]" \
                    --output table 2>/dev/null || echo "      No Target Groups found"
                
                # Check for network interfaces
                echo "    Checking for ENIs..."
                ENI_COUNT=$(aws ec2 describe-network-interfaces --region $REGION \
                    --filters "Name=vpc-id,Values=$VPC_ID" \
                    --query 'NetworkInterfaces[*].NetworkInterfaceId' \
                    --output text 2>/dev/null | wc -w || echo "0")
                echo "      Found $ENI_COUNT network interface(s)"
            fi
        fi
    done
    
    # Check for and delete any Load Balancer Controller security groups
    echo "  - Checking for orphaned security groups..."
    VPC_ID=$(aws ec2 describe-vpcs --region $REGION --filters "Name=tag:Name,Values=iai-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")
    if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
        echo "    Found VPC: $VPC_ID"
        echo "    Looking for Load Balancer Controller security groups..."
        
        SG_IDS=$(aws ec2 describe-security-groups --region $REGION \
            --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:elbv2.k8s.aws/cluster,Values=$CLUSTER_NAME" \
            --query 'SecurityGroups[*].GroupId' --output text 2>/dev/null || echo "")
        
        if [ -n "$SG_IDS" ]; then
            echo "    Found security groups created by Load Balancer Controller:"
            for sg_id in $SG_IDS; do
                echo "      Deleting security group: $sg_id"
                aws ec2 delete-security-group --region $REGION --group-id $sg_id 2>/dev/null || \
                    echo "      ⚠️  Could not delete $sg_id (may have dependencies)"
            done
        else
            echo "    No orphaned security groups found"
        fi
    fi
    
    echo "✅ Resources that block Terraform deleted"
    echo ""
else
    echo "⏭️  Skipping Kubernetes resource deletion (cluster not accessible)"
    echo ""
fi

# Delete Terraform infrastructure
echo "🏗️  Destroying Terraform infrastructure..."
cd terraform

if [ ! -d ".terraform" ]; then
    echo "⚠️  Terraform not initialized. Initializing now..."
    terraform init
fi

echo ""
echo "This will destroy:"
echo "  - EKS Cluster"
echo "  - Worker Nodes"
echo "  - VPC and Networking"
echo "  - ECR Repositories (and all images)"
echo "  - Load Balancer Controller"
echo "  - All IAM roles and policies"
echo ""
echo "⚠️  WARNING: This action cannot be undone!"
echo ""

read -p "Are you sure you want to destroy all resources? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Destroy cancelled"
    exit 1
fi

echo ""
echo "Starting Terraform destroy..."
terraform destroy -auto-approve

cd ..

echo ""
echo "✅ All AWS resources have been destroyed!"
echo ""
echo "📝 Note: The following still exist and may incur minimal costs:"
echo "  - ECR images (if lifecycle policy hasn't cleaned them yet)"
echo "  - CloudWatch logs (minimal storage cost)"
echo ""
echo "To completely remove ECR repositories and images manually:"
echo "  aws ecr delete-repository --repository-name iai-backend --region $REGION --force"
echo "  aws ecr delete-repository --repository-name iai-frontend --region $REGION --force"
echo ""
echo "🎉 Cleanup complete!"
