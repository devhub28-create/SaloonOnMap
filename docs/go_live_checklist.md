# Production Go-Live Checklist

This checklist verifies all requirements before promoting the SLOT application to production.

## 1. Backend & Infrastructure Verification
- [x] Backend NestJS app compiles without errors (`npm run build`).
- [x] Environment configuration updated with mandatory `JWT_SECRET`, `POSTGRES_PASSWORD`, `REDIS_PASSWORD`.
- [x] Version endpoint (`GET /api/v1/version`) deployed and returning version, commit SHA, build time, environment.
- [x] Production migration command (`npm run migration:run`) verified.
- [x] Seed data command (`npm run seed:development`) explicitly excluded from production pipelines.
- [x] Nginx reverse proxy configured with SSL/TLS termination, rate limiting, and WebSocket proxying (`slot/infrastructure/nginx/nginx.conf`).

## 2. Platform & UI Quality Assurance
- [x] Customer App Flutter Web & Android build cleanly without code warnings (`flutter analyze` - 0 issues).
- [x] Partner App Flutter Web & Android build cleanly without code warnings (`flutter analyze` - 0 issues).
- [x] Admin Panel Flutter Web & Android build cleanly without code warnings (`flutter analyze` - 0 issues).
- [x] Automated unit and integration test suites passing (100% pass across all packages).
- [x] Concurrency protection verified under 100 concurrent requests with pessimistic row locks.

## 3. Deployment & Release Integrity
- [x] Immutable Docker image tagging schema (`slot-backend:1.0.0`) established.
- [x] Rollback documentation (`docs/rollback.md`) and database migration strategy (`docs/migration_strategy.md`) published.
- [x] Production alerts and observability thresholds (`docs/production_alerts.md`) configured.
- [x] Android release artifacts (AAB / APK) built and ready for store submission.
- [!] **iOS Status**: Explicitly reported as `NOT VERIFIED` due to lack of Apple Developer signing certificates on host machine.

## 4. Final Verdict
- **Status**: **RELEASE CANDIDATE READY** (Pending live infrastructure SSL provisioning & Apple signing certificates for iOS).
