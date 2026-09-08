# Performance Optimization Plan: Node.js + MySQL (Shared cPanel Hosting)

Comprehensive analysis and optimization strategy for the Node.js backend (`/Users/naethra/Desktop/Projects/GP-Personal/Moi Project/MOI-LIVE-APPs/Final Version/backend`).

## Executive Summary & Application Flow Analysis

### Architecture & Application Flow
```
Client Request
  └── Express Middleware (cors, helmet, morgan, express.json, apiSecurity)
       └── Route Dispatcher (src/routes)
            └── Authentication / Authorization (src/middlewares/auth.js)
                 └── Controller Layer (src/controllers)
                      └── Cache Layer Check (src/utils/cache.js - node-cache)
                           ├── Cache Hit  ──► Return Response (0 DB round trips)
                           └── Cache Miss ──► Service / Model Layer (src/models)
                                                └── MySQL Connection Pool (src/config/database.js - mysql2/promise)
                                                     └── Query Execution & Response
```

### Identified Performance Bottlenecks & Priority Matrix

| Priority | Category | Component / File | Issue Description | Optimization Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **P1** | **N+1 Queries** | `transactions.js` (controller) | `createV2Bulk` loops over N items, executing `User.findById`, `PersonModel.findDuplicate`/`readById`, `resolveTransactionFunction`, `Model.create`, and `Model.readById` sequentially for every item. (Up to N×7 queries). | Batch/cache user lookups for request payload, resolve persons & functions in bulk, perform batch insertions, and construct return objects locally. |
| **P1** | **N+1 Queries** | `notificationController.js` | `sendBulkNotifications` invokes `Notification.create` in a loop for each target user (N `INSERT` statements). | Replace individual `INSERT`s with a single bulk insert `Notification.createBulk`. |
| **P2** | **Excessive DB Round Trips** | `dashboardController.js` | `getDashboard` & `getDashboardDetailed` execute 11 to 14 separate `db.query` calls per request for counts. | Consolidate count & sum queries on `transactions` into a single query using conditional aggregation (`COUNT(*)`, `SUM(CASE WHEN type='invest' THEN 1 ELSE 0 END)`, etc.). |
| **P3** | **Missing Composite Indexes** | Database Schema (`transactions`, `persons`, `user_devices`, `notifications`) | Queries routinely filter by `user_id` + `is_deleted` + `type`/`person_id`/`created_at`. Current schema has mostly single-column indexes. | Add targeted composite indexes to support frequent filter/sort patterns without full user scan. |
| **P4** | **Unindexed/Non-sargable Queries** | `models/transactions.js`, `models/user.js` | `DATE(t.transaction_date) >= ?` and `LOWER(u.email) = LOWER(?)` prevent index usage on `transaction_date` and `uk_users_email`. | Use range comparison (`t.transaction_date >= ? AND t.transaction_date <= ?`) and direct parameter normalization (`u.email = LOWER(?)`). |
| **P5** | **Cache Opportunities** | `models/moiDefaultFunctions.js` | `default_functions` table (master lookup data) is queried on every transaction/list operation without caching. | Implement in-process `node-cache` wrapping for `readAll` & `readById` with targeted invalidation on write/update/delete. |
| **P6** | **Redundant DB Reads** | `controllers/transactions.js` | `createV2` executes `Model.create` followed by `Model.readById` to fetch inserted transaction details. | Construct and return transaction response directly from payload metadata to eliminate the extra `SELECT` round trip. |

---

## User Review Required

> [!IMPORTANT]
> **Database Index Migration Script**
> We recommend adding composite indexes on key MySQL tables (`transactions`, `persons`, `transaction_functions`, `upcoming_functions`, `notifications`, `user_devices`). These SQL `ALTER TABLE` statements will be saved to a migration file (`database/optimizations_indexes.sql`) so you can execute them directly on your cPanel MySQL database.

> [!NOTE]
> All optimized endpoints strictly maintain API response contracts, error handling, status codes, and data payload structures.

---

## Open Questions

None at this time. All requirements and logic patterns are fully understood from source code analysis.

---

## Proposed Changes

### Database Layer & Indexing

