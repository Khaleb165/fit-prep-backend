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
