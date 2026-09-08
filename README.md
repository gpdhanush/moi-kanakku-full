# Moi Kanakku - Financial & Gift Tracking Suite

**Moi Kanakku** is a comprehensive, production-grade financial and gift contribution ("Moi") tracking system built for managing Tamil traditional gifts, event finances, transactions, user records, and administration.

The project is structured as a monorepo containing three core applications:

1. **`mobile-app/`**: Cross-platform mobile application (Flutter / Dart) with offline capabilities, biometric authentication, PDF report generation (in Tamil/English), and automated GitLab CI/CD Play Store releases.
2. **`backend/`**: Node.js / Express REST API backend connected to MySQL/MariaDB database, featuring JWT authentication, MFA (TOTP), Firebase Admin integration, rate limiting, and scheduled cron services.
3. **`admin-app/`**: Modern Admin Web Dashboard built with React, Vite, TypeScript, Tailwind CSS, and shadcn/ui for managing system users, transaction records, OTPs, notifications, feedback, and security policies.

---

## 🏗 Repository Structure

```
.
├── admin-app/         # Vite + React + TypeScript Admin Web Dashboard
├── backend/           # Node.js + Express REST API Backend & MySQL Database
└── mobile-app/        # Flutter Cross-Platform Mobile Application
```

---

## 🚀 Applications Overview

### 📱 1. Mobile Application (`mobile-app/`)

The mobile application enables end-users to record and manage incoming and outgoing Moi contributions during functions (e.g., weddings, ear-piercing ceremonies, housewarmings).

* **Tech Stack**: Flutter 3.44.9 / Dart 3.8+, Firebase (Core, Messaging, Analytics, Performance, Crashlytics), Local Auth (Biometrics), PDF Printing with Tamil Font Support (`tamil_pdf_shaper`).
* **Key Features**:
  * Record credit/debit transactions per function and person.
  * Multi-language support (English & Tamil).
  * Generate and share formatted PDF statements.
  * Secure biometric locking (Fingerprint/FaceID) and secure storage.
  * Automated GitLab CI/CD pipeline building signed AABs and deploying to Google Play Console testing tracks.

For detailed setup and CI/CD configuration, see [`mobile-app/README.md`](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/mobile-app/README.md).

---

### ⚙️ 2. Backend API Server (`backend/`)

The backend API handles core business logic, user security, authentication, function cataloging, PDF generation, and automated cron background tasks.

* **Tech Stack**: Node.js (v18+), Express 4.x, MySQL / MariaDB, JWT Auth, Winston Logger, Nodemailer, Node-Cron, Speakeasy (TOTP/MFA), Firebase Admin SDK.
* **Key Features**:
  * Secure RESTful endpoints for Users, Persons, Functions, and Transactions under `/apis/*`.
  * Rate-limited registration and sensitive action endpoints using API Secret keys.
  * Scheduled daily cron jobs (9:00 AM) for function reminders and password expiration warnings.
  * Automated email notifications and transaction receipt creation.

For detailed setup, database import, and environment configuration, see [`backend/README.md`](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/README.md).

---

### 💻 3. Admin Web Dashboard (`admin-app/`)

The web dashboard allows system administrators to monitor system activity, view user transactions, inspect OTP logs, manage app settings, and configure push notifications.

* **Tech Stack**: React 18, Vite, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query, Zustand, Lucide React icons.
* **Key Features**:
  * Dashboard analytics and transaction breakdown.
  * User Master & Detail view with account status controls.
  * OTP logs and multi-factor authentication (MFA) setup & verification.
  * Custom feedback review and broadcast notification system.
  * Production-ready deployment setup with Nginx, `.htaccess`, and shell automation scripts.

For detailed setup and build instructions, see [`admin-app/README.md`](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/admin-app/README.md).

---

## ⚡ Quick Start

### Step 1: Backend Setup

```bash
cd backend
npm install
# Copy environment template and configure DB credentials
cp .env.example .env
# Start development server
npm run dev
```

### Step 2: Admin App Setup

```bash
cd admin-app
npm install
# Start Vite development server
npm run dev
```

### Step 3: Mobile App Setup

```bash
cd mobile-app
flutter pub get
flutter run
```

---

## 🛡 Security & Best Practices

* **Secrets Management**: Never commit `.env` files, keystores, or service account JSON keys to git.
* **API Key Protection**: API registration endpoints require the `X-API-Key` header.
* **Rate Limiting**: Protect endpoints against brute-force attacks via `express-rate-limit`.
* **Biometric & Secure Storage**: Sensitive tokens in mobile are stored using `flutter_secure_storage`.

---

## 📄 License & Attribution

Maintained by **GP_Dhanush** (gpdhanush). All rights reserved.
