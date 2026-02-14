# Backend Implementation Plan: Competition Management

## Overview
This document outlines the backend implementation plan for the Competition Create and List screens. It covers database schema, API endpoints, validation rules, file handling, and security considerations.

---

## 1. Database Schema

### 1.1 Competitions Table

```sql
CREATE TABLE competitions (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    competition_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    event_start_date DATE NOT NULL,
    event_end_date DATE NOT NULL,
    display_ad_from DATE,
    spot_registration BOOLEAN DEFAULT FALSE,
    participants_per_stage INT CHECK (participants_per_stage >= 1 AND participants_per_stage <= 5),
    minimum_marks INT CHECK (minimum_marks >= 0 AND minimum_marks <= 100),
    maximum_marks INT CHECK (maximum_marks >= 0 AND maximum_marks <= 100),
    brochure_url VARCHAR(500),
    brochure_file_path VARCHAR(500),
    created_by VARCHAR(36),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_dates CHECK (event_end_date >= event_start_date),
    CONSTRAINT chk_marks CHECK (maximum_marks >= minimum_marks),
    
    -- Indexes
    INDEX idx_event_start_date (event_start_date),
    INDEX idx_event_end_date (event_end_date),
    INDEX idx_created_at (created_at),
    INDEX idx_competition_name (competition_name)
);
```

### 1.2 Competition Prizes Table (Many-to-Many)

```sql
CREATE TABLE competition_prizes (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    competition_id VARCHAR(36) NOT NULL,
    prize_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (competition_id) REFERENCES competitions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_competition_prize (competition_id, prize_name),
    INDEX idx_competition_id (competition_id)
);
```

### 1.3 Competition Categories Table (Many-to-Many)

```sql
CREATE TABLE competition_categories (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    competition_id VARCHAR(36) NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    amount DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (competition_id) REFERENCES competitions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_competition_category (competition_id, category_name),
    INDEX idx_competition_id (competition_id)
);
```

### 1.4 Competition Stages Table (Many-to-Many)

```sql
CREATE TABLE competition_stages (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    competition_id VARCHAR(36) NOT NULL,
    stage_name VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (competition_id) REFERENCES competitions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_competition_stage (competition_id, stage_name),
    INDEX idx_competition_id (competition_id)
);
```

### 1.5 Competition Stage Groups Table (Many-to-Many)

```sql
CREATE TABLE competition_stage_groups (
    id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
    competition_id VARCHAR(36) NOT NULL,
    stage_name VARCHAR(10) NOT NULL,
    group_name VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (competition_id) REFERENCES competitions(id) ON DELETE CASCADE,
    UNIQUE KEY unique_competition_stage_group (competition_id, stage_name, group_name),
    INDEX idx_competition_id (competition_id),
    INDEX idx_stage_name (stage_name)
);
```

---

## 2. API Endpoints

### 2.1 Create Competition

**Endpoint:** `POST /api/competitions`

**Authentication:** Required (Admin/Sub-Admin role)

**Request Headers:**
```
Content-Type: multipart/form-data (if brochure included)
Authorization: Bearer <token>
```

