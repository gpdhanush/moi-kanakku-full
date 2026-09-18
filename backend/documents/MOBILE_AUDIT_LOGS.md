# Mobile User Audit Logs

## Purpose

Track successful mobile-app write activity so admins can review what users did
(login, profile changes, transactions, persons, functions, feedback, and more).

## Deploy steps

1. Run the SQL migration on the target database:

```bash
mysql -u <user> -p <database> < backend/database/user_audit_logs.sql
```

2. Deploy the backend that writes to `user_audit_logs` and exposes:

```text
GET /apis/admin/audit-logs?page=1&limit=25&userId=&action=&q=
```

3. Deploy the admin app (sidebar **Audit Logs** page + User Details activity section).

## Soft failure

If the table is missing, `recordAuditLog` catches insert errors and only warns in
server logs. Mobile APIs continue to succeed.

## What is logged

Successful write actions only (not list/read endpoints). Sensitive values such as
passwords, OTPs, and full FCM tokens are never stored.
