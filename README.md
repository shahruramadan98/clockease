<p align="center">
  <img src="assets/images/logo.png" alt="ClockEase Logo" width="200"/>
</p>

<h1 align="center">ClockEase</h1>

<p align="center">
  <strong>Intelligent Workforce Management System</strong><br/>
  A cross-platform mobile application built with Flutter & Firebase for automated attendance tracking, leave management, and workforce analytics.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Riverpod-State_Management-00897B" alt="Riverpod"/>
  <img src="https://img.shields.io/badge/Platform-Android_|_iOS-green" alt="Platform"/>
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Problem Statement](#-problem-statement)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Module Breakdown](#-module-breakdown)
- [Screenshots](#-screenshots)
- [Getting Started](#-getting-started)
- [Project Structure](#-project-structure)
- [Contributors](#-contributors)

---

## 🧭 Overview

**ClockEase** is a comprehensive workforce management system designed to digitize and automate attendance tracking, leave management, and employee analytics for small-to-medium enterprises. Built as a final year project, the system replaces manual HR processes with an intelligent, mobile-first platform.

> **Developed for:** HForce International Sdn Bhd (case study)  
> **Project Duration:** November 2025 – January 2026  
> **Codebase:** ~11,800 lines of Dart across 64 source files  

---

## ❓ Problem Statement

Traditional workforce management at many SMEs still relies on **manual processes** — paper sign-in sheets, Excel-based attendance tracking, and physical leave application forms. This leads to:

- ❌ **Time fraud** — no biometric or location verification for clock-in
- ❌ **Delayed approvals** — leave requests take days to process manually
- ❌ **No real-time visibility** — managers lack instant attendance dashboards
- ❌ **Data inconsistency** — manual data entry causes errors and duplication
- ❌ **Zero analytics** — no insights into punctuality trends or workforce patterns

**ClockEase solves all of these** by providing a mobile-first system with face verification, GPS tracking, real-time dashboards, and automated workflows.

---

## ✨ Key Features

### 👤 Employee Features
| Feature | Description |
|---------|-------------|
| **🔐 Secure Authentication** | Firebase Auth with email/password, forgot password, and role-based access control |
| **📸 Face Verification** | ML Kit face detection with TFLite model for biometric clock-in/out verification |
| **📍 GPS Location Tracking** | Automatic GPS coordinate capture with reverse geocoding to verify attendance location |
| **⏰ Smart Clock-In/Out** | One-tap attendance with automatic status calculation (On Time, Late, Half Day, Absent) |
| **🏖️ Leave Management** | Apply for leave (Annual, Medical, Emergency, etc.) with file attachment support |
| **📊 Personal Insights** | Punctuality trends, working hours analytics, streak tracking, and monthly summaries |
| **📅 Team Leave Calendar** | View when teammates are on leave using an integrated calendar widget |
| **👤 Profile Management** | Edit personal info, change password, toggle dark mode |

### 🛡️ Admin Features
| Feature | Description |
|---------|-------------|
| **📊 Admin Dashboard** | Real-time overview of total staff, present today, and pending leave requests |
| **✅ Leave Approval** | Review, approve, or reject leave applications with one tap |
| **👥 Staff Management** | Full CRUD operations for employee accounts and role assignments |
| **📋 Attendance Management** | View and manage all staff attendance records with filtering |
| **⚙️ Company Settings** | Configure leave policies (annual, medical, etc.) and company-wide settings |

### 🔧 Technical Highlights
| Feature | Implementation |
|---------|---------------|
| **State Management** | Flutter Riverpod for reactive, provider-based architecture |
| **Real-time Data** | Firestore streams for live dashboard updates |
| **Offline Support** | Firestore's built-in offline persistence |
| **Multi-tenant** | Company-scoped data isolation in Firestore |
| **Dark Mode** | System-wide theme switching with persisted preference |
| **Location Confirmation** | Interactive dialog showing GPS coordinates, accuracy, and reverse-geocoded address before clock-in |

---

## 🛠️ Tech Stack

```
┌─────────────────────────────────────────────────────┐
│  FRONTEND                                           │
│  ├── Flutter 3.x (Cross-platform UI framework)      │
│  ├── Dart 3.9 (Programming language)                │
│  └── Material Design 3 (Design system)              │
│                                                     │
│  STATE MANAGEMENT                                   │
│  └── Flutter Riverpod 2.5 (Reactive providers)      │
│                                                     │
│  BACKEND (SERVERLESS)                               │
│  ├── Firebase Auth (Authentication)                 │
│  ├── Cloud Firestore (NoSQL Database)               │
│  └── Firebase Storage (File uploads)                │
│                                                     │
│  AI / ML                                            │
│  ├── Google ML Kit (Face Detection)                 │
│  └── TensorFlow Lite (Face Recognition Model)       │
│                                                     │
│  DEVICE APIs                                        │
│  ├── Camera (Front-facing camera access)            │
│  ├── Geolocator (GPS coordinates)                   │
│  └── Geocoding (Reverse geocoding)                  │
│                                                     │
│  UI LIBRARIES                                       │
│  ├── fl_chart (Data visualization)                  │
│  ├── table_calendar (Leave calendar)                │
│  ├── Google Fonts (Typography)                      │
│  └── intl (Date/time formatting)                    │
└─────────────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

ClockEase follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│              PRESENTATION LAYER             │
│  (Pages, Widgets, UI Components)            │
│  ┌─────────┐ ┌──────────┐ ┌─────────────┐  │
│  │Dashboard│ │Attendance│ │Leave Manager│  │
│  └────┬────┘ └────┬─────┘ └──────┬──────┘  │
│       │           │              │          │
├───────┼───────────┼──────────────┼──────────┤
│       ▼           ▼              ▼          │
│            CONTROLLER LAYER                 │
│  (Riverpod Providers & State Logic)         │
│  ┌────────────────────────────────────────┐ │
│  │ attendance_controller.dart             │ │
│  │ dashboard_controller.dart              │ │
│  │ insights_controller.dart               │ │
│  │ leave_controller.dart                  │ │
│  │ profile_controller.dart                │ │
│  │ user_provider.dart                     │ │
│  └───────────────┬────────────────────────┘ │
│                  │                          │
├──────────────────┼──────────────────────────┤
│                  ▼                          │
│             SERVICE LAYER                   │
│  (Business Logic & API Abstraction)         │
│  ┌────────────────────────────────────────┐ │
│  │ attendance_service.dart                │ │
│  │ leave_service.dart                     │ │
│  │ location_service.dart                  │ │
│  │ face_detector_service.dart             │ │
│  │ user_service.dart                      │ │
│  │ firestore_service.dart                 │ │
│  └───────────────┬────────────────────────┘ │
│                  │                          │
├──────────────────┼──────────────────────────┤
│                  ▼                          │
│              DATA LAYER                     │
│  (Models & Firebase Backend)                │
│  ┌────────────────────────────────────────┐ │
│  │ attendance_record.dart                 │ │
│  │ attendance_log.dart                    │ │
│  │ user_profile.dart                      │ │
│  │ leave_info.dart                        │ │
│  │ leave_policy.dart                      │ │
│  │ employee_schedule.dart                 │ │
│  └────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────┐
  │   Firebase   │
  │  ┌────────┐  │
  │  │  Auth  │  │
  │  ├────────┤  │
  │  │Firestore│ │
  │  ├────────┤  │
  │  │Storage │  │
  │  └────────┘  │
  └──────────────┘
```

---

## 📦 Module Breakdown

### 1. Authentication Module
- Email/password login with Firebase Auth
- Company registration flow → Admin account creation → Employee invitation
- Role-based access control (Admin vs Employee)
- Forgot password with email reset link
- Secure session management with `authStateChanges()` stream

### 2. Attendance Module
- **Clock-In Flow:** Face Verification → GPS Capture → Location Confirmation → Firestore Write
- Automatic attendance status calculation based on company schedule:
  - ✅ **On Time** — clocked in before shift start
  - ⚠️ **Late** — clocked in after shift start (duration tracked)
  - 🔶 **Half Day** — worked less than half the shift
  - ❌ **Absent** — no clock-in recorded
- Monthly summary with total hours, on-time count, late count
- Historical attendance records with date-wise breakdown

### 3. Leave Management Module
- Multiple leave types: Annual, Medical, Emergency, Compassionate, etc.
- Half-day leave support
- File attachment for medical certificates (Firebase Storage)
- Leave balance tracking aligned with company leave policy
- Real-time leave application status (Pending → Approved/Rejected)
- Notification system for leave approval updates

### 4. Insights & Analytics Module
- **Attendance Summary Grid** — On Time, Late, Half Day, Absent counts
- **Punctuality Trend Chart** — Weekly on-time rate visualization (fl_chart)
- **Working Hours Overview** — Total hours and daily average
- **Streak Tracking** — Current and best on-time streaks
- **Team Leave Calendar** — Company-wide leave visibility

### 5. Admin Panel
- **Dashboard** — Real-time company overview (staff count, present today, pending leave)
- **Leave Approval** — Review and process leave requests
- **Staff Management** — Add/edit/remove employees, assign admin roles
- **Attendance Management** — View all staff attendance with filtering
- **Company Settings** — Configure leave policies and entitlements

### 6. Profile Module
- View and edit personal information (name, phone, designation, gender)
- Change password with re-authentication
- Dark mode toggle
- Admin panel access for admin users

---

## 📸 Screenshots

> 📱 *Screenshots of the running application can be provided during the demo session.*

| Screen | Description |
|--------|-------------|
| Login Page | Clean login UI with custom triangle clip decorations and brand colors |
| Dashboard | Greeting card, live clock, and quick action shortcuts |
| Attendance | Monthly summaries with gradient boxes and daily attendance cards |
| Leave Application | Multi-type leave form with calendar picker and file attachment |
| Insights | Analytics dashboard with charts, summary grids, and streak cards |
| Profile | Gradient header, editable fields, dark mode toggle, and admin access |
| Admin Dashboard | Company overview with real-time Firestore streams |
| Leave Approval | Pending requests list with approve/reject actions |
| Staff Management | Full employee CRUD with role management |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.9
- Firebase project configured
- Android Studio / VS Code with Flutter plugins
- Physical device recommended (for camera & GPS features)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/shahruramadan98/clockease.git
cd clockease

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Firebase Setup

The app uses Firebase services. To connect to your own Firebase project:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Email/Password)
3. Enable **Cloud Firestore**
4. Enable **Firebase Storage**
5. Run `flutterfire configure` to generate `firebase_options.dart`

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point & auth wrapper
├── login_page.dart                    # Login UI with forgot password
├── home_page.dart                     # Bottom navigation (5 tabs)
├── auth_gate.dart                     # Authentication gate
├── auth_provider.dart                 # Auth state provider
├── firebase_options.dart              # Firebase configuration
│
├── controllers/                       # Riverpod state management
│   ├── attendance_controller.dart     # Attendance state & providers
│   ├── dashboard_controller.dart      # Dashboard state
│   ├── insights_controller.dart       # Analytics data providers
│   ├── leave_controller.dart          # Leave state management
│   ├── profile_controller.dart        # User profile providers
│   ├── theme_controller.dart          # Dark mode state
│   └── user_provider.dart             # Current user provider
│
├── models/                            # Data models
│   ├── attendance_log.dart            # Attendance log model
│   ├── attendance_record.dart         # Attendance record model
│   ├── attendance_status.dart         # Status enum
│   ├── attendance_status_calculator.dart # Status calculation logic
│   ├── dashboard_attendance_state.dart  # Dashboard state model
│   ├── employee_schedule.dart         # Work schedule model
│   ├── leave_info.dart                # Leave application model
│   ├── leave_policy.dart              # Company leave policy model
│   ├── staff_attendance_info.dart     # Admin staff attendance model
│   └── user_profile.dart              # User profile model
│
├── services/                          # Business logic & API layer
│   ├── attendance_service.dart        # Attendance CRUD operations
│   ├── admin_attendance_service.dart  # Admin attendance operations
│   ├── leave_service.dart             # Leave CRUD operations
│   ├── location_service.dart          # GPS & geocoding
│   ├── face_detector_service.dart     # ML Kit face detection
│   ├── image_utils.dart               # Image processing utilities
│   ├── firestore_service.dart         # Firestore abstraction
│   ├── user_service.dart              # User CRUD operations
│   └── company_settings_service.dart  # Company settings
│
├── dashboard/                         # Dashboard module
│   ├── dashboard.dart                 # Dashboard page
│   └── widgets/                       # Dashboard components
│
├── attendance/                        # Attendance module
│   ├── attendance_page.dart           # Attendance history page
│   └── widgets/                       # Attendance components
│
├── leave/                             # Leave module
│   ├── leave_home_page.dart           # Leave dashboard (tabbed)
│   ├── leave_application_form.dart    # Leave application form
│   └── leave_notifications_page.dart  # Leave notifications
│
├── insights/                          # Analytics module
│   ├── insights_page.dart             # Insights dashboard
│   └── widgets/                       # Charts & cards
│
├── profile/                           # Profile module
│   └── profile_page.dart              # Profile & settings
│
├── face_verification/                 # Face verification module
│   └── face_verification_page.dart    # Camera & verification UI
│
├── signup/                            # Registration module
│   ├── signup_company_page.dart       # Company registration
│   └── signup_employee_page.dart      # Employee registration
│
├── admin/                             # Admin panel
│   ├── admin_home.dart                # Admin navigation
│   ├── dashboard/                     # Admin dashboard
│   │   ├── admin_dashboard.dart       # Overview page
│   │   └── widgets/                   # Admin dashboard widgets
│   ├── leave/
│   │   └── leave_approval_page.dart   # Leave approval
│   ├── staff/
│   │   └── staff_management_page.dart # Staff CRUD
│   ├── attendance/
│   │   ├── attendance_management_page.dart
│   │   └── widgets/
│   └── settings/
│       └── leave_policy_page.dart     # Company leave policy
│
├── widgets/                           # Shared widgets
│   └── location_confirmation_dialog.dart
│
└── utils/                             # Utilities
```

---

## 🤝 Contributors

| Name | Role |
|------|------|
| **Shahru Ramadan** | Full-Stack Developer (Flutter + Firebase) |

---

## 📄 License

This project was developed as a **Final Year Project** for academic purposes.

---

<p align="center">
  <strong>Built with ❤️ using Flutter & Firebase</strong>
</p>
