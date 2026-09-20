You are a full-stack engineer implementing Google Sign-In and email/password authentication for the Moi Kanakku application. Your task is to design and build a complete, production-ready authentication system that integrates Google Sign-In with existing mobile, admin, and email-based authentication—without breaking any existing functionality, APIs, transactions, or user data.

**Core Constraint:** Preserve the existing authentication architecture, API response format, state management pattern, and design system throughout. Reuse existing patterns wherever they exist; introduce new code only where genuinely required.

---

## The Complete Implementation Scope

You are implementing across three layers:

**Flutter Mobile:** Email/password login, Google Sign-In, and a dedicated password setup flow for Google users.

**Node.js Backend:** Google ID token validation, safe account linking, duplicate-account prevention, and password setup endpoints.

**MySQL Database:** Authentication provider tracking, Google ID storage, password state flags, and email verification status.

**Admin Application:** Display and filter users by authentication type and linked providers.

---

## Authentication Provider Architecture

Introduce a single, consistent authentication provider type field across all layers (Flutter, backend, database). If the existing codebase already has a field like `signup_type`, `auth_source`, or `authentication_method`, reuse it instead of creating a duplicate.

Supported provider values:
- `email` — standard email/password signup
- `google` — Google Sign-In
- `mobile_app` — existing mobile app authentication
- `admin` — admin user authentication

Use enums/constants throughout the codebase instead of hardcoded strings:

**Flutter example:**
```dart
enum SignupType {
  email,
  google,
  mobileApp,
  admin,
}
```

**Backend example:** Create equivalent constants matching the Flutter enum.

Maintain naming consistency across all codebases.

---

## Database Changes

Before making any modifications, inspect the existing users table and schema.

Add **only** the fields that are actually required. Do not add fields for fields' sake.

Minimum required additions:
- `signup_type VARCHAR(...)` — authentication provider type
- `google_id VARCHAR(...)` — unique Google subject ID (indexed, nullable, unique where used)
- `password_set BOOLEAN DEFAULT false` — tracks whether the user has set an application password
- `email_verified BOOLEAN DEFAULT false` — tracks email verification status

**Critical rules:**
- Do NOT store Google access tokens or refresh tokens as passwords.
- Do NOT store Google OAuth tokens unless absolutely necessary for your specific implementation.
- `google_id` must be unique where applicable (indexed).
- Email normalization must remain consistent with existing implementation.
- Existing users must continue working without modification.
- Existing password hashes must NOT be touched.
- Existing users should receive an appropriate default `signup_type` value via migration (e.g., existing email users → `signup_type = 'email'`).

**Write a safe, non-destructive database migration.** Do NOT drop or recreate the users table. The migration must be reversible if needed.

---

## Google Authentication Flow (Complete Journey)

```
User opens Login
       ↓
[Continue with Google] button
       ↓
Google account selection (native UI)
       ↓
Google authentication (native SDK)
       ↓
Receive Google ID token
       ↓
Send idToken to backend: POST /auth/google
       ↓
Backend validates Google ID token cryptographically
       ↓
Extract verified Google subject ID, email, name
       ↓
Search: Does google_id exist? Does email exist?
       ↓
┌─────────────────────────────────────────┐
│ Case 1: Existing Google user            │
│ → Authenticate, check password_set flag │
│                                         │
│ Case 2: Existing email user             │
│ → Safe account linking required         │
│                                         │
│ Case 3: Existing mobile_app user        │
│ → Safe account linking required         │
│                                         │
│ Case 4: Brand new user                  │
│ → Create user, signup_type = google     │
└─────────────────────────────────────────┘
       ↓
Return application JWT/session token
       ↓
Flutter receives token, stores session
       ↓
Check password_set flag
       ↓
If false → Show Set Password screen
If true → Navigate to Home
```

**Security rule:** Do NOT trust email or profile data from the client alone. The backend MUST cryptographically validate the Google ID token before trusting any user data.

---

## New Google User Flow

When a user signs in with Google for the first time (no existing account by email or Google ID):

1. Backend creates a new user with `signup_type = 'google'` and `google_id = <verified_google_subject_id>`
2. Set `password_set = false`
3. Return success with `requires_password_setup: true`
4. Flutter receives the response and navigates to the **Set Password screen**

**Important:** The user should NOT be blocked from entering the application if your product design allows authenticated Google-only access. However, immediately after first Google login, present the password setup flow. Example UI:

```
Create Your Password

Your Google account is connected.
Set a password so you can also sign in
using your email and password.

[Password input field]
[Confirm Password input field]

[Create Password] button
```

---

## Google User Password Setup

