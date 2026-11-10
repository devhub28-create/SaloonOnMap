# REST API & WebSockets Specification - SLOT Platform

Base URL: `http://localhost:3000/api/v1`  
Swagger Documentation: `http://localhost:3000/api/v1/docs`

---

## 1. Authentication Endpoints

### `POST /auth/request-otp`
- Request: `{ "phone": "+919876543210" }`
- Response: `{ "message": "OTP sent successfully" }`

### `POST /auth/verify-otp`
- Request: `{ "phone": "+919876543210", "code": "123456", "role": "CUSTOMER" }`
- Response: `{ "accessToken": "<jwt>", "user": { "id": "...", "phone": "...", "role": "CUSTOMER" } }`

---

## 2. Customer Home & Salon Endpoints

### `GET /customer/home?gender=MEN`
- Response: Returns hero banner, active booking banner, popular services, power combos, and recommended salons.

### `GET /salons?search=Indiranagar`
- Response: Array of active salons matching search.

### `GET /salons/:id`
- Response: Detailed salon entity, service menu, and featured combos.

### `GET /salons/:id/available-slots?date=2026-09-28`
- Response: Available time slots and seat inventory list.

---

## 3. Booking Engine Endpoints

### `POST /bookings/holds`
- Request:
  ```json
  {
    "customerId": "customer-id",
    "salonId": "maison-muse-id",
    "seatId": "seat-04-id",
    "serviceIds": ["svc-1", "svc-2"],
    "startAt": "2026-09-28T16:15:00.000Z",
    "endAt": "2026-09-28T17:00:00.000Z",
    "totalPrice": 648.0,
    "totalDuration": 45
  }
  ```
- Response: `{ "holdId": "uuid", "expiresAt": "ISOString", "expiresInSeconds": 300 }`

### `POST /bookings`
- Headers: `Idempotency-Key: idemp-123456`
- Request: `{ "holdId": "uuid", "customerId": "customer-id", "notes": "Pay at salon" }`
- Response: `{ "id": "uuid", "referenceCode": "#MM2841", "status": "CONFIRMED", "seatLabel": "Seat 4" }`

---

## 4. Partner App Endpoints

### `GET /partner/bookings?salonId=maison-muse-id&status=ALL`
- Response: Returns all live bookings for the authorized salon.

### `GET /partner/seats?salonId=maison-muse-id`
- Response: Returns current status grid of all physical seats (Seats 01 to 06).

### `PATCH /partner/seats/:id/status`
- Request: `{ "status": "IN_SERVICE" }`
- Response: Updated seat record. Emits `seat.updated` event over WebSocket gateway.

---

## 5. WebSockets Realtime Events

Gateway Endpoint: `ws://localhost:3000`

- `booking.created`: Broadcast when customer confirms booking.
- `seat.updated`: Broadcast when seat status changes.
