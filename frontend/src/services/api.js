import axios from 'axios';

// Use relative path so nginx can proxy to backend
// In development: http://localhost:5000/api
// In production: /api (proxied by nginx to backend service)
const API_BASE_URL = process.env.NODE_ENV === 'production' 
  ? '/api' 
  : 'http://localhost:5000/api';

// Create axios instance with default config
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json',
  },
});

/**
 * Fetch all users
 * @returns {Promise<Array>} Array of user objects
 */
export const fetchUsers = async () => {
  try {
    const response = await api.get('/users');
    return response.data.data;
  } catch (error) {
    console.error('Error fetching users:', error);
    throw error;
  }
};

/**
 * Fetch a single user by ID
 * @param {number} id - User ID
 * @returns {Promise<Object>} User object
 */
export const fetchUserById = async (id) => {
  try {
    const response = await api.get(`/users/${id}`);
    return response.data.data;
  } catch (error) {
    console.error(`Error fetching user ${id}:`, error);
    throw error;
  }
};

/**
 * Search users by ID (partial match)
 * @param {string} searchId - Search string for user ID
 * @returns {Promise<Array>} Array of matching user objects
 */
export const searchUserById = async (searchId) => {
  try {
    const response = await api.get(`/users/search/${searchId}`);
    return response.data.data;
  } catch (error) {
    console.error('Error searching users:', error);
    throw error;
  }
};

export default api;