A Google user must be able to set an independent application password after their first Google login. This password is **not** the user's Google password—it is a separate credential for Moi Kanakku.

Flow:
1. Google user authenticates successfully
2. Backend returns `password_set: false`
3. Flutter navigates to Set Password screen
4. User enters new password
5. Flutter sends POST /auth/set-password with the new password
6. Backend hashes the password using the existing password hashing algorithm
7. Backend sets `password_set = true`
8. User can now log in using either:
   - Google Sign-In
   - Email + new password

**Security rules:**
- Use the same password hashing algorithm already used by the backend (e.g., bcrypt).
- Never store plaintext passwords.
- Never log passwords, even in debug mode.
- Never send passwords to analytics, Crashlytics, or any third-party service.

---

## Existing Email User + Google Login (Account Linking)

This is a critical case. If a Google login returns an email that already exists in the database as an email-signup user:

**DO NOT automatically create a duplicate user.**

Instead:

1. Backend detects the existing email account with `signup_type = 'email'`
2. Backend verifies the Google identity (token validation successful)
3. Backend links the Google account: set `google_id = <verified_google_subject_id>`
4. User's account now supports both login methods:
   - Email + existing password
   - Google Sign-In
5. Do NOT overwrite or reset the existing password
6. Return success; user can proceed to Home

If your existing architecture cannot safely auto-link accounts, require the user to authenticate their existing email account before linking Google (show a secondary login prompt).

---

## Existing Mobile-App User + Google Login

Existing users created through the current mobile app have `signup_type = 'mobile_app'`. These users must continue working unchanged.

If a mobile-app user later signs in with Google using the same verified email:

1. Backend detects the existing `mobile_app` user by email
2. Backend verifies Google identity
3. Backend links Google: set `google_id = <verified_google_subject_id>`
4. User account now supports both:
   - Existing mobile app login (password, OTP, biometric, or whatever mechanism exists)
   - Google Sign-In
5. Do NOT force account recreation

---

## Backend API Design

Inspect the existing API architecture, naming conventions, authentication controller/service structure, and response format.

Extend the existing authentication module instead of creating a parallel system. Follow existing patterns for:
- Route naming
- Request/response structure
- Error format
- Authorization headers
- HTTP status codes

**Recommended endpoints:**

### POST /auth/google

**Request:**
```json
{
  "idToken": "GOOGLE_ID_TOKEN_FROM_CLIENT"
}
```

**Backend responsibilities:**
1. Validate Google ID token signature using Google's public keys (or a library like `google-auth-library-nodejs`)
2. Verify issuer is `https://accounts.google.com`
3. Verify audience/client ID matches your Android or iOS client ID (or both, handle both)
4. Verify token has not expired
5. Extract verified claims:
   - Google subject ID (`sub`)
   - email
   - name
   - profile picture URL (if required by product)
6. Normalize email (lowercase, trim)
7. Search database: does a user with this `google_id` exist?
8. If not found, search: does a user with this email exist?
9. Handle three cases:
   - **Existing google_id:** Authenticate the user
   - **Existing email (different signup_type):** Link the account (update `google_id`)
   - **Neither exist:** Create new user with `signup_type = 'google'`, `google_id = <verified_sub>`, `password_set = false`
10. Generate your standard application JWT or session token
11. Return success response with user data and password setup flag

**Response:**
```json
{
  "success": true,
  "token": "APPLICATION_JWT_OR_SESSION_TOKEN",
  "user": {
    "id": 123,
    "name": "User Name",
    "email": "user@gmail.com",
    "signupType": "google",
    "passwordSet": false
  },
  "requiresPasswordSetup": true
}
```

**Security rule:** Do NOT expose Google tokens, access tokens, refresh tokens, or sensitive backend secrets in any response.

---

### POST /auth/set-password

**Authentication:** Requires valid application JWT/session token in Authorization header.

**Request:**
```json
{
  "password": "NewSecurePassword123!"
}
```

**Backend responsibilities:**
1. Authenticate the current user from the JWT/session
2. Validate password meets your password policy (minimum length, complexity, etc.)
3. Hash the password using the existing algorithm
4. Store the hash in the `password` column
5. Set `password_set = true` for this user
6. Do NOT modify `google_id` or any other authentication relationship
7. Return success

**Response:**
```json
{
  "success": true,
  "message": "Password created successfully"
}
```

---

### Existing Endpoints (Preserve)

Ensure existing endpoints continue working unchanged:
- POST /auth/login (email + password)
- POST /auth/register (email signup)
- POST /auth/logout
- Any existing mobile authentication endpoint

---

## Flutter Mobile App Implementation

