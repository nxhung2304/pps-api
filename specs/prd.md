# PRD — `pps-api` (Backend)

> **Repo:** `pps-api`  
> **Stack:** Ruby on Rails 7 · PostgreSQL 15 · Apache Kafka · ActionCable · Docker  
> **Phụ thuộc bởi:** `pps-web`, `pps-mobile (future)`  
> **Phiên bản:** 1.0  
> **Cập nhật:** 2026-04-30

---

## 1. Mục tiêu

`pps-api` là **single backend** cho toàn bộ hệ thống Personal Performance System.

Nhiệm vụ:
- Nhận event từ mọi client (web, mobile, CLI)
- Publish event vào Kafka pipeline
- Xử lý event qua các consumer (persistence, stats, alert, realtime)
- Expose REST API cho client query stats & alerts
- Broadcast realtime qua WebSocket (ActionCable)

---

## 2. System Architecture

```
Client (pps-web / pps-mobile / curl)
  │
  ▼
[Rails API — pps-api]  ─────────────────────────────────────────
  │  POST /api/v1/events (auth required)                        │
  │  GET  /api/v1/stats  (auth required)                        │
  │  GET  /api/v1/alerts (auth required)                        │
  │                                                             │
  ▼                                                             ▼
[Kafka: user.events topic]                            [ActionCable WS]
  │                                                        (per user)
  ├──▶ Consumer: event_persistence  ──▶ PostgreSQL              ▲
  ├──▶ Consumer: stats_processor    ──▶ PostgreSQL         broadcast
  ├──▶ Consumer: alert_processor    ──▶ alerts table ───────────┘
  └──▶ Consumer: realtime_processor ──▶ WS broadcast
```

---

## 3. Authentication

**Strategy:** JWT Token (stateless)

### Endpoints

```
POST /auth/register   → tạo tài khoản
POST /auth/login      → trả về JWT token
```

### JWT Payload

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "iat": 1710000000,
  "exp": 1710086400
}
```

### Request Flow

```
Client gửi: Authorization: Bearer <jwt_token>
Rails validates → extract user_id → gán vào request context
```

### Implementation Notes

```ruby
# Gem: 'jwt'
# ApplicationController với before_action :authenticate_user!
# JwtService.encode / JwtService.decode
```

---

## 4. Event Design

### Base Schema

```json
{
  "id": "uuid-v4",
  "user_id": "uuid-v4",
  "type": "string",
  "timestamp": "unix_epoch_number",
  "payload": {}
}
```

### Event Types

| Type | Payload fields |
|------|---------------|
| `coding_session` | `duration` (minutes), `language`, `project` |
| `gym_session` | `duration` (minutes), `type` (strength/cardio) |
| `run_completed` | `distance_km`, `duration` (minutes) |
| `sleep_logged` | `duration` (hours), `quality` (good/fair/poor) |

### Validation Rules (API layer)

| Field | Rule |
|-------|------|
| `type` | Phải nằm trong whitelist |
| `timestamp` | Unix epoch, không được ở tương lai |
| `payload.duration` | Integer > 0 |
| `payload.distance_km` | Float > 0 (chỉ `run_completed`) |

> Validate ở API layer **trước** khi publish Kafka — không để message lỗi vào queue.

---

## 5. Kafka Design

### Topic

```
user.events
  - Partitions: 4 (partition key = user_id)
  - Replication: 1 (dev), 3 (prod)
  - Retention: 7 ngày
```

### Consumer Groups

| Group | Nhiệm vụ | Mode |
|-------|----------|------|
| `event_persistence` | Lưu raw event vào DB | Sync |
| `stats_processor` | Cập nhật `stats` table | Sync |
| `alert_processor` | Kiểm tra alert rules | Async |
| `realtime_processor` | Broadcast WebSocket | Async |

### Kafka Message Format

```json
{
  "event_id": "uuid",
  "user_id": "uuid",
  "type": "coding_session",
  "timestamp": 1710000000,
  "payload": { "duration": 120 },
  "produced_at": 1710000001
}
```

---

## 6. Database Design

### `users`

```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
email           VARCHAR NOT NULL UNIQUE
password_digest VARCHAR NOT NULL
created_at      TIMESTAMP
updated_at      TIMESTAMP
```

### `events`

```sql
id          UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id     UUID NOT NULL REFERENCES users(id)
type        VARCHAR NOT NULL
timestamp   BIGINT NOT NULL
payload     JSONB NOT NULL DEFAULT '{}'
created_at  TIMESTAMP

INDEX: (user_id, type, timestamp)
INDEX: (user_id, timestamp)
```

### `stats` (pre-computed)

```sql
id                  UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id             UUID NOT NULL REFERENCES users(id)
date                DATE NOT NULL
total_coding_time   INTEGER DEFAULT 0    -- minutes
total_gym_time      INTEGER DEFAULT 0    -- minutes
total_run_distance  FLOAT   DEFAULT 0    -- km
sleep_duration      FLOAT   DEFAULT 0    -- hours
event_count         INTEGER DEFAULT 0
created_at          TIMESTAMP
updated_at          TIMESTAMP

