import React, { useState, useEffect } from 'react';
import './App.css';
import UserList from './components/UserList';
import SearchBar from './components/SearchBar';
import { fetchUsers, searchUserById } from './services/api';

function App() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchId, setSearchId] = useState('');

  // Fetch all users on component mount
  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchUsers();
      setUsers(data);
      setSearchId('');
    } catch (err) {
      setError('Failed to load users. Please make sure the backend server is running.');
      console.error('Error loading users:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async (id) => {
    if (!id.trim()) {
      // If search is empty, reload all users
      loadUsers();
      return;
    }

    try {
      setLoading(true);
      setError(null);
      const data = await searchUserById(id);
      setUsers(data);
      setSearchId(id);
    } catch (err) {
      setError('Failed to search users. Please try again.');
      console.error('Error searching users:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleClearSearch = () => {
    loadUsers();
  };

  return (
    <div className="App">
      <div className="container">
        <header className="header">
          <h1>User Management System</h1>
          <p className="subtitle">IAI Project - User Directory</p>
        </header>

        <SearchBar 
          onSearch={handleSearch}
          onClear={handleClearSearch}
          searchValue={searchId}
        />

        {error && (
          <div className="error-message">
            <p>{error}</p>
          </div>
        )}

        {loading ? (
          <div className="loading">
            <div className="spinner"></div>
            <p>Loading users...</p>
          </div>
        ) : (
          <UserList users={users} searchId={searchId} />
        )}
      </div>
    </div>
  );
}

export default App;