### Update Login Screen

Redesign the login screen to support both email/password and Google Sign-In. Follow the existing Moi Kanakku design system:

```
[Email input]
[Password input]

[Login] button

Forgot Password?

────── OR ──────

[Continue with Google] button

Don't have an account?
[Create Account] link
```

Maintain existing:
- Light and dark theme support
- Typography
- Border radius
- Button styles
- Spacing
- Reusable widgets

Do NOT introduce new colors or break the design system.

### Update Signup Screen

```
Create Account

[Name input]
[Email input]
[Password input]
[Confirm Password input]

[Create Account] button

────── OR ──────

[Continue with Google] button
```

Same design system constraints as Login screen.

### Google Authentication Service Architecture

Create a clean separation between authentication logic and UI:

```
lib/
  core/
    auth/
      auth_service.dart           (main auth interface)
      google_auth_service.dart    (Google-specific logic)
      auth_provider.dart          (state management integration)
      constants/
        signup_type_constants.dart (SignupType enum)
  
  features/
    authentication/
      login/
        screens/
          login_screen.dart
        widgets/
          google_signin_button.dart
      
      signup/
        screens/
          signup_screen.dart
      
      set_password/
        screens/
          set_password_screen.dart
        widgets/
          password_input_field.dart (reuse if exists)
```

Do NOT embed Google authentication code directly inside Login or Signup UI widgets. Authentication logic must be in a service layer.

### Reusable Google Sign-In Button Widget

Create a single, reusable widget used everywhere Google Sign-In appears (Login, Signup, account linking screens):

```dart
class GoogleSignInButton extends StatefulWidget {
  // Constructor
}
```