**Request Body (Form Data):**
```json
{
  "competitionName": "Yoga Championship 2024",
  "description": "Annual yoga championship competition",
  "address": "123 Yoga Street, Wellness City, 12345",
  "eventStartDate": "2024-06-01",
  "eventEndDate": "2024-06-05",
  "displayAdFrom": "2024-05-15",
  "spotRegistration": true,
  "participantsPerStage": 3,
  "minimumMarks": 0,
  "maximumMarks": 100,
  "prizes": ["1st", "2nd", "3rd", "4th", "5th"],
  "categories": ["COMMON", "SPECIAL", "CHAMPIONS"],
  "categoryAmounts": {
    "COMMON": 500.0,
    "SPECIAL": 600.0,
    "CHAMPIONS": 700.0
  },
  "stages": ["A", "B", "C"],
  "stageGroups": {
    "A": ["II", "III"],
    "B": ["IV", "V"],
    "C": ["VI", "VII"]
  },
  "brochure": <file> (optional, PDF/Image)
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Competition created successfully",
  "data": {
    "id": "uuid-here",
    "competitionName": "Yoga Championship 2024",
    "description": "Annual yoga championship competition",
    "address": "123 Yoga Street, Wellness City, 12345",
    "eventStartDate": "2024-06-01",
    "eventEndDate": "2024-06-05",
    "displayAdFrom": "2024-05-15",
    "spotRegistration": true,
    "participantsPerStage": 3,
    "minimumMarks": 0,
    "maximumMarks": 100,
    "prizes": ["1st", "2nd", "3rd", "4th", "5th"],
    "categories": ["COMMON", "SPECIAL", "CHAMPIONS"],
    "categoryAmounts": {
      "COMMON": 500.0,
      "SPECIAL": 600.0,
      "CHAMPIONS": 700.0
    },
    "stages": ["A", "B", "C"],
    "stageGroups": {
      "A": ["II", "III"],
      "B": ["IV", "V"],
      "C": ["VI", "VII"]
    },
    "brochureUrl": "https://storage.example.com/brochures/uuid.pdf",
    "createdAt": "2024-04-01T10:00:00Z",
    "updatedAt": "2024-04-01T10:00:00Z"
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "competitionName": ["Competition name is required"],
    "eventStartDate": ["Event start date must be in the future"],
    "eventEndDate": ["Event end date must be after start date"]
  }
}
```

### 2.2 Get All Competitions

**Endpoint:** `GET /api/competitions`

**Authentication:** Required (Admin/Sub-Admin/Judge/Jury)

**Query Parameters:**
```
?search=keyword (optional) - Search by name, description, or address
?status=upcoming|ongoing|completed (optional) - Filter by status
?page=1 (optional) - Page number for pagination
?limit=20 (optional) - Items per page
?sortBy=createdAt|eventStartDate|eventEndDate (optional)
?order=asc|desc (optional)
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Competitions retrieved successfully",
  "data": [
    {
      "id": "uuid-here",
      "competitionName": "Yoga Championship 2024",
      "description": "Annual yoga championship competition",
      "address": "123 Yoga Street, Wellness City, 12345",
      "eventStartDate": "2024-06-01",
      "eventEndDate": "2024-06-05",
      "displayAdFrom": "2024-05-15",
      "spotRegistration": true,
      "participantsPerStage": 3,
      "minimumMarks": 0,
      "maximumMarks": 100,
      "prizes": ["1st", "2nd", "3rd", "4th", "5th"],
      "categories": ["COMMON", "SPECIAL", "CHAMPIONS"],
      "categoryAmounts": {
        "COMMON": 500.0,
        "SPECIAL": 600.0,
        "CHAMPIONS": 700.0
      },
      "stages": ["A", "B", "C"],
      "stageGroups": {
        "A": ["II", "III"],
        "B": ["IV", "V"],
        "C": ["VI", "VII"]
      },
      "brochureUrl": "https://storage.example.com/brochures/uuid.pdf",
      "status": "upcoming",
      "createdAt": "2024-04-01T10:00:00Z",
      "updatedAt": "2024-04-01T10:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 50,
    "totalPages": 3
  }
}
```

**Response (Error - 500):**
```json
{
  "success": false,
  "message": "Failed to fetch competitions",
  "error": "Internal server error"
}
```

### 2.3 Get Competition by ID

**Endpoint:** `GET /api/competitions/:id`

**Authentication:** Required

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    // Same structure as create response
  }
}
```

### 2.4 Update Competition

**Endpoint:** `PUT /api/competitions/:id`

**Authentication:** Required (Admin/Sub-Admin role)

**Request Body:** Same as create, but all fields optional

**Response:** Same structure as create

### 2.5 Delete Competition

**Endpoint:** `DELETE /api/competitions/:id`

**Authentication:** Required (Admin role only)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Competition deleted successfully"
}
```

---

## 3. Validation Rules

