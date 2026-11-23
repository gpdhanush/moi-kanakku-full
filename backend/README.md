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

Daily jobs run from **system cron** (cPanel → Cron Jobs), not inside the web process — LiteSpeed runs several app workers and pauses idle ones, which caused missed and duplicated runs.

| Job | IST | cPanel schedule (server is UTC) | Command |
|---|---|---|---|
| Upcoming function reminders | 06:00 | `30 0 * * *` | `node scripts/run-scheduled-job.js reminders` |
| Password expiry + FCM token health | 09:00 | `30 3 * * *` | `node scripts/run-scheduled-job.js daily` |

cPanel command (use the Node venv path shown on the Setup Node.js App page):

```
cd /home/floatwal/moi-api.floatwalktiruppur.in/backend && /home/floatwal/nodevenv/moi-api.floatwalktiruppur.in/backend/20/bin/node scripts/run-scheduled-job.js reminders >> logs/cron.log 2>&1
```

Locally you can run `npm run job:daily` / `npm run job:reminders`, or set `ENABLE_IN_PROCESS_CRON=true` to keep the old node-cron schedule inside `app.js`.

## 💳 Paid PDF export (UPI)

Users pay once by UPI QR, submit the 12-digit UPI transaction ID, and an admin approves it in **Export Payments**. Each approval gives the user **3 PDF exports** (`EXPORT_PAYMENT_EXPORTS_PER_PAYMENT` in `.env` to change); after they are used, the user pays again. The app calls `POST /consume` once per export, just before sharing the PDF.

- Tables: run `migrations/create_export_payments.sql`, `migrations/add_export_limits_to_export_payments.sql` and `migrations/create_export_payment_settings.sql` once.
- Payee details: set in the admin panel (**Export Payments → Payment settings**): UPI ID, payee name, amount, and an optional uploaded QR image (PNG/JPG/WEBP, ≤ 2 MB, saved under `UPLOAD_DIR/export-payment/`). `EXPORT_PAYMENT_UPI_ID`, `EXPORT_PAYMENT_PAYEE_NAME` and `EXPORT_PAYMENT_AMOUNT` in `.env` are only fallbacks. Until a UPI ID + name or a QR image is set, the app shows "payments unavailable".
- Routes (`/apis/export-payments`): `GET /status`, `POST /submit`, `POST /consume` (user token); `GET /admin/list`, `POST /admin/review`, `GET|PUT /admin/settings`, `POST|DELETE /admin/settings/qr` (admin).

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