UNIQUE INDEX: (user_id, date)
```

> `stats_processor` consumer cập nhật bảng này sau mỗi event — `GET /stats` không query raw events.

### `alerts`

```sql
id           UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id      UUID NOT NULL REFERENCES users(id)
rule_key     VARCHAR NOT NULL
message      TEXT NOT NULL
severity     VARCHAR NOT NULL     -- "info" | "warning" | "critical"
read_at      TIMESTAMP            -- NULL = chưa đọc
triggered_at TIMESTAMP NOT NULL
created_at   TIMESTAMP

INDEX: (user_id, read_at)
```

---

## 7. API Endpoints

### Auth

| Method | Path | Mô tả |
|--------|------|-------|
| POST | `/auth/register` | Tạo tài khoản |
| POST | `/auth/login` | Lấy JWT token |

### Events

```
POST /api/v1/events
Authorization: Bearer <token>

Body:
{
  "type": "coding_session",
  "timestamp": 1710000000,
  "payload": { "duration": 120, "language": "ruby" }
}

Response 201:
{
  "id": "uuid",
  "status": "queued"
}
```

### Stats

```
GET /api/v1/stats
Authorization: Bearer <token>
Query: from=2026-04-23&to=2026-04-30&type=coding

Response 200:
{
  "from": "2026-04-23",
  "to": "2026-04-30",
  "data": [
    {
      "date": "2026-04-30",
      "total_coding_time": 240,
      "total_gym_time": 60,
      "total_run_distance": 5.2,
      "sleep_duration": 7.5
    }
  ]
}
```

### Alerts

| Method | Path | Mô tả |
|--------|------|-------|
| GET | `/api/v1/alerts` | Danh sách alert chưa đọc |
| PATCH | `/api/v1/alerts/:id/read` | Đánh dấu đã đọc |

---

## 8. Alert System

### Rules

| Rule Key | Điều kiện | Severity |
|----------|-----------|----------|
| `no_coding_2_days` | Không code 2 ngày liên tiếp | warning |
| `no_coding_5_days` | Không code 5 ngày | critical |
| `short_sleep` | `sleep_duration` < 6h | warning |
| `no_gym_7_days` | Không gym/run 7 ngày | warning |
| `streak_coding_7_days` | Code đủ 7 ngày liên tiếp | info |

### Alert Processor Flow

```
Consumer nhận event
  → Query lịch sử 7 ngày của user
  → Chạy từng rule
  → Nếu trigger AND chưa có alert unread cùng rule_key
      → INSERT alerts
      → Broadcast qua WebSocket "user_#{user_id}"
```

---

## 9. WebSocket — ActionCable

### Channel

```ruby
# app/channels/user_channel.rb
class UserChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_#{current_user.id}"
  end
end
```

### Auth Connection

```ruby
# app/channels/application_cable/connection.rb
def find_verified_user
  token = request.params[:token]
  decoded = JwtService.decode(token)
  User.find(decoded["sub"])
rescue
  reject_unauthorized_connection
end
```

Client connect: `wss://<host>/cable?token=<jwt>`

### Broadcast Payload

```json
// new_event
{ "type": "new_event", "event_type": "coding_session", "timestamp": 1710000000, "stats": {} }

// alert
{ "type": "alert", "rule_key": "no_coding_2_days", "message": "...", "severity": "warning" }
```

---

## 10. Tech Stack

| Layer | Tech |
|-------|------|
| Framework | Ruby on Rails 7 (API mode) |
| Database | PostgreSQL 15 |
| Kafka Client | `karafka` gem |
| Auth | `jwt` gem |
| Realtime | ActionCable (built-in) |
| Container | Docker + Docker Compose |
| Testing | RSpec + FactoryBot |

### Docker Compose Services

```yaml
services:
  api:        # Rails
  postgres:   # PostgreSQL 15
  kafka:      # confluentinc/cp-kafka
  zookeeper:  # confluentinc/cp-zookeeper
```

---

## 11. Development Plan

### Week 1 — Foundation

- [ ] Rails new (API mode) + PostgreSQL setup
- [ ] `users` migration + Auth (register/login + JWT)
- [ ] `events` migration + `POST /api/v1/events` + validation
- [ ] Docker Compose: Rails + PostgreSQL + Kafka + Zookeeper
- [ ] Karafka setup + `event_persistence` consumer

### Week 2 — Stats & Realtime

- [ ] `stats` migration
- [ ] `stats_processor` consumer
- [ ] `GET /api/v1/stats` với query params
- [ ] ActionCable setup + `UserChannel`
- [ ] `realtime_processor` consumer → broadcast

### Week 3 — Alert & Polish

- [ ] `alerts` migration
- [ ] `alert_processor` consumer + rule engine
- [ ] `GET /api/v1/alerts` + `PATCH /alerts/:id/read`
- [ ] Alert broadcast qua WebSocket
- [ ] Error handling + logging
- [ ] README + local setup guide

---

## 12. Non-Goals

- ❌ OAuth / SSO
- ❌ Email notification
- ❌ Dynamic alert rules
- ❌ Kafka multi-cluster
- ❌ Microservices

---

*PRD v1.0 — pps-api*
