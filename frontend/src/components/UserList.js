import React from 'react';
import './UserList.css';
import UserCard from './UserCard';

function UserList({ users, searchId }) {
  if (users.length === 0) {
    return (
      <div className="no-users">
        <div className="no-users-icon">🔍</div>
        <h3>No users found</h3>
        <p>
          {searchId 
            ? `No users match ID "${searchId}"`
            : 'No users available in the system'
          }
        </p>
      </div>
    );
  }

  return (
    <div className="user-list-container">
      <div className="user-list-header">
        <h2>Users List</h2>
        <span className="user-count">{users.length} user{users.length !== 1 ? 's' : ''} found</span>
      </div>
      <div className="user-list">
        {users.map((user) => (
          <UserCard key={user.id} user={user} />
        ))}
      </div>
    </div>
  );
}

export default UserList;