The widget must support:
- Loading state (show spinner, disable button)
- Disabled state
- Light and dark mode
- Proper Google branding (follow Google's branding guidelines)
- Accessibility (semantic labels, high contrast)
- Error handling (show user-friendly error messages)

Create this widget once. Reuse it everywhere. Do NOT create duplicate Google buttons.

### Set Password Screen

Create a dedicated screen:

```dart
class SetPasswordScreen extends StatefulWidget {
  // Constructor
}
```

**UI:**
```
Create Your Password

Your Google account is connected.
Set a password so you can also sign in
using your email and password.

[Password input]
[Confirm Password input]

[Create Password] button

Skip (optional, depending on product policy)
```

**Validation:**
- Both fields required
- Minimum length (use existing project's password rules)
- Password confirmation must match
- Show/hide password toggle

Reuse existing password input field widget from the project if one exists.

### Navigation Logic After Authentication

```dart
// After successful Google login
if (response.requiresPasswordSetup) {
  // Navigate to Set Password screen
  navigateTo(SetPasswordScreen());
} else {
  // Navigate to Home
  navigateTo(HomeScreen());
}

// After password creation on Set Password screen
// Refresh user/session state
// Navigate to Home
```

Prevent users from accidentally navigating back to the authentication screen using the back button. Handle logout correctly and completely.

### Auth State Model

Update your existing authentication state model (or create one if it doesn't exist):

```dart
class AuthUser {
  final int id;
  final String name;
  final String email;
  final String signupType;    // 'email', 'google', 'mobile_app', 'admin'
  final bool passwordSet;
  final bool emailVerified;
}
```

Do NOT duplicate authentication state across multiple providers or controllers. Use your existing state management architecture (Provider, Riverpod, BLoC, etc.) consistently.

### Google Cloud Configuration for Flutter

Inspect the existing Android and iOS project configuration.

**Android:**
- Verify package name
- Obtain SHA-1 and SHA-256 certificate fingerprints of the signing key
- Create OAuth 2.0 client ID in Google Cloud Console for Android with correct package name and certificate fingerprints

**iOS:**
- Verify bundle identifier
- Create OAuth 2.0 client ID in Google Cloud Console for iOS with correct bundle identifier

Add the OAuth configuration to your Flutter project:
- `android/app/build.gradle` or `android/app/google-services.json`
- `ios/Podfile` or `ios/Runner/GoogleService-Info.plist`
- `pubspec.yaml` with appropriate Google Sign-In package

Do NOT hardcode secrets into source code. Do NOT commit secrets to version control.

Verify debug and release configurations work separately.

---

## Admin Application

### Update User Details View

Modify the user details/profile view to display authentication information:

```
User
Email: user@gmail.com
Signup Type: Google
Google Linked: Yes / No
Password Set: Yes / No
Email Verified: Yes / No
Created Date: [date]
Last Login: [date/time]
```

**Do NOT display:**
- Password (ever)
- Password hash
- Google ID tokens or refresh tokens
- Google access tokens
- Application JWT or session tokens

### User List Filtering

If the existing admin user list supports filtering, add signup type filters:
- All
- Email
- Google
- Mobile App
- Admin

Optionally add:
- Google Linked (Yes / No)
- Password Set (Yes / No)

Use the existing admin design system and reusable components.

### Admin Authorization

Admin APIs must continue using the existing admin authorization system. Do NOT allow normal mobile users to access admin endpoints.

Verify:
- User is authenticated
- User has admin role
- Valid application token

Do NOT trust `signupType = 'admin'` as the only authorization check. Use the existing role/permission architecture.

---

## Duplicate Account Prevention

Implement protection against duplicate accounts using `google_id` and normalized email as the key identifiers.

**Test these cases:**

**Case 1: New Google account, no existing email or Google ID**
- Action: Create new user with `signup_type = 'google'`

**Case 2: Existing Google user logs in again**
- Action: Authenticate existing user, never create duplicate

**Case 3: Existing email user, new Google login with same email**
- Action: Link Google account, never create duplicate

**Case 4: Existing mobile_app user, new Google login with same email**
- Action: Link Google account, never create duplicate

**Case 5: Same Google account used multiple times**
- Action: Authenticate same user every time, never create duplicate

---

## Error Handling

Handle and surface these errors gracefully:

```
Google sign-in cancelled by user
Google account unavailable
Invalid Google ID token
Expired Google ID token
Email already exists under different signup_type
Account linking required (user must authenticate existing account)
Network connectivity failure
Server error / backend unavailable
Password validation error (mismatch, too weak, etc.)
Session expired
```

Show user-friendly error messages in the UI. Never expose:
- Backend stack traces
- SQL errors
- Google token validation errors or internal details
- Sensitive configuration information

---

## Loading States

Google authentication must have proper loading feedback.

```
User taps [Continue with Google]
       ↓
Button shows loading spinner, disabled
       ↓
Google authentication in progress
       ↓
Server validates token
       ↓
Response received
       ↓
Button returns to normal state
```

Prevent multiple concurrent authentication requests. Disable the button while authentication is running.

---

## Logout

Logout must cleanly clear:
- Application access token
- Refresh token (if used)
- User session
- Local authentication state
- Any cached user data

Also sign out from Google SDK if required (call the Google SDK logout method). However, do NOT revoke the user's Google account authorization when simply logging out of Moi Kanakku—that's unnecessarily aggressive. Let the user stay logged into their Google account.

---

## Security Requirements (Non-negotiable)

Follow these rules strictly:

- Never trust email or profile data received directly from the client.
- Never trust Google profile data from Flutter without server-side token validation.
- **Always validate Google ID tokens on the backend** using Google's public keys.
- Never store plaintext passwords.
- Never log passwords in any log system.
- Never log Google tokens, OAuth tokens, or ID tokens.
- Never log authorization headers or authentication credentials.
- Never expose secrets in Flutter source code.
- Use environment variables and server-side configuration for all backend secrets.
- Validate all authentication requests on the backend.
- Implement rate limiting on authentication endpoints if your backend infrastructure supports it.
- Prevent duplicate accounts using `google_id` and normalized email.
- Use HTTPS/TLS in production for all authentication traffic.
- Maintain existing JWT/session security; do not weaken it for Google integration.
- Do not introduce new security vulnerabilities while adding Google authentication.

---

## Backend Environment Variables

If backend Google verification requires configuration, define environment variables:

```env
GOOGLE_CLIENT_ID=your_web_client_id_for_backend_verification
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id
GOOGLE_IOS_CLIENT_ID=your_ios_client_id
```

Use the exact configuration required by your chosen Google authentication library (e.g., `google-auth-library-nodejs`).

Never commit production secrets to version control.

---

## API Response Consistency

Use your existing API response format throughout. Every authentication endpoint should return a consistent structure:

```json
{
  "success": true/false,
  "message": "...",
  "token": "...",
  "user": { ... },
  "requiresPasswordSetup": true/false,
  "error": "..." (if applicable)
}
```

Do NOT create a completely different response structure only for Google login if your existing authentication API has a standard format. Maintain consistency.

---

## Testing Checklist

Before marking implementation complete, verify these scenarios work end-to-end:

**Registration**
- [ ] Email signup works
- [ ] Google signup works
- [ ] Existing email account prevents duplicate signup
- [ ] Existing Google account prevents duplicate signup
- [ ] Existing mobile_app account can link to Google

**Login**
- [ ] Email/password login works
- [ ] Google login works
- [ ] Wrong password rejected
- [ ] Cancelled Google login handled gracefully
- [ ] Expired Google token handled gracefully
- [ ] Network failure handled gracefully

**Password**
- [ ] Google user without password sees Set Password screen
- [ ] Google user creates password successfully
- [ ] Google user can log in with email + newly-set password
- [ ] Wrong password rejected
- [ ] Password confirmation mismatch rejected

**Account Linking**
- [ ] Existing email user can link Google account
- [ ] Existing mobile_app user can link Google account
- [ ] Same Google account used repeatedly doesn't create duplicate
- [ ] Duplicate email prevention works

**Admin**
- [ ] Admin can view user list with signup type
- [ ] Admin can see Google linked status
- [ ] Admin can see password set status
- [ ] Admin authorization unchanged
- [ ] Admin cannot access admin APIs without admin role

**Regression (Existing Functionality)**
- [ ] Transactions continue working
- [ ] Dashboard works
- [ ] User profile works
- [ ] Notifications work
- [ ] Logout works completely
- [ ] All existing APIs respond correctly
- [ ] Existing user data untouched
- [ ] Existing admin features work

---

## Code Quality & Architecture

Before writing implementation code:

1. **Inspect** the current authentication architecture (existing login/signup flow, state management, API design)
2. **Inspect** database schema (what fields exist, what naming conventions, what relationships)
3. **Inspect** existing login/signup APIs (request/response format, error handling, status codes)
4. **Inspect** Flutter state management (Provider, BLoC, Riverpod, etc.)
5. **Inspect** admin authentication and authorization system
6. **Reuse** existing patterns, naming conventions, and architectural decisions wherever possible

Do NOT rewrite the entire authentication system unnecessarily.

**Code organization:**
- Create reusable components (services, widgets, utilities)
- Avoid duplicated code
- Use constants and enums for `signupType` values and authentication states
- Add comments only where logic is non-obvious
- Follow the project's existing code style and conventions

Keep the implementation production-ready: it should be safe to deploy immediately after review.

---

## Final Deliverables Summary

After implementation is complete, provide a comprehensive summary:

### Flutter Mobile
- List of files created (new authentication services, screens, widgets)
- List of files modified (existing login/signup screens, navigation)
- Google Sign-In configuration details (Android package name, iOS bundle ID, certificate fingerprints used)
- Login/signup UI changes (screenshots or description)
- Set Password screen (screenshot or description)
- Navigation flow changes (where users are routed after authentication)

### Admin Application
- List of files modified
- Authentication information now displayed (signup type, Google linked, password set, etc.)
- Filtering options added (if applicable)
- UI changes (screenshots or description)

### Backend
- Database migration provided (SQL script, safe and non-destructive)
- New/modified API endpoints (POST /auth/google, POST /auth/set-password, etc.)
- Google token validation implementation (library used, configuration required)
- Account linking logic (how duplicate accounts are prevented)
- Password setup flow (backend validation and storage)
- Security changes (what was added or hardened)

### Testing Summary
Provide a checklist verifying:

```
[✓] Email signup working
[✓] Email login working
[✓] Google signup working
[✓] Google login working
[✓] Google user password setup working
[✓] Email login after Google password setup working
[✓] Existing email account + Google linking working
[✓] Existing mobile_app account + Google linking working
[✓] Duplicate account prevention working
[✓] Admin user management working
[✓] Admin filters working
[✓] Logout working completely
[✓] All existing APIs working (regression tests)
[✓] No existing user data lost or modified
[✓] Security rules enforced
```

---

## Acceptance Criteria

Implementation is complete and ready for deployment when:

1. **End-to-end flow works:** Flutter mobile → Google authentication → backend validation → MySQL database → application JWT/session → Set Password (if needed) → Home screen
2. **No existing functionality broken:** All existing APIs, transactions, user data, and admin features continue working
3. **All security rules enforced:** Google tokens validated server-side, passwords hashed, no secrets in source code
4. **Duplicate accounts prevented:** No user can create multiple accounts using the same email or Google ID
5. **Account linking safe:** Existing users can link Google without losing data or password
6. **Code follows project patterns:** Uses existing architecture, naming, state management, response format, design system
7. **All test scenarios pass:** Including registration, login, password setup, account linking, admin, and regression tests
8. **Production-ready:** Code is clean, commented where necessary, follows conventions, and is ready to deploy

---

Begin by inspecting the existing codebase to understand the current authentication architecture, database schema, API design, state management, and design system. Then design the implementation to extend these existing patterns rather than replace them. Once you understand the existing system, provide your detailed implementation plan covering Flutter, backend, database, and admin changes, followed by the actual code and migration scripts.