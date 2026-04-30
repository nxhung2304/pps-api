# Story: pps-api Implementation

This story breaks down the [Implementation Plan](plan.md) into PR-sized tasks.

## Phase 1: Auth & Simple Ingestion (Walking Skeleton)

### Task 1.1: User Model & JWT Service
- [ ] Implement `User` model with `has_secure_password` and email uniqueness.
- [ ] Create `JwtService` for encoding and decoding tokens.
- [ ] Add unit tests for `User` and `JwtService`.

### Task 1.2: Authentication Endpoints
- [ ] Implement `POST /auth/register` controller action.
- [ ] Implement `POST /auth/login` controller action returning a JWT.
- [ ] Add integration tests for registration and login flows.

### Task 1.3: Secure API Base & Event Model
- [ ] Create `authenticate_user!` before_action in `ApplicationController`.
- [ ] Implement `Event` model with validations for `type`, `timestamp`, and `payload` (JSONB).
- [ ] Add migration and unit tests for `Event`.

### Task 1.4: Event Ingestion API (Sync)
- [ ] Implement `POST /api/v1/events` with payload validation.
- [ ] Ensure the endpoint saves directly to the DB (for now) and returns 201.
- [ ] Add integration tests for authorized and unauthorized event posting.

---

## Phase 2: Kafka Event Pipeline

### Task 2.1: Docker & Kafka Infrastructure
- [ ] Add Kafka and Zookeeper services to `docker-compose.yml`.
- [ ] Verify connectivity and topic creation capability.

### Task 2.2: Karafka Integration & Producer
- [ ] Install and configure the `karafka` gem.
- [ ] Refactor `POST /api/v1/events` to publish to the `user.events` topic.
- [ ] Update API response to return `status: "queued"`.

### Task 2.3: Event Persistence Consumer
- [ ] Implement the `EventPersistenceConsumer` to save raw events from Kafka to PostgreSQL.
- [ ] Configure the consumer group and verify end-to-end async persistence.

---

## Phase 3: Stats Aggregation & Querying

### Task 3.1: Stats Model & Schema
- [ ] Create `Stat` model and migration with unique index on `(user_id, date)`.
- [ ] Add unit tests for stats calculations/upserts.

### Task 3.2: Stats Processor Consumer
- [ ] Implement `StatsProcessorConsumer` to increment daily metrics based on incoming events.
- [ ] Support `coding_session`, `gym_session`, `run_completed`, and `sleep_logged` types.

### Task 3.3: Stats Query API
- [ ] Implement `GET /api/v1/stats` with filters for `from`, `to`, and `type`.
- [ ] Add integration tests for various time range queries.

---

## Phase 4: Realtime Alerts & WebSocket

### Task 4.1: ActionCable JWT Authentication
- [ ] Configure `ApplicationCable::Connection` to authenticate via JWT query param.
- [ ] Implement `UserChannel` for scoped broadcasts.

### Task 4.2: Alerts Model & Basic Rule Engine
- [ ] Create `Alert` model and migration.
- [ ] Implement `AlertProcessorConsumer` with a basic rule (e.g., "no coding for 2 days").

### Task 4.3: Realtime Broadcasts & Alerts API
- [ ] Broadcast new alerts and stats updates via ActionCable.
- [ ] Implement `GET /api/v1/alerts` and `PATCH /api/v1/alerts/:id/read`.
- [ ] Add integration tests for the full alert lifecycle.

---

## Progress Tracking

- [ ] Phase 1: Auth & Simple Ingestion (Walking Skeleton)
- [ ] Phase 2: Kafka Event Pipeline
- [ ] Phase 3: Stats Aggregation & Querying
- [ ] Phase 4: Realtime Alerts & WebSocket

**Total Tasks**: 13
