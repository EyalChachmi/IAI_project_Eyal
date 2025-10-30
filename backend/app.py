from flask import Flask, jsonify, request
from flask_cors import CORS
import json
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Load users data
def load_users():
    """Load users from JSON file"""
    try:
        users_file = os.path.join(os.path.dirname(__file__), 'data', 'users.json')
        with open(users_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return []
    except json.JSONDecodeError:
        return []

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'success': True,
        'message': 'Server is running'
    })

@app.route('/api/users', methods=['GET'])
def get_all_users():
    """Get all users"""
    try:
        users = load_users()
        return jsonify({
            'success': True,
            'data': users,
            'count': len(users)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': 'Error fetching users',
            'error': str(e)
        }), 500

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user_by_id(user_id):
    """Get a specific user by ID"""
    try:
        users = load_users()
        user = next((u for u in users if u['id'] == user_id), None)
        
        if user:
            return jsonify({
                'success': True,
                'data': user
            })
        else:
            return jsonify({
                'success': False,
                'message': f'User with ID {user_id} not found'
            }), 404
    except Exception as e:
        return jsonify({
            'success': False,
            'message': 'Error fetching user',
            'error': str(e)
        }), 500

@app.route('/api/users/search/<search_id>', methods=['GET'])
def search_users_by_id(search_id):
    """Search users by ID (partial match)"""
    try:
        users = load_users()
        # Filter users whose ID contains the search string
        filtered_users = [u for u in users if str(search_id) in str(u['id'])]
        
        return jsonify({
            'success': True,
            'data': filtered_users,
            'count': len(filtered_users)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': 'Error searching users',
            'error': str(e)
        }), 500

if __name__ == '__main__':
    print('Flask server starting...')
    print('API Endpoints:')
    print('  - GET  http://localhost:5000/api/users')
    print('  - GET  http://localhost:5000/api/users/<id>')
    print('  - GET  http://localhost:5000/api/users/search/<id>')
    app.run(debug=True, port=5000)
