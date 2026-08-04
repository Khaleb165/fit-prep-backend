# fit_prep_backend

Dart Frog backend for FitPrep.

## Phase 1

Implemented from the authentication architecture plan:

- User model
- Register endpoint
- Login endpoint
- JWT authentication middleware
- Password hashing with bcrypt

## Run Locally

```sh
dart_frog dev
```

Set a real JWT secret outside local development:

```sh
JWT_SECRET="replace-with-a-long-random-secret" dart_frog dev
```

For persistent users and plans, configure PostgreSQL and apply the schema:

```sh
cp .env.example .env
dart run bin/migrate.dart
```

In a deployed environment, set `DATABASE_URL`. Set
`DATABASE_AUTO_MIGRATE=true` if the server should apply the idempotent schema
on startup; the Docker image includes the schema file for this purpose.

## Endpoints

### `GET /`

Health/status endpoint.

### `POST /auth/register`

Body:

```json
{
  "username": "user",
  "email": "user@example.com",
  "password": "secret1",
  "name": "John Doe",
  "timezone": "Africa/Accra"
}
```

### `POST /auth/login`

Body:

```json
{
  "username": "user",
  "password": "secret1"
}
```

### `GET /auth/me`

Requires `Authorization: Bearer <token>`.


## Phase 2

Authenticated plan CRUD endpoints:

- `GET /plans`
- `POST /plans`
- `GET /plans/{id}`
- `PATCH /plans/{id}`
- `DELETE /plans/{id}`

All `/plans` endpoints require `Authorization: Bearer <token>`.

The plan request follows the Flutter creation flow:

```json
{
  "title": "Morning Workout Plan",
  "items": [{"id": "water", "title": "Water bottle", "is_checked": false}],
  "gym_session": "morning",
  "packing_time": "07:30",
  "reminder": "one_hour_before"
}
```

Plan responses also include `reminder_time`, derived from `packing_time` and
`reminder` (for this example, `06:30`). Times are recurring local wall times.
