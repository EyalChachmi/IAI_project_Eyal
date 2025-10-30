# Flask Backend API

## Installation

```bash
cd backend
pip install -r requirements.txt
```

## Running the Server

```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### Get All Users
- **URL**: `/api/users`
- **Method**: `GET`
- **Response**: Returns all users

### Get User by ID
- **URL**: `/api/users/<id>`
- **Method**: `GET`
- **Response**: Returns a specific user by ID

### Search Users by ID
- **URL**: `/api/users/search/<id>`
- **Method**: `GET`
- **Response**: Returns users whose ID contains the search string

### Health Check
- **URL**: `/api/health`
- **Method**: `GET`
- **Response**: Server status
