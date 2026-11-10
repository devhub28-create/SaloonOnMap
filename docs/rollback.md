# Production Rollback Procedures

This document describes the operational procedures for rolling back releases of the SLOT platform in production.

## 1. Application Backend Rollback (Docker Image Swapping)

The backend service is deployed as immutable Docker containers tagged with version numbers and Git commit SHAs (e.g., `slot-backend:1.0.0-a7b3c9d`).

### Steps:
1. **Identify Previous Target Tag**:
   Query the release log or image registry for the last known healthy image tag (e.g., `slot-backend:1.0.6`).
2. **Update Service Image Tag**:
   ```bash
   docker service update --image slot-backend:1.0.6 slot_backend
   # Or using Docker Compose / Helm:
   # edit .env set BACKEND_TAG=1.0.6 && docker-compose up -d backend
   ```
3. **Verify Deployment**:
   Execute curl against `/api/v1/version` to ensure active release reports the expected rollback version:
   ```bash
   curl https://api.slotapp.com/api/v1/version
   ```

---

## 2. Database Schema Rollback Strategy

Database migrations follow an **Expand / Contract** pattern. Schema changes must be backward-compatible with previous application code.

### Rollback Guidelines:
- If a deployment fails before the contract phase, rolling back the application code requires **zero database schema changes**.
- If a migration added non-breaking columns or tables, leave them in place during an application code rollback.
- If a migration script revert is required:
  ```bash
  cd slot/apps/backend
  npm run migration:revert
  ```
- **CRITICAL**: Never run `npm run seed` or `npm run seed:development` in production during a rollback or deployment.

---

## 3. Web Frontends Rollback (Customer, Partner, Admin)

Web applications are built static Flutter Web bundles hosted behind Nginx.

### Steps:
1. **Re-point Static Files**:
   Swap symlink or deploy folder `/usr/share/nginx/html/customer` (and `partner`, `admin`) to point to previous release artifact bundle.
2. **Reload Nginx**:
   ```bash
   nginx -s reload
   ```

---

## 4. Mobile Apps Rollback (Android / iOS)

- **Android (AAB / APK)**: Rollback is managed via Google Play Console internal test / production tracks by setting the primary active release track to the previous version code, or releasing a hotfix patch build (`1.0.1+2`).
- **iOS (IPA)**: Rollback is managed via TestFlight / App Store Connect release management. Note: iOS builds are currently **NOT VERIFIED** due to missing Apple Developer signing certificates on the local build host.
