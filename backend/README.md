# Moi Kanakku - Backend API Server

A robust Node.js/Express REST API backend for the **Moi Kanakku** gift and transaction management system.

---

## 📋 Prerequisites

- **Node.js**: v18.0.0 or higher
- **MySQL / MariaDB**: 10.11+ or MySQL 8.0+
- **npm** or **yarn**

---

## ⚡ Installation & Setup

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up the Database:**
   - Create a MySQL database named `prasowla_moi_master` (or custom name configured in `.env`).
   - Import database dump from `prasowla_moi_kanakku_db.sql` or `db backup/`:
     ```bash
     mysql -u root -p prasowla_moi_master < prasowla_moi_kanakku_db.sql
     ```
   - Apply any necessary migrations:
     ```bash
     mysql -u root -p prasowla_moi_master < migrations/add_firstname_secondname_city_to_credit_debit.sql
     ```

4. **Configure Environment Variables:**
   Create a `.env` file in the root of `backend/` using the following configuration:
   ```env
   PORT=3000
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=your_mysql_password
   DB_NAME=prasowla_moi_master
   JWT_SECRET=your_jwt_secret_key
   API_SECRET_KEY=your_secure_api_registration_key
   NODE_ENV=development
   ```

   > ⚠️ **Security Note:** Set a strong `API_SECRET_KEY` to protect registration endpoints. Registration requests must send this key in the `X-API-Key` HTTP header.

---

## 🚀 Running the Server

### Development Mode (with auto-reload via nodemon)

```bash
npm run dev
```

### Production Mode

```bash
npm start
```

The API server will listen on `http://localhost:3000/apis`.

---

## 🌐 API Endpoints Overview

Base Endpoint: `http://localhost:3000/apis`

| Endpoint Route | Resource Description |
|---|---|
| `/apis/user/*` | User authentication, registration, profiles, MFA setup/verify |
| `/apis/moi-persons/*` | Person contacts and gift contributor directory |
| `/apis/moi-credit-debit/*` | Credit/Debit transactions and event gift entries |
| `/apis/moi-functions/*` | Custom event & function management |
| `/apis/moi-default-functions/*` | Pre-defined default function categories |
| `/apis/notifications/*` | User and system notification delivery |
| `/apis/uploads/*` | Attachment uploads and media handling |

---

## ⏰ Scheduled Tasks (Cron Jobs)

The backend runs automated daily tasks (`node-cron`) at 9:00 AM:
1. **Password Expiration Check**: Evaluates user password age and dispatches renewal notifications.
2. **Function Reminder Service**: Sends reminders 1 day prior to upcoming scheduled functions.

---

## 📁 Project Structure

```
backend/
├── app.js                 # Main server entrypoint & middleware stack
├── src/
│   ├── config/           # Database & environmental configurations
│   ├── controllers/      # Route request controllers
│   ├── models/           # Data access objects & MySQL query models
│   ├── routes/           # Express router endpoints
│   ├── middlewares/      # JWT validation, rate limiting, header checks
│   └── services/         # Cron tasks, notification & mail services
├── migrations/           # SQL migration scripts
├── db backup/            # Database schema & seed backups
└── package.json          # Node.js dependencies & scripts
```

---

## 🛠 Main Dependencies

- **Framework**: `express`, `cors`, `helmet`, `morgan`
- **Database**: `mysql2`
- **Security**: `jsonwebtoken`, `bcryptjs`, `speakeasy`, `express-rate-limit`
- **Utilities**: `moment`, `nodemailer`, `multer`, `winston`, `qrcode`
- **Firebase**: `firebase-admin`

---

## 📄 License & Author

Maintained by **GP_Dhanush** (gpdhanush).