### 3.1 Competition Name
- **Required:** Yes
- **Type:** String
- **Min Length:** 3 characters
- **Max Length:** 255 characters
- **Pattern:** Alphanumeric, spaces, hyphens, underscores allowed

### 3.2 Description
- **Required:** Yes
- **Type:** String
- **Min Length:** 10 characters
- **Max Length:** 2000 characters

### 3.3 Address
- **Required:** Yes
- **Type:** String
- **Min Length:** 10 characters
- **Max Length:** 500 characters

### 3.4 Event Start Date
- **Required:** Yes
- **Type:** Date (ISO 8601 format: YYYY-MM-DD)
- **Validation:** Must be today or in the future
- **Format:** YYYY-MM-DD

### 3.5 Event End Date
- **Required:** Yes
- **Type:** Date
- **Validation:** Must be after or equal to event start date
- **Format:** YYYY-MM-DD

### 3.6 Display Ad From
- **Required:** Yes
- **Type:** Date
- **Validation:** Must be before or equal to event start date
- **Format:** YYYY-MM-DD

### 3.7 Spot Registration
- **Required:** Yes
- **Type:** Boolean
- **Default:** false

### 3.8 Participants Per Stage
- **Required:** Yes
- **Type:** Integer
- **Range:** 1-5
- **Validation:** Must be between 1 and 5

### 3.9 Minimum Marks
- **Required:** No
- **Type:** Integer
- **Range:** 0-100
- **Validation:** If provided, must be between 0 and 100, and less than maximum marks

### 3.10 Maximum Marks
- **Required:** No
- **Type:** Integer
- **Range:** 0-100
- **Validation:** If provided, must be between 0 and 100, and greater than minimum marks

### 3.11 Prizes
- **Required:** Yes
- **Type:** Array of Strings
- **Min Items:** 1
- **Max Items:** 20
- **Validation:** Each prize name must be unique, 1-50 characters

### 3.12 Categories
- **Required:** Yes
- **Type:** Array of Strings
- **Min Items:** 1
- **Max Items:** 20
- **Validation:** Each category name must be unique, 1-50 characters

### 3.13 Category Amounts
- **Required:** No (but required if categories exist)
- **Type:** Object (Map<String, Double>)
- **Validation:** 
  - Keys must match selected categories
  - Values must be >= 0
  - Max value: 999999.99

### 3.14 Stages
- **Required:** Yes
- **Type:** Array of Strings
- **Min Items:** 1
- **Max Items:** 26 (A-Z)
- **Validation:** Each stage name must be unique, 1-10 characters

### 3.15 Stage Groups
- **Required:** No (but required if stages exist)
- **Type:** Object (Map<String, Array<String>>)
- **Validation:**
  - Keys must match selected stages
  - Each group name must be unique within a stage
  - Valid group names: II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, UG, PG

### 3.16 Brochure File
- **Required:** Yes
- **Type:** File (multipart/form-data)
- **Allowed Types:** PDF, JPG, JPEG, PNG
- **Max Size:** 10 MB
- **Validation:** 
  - File must be valid PDF or image
  - File size must not exceed 10 MB

---

## 4. Business Logic

### 4.1 Competition Status Calculation

```javascript
function calculateCompetitionStatus(competition) {
  const now = new Date();
  const startDate = new Date(competition.eventStartDate);
  const endDate = new Date(competition.eventEndDate);
  
  if (now < startDate) {
    return 'upcoming';
  } else if (now >= startDate && now <= endDate) {
    return 'ongoing';
  } else {
    return 'completed';
  }
}
```

### 4.2 Search Functionality

Search should match against:
- Competition name (partial match, case-insensitive)
- Description (partial match, case-insensitive)
- Address (partial match, case-insensitive)

### 4.3 Filter Functionality

Filter by status:
- **upcoming:** eventStartDate > current date
- **ongoing:** current date between eventStartDate and eventEndDate
- **completed:** eventEndDate < current date

### 4.4 Stage Group Validation

- Each group can only be assigned to one stage per competition
- If a group is already assigned to a stage, it cannot be assigned to another stage
- Groups must be from the predefined list: II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, UG, PG

