# Production Observability & Alerting Thresholds

This document defines the key performance metrics, log formatting, and alert triggers for monitoring the SLOT production environment.

## 1. High-Priority Alert Triggers

| Alert Name | Metric / Trigger | Threshold | Severity | Recommended Action |
| --- | --- | --- | --- | --- |
| **High Error Rate** | HTTP 5xx Status Ratio | > 1% over 5 mins | P1 - CRITICAL | Check backend logs for unhandled exceptions or DB connectivity errors. |
| **High Latency (P95)** | API Latency (P95) | > 100ms over 5 mins | P2 - HIGH | Inspect PostgreSQL query performance, CPU usage, and Redis cache hit rate. |
| **Database Down** | DB Connection Failures | > 0 consecutive failures | P1 - CRITICAL | Verify PostgreSQL container health, disk space, and memory pool. |
| **Redis Down** | Redis Lock/Cache Errors | > 0 consecutive failures | P1 - CRITICAL | Verify Redis container health and socket connections. |
| **Booking Hold Spikes** | Hold Failure Rate | > 5% conflicts/sec | P2 - HIGH | Investigate double-booking contention on popular salon seats. |

---

## 2. Health & Version Monitoring

- **Endpoint**: `GET /api/v1/health` (Reports DB & Redis connection health status)
- **Version Endpoint**: `GET /api/v1/version` (Reports Git commit SHA, environment, version string, and build timestamp)
