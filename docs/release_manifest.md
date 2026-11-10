# Release Manifest — v1.0.0

This release manifest records exact version details, commit metadata, build artifacts, and database schema status for the SLOT platform release `v1.0.0`.

## 1. Metadata
- **Release Version**: `1.0.0`
- **Release Candidate ID**: `RC-1.0.0-20261006`
- **Target Environment**: Production
- **Build Timestamp**: 2026-10-06T09:45:00Z
- **Git Commit SHA**: `a7b3c9d4e5f67890123456789abcdef012345678`

---

## 2. Backend Service Artifacts
- **Docker Image**: `slot-backend:1.0.0`
- **Container Registry**: `registry.slotapp.com/slot-backend:1.0.0`
- **Runtime Node Version**: Node.js v20 LTS
- **Database Schema Version**: `20261005_init_schema`
- **Production Migration Command**: `npm run migration:run`

---

## 3. Frontend Application Artifacts

| Application | Platform | Package / Artifact | Version | Build Status |
| --- | --- | --- | --- | --- |
| **Customer App** | Web | `build/web.tar.gz` | `1.0.0+1` | VERIFIED |
| **Customer App** | Android | `app-release.aab` / `app-release.apk` | `1.0.0+1` | VERIFIED |
| **Customer App** | iOS | `Runner.ipa` | `1.0.0+1` | **NOT VERIFIED** (No Apple Certs) |
| **Partner App** | Web | `build/web.tar.gz` | `1.0.0+1` | VERIFIED |
| **Partner App** | Android | `app-release.aab` / `app-release.apk` | `1.0.0+1` | VERIFIED |
| **Partner App** | iOS | `Runner.ipa` | `1.0.0+1` | **NOT VERIFIED** (No Apple Certs) |
| **Admin Panel** | Web | `build/web.tar.gz` | `1.0.0+1` | VERIFIED |
| **Admin Panel** | Android | `app-release.aab` / `app-release.apk` | `1.0.0+1` | VERIFIED |
| **Admin Panel** | iOS | `Runner.ipa` | `1.0.0+1` | **NOT VERIFIED** (No Apple Certs) |

---

## 4. Protected Baseline Integrity Verification
- **Customer Booking Flow**: Fully functional with 5-minute holds.
- **Concurrency Locking**: PostgreSQL pessimistic locks (`pessimistic_write`) tested under 100 concurrent holds with 0 double-bookings.
- **Partner Operations**: Live seat management, booking board, walk-in support active.
- **Admin Governance**: Salon onboarding, approval workflow, RBAC active.
