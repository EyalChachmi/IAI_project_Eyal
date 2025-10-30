# IAI Project - User Management System

A full-stack web application with a **Python Flask** backend and **React** frontend for managing and searching users.

## Project Structure

```
IAI Project/
├── backend/           # Flask API server
│   ├── app.py        # Main Flask application
│   ├── requirements.txt
│   ├── data/
│   │   └── users.json  # Sample users data
│   └── README.md
├── frontend/          # React application
│   ├── public/
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── services/    # API service
│   │   ├── App.js
│   │   └── index.js
│   ├── package.json
│   └── README.md
└── README.md          # This file
```

## Features

### Backend (Flask)
- RESTful API with CORS support
- Endpoints for:
  - Get all users
  - Get user by ID
  - Search users by ID (partial match)
- JSON-based data storage
- Error handling

### Frontend (React)
- Display list of users in a modern card layout
- Search functionality to filter users by ID
- Responsive design (mobile, tablet, desktop)
- Real-time API integration
- Beautiful gradient UI

## Installation & Setup

### Prerequisites
- Python 3.8+
- Node.js 14+
- npm or yarn

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

3. Run the Flask server:
```bash
python app.py
```

The backend will run on `http://localhost:5000`

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install npm dependencies:
```bash
npm install
```

3. Start the React development server:
```bash
npm start
```

The frontend will run on `http://localhost:3000`

## Usage

1. **Start the Backend**: Make sure the Flask server is running first
2. **Start the Frontend**: Launch the React application
3. **View Users**: The application will display all users on load
4. **Search by ID**: Use the search bar to filter users by their ID
5. **Clear Search**: Click "Show All Users" to reset the filter

## API Endpoints

### Backend API (Flask)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/users` | Get all users |
| GET | `/api/users/<id>` | Get a specific user by ID |
| GET | `/api/users/search/<id>` | Search users by ID (partial match) |
| GET | `/api/health` | Health check endpoint |

### Example Response

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@example.com",
      "phone": "+1-555-0101",
      "role": "Developer"
    }
  ],
  "count": 1
}
```

## Technologies Used

### Backend
- Python 3
- Flask - Web framework
- Flask-CORS - Cross-origin resource sharing

### Frontend
- React 18 - UI library
- Axios - HTTP client
- CSS3 - Styling

## Development

### Adding New Users

Edit `backend/data/users.json` to add or modify users.

### Modifying the API

Edit `backend/app.py` to add new endpoints or modify existing ones.

### Customizing the UI

- Component files are in `frontend/src/components/`
- Styling files are in `frontend/src/components/*.css`

## Troubleshooting

### Backend not connecting
- Make sure Flask is running on port 5000
- Check for any Python dependency errors

### Frontend API errors
- Verify the backend is running
- Check the API URL in `frontend/src/services/api.js`
- Ensure CORS is properly configured

### Port conflicts
- Backend: Change port in `backend/app.py`
- Frontend: Set `PORT=3001` in environment or `.env` file

## License

This project is for educational purposes (IAI Project).

## Author

Created for IAI Project requirements.
