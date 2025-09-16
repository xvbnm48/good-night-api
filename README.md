# Good Night App API

A Rails API application for tracking sleep records and user relationships. Users can clock in/out their sleep times and follow other users to see their sleep records.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Features](#features)

## Prerequisites

- Ruby 3.3.7
- Rails 8.0.2.1
- SQLite3 (for development)

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd good_night_app
```

2. Install dependencies:

```bash
bundle install
```

## Configuration

The application uses SQLite3 for development and test environments. Database configuration is located in `config/database.yml`.

## Database Setup

1. Create and setup the database:

```bash
rails db:create
rails db:migrate
```

2. (Optional) Seed the database:

```bash
rails db:seed
```

## Running the Application

1. Start the Rails server:

```bash
rails server
```

2. The API will be available at: `http://localhost:3000`

## API Documentation

### Base URL

```
http://localhost:3000/api/v1
```

### Response Format

All responses follow this format:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error message",
  "errors": ["Detailed error"]
}
```

---

## Users Endpoints

### 1. Get All Users

```
GET /api/v1/users
```

**Response:**

```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": {
    "users": [
      {
        "id": 1,
        "name": "John Doe",
        "created_at": "2025-09-16T16:00:00.000Z"
      }
    ],
    "total_count": 1
  }
}
```

### 2. Get Specific User

```
GET /api/v1/users/:id
```

**Response:**

```json
{
  "success": true,
  "message": "User retrieved successfully",
  "data": {
    "id": 1,
    "name": "John Doe",
    "created_at": "2025-09-16T16:00:00.000Z"
  }
}
```

### 3. Create New User

```
POST /api/v1/users
```

**Request Body:**

```json
{
  "name": "John Doe"
}
```

**Response:**

```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": 1,
    "name": "John Doe",
    "created_at": "2025-09-16T16:00:00.000Z"
  }
}
```

---

## Sleep Records Endpoints

### 1. Clock In/Out

```
POST /api/v1/users/:user_id/sleep_records/clock_in
```

**Description:**

- If user has no active sleep record: creates a new record (clock in)
- If user has an active sleep record: closes it (clock out)

**Response (Clock In):**

```json
{
  "success": true,
  "message": "Successfully clocked in",
  "data": {
    "id": 1,
    "user_id": 1,
    "clock_in_time": "2025-09-16T22:00:00.000Z",
    "clock_out_time": null,
    "duration_hours": null,
    "status": "in_progress"
  }
}
```

**Response (Clock Out):**

```json
{
  "success": true,
  "message": "Successfully clocked out",
  "data": {
    "id": 1,
    "user_id": 1,
    "clock_in_time": "2025-09-16T22:00:00.000Z",
    "clock_out_time": "2025-09-17T06:00:00.000Z",
    "duration_hours": 8.0,
    "status": "completed"
  }
}
```

### 2. Get User's Sleep Records

```
GET /api/v1/users/:user_id/sleep_records
```

**Query Parameters:**

- `page` (optional): Page number (default: 1)
- `per_page` (optional): Records per page (default: 20, max: 100)

**Response:**

```json
{
  "success": true,
  "message": "Sleep records retrieved successfully",
  "data": {
    "sleep_records": [
      {
        "id": 1,
        "user_id": 1,
        "clock_in_time": "2025-09-16T22:00:00.000Z",
        "clock_out_time": "2025-09-17T06:00:00.000Z",
        "duration_hours": 8.0,
        "status": "completed"
      }
    ],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total_count": 5,
      "total_pages": 1
    }
  }
}
```

### 3. Get Specific Sleep Record

```
GET /api/v1/users/:user_id/sleep_records/:id
```

### 4. Get Following Users' Sleep Records

```
GET /api/v1/users/:user_id/sleep_records/following_sleep_records
```

**Description:** Returns sleep records from users that the current user follows, ordered by sleep duration.

**Response:**

```json
{
  "success": true,
  "message": "Following sleep records retrieved successfully",
  "data": {
    "sleep_records": [
      {
        "id": 1,
        "user": {
          "id": 2,
          "name": "Jane Doe"
        },
        "clock_in_time": "2025-09-16T22:00:00.000Z",
        "clock_out_time": "2025-09-17T07:00:00.000Z",
        "duration_hours": 9.0,
        "status": "completed"
      }
    ]
  }
}
```

---

## User Following Endpoints

### 1. Follow a User

```
POST /api/v1/users/:user_id/followings
```

**Request Body:**

```json
{
  "followed_user_id": 2
}
```

**Response:**

```json
{
  "success": true,
  "message": "Successfully followed user",
  "data": {
    "follower": {
      "id": 1,
      "name": "John Doe"
    },
    "followed": {
      "id": 2,
      "name": "Jane Doe"
    }
  }
}
```

### 2. Get Users I'm Following

```
GET /api/v1/users/:user_id/followings
```

**Response:**

```json
{
  "success": true,
  "message": "Following list retrieved successfully",
  "data": {
    "following": [
      {
        "id": 2,
        "name": "Jane Doe",
        "created_at": "2025-09-16T16:00:00.000Z"
      }
    ],
    "total_count": 1
  }
}
```

### 3. Get My Followers

```
GET /api/v1/users/:user_id/followings/followers
```

**Response:**

```json
{
  "success": true,
  "message": "Followers list retrieved successfully",
  "data": {
    "followers": [
      {
        "id": 3,
        "name": "Bob Smith",
        "created_at": "2025-09-16T16:00:00.000Z"
      }
    ],
    "total_count": 1
  }
}
```

### 4. Unfollow a User

```
DELETE /api/v1/users/:user_id/followings/:followed_user_id
```

**Response:**

```json
{
  "success": true,
  "message": "Successfully unfollowed user",
  "data": {
    "follower": {
      "id": 1,
      "name": "John Doe"
    },
    "unfollowed": {
      "id": 2,
      "name": "Jane Doe"
    }
  }
}
```

---

## Error Codes

| HTTP Status | Description |
|-------------|-------------|
| 200 | Success |
| 201 | Created successfully |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource doesn't exist |
| 422 | Unprocessable Entity - Validation failed |
| 500 | Internal Server Error |

---

## Example Usage

### Complete User Flow

1. **Create a user:**

```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John Doe"}'
```

2. **Clock in for sleep:**

```bash
curl -X POST http://localhost:3000/api/v1/users/1/sleep_records/clock_in
```

3. **Clock out (after some time):**

```bash
curl -X POST http://localhost:3000/api/v1/users/1/sleep_records/clock_in
```

4. **Follow another user:**

```bash
curl -X POST http://localhost:3000/api/v1/users/1/followings \
  -H "Content-Type: application/json" \
  -d '{"followed_user_id": 2}'
