import React, { useState } from 'react';
import './SearchBar.css';

function SearchBar({ onSearch, onClear, searchValue }) {
  const [inputValue, setInputValue] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSearch(inputValue);
  };

  const handleClear = () => {
    setInputValue('');
    onClear();
  };

  return (
    <div className="search-bar-container">
      <form onSubmit={handleSubmit} className="search-form">
        <div className="search-input-wrapper">
          <span className="search-icon">🔍</span>
          <input
            type="text"
            className="search-input"
            placeholder="Search users by ID (e.g., 1, 2, 3...)"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
          />
          {inputValue && (
            <button
              type="button"
              className="clear-button"
              onClick={handleClear}
              title="Clear search"
            >
              ✕
            </button>
          )}
        </div>
        <button type="submit" className="search-button">
          Search
        </button>
      </form>
      {searchValue && (
        <div className="search-info">
          Showing results for ID: <strong>{searchValue}</strong>
          <button className="show-all-button" onClick={handleClear}>
            Show All Users
          </button>
        </div>
      )}
    </div>
  );
}

export default SearchBar;
