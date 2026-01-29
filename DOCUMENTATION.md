# Yogasana Championship 2025 - User Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Getting Started](#getting-started)
3. [User Roles](#user-roles)
4. [Step-by-Step Guides](#step-by-step-guides)
5. [How It Works](#how-it-works)
6. [Troubleshooting](#troubleshooting)

---

## Project Overview

**Yogasana Championship 2025** is a comprehensive event management system for yoga competitions. The application manages:

- **Event Management**: Create and manage yoga competition events
- **Participant Registration**: Register participants for events
- **Judge Management**: Manage judges and their assignments
- **Scoring System**: Record and calculate scores from multiple judges
- **Participant Management**: View and manage participant details
- **Certificate Generation**: Download participant certificates

### Key Features
- ✅ Multi-role access (Admin, Judge, Participant)
- ✅ Event creation and management
- ✅ Participant registration with photo upload
- ✅ Judge assignment to participants
- ✅ Multi-judge scoring system
- ✅ Real-time score calculation
- ✅ Certificate download
- ✅ Responsive web design

---

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Web browser (Chrome, Firefox, Edge)
- Backend API server running

### Installation

1. **Clone or download the project**
   ```bash
   cd yoga_champ
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   - For QA: Use `lib/main_qa.dart`
   - For Production: Use `lib/main_prod.dart`
   - Update API URLs in `lib/config/app_config.dart`

4. **Run the application**
   ```bash
   # For Development
   flutter run -d chrome -t lib/main.dart
   
   # For QA Environment
   flutter run -d chrome -t lib/main_qa.dart
   
   # For Production
   flutter run -d chrome -t lib/main_prod.dart
   ```

### Build for Web

```bash
# QA Build
flutter build web -t lib/main_qa.dart

# Production Build
flutter build web -t lib/main_prod.dart
```

---

## User Roles

The application supports three main user roles:

### 1. **Admin**
- Full access to all features
- Create and manage events
- Manage judges
- View all participants
- Assign judges to participants
- View and manage scores
- Download certificates

### 2. **Judge**
- View assigned participants
- Enter scores for assigned participants
- View participant details

### 3. **Participant**
- Register for events
- View own registrations
- View own scores
- Download own certificate

---

## Step-by-Step Guides

### For Administrators

#### 1. Creating an Event

**Step 1:** Login as Admin
- Go to Login page
- Select "Admin" role
- Enter admin credentials
- Click "Login"

**Step 2:** Navigate to Event Management
- From Admin Dashboard, click "Event Management" or navigate to Events section

**Step 3:** Create New Event
- Click the "Create" or "+" button
- Fill in the event form:
  - **Event Name**: Enter the competition name (e.g., "State Level Yoga Championship")
  - **Description**: Add event description
  - **Start Date**: Select event start date
  - **End Date**: Select event end date
  - **Location**: Enter venue address
  - **Banner Image**: Upload event banner (optional)
- Click "Create" or "Save"

**Step 4:** Verify Event
- The event will appear in the events list
- You can edit or view event details

---

#### 2. Adding a Judge

**Step 1:** Navigate to Judge Management
- From Admin Dashboard, go to "Judge Management"

**Step 2:** Create New Judge
- Click "Create" button
- Fill in the judge form:
  - **Name***: Judge's full name
  - **Designation***: Job title/position
  - **Username***: Unique username for login
  - **Email***: Valid email address (mandatory)
  - **Address**: Physical address
  - **Password***: Set initial password
  - **Confirm Password***: Re-enter password
- Click "Create"

**Step 3:** Verify Judge
- Judge appears in the judges list
- Judge can now login with their credentials

**Note:** Email field is mandatory and must be in valid format.

---

#### 3. Registering a Participant

**Step 1:** Navigate to Event Details
- Go to Events List
- Click on the event you want to register participants for

**Step 2:** Access Registration
- In Event Details page, find "Registered Participants" section
- Click "Register Participant" or similar button

**Step 3:** Fill Registration Form
- **Personal Information**:
  - Name*
  - Date of Birth*
  - Gender* (Male/Female)
  - Address*
  - Photo* (Upload participant photo)
  
- **Yoga Details**:
  - Yoga Master Name*
  - Yoga Master Contact*
  - School Name*
  - Group/Standard* (Select from: II,III / IV,V / VI,VII / VIII,IX / X-XII / UG/PG)
  
- **Event Details**:
  - Select Categories* (Common, Special, or both)
  - Event ID (auto-filled)

**Step 4:** Submit Registration
- Review all information
- Click "Submit" or "Register"
- Participant will be added to the event

---

#### 4. Assigning Judges to Participants

**Step 1:** Navigate to Event Details
- Go to the event where participants are registered

**Step 2:** View Participants
- Scroll to "Registered Participants" section
- You'll see list of all registered participants

**Step 3:** Assign Judge
- Click on "Assign" or similar option for a participant
- Select a judge from the dropdown
- Confirm assignment
- The judge will now see this participant in their assigned list

**Alternative Method:**
- Go to "Assign Participants" screen
- Select Event
- Select Judge
- Select Participants to assign
- Click "Assign"

---

#### 5. Viewing Participant Scores

**Step 1:** Navigate to Scores
- From Admin Dashboard, go to "Participant Scores" or navigate to event scores

**Step 2:** Select Event
- Choose the event from the list
- View all participants with scores

**Step 3:** View Score Details
- Click on a participant's name or score
- View detailed breakdown:
  - Category scores (Common/Special)
  - Individual asana scores
  - Jury marks from each judge
  - Grand totals

---

#### 6. Downloading Certificates

**Step 1:** Navigate to Event Details
- Go to the event page

**Step 2:** Find Participant
- In "Registered Participants" section
- Find the participant whose certificate you want

**Step 3:** Download Certificate
- Click the certificate/download icon next to participant
- Certificate will download as PDF
- Certificate is available for participants with "Scored" status

---

### For Judges

#### 1. Logging In as Judge

**Step 1:** Go to Login Page
- Select "User" role (judges use user role)
- Enter username and password provided by admin

**Step 2:** Access Assigned Participants
- After login, navigate to "Assigned Participants" or similar section
- Select the event you're assigned to

**Step 3:** View Participants
- You'll see list of participants assigned to you

---

#### 2. Scoring a Participant

**Step 1:** Select Participant
- From assigned participants list, click on a participant

**Step 2:** Enter Scores
- For each category (Common/Special):
  - Select each asana
  - Enter score (typically 0-10 scale)
  - Repeat for all asanas in the category

**Step 3:** Submit Scores
- Review all scores
- Click "Submit" or "Save Scores"
- Scores are saved and calculated automatically

**Note:** 
- Scores are calculated as: Sum of all asana scores
- Grand total = Sum of all category totals
- Multiple judges' scores are averaged

---

### For Participants

#### 1. Registering for an Event

**Step 1:** Browse Events
- Go to "Events" page from home
- Browse available events

**Step 2:** Select Event
- Click on an event to view details
- Check eligibility and requirements

**Step 3:** Register
- Click "Register" or "Register Now" button
- Fill in registration form (see Admin guide section 3)
- Upload required photo
- Submit registration

**Step 4:** Confirmation
- Wait for admin approval
- Check "My Registrations" to see status

---

#### 2. Viewing Your Scores

**Step 1:** Login
- Login with your credentials

**Step 2:** Navigate to Scores
- Go to "My Registrations" or "My Scores"
- Select the event

**Step 3:** View Details
- See your scores breakdown
- View category-wise scores
- See individual asana scores
- Check grand total

---

#### 3. Downloading Your Certificate

**Step 1:** Login
- Login to your account

**Step 2:** Navigate to Event
- Go to the event you participated in

**Step 3:** Download Certificate
- Find download certificate option
- Click to download PDF certificate
- Certificate available after scoring is complete

---

## How It Works

### System Architecture

```
┌─────────────────┐
│   Frontend      │  Flutter Web App
│   (Flutter)     │  - GetX State Management
└────────┬────────┘  - GoRouter Navigation
         │
         │ HTTP/REST API
         │
┌────────▼────────┐
│   Backend API   │  Node.js/Express/Spring Boot
│   (Server)      │  - Authentication
└────────┬────────┘  - Data Storage
         │
┌────────▼────────┐
│   Database     │  MongoDB/PostgreSQL
└─────────────────┘
```

### Data Flow

#### 1. **Event Creation Flow**
```
Admin → Create Event → API → Database → Event List Updated
```

#### 2. **Registration Flow**
```
Participant → Fill Form → Upload Photo → API → Database → Admin Approval → Status Updated
```

#### 3. **Scoring Flow**
```
Admin Assigns Judge → Judge Views Participants → Judge Enters Scores → 
API Calculates → Database Stores → Scores Displayed → Certificate Generated
```

### Scoring System

#### Score Calculation:
1. **Asana Score**: Individual score from each judge (0-10 typically)
2. **Subtotal**: Sum of all asana scores in a category
3. **Grand Total**: Sum of all category totals
4. **Multiple Judges**: Scores are averaged across all judges

#### Example:
```
Category: Common
  - Asana 1: Judge 1 (9.0) + Judge 2 (8.5) = Average 8.75
  - Asana 2: Judge 1 (9.5) + Judge 2 (9.0) = Average 9.25
  Subtotal: 18.0

Category: Special
  - Asana 1: Judge 1 (8.0) + Judge 2 (8.5) = Average 8.25
  Subtotal: 8.25

Grand Total: 18.0 + 8.25 = 26.25
```

### Status Workflow

```
Registration → Pending → Accepted → Scored → Certificate Available
```

- **Pending**: Registration submitted, awaiting admin approval
- **Accepted**: Admin approved registration
- **Scored**: Judges have entered scores
- **Certificate Available**: Can download certificate

---

## Troubleshooting

### Common Issues

#### 1. **Login Not Working**
- **Problem**: Cannot login after page refresh
- **Solution**: 
  - Clear browser cache
  - Check if backend API is running
  - Verify credentials are correct
  - Check browser console for errors

#### 2. **Events Not Loading**
- **Problem**: Events list is empty
- **Solution**:
  - Check API connection
  - Verify backend server is running
  - Check network connectivity
  - Refresh the page

#### 3. **Photo Upload Failing**
- **Problem**: Cannot upload participant photo
- **Solution**:
  - Check file size (should be reasonable)
  - Verify file format (JPG, PNG)
  - Check internet connection
  - Try smaller image size

#### 4. **Scores Not Saving**
- **Problem**: Judge scores not saving
- **Solution**:
  - Check if judge is assigned to participant
  - Verify all required fields are filled
  - Check internet connection
  - Refresh and try again

#### 5. **Certificate Not Downloading**
- **Problem**: Certificate download not working
- **Solution**:
  - Verify participant status is "Scored"
  - Check if scores are complete
  - Try different browser
  - Check browser download settings

### Browser Compatibility

- ✅ Chrome (Recommended)
- ✅ Firefox
- ✅ Edge
- ✅ Safari

### API Configuration

Update API URLs in `lib/config/app_config.dart`:

```dart
case Environment.qa:
  return 'https://your-qa-server.com';
case Environment.prod:
  return 'https://your-prod-server.com';
```

---

## Quick Reference

### Admin Actions
- **Create Event**: Admin Dashboard → Event Management → Create
- **Add Judge**: Admin Dashboard → Judge Management → Create
- **View Participants**: Event Details → Registered Participants
- **Assign Judge**: Event Details → Assign button
- **View Scores**: Admin Dashboard → Participant Scores

### Judge Actions
- **View Assigned**: Login → Assigned Participants → Select Event
- **Enter Scores**: Click Participant → Enter Scores → Submit

### Participant Actions
- **Register**: Events → Select Event → Register
- **View Scores**: My Registrations → Select Event → View Scores
- **Download Certificate**: Event Details → Download Icon

---

## Support

For technical support or questions:
- Check this documentation
- Review error messages in browser console
- Contact system administrator
- Check backend API logs

---

## Version Information

- **Application**: Yogasana Championship 2025
- **Version**: 1.0.0
- **Platform**: Flutter Web
- **Last Updated**: 2025

---

**Note**: This documentation is for demo purposes. Actual implementation may vary based on backend API specifications.

