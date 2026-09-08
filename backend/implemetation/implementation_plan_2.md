# Performance Optimization Plan: `GET /apis/users/admin/all-user-lists`

## Executive Summary & Root Cause Analysis

### Current Bottleneck Analysis (16-second response time)
The current implementation of `GET /apis/users/admin/all-user-lists`:
1. `userController.adminAllUserLists` calls `User.getAllPublicDetails()`.
2. `User.getAllPublicDetails()` executes `SELECT id FROM users WHERE is_deleted = 0 ORDER BY created_at DESC`.
3. Then, inside an async `for` loop over every returned user ID, it calls `User.getPublicDetails(userId)`.
4. `User.getPublicDetails(userId)` executes **5 separate database queries** per user:
   - `SELECT ... FROM users WHERE id = ?`
   - `SELECT ... FROM user_profiles WHERE user_id = ?`
   - `SELECT ... FROM user_devices WHERE user_id = ? AND is_active = 1 ORDER BY last_used_at DESC LIMIT 1`
   - `SELECT referrer_user_id FROM user_referrals WHERE referred_user_id = ?` (Unused by endpoint response!)
   - `SELECT COUNT(*) AS cnt FROM user_referrals WHERE referrer_user_id = ?` (Unused by endpoint response!)

**Result**: For 500 users, the backend executes $1 + (500 \times 5) = \mathbf{2,501\text{ sequential database queries}}$ per API request! This causes severe MySQL connection starvation, excessive Node.js event-loop lag, and a ~16 second API response time.

---

## Target Metrics

- **Response Time**: Reduce from **~16,000 ms** to **< 100 ms** (on local/dev) and **< 300 ms** under full dataset conditions.
- **Database Queries**: Reduce from **2,501 queries** to **1 query** (or 0 queries on cache hit).
- **Database Payload**: Select only the 7 fields required by `formatAdminUserListItem` (`id`, `mobile`, `name`, `last_login`, `city`, `profile_image_url`, `device_name`).

---

## User Review Required

> [!IMPORTANT]
> **API Compatibility Assurance**
> The response structure `{ responseType: "S", responseValue: [ { id, mobile, name, last_login, city, profile_image_url, device_name }, ... ] }` will remain 100% identical.

> [!NOTE]
> **In-Process Cache & Invalidation**
> Results will be cached in `node-cache` with a 60-second TTL (`admin:all-user-lists`). Any user updates, creates, status changes, or soft deletes will trigger `cache.delByPrefix('admin:all-user-lists')` to ensure real-time data accuracy.

---

## Open Questions

None. The entire execution flow and cause of the 16s latency have been isolated.

---

## Proposed Changes

### Model Layer

#### [MODIFY] [user.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/models/user.js)
- Rewrite `getAllPublicDetails()` to perform a single consolidated `LEFT JOIN` query across `users`, `user_profiles`, and `user_devices` (using subquery for the active device).
- Support optional pagination (`limit`, `offset`) and search parameters if provided by the controller.
- Add helper method `clearUserCache()` to invalidate `admin:all-user-lists` cache on user create/update/delete.

### Controller Layer

#### [MODIFY] [user.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/controllers/user.js)
- Wrap `adminAllUserLists` in `cache.getOrSet` with a 60-second TTL.
- Add cache invalidation calls in `updateStatus`, `deleteUser`, `updateUser`, and registration routes.

---

## Verification & Benchmarking Plan

### Automated Benchmark Script
- Create a benchmark script `scratch/benchmark_admin_user_list.js` to execute `GET /apis/users/admin/all-user-lists` multiple times and measure:
  - Total response time (ms)
  - Number of SQL queries executed
  - Response payload size and status code

### Regression Check
- Verify response structure matches exact frontend expectations:
  `[ { id, mobile, name, last_login, city, profile_image_url, device_name } ]`
