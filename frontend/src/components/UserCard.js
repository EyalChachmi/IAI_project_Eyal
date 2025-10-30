import React from 'react';
import './UserCard.css';

function UserCard({ user }) {
  return (
    <div className="user-card">
      <div className="user-card-header">
        <div className="user-avatar">
          {user.name.charAt(0).toUpperCase()}
        </div>
        <div className="user-id-badge">ID: {user.id}</div>
      </div>
      <div className="user-card-body">
        <h3 className="user-name">{user.name}</h3>
        <div className="user-role">{user.role}</div>
        <div className="user-details">
          <div className="user-detail">
            <span className="detail-icon">📧</span>
            <span className="detail-text">{user.email}</span>
          </div>
          <div className="user-detail">
            <span className="detail-icon">📱</span>
            <span className="detail-text">{user.phone}</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export default UserCard;
