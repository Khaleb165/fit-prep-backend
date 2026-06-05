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
  "username": "caleb",
  "email": "caleb@example.com",
  "password": "secret1",
  "name": "Caleb",
  "timezone": "Africa/Accra"
}
```

### `POST /auth/login`

Body:

```json
{
  "username": "caleb",
  "password": "secret1"
}
```

### `GET /auth/me`

Requires `Authorization: Bearer <token>`.
