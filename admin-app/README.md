# Moi Kanakku - Admin Web Dashboard

The **Moi Kanakku Admin Web Dashboard** is a modern React-based administrative application designed to manage the Moi Kanakku system. It provides platform administrators with real-time insights into user activities, transaction logs, OTP security records, system notifications, feedback management, and system configuration.

---

## 🛠 Tech Stack

- **Framework**: [React 18](https://react.dev/) + [Vite](https://vitejs.dev/)
- **Language**: [TypeScript](https://www.typescriptlang.org/)
- **Styling**: [Tailwind CSS](https://tailwindcss.com/) + [shadcn/ui](https://ui.shadcn.com/) + Radix UI primitives
- **State & Data Management**: [TanStack Query (React Query)](https://tanstack.com/query) + [Zustand](https://zustand-demo.pmnd.rs/)
- **Routing**: [React Router v6](https://reactrouter.com/)
- **Icons & UI Utilities**: [Lucide React](https://lucide.dev/), `date-fns`, Recharts, Sonner toasts
- **Realtime**: Socket.IO Client + Firebase Integration

---

## 🔑 Key Features

- **Dashboard Analytics**: High-level metrics, real-time activity tracking, and summary statistics.
- **User Management**: View, filter, and manage user accounts, status, and permissions.
- **Transaction Logs**: Comprehensive overview of credit and debit Moi transactions across all registered users and functions.
- **Security & MFA**: Multi-factor authentication (MFA) setup, TOTP verification, and user OTP audit logs.
- **Notifications Engine**: Send, review, and broadcast system notifications to app users.
- **Feedback & Support**: Track user feedback, issues, and system ratings.
- **System Settings**: Configure system parameters, security policies, and service settings.

---

## 📁 Project Structure

```
admin-app/
├── public/                 # Static assets & public images
├── scripts/                # Build and versioning scripts
├── src/
│   ├── components/        # Reusable UI components & layout components
│   ├── contexts/          # React Context providers (Auth, Theme, etc.)
│   ├── features/          # Feature-specific modules & components
│   ├── hooks/             # Custom React hooks
│   ├── lib/               # Utility libraries & API client configuration
│   ├── pages/             # Route page views (Dashboard, Users, Transactions, etc.)
│   ├── shared/            # Shared types and constants
│   └── utils/             # Helper utilities
├── nginx.conf              # Production Nginx configuration
├── deploy-to-server.sh     # Deployment automation script
└── vite.config.ts          # Vite configuration
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js**: v18.0.0 or higher
- **npm** / **bun** / **yarn**

### Installation

1. **Navigate to the admin-app directory:**
   ```bash
   cd admin-app
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Configure Environment Variables:**
   Create a `.env` file in the root of `admin-app/` based on `.env.example`:
   ```env
   VITE_API_BASE_URL=http://localhost:3000/apis
   VITE_FIREBASE_API_KEY=your_firebase_api_key
   VITE_FIREBASE_AUTH_DOMAIN=your_firebase_auth_domain
   VITE_FIREBASE_PROJECT_ID=your_firebase_project_id
   ```

4. **Start the Development Server:**
   ```bash
   npm run dev
   ```
   The application will be available at `http://localhost:8080` or the port displayed in your terminal.

---

## 📦 Build & Deployment

### Production Build

To build the static production bundle:

```bash
npm run build
```

The output will be placed in the `dist/` directory.

### Preview Local Production Build

```bash
npm run preview
```

### Deployment Options

- **Nginx Server**: Use the provided `nginx.conf` template for reverse-proxying and serving single-page application routes cleanly.
- **Apache Web Server**: Use the included `.htaccess` file for URL rewriting.
- **Server Deployment Script**: Execute `./deploy-to-server.sh` for automated deployment to designated Linux servers.

---

## 📜 Scripts

| Command | Description |
|---|---|
| `npm run dev` | Starts Vite dev server with Hot Module Replacement (HMR) |
| `npm run build` | Builds optimized production bundle |
| `npm run preview` | Serves production build locally for testing |
| `npm run lint` | Runs ESLint check across project files |
| `npm run version:patch` | Increments patch version number |
| `npm run version:minor` | Increments minor version number |

---

## 📄 License & Author

Developed and maintained by **GP_Dhanush** (gpdhanush).