#### [NEW] [optimizations_indexes.sql](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/database/optimizations_indexes.sql)
Create SQL script containing composite index additions to optimize frequent filtering & sorting:
- `ALTER TABLE transactions ADD INDEX idx_trans_user_del_type (user_id, is_deleted, type);`
- `ALTER TABLE transactions ADD INDEX idx_trans_user_del_person (user_id, is_deleted, person_id);`
- `ALTER TABLE transactions ADD INDEX idx_trans_user_del_func (user_id, is_deleted, transaction_function_id);`
- `ALTER TABLE transactions ADD INDEX idx_trans_user_del_date (user_id, is_deleted, transaction_date DESC);`
- `ALTER TABLE persons ADD INDEX idx_persons_user_del_name (user_id, is_deleted, first_name);`
- `ALTER TABLE transaction_functions ADD INDEX idx_tf_user_del_date (user_id, is_deleted, function_date DESC);`
- `ALTER TABLE upcoming_functions ADD INDEX idx_uf_user_del_date (user_id, is_deleted, function_date ASC);`
- `ALTER TABLE notifications ADD INDEX idx_notif_user_del_created (user_id, is_deleted, created_at DESC);`
- `ALTER TABLE user_devices ADD INDEX idx_ud_user_active_used (user_id, is_active, last_used_at DESC);`

---

### Controllers Component

#### [MODIFY] [dashboardController.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/controllers/dashboardController.js)
- Consolidate transaction count queries (total, invest, return, totals by amount) into single conditional aggregation queries.
- Reduce database queries in `getDashboard` from 11 queries to 7 queries.
- Reduce database queries in `getDashboardDetailed` from 14 queries to 8 queries.

#### [MODIFY] [transactions.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/controllers/transactions.js)
- Optimize `createV2Bulk`:
  - Verify `user` once per unique `userId` in payload instead of N times in loop.
  - Pre-fetch existing persons for the user to resolve duplicates in-memory.
  - Eliminate post-insert `readById` round trips by generating response objects directly.
- Optimize `createV2`: Avoid extra `readById` call when returning insert status.
- Ensure cache invalidation (`clearTransactionCaches`) fires cleanly.

#### [MODIFY] [notificationController.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/controllers/notificationController.js)
- Add `createBulk` usage to batch insert notifications for bulk notification sends instead of individual `INSERT` calls per user.

---

### Models Component

#### [MODIFY] [moiDefaultFunctions.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/models/moiDefaultFunctions.js)
- Wrap `readAll()` and `readById()` in `cache.getOrSet` with TTL DEFAULTS (5 minutes).
- Invalidate cache keys (`default_functions:all`, `default_functions:id:${id}`) on `create`, `update`, and `delete`.

#### [MODIFY] [notificationModels.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/models/notificationModels.js)
- Add `createBulk(notificationsArray)` model method for multi-row insertion in a single SQL query: `INSERT INTO notifications (user_id, title, body, type, is_read) VALUES ...`.

#### [MODIFY] [transactions.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/models/transactions.js)
- Replace `DATE(t.transaction_date) >= ?` and `DATE(t.transaction_date) <= ?` with range conditions `t.transaction_date >= ?` and `t.transaction_date <= ?` to enable index range scanning.

#### [MODIFY] [user.js](file:///Users/naethra/Desktop/Projects/GP-Personal/Moi%20Project/MOI-LIVE-APPs/Final%20Version/backend/src/models/user.js)
- Change `WHERE LOWER(u.email) = LOWER(?)` to `WHERE u.email = ?` (with `email.toLowerCase()` in JS) to utilize `uk_users_email` unique index.

---

## Verification Plan

### Automated Tests & Syntax Verification
- Run Node syntax validation across all modified files:
  `node -c app.js`
  `node -c src/controllers/dashboardController.js`
  `node -c src/controllers/transactions.js`
  `node -c src/controllers/notificationController.js`
  `node -c src/models/moiDefaultFunctions.js`
  `node -c src/models/notificationModels.js`
  `node -c src/models/transactions.js`
  `node -c src/models/user.js`

### Manual Verification
- Test dev server boot: `node app.js`.
- Test dashboard stats endpoint response format.
- Test bulk transaction creation endpoint to verify N+1 query elimination and response format compatibility.
- Test notification creation and default functions caching.
