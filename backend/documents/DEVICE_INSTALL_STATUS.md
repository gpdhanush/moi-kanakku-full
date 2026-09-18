# Device install status

The system detects a device as **Likely Uninstalled** when FCM indicates that its registration token is no longer valid/unregistered. It cannot guarantee the exact uninstall time.

There is no `onAppUninstalled` callback. Do not treat old `last_used_at` as uninstall.

## Status meanings

| Status | Meaning |
| --- | --- |
| Unknown | No `user_devices` row. Existing users who have not opened the updated app. |
| Installed / Active | At least one device has an active FCM token and recent `last_used_at`. |
| Inactive | Token is still valid, but last app activity is older than `DEVICE_INACTIVE_DAYS`. |
| Likely Uninstalled | Every known device has `token_status = invalid` after FCM unregistered/invalid. |

FCM invalidation is not instantaneous. Tokens can stay valid after uninstall for a while. Invalid tokens can also come from notification being disabled, app data being cleared, token rotation, or OS delivery limits.

## Database changes

File: `backend/database/user_devices_install_status.sql`

Adds to existing `user_devices`:

- `platform` (default `android`)
- `app_version`
- `token_status` (`active` / `invalid`)
- `uninstalled_at`

`is_active` stays in sync (`1` = active token, `0` = invalid). `last_used_at` is last seen and is **not** updated when a token is invalidated.

Run this SQL on production **before** deploying the backend that reads these columns.

Down statements are commented at the bottom of the SQL file.

## API changes

- `POST /users/update-notification-token` (authenticated)
  - User id comes from JWT, not the request body.
  - Body: `token`, `device_id`, optional `platform`, `app_version`, device metadata.
  - Upserts by `(user_id, device_id)`. Does not delete sibling devices.
  - Updates `last_used_at` even when the FCM token is unchanged (heartbeat).
- Admin `GET /users/admin/all-user-lists` and `GET /users/admin/all-user-lists/:id`
  - Adds `app_status`, `last_seen_at`, `device_count`, `platforms`, `app_version`, `devices`.
  - Does **not** return raw FCM tokens.

## Flutter changes

- Login, home, token refresh, and throttled app resume send device heartbeat.
- Sends `app_version` from `package_info_plus` and `platform: android`.
- Heartbeat is throttled to 6 hours on resume. Login and FCM token refresh always send.
- Failure does not block login or app use.

## FCM / background job

Daily 9:00 AM IST cron in `app.js` runs `runFcmTokenHealthCheck()`.

It sends **data-only** messages (`data.type = device_health_check`) with no visible notification payload. Invalid/unregistered tokens are marked Likely Uninstalled.

This is not a guaranteed uninstall event.

## Environment variables

```
DEVICE_INACTIVE_DAYS=14
FCM_HEALTH_CHECK_INTERVAL=24
FCM_HEALTH_CHECK_BATCH_SIZE=100
```

`FCM_HEALTH_CHECK_INTERVAL` documents the intended cadence. The job currently runs with the existing daily cron.

## Deployment order

1. Run `backend/database/user_devices_install_status.sql` on production.
2. Deploy backend.
3. Deploy admin UI.
4. Deploy Flutter app.
5. Existing users get a device row when they open the updated app and authenticate.
6. Daily health check begins marking invalid tokens.

Old mobile builds can still call `update-notification-token`. Extra columns have defaults.

## Testing

Backend:

```
cd backend && npm test
```

Flutter:

```
cd mobile-app && flutter test test/device_heartbeat_test.dart && flutter analyze
```

## Admin UI

Users Master shows App Status, Last Seen, and device count, with filters:

All / Installed / Inactive / Likely Uninstalled / Unknown

User details lists each device: Platform, App Version, Last Seen, Status.

Account Activate/Deactivate is separate from app install status.