---

## 5. File Upload Handling

### 5.1 Brochure Storage

**Storage Location:** Cloud storage (AWS S3, Google Cloud Storage, or Azure Blob Storage)

**File Naming Convention:** `competitions/{competition_id}/brochure_{timestamp}.{extension}`

**Supported Formats:**
- PDF (preferred)
- Images: JPG, JPEG, PNG

**File Size Limit:** 10 MB

**Storage Path Structure:**
```
storage/
  competitions/
    {competition_id}/
      brochure/
        original_{timestamp}.pdf
        thumbnail_{timestamp}.jpg (if image)
```

### 5.2 File Upload Process

1. Validate file type and size
2. Generate unique filename
3. Upload to cloud storage
4. Store file URL in database
5. Return public URL to client

### 5.3 File Deletion

When a competition is deleted:
- Delete associated brochure file from storage
- Remove file reference from database

---

## 6. Security Considerations

### 6.1 Authentication & Authorization

- **Create Competition:** Admin, Sub-Admin only
- **View Competitions:** Admin, Sub-Admin, Judge, Jury
- **Update Competition:** Admin, Sub-Admin only
- **Delete Competition:** Admin only

### 6.2 Input Sanitization

- Sanitize all string inputs to prevent XSS attacks
- Validate and sanitize file uploads
- Use parameterized queries to prevent SQL injection

### 6.3 Rate Limiting

- **Create Competition:** 10 requests per hour per user
- **Get Competitions:** 100 requests per minute per user

### 6.4 Data Validation

- Validate all inputs server-side (never trust client-side validation)
- Reject requests with invalid data types
- Enforce business rules and constraints

---

## 7. Error Handling

### 7.1 Error Response Format

```json
{
  "success": false,
  "message": "Error message",
  "errors": {
    "fieldName": ["Error message 1", "Error message 2"]
  },
  "errorCode": "VALIDATION_ERROR",
  "timestamp": "2024-04-01T10:00:00Z"
}
```

### 7.2 Error Codes

- **VALIDATION_ERROR (400):** Input validation failed
- **UNAUTHORIZED (401):** Authentication required
- **FORBIDDEN (403):** Insufficient permissions
- **NOT_FOUND (404):** Resource not found
- **CONFLICT (409):** Resource conflict (e.g., duplicate name)
- **FILE_TOO_LARGE (413):** File size exceeds limit
- **UNSUPPORTED_MEDIA_TYPE (415):** Invalid file type
- **INTERNAL_SERVER_ERROR (500):** Server error
- **SERVICE_UNAVAILABLE (503):** External service unavailable

### 7.3 Logging

Log all errors with:
- Timestamp
- User ID
- Request details
- Error stack trace
- Error code

---

## 8. Performance Optimization

### 8.1 Database Indexing

- Index on `competition_name` for search
- Index on `event_start_date` and `event_end_date` for filtering
- Index on `created_at` for sorting
- Composite indexes for common query patterns

### 8.2 Caching Strategy

- Cache competition list for 5 minutes
- Invalidate cache on create/update/delete
- Use Redis for caching

### 8.3 Pagination

- Default page size: 20 items
- Maximum page size: 100 items
- Include total count in response

### 8.4 Query Optimization

- Use eager loading for related data (prizes, categories, stages)
- Avoid N+1 queries
- Use database views for complex queries

---

## 9. Testing Requirements

### 9.1 Unit Tests

- Test all validation rules
- Test business logic functions
- Test data transformation

### 9.2 Integration Tests

- Test API endpoints
- Test database operations
- Test file upload functionality

### 9.3 Test Cases

**Create Competition:**
- ✅ Valid competition creation
- ✅ Missing required fields
- ✅ Invalid date ranges
- ✅ Invalid file type
- ✅ File size too large
- ✅ Duplicate competition name
- ✅ Invalid marks range
- ✅ Unauthorized access

**Get Competitions:**
- ✅ Retrieve all competitions
- ✅ Search functionality
- ✅ Filter by status
- ✅ Pagination
- ✅ Sorting
- ✅ Empty result set

