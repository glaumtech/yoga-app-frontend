# Yoga Championship Event Management System
## Project Documentation for Client

---

## Table of Contents

1. [Introduction](#introduction)
2. [System Overview](#system-overview)
3. [User Roles & Access](#user-roles--access)
4. [Main Features](#main-features)
5. [Feature Details](#feature-details)
6. [Language Support](#language-support)
7. [Summary](#summary)

---

## Introduction

This document provides an overview of the **Yoga Championship Event Management System** - a comprehensive web-based platform designed to manage yoga competitions from start to finish. The system handles user management, event creation, participant registration, scoring, and reporting.

---

## System Overview

The Yoga Championship Event Management System is a complete solution for organizing and managing yoga competitions. It provides:

- **User Management**: Create and manage different types of users (Sub-Admins, Spot Registration Admins, Juries, and Volunteers)
- **Competition Management**: Create competitions with detailed settings
- **Registration System**: Individual and bulk registration for participants
- **Scoring System**: Efficient scoring interface for judges
- **Reporting**: Comprehensive reports and analytics
- **School/College Management**: Maintain database of educational institutions
- **Sponsorship**: Manage sponsors and their contributions

---

## User Roles & Access

The system supports multiple user roles, each with specific permissions:


### 1. **Sub-Admin**
- Can create, edit, or delete: Juries, Spot Registration Admins, and Volunteers
- Access to most administrative features
- Can manage competitions and registrations

### 2. **Spot Registration Admin**
- Access to Registration form
- Can view reports for registered users only
- Acts as coordinator for the event

### 3. **Jury (Judge)**
- Access to scoring interface only
- Can score participants assigned to them
- No access to menu or other administrative features

### 4. **Volunteers**
- Support staff for events
- Access based on assigned permissions

---

## Main Features

### 1. **Create Users**

**Purpose**: Create and manage different types of users in the system.

**Key Features**:
- Create Sub-Admins, Spot Registration Admins, Juries, and Volunteers
- Upload user photos
- Assign user types with radio button selection
- Set permissions (Create, Edit, Delete) for Sub-Admins
- Auto-generated random passwords (communicated separately by Admin)
- Display list of created users below the form

**Special Features for Juries**:
- Allot specific stages (Stage 1-6) to each jury
- Allot categories (Common, Special, Champions) to each jury
- Custom stage/category names can be added via "Add More" option

**Special Features for Volunteers**:
- Bulk creation using table format
- Auto-generated Volunteer Numbers (VOL-001, VOL-002, etc.)
- Fields: Volunteer Number, Name, Password, Cell Number, Photo
- "Add More" option to add more volunteers
- Auto-send Volunteer Number, Name, and Password via WhatsApp for login access

---

### 2. **Create Competition**

**Purpose**: Set up a new yoga competition with all necessary details.

**Key Features**:

**Event Information**:
- Event Name
- Description
- Address
- Event Start Date
- Event End Date
- Display Ad From (date when brochure appears on website/app)
- Upload Brochure (PDF/image file)

**Competition Settings**:
- **Prizes**: Select prize positions (1st, 2nd, 3rd, 4th, 5th) with option to add more
- **Categories**: Select categories (Common, Special, Champions) with option to add custom categories
- **Amount**: Set registration fee for each category (Common, Special, Champions)
- **Spot Registration**: Enable or disable on-the-spot registration (Yes/No)
- **Stages**: Select competition stages (A, B, C, D, E, F) with option to add more
- **Assign Groups**: Assign grade/class groups to each stage
  - Example: Stage A → LKG, UKG
  - Example: Stage B → I, II
  - Example: Stage C → III & IV
- **Number of Participants Per Stage**: Set maximum participants per stage (can be updated later)

**Important Notes**:
- Categories and amounts will reflect in the Registration form
- Helps calculate revenue in reports
- Groups are displayed based on selected stages

---

### 3. **Registration**

**Purpose**: Register individual participants for the competition.

**Key Features**:

**Participant Information**:
- Participant's Name (appears on E-Certificate)
- Date of Birth (with date picker)
- Age (auto-calculated from date of birth)
- Participant's Photo (upload)
- Sex (Male/Female)

**Competition Details**:
- Category (dropdown - auto-populated from competition creation)
- Select Group (dropdown - auto-populated from competition creation)

**Teacher & Institution**:
- Yoga Teacher Name
- Yoga Teacher Cell Number (10 digits, without +91)
- Institution Name (dropdown - auto-populated from Schools & Colleges list)

**Documents & Payment**:
- Bonafied Certificate upload (applicable only for Govt/Govt Aided institutions)
- Payment Mode (with QR code option)
- Payment Amount (auto-calculated based on selected category)

**Important Notes**:
- Name format: Use period (.) to separate initial and name
- Cell number validation: Ensures 10 digits, alerts for fake numbers
- Separate registration required for each category
- Helps in accurate reporting and stage-wise participant organization

---

### 4. **Bulk Registration**

**Purpose**: Register multiple participants at once (typically for schools/colleges).

**Key Features**:
- Enter common details once:
  - Yoga Teacher Name
  - Yoga Teacher Cell Number
  - Institution Name
  - Category
- Add multiple participants in a table:
  - Name
  - Date of Birth (D.O.B)
  - Sex
  - Group
  - Photo
- "Add More" option to add more rows
- Save all participants at once

**Use Case**: Ideal for schools/colleges registering multiple students together.

---

### 5. **Schools & Colleges List**

**Purpose**: Maintain and manage database of educational institutions.

**Key Features**:

**Search & View Lists**:
- Select District (dropdown)
- Select State (dropdown)
- Generate printable PDF reports:
  - Private Schools
  - Govt / Govt Aided Schools
  - Private Colleges
  - Govt / Govt Aided Colleges

**Manual Entry**:
- Add new institutions manually:
  - Institution Name
  - Address
  - District (dropdown)
  - State (dropdown)
  - Pincode (dropdown)
  - Institution Type (radio buttons):
    - Private School
    - Private College
    - Govt / Govt Aided School
    - Govt / Govt Aided College

**Important Notes**:
- PDF reports are auto-populated using web crawlers/bots
- Reports are filtered by selected District and State
- PDF format: A4 size with addresses displayed in two halves
- Manual entry available for institutions not in the database

---

### 6. **Reports**

**Purpose**: Generate comprehensive reports and analytics for the competition.

**Available Reports**:

**Participant Statistics**:
- Total Participants
- Number of Boys
- Number of Girls
- Common Category Participants
- Special Category Participants
- Champions Category Participants
- Number of Online Registrations
- Number of Spot Registrations

**Age-wise Category Reports**:
- CBA, CBB, CBC... (Common Boys Age-wise)
- SBA, SBB, SBC... (Special Boys Age-wise)
- CGA, CGB, CGC... (Common Girls Age-wise)
- SGA, SGB, SGC... (Special Girls Age-wise)
- Format: Category + Age (Number of Participants)
- Example: CBA 5 (10) means 10 participants of age 5 in Common Boys category

**Institution Reports**:
- Total Schools Participated
- Total Colleges Participated
- Schools/Colleges list with number of participants (sorted from max to min)

**Prize Winners**:
- Prize winners list - category wise
- Displays participants with positions 1 to 5 (or based on prize list created in competition)

**User Reports**:
- Created Users list (Sub Admins, Spot Reg Admins, Juries, Volunteers separately)
- Includes all details with timestamp

**Revenue Reports (Admin Only)**:
- Online Registration Revenue
- Spot Registration Revenue
- Total Revenue
- Split by institution type:
  - Private Schools
  - Private Colleges
  - Govt/Govt Aided Schools
  - Govt/Govt Aided Colleges

**Report Features**:
- All reports available as Dashboard for Admin/Sub-Admins
- Detailed reports can be viewed or downloaded as PDF
- Option to download all reports separately as PDF
- Option to download all reports as a single ZIP file
- Revenue amounts calculated based on category-wise pricing

**Important Notes**:
- Prize allotment ensures all schools/colleges receive at least one prize
- Even non-eligible participants may receive 4th or 5th prize if they are the only participant from their institution
- All reports reflect in the main dashboard

---

### 7. **Sponsors**

**Purpose**: Allow individuals/organizations to sponsor students (especially Govt/Govt Aided students).

**Key Features**:
- Select number of students to sponsor (dropdown)
- Payment Mode (with QR code option)
- Billing Information:
  - Sponsor's Name
  - Address
  - City
  - State
  - Pincode
  - Cell Phone
  - WhatsApp
  - E-mail Address

**Post-Payment**:
- PDF receipt generation
- Receipt sent via WhatsApp and/or Email
- Downloadable PDF option available

**Purpose Statement**: "You are encouraging the Govt/Govt-Aided students who need financial support to participate in this event"

---

### 8. **Scoring Interface (For Juries)**

**Purpose**: Allow judges to score participants efficiently.

**Key Features**:

**Selection Options**:
- Select Stage (dropdown - one at a time)
- Select Category (dropdown - Common/Special/Champions)
- Select Groups (dropdown - e.g., II & III)
- Queue Status: Shows number of participants in queue (e.g., "IN QUEUE: 555")

**Scoring Interface**:
- Large display of participant identifiers (e.g., "ABC" or participant codes like CBA001, CBA002, CBA003)
- Checkboxes to select participants
- Refresh button to reallocate participants from queue
- Input fields for each asana score (Asana 1, Asana 2, etc.)
- Submit button to save scores

**Workflow**:
- Jury selects one Stage, Category, and Group at a time
- System displays next set of participants (e.g., CBA001, CBA002, CBA003)
- Jury enters scores for each asana
- After all juries submit scores for current participants, next set auto-populates
- If a jury hasn't submitted, system shows note: "Jury X is yet to submit the scores"
- Asana number updates after each submit (Asana 1 → Asana 2 → etc.)

**Special Features**:
- Refresh button allows reallocation if participant is absent or late
- Checkbox selection helps skip unavailable participants
- Prevents time wastage by quickly moving to next available participant

---

## Language Support

**Multi-Language Feature**:
- System supports multiple languages
- Language selection available (e.g., "EN" for English)
- Uses Google Translate or similar translation service
- English text displayed below translated labels for better understanding
- Language preference captured during user login

**Implementation Note**: The system will detect user's language preference during login and display all content accordingly, with English as fallback for clarity.

---

## Summary

The Yoga Championship Event Management System is a complete solution that covers:

✅ **User Management**: Create and manage Admins, Sub-Admins, Spot Reg Admins, Juries, and Volunteers

✅ **Competition Setup**: Create competitions with prizes, categories, stages, groups, and pricing

✅ **Registration**: Individual and bulk registration with photo upload and document management

✅ **Institution Management**: Maintain database of schools and colleges with search and PDF generation

✅ **Scoring**: Efficient interface for judges to score participants stage-wise and category-wise

✅ **Reporting**: Comprehensive reports including participant statistics, revenue, prize winners, and user lists

✅ **Sponsorship**: Allow sponsors to support students financially

✅ **Multi-Language**: Support for multiple languages with English fallback

✅ **Payment Integration**: Payment options with QR code support

✅ **Certificate Generation**: E-Certificates for participants

---

## Key Benefits

1. **Streamlined Process**: All competition management in one place
2. **Efficient Registration**: Both individual and bulk registration options
3. **Accurate Scoring**: Organized scoring system for judges
4. **Comprehensive Reports**: Detailed analytics and insights
5. **User-Friendly**: Simple interface for all user types
6. **Scalable**: Can handle large number of participants and events
7. **Multi-Language**: Accessible to users in different languages
8. **Mobile-Friendly**: Responsive design works on all devices

---

## Contact & Support

For any questions or clarifications about the system features, please contact the development team.

---

**Document Version**: 1.0  
**Last Updated**: 2025  
**Project**: Yoga Championship Event Management System