```

5. **View following users' sleep records:**

```bash
curl http://localhost:3000/api/v1/users/1/sleep_records/following_sleep_records
```

---

## Features

### Core Features

- ✅ User management (create, view)
- ✅ Sleep tracking with clock in/out functionality
- ✅ User following system
- ✅ View sleep records of followed users
- ✅ Sleep records ordered by duration

### Additional Features

- ✅ Pagination support
- ✅ Input validation
- ✅ Duplicate prevention (following same user twice)
- ✅ Performance optimized queries
- ✅ Comprehensive error handling
- ✅ RESTful API design

### Database Features

- ✅ Optimized indexes for performance
- ✅ Foreign key constraints
- ✅ Unique constraints for data integrity

---

## Testing

Run the test suite:

```bash
rspec
```

## Development

### Database Console

```bash
rails dbconsole
```

### Rails Console

```bash
rails console
```

### View Routes

```bash
rails routes
```

---

## Architecture

### Models

- **User**: Manages user data and relationships
- **SleepRecord**: Tracks sleep sessions with clock in/out times
- **UserFollowing**: Manages user-to-user following relationships

### Controllers

- **UsersController**: User CRUD operations
- **SleepRecordsController**: Sleep tracking functionality
- **UserFollowingsController**: Following/follower management

### Key Design Decisions

- Used SQLite for simplicity in development
- Implemented clock in/out as a single endpoint for better UX
- Added pagination for scalability
- Used proper HTTP status codes and response format
- Implemented comprehensive input validation