---

## 10. API Implementation Example (Node.js/Express)

```javascript
// routes/competitions.js
const express = require('express');
const multer = require('multer');
const router = express.Router();
const competitionController = require('../controllers/competitionController');
const { authenticate, authorize } = require('../middleware/auth');
const { validateCompetition } = require('../middleware/validation');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only PDF, JPG, and PNG are allowed.'));
    }
  }
});

// Create competition
router.post(
  '/',
  authenticate,
  authorize(['admin', 'sub-admin']),
  upload.single('brochure'),
  validateCompetition,
  competitionController.createCompetition
);

// Get all competitions
router.get(
  '/',
  authenticate,
  authorize(['admin', 'sub-admin', 'judge', 'jury']),
  competitionController.getAllCompetitions
);

// Get competition by ID
router.get(
  '/:id',
  authenticate,
  competitionController.getCompetitionById
);

// Update competition
router.put(
  '/:id',
  authenticate,
  authorize(['admin', 'sub-admin']),
  upload.single('brochure'),
  competitionController.updateCompetition
);

// Delete competition
router.delete(
  '/:id',
  authenticate,
  authorize(['admin']),
  competitionController.deleteCompetition
);

module.exports = router;
```

---

## 11. Database Migration Scripts

### 11.1 Initial Migration

```sql
-- Create competitions table
CREATE TABLE competitions (...);

-- Create related tables
CREATE TABLE competition_prizes (...);
CREATE TABLE competition_categories (...);
CREATE TABLE competition_stages (...);
CREATE TABLE competition_stage_groups (...);

-- Create indexes
CREATE INDEX idx_event_start_date ON competitions(event_start_date);
CREATE INDEX idx_event_end_date ON competitions(event_end_date);
CREATE INDEX idx_created_at ON competitions(created_at);
CREATE INDEX idx_competition_name ON competitions(competition_name);
```

### 11.2 Seed Data (Optional)

```sql
-- Insert sample competition for testing
INSERT INTO competitions (
  id, competition_name, description, address,
  event_start_date, event_end_date, display_ad_from,
  spot_registration, participants_per_stage
) VALUES (
  UUID(), 'Sample Competition', 'Sample description',
  'Sample address', '2024-06-01', '2024-06-05', '2024-05-15',
  TRUE, 3
);
```

---

## 12. Deployment Checklist

- [ ] Database tables created and migrated
- [ ] API endpoints implemented and tested
- [ ] File upload functionality configured
- [ ] Cloud storage configured
- [ ] Authentication/Authorization middleware implemented
- [ ] Validation rules implemented
- [ ] Error handling implemented
- [ ] Logging configured
- [ ] Rate limiting configured
- [ ] Caching configured
- [ ] Unit tests written and passing
- [ ] Integration tests written and passing
- [ ] API documentation updated
- [ ] Security audit completed
- [ ] Performance testing completed

---

## 13. API Documentation

### 13.1 Swagger/OpenAPI Specification

Generate OpenAPI 3.0 specification for all endpoints including:
- Request/Response schemas
- Authentication requirements
- Error responses
- Example requests/responses

### 13.2 Postman Collection

Create Postman collection with:
- All endpoints
- Example requests
- Environment variables
- Test scripts

---

## 14. Monitoring & Analytics

### 14.1 Metrics to Track

- Number of competitions created per day
- Average competition creation time
- File upload success rate
- API response times
- Error rates by endpoint

### 14.2 Alerts

- High error rate (> 5%)
- Slow response times (> 2 seconds)
- Storage quota warnings
- Failed file uploads

---

## 15. Future Enhancements

- Bulk import/export competitions
- Competition templates
- Competition cloning
- Advanced search with filters
- Competition analytics dashboard
- Email notifications for competition creation
- Competition approval workflow

---

## Conclusion

This implementation plan provides a comprehensive guide for building the backend for the Competition Management system. Follow the schema design, API specifications, and validation rules to ensure a robust and secure implementation.

