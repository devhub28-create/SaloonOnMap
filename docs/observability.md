# Observability & Logging Architecture — SLOT Platform

## Request Tracing
- Every incoming HTTP request is assigned a unique `X-Request-ID` correlation identifier.
- Logs include `requestId`, `timestamp`, `path`, `method`, `statusCode`, and latency `durationMs`.

## Metric Counters
- `http_requests_total`
- `booking_holds_created_total`
- `booking_holds_expired_total`
- `booking_confirmations_total`
- `booking_conflicts_total`
- `websocket_connections_active`
