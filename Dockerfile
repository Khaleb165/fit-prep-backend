FROM dart:stable AS build

WORKDIR /app

ENV PATH="/root/.pub-cache/bin:${PATH}"

RUN dart pub global activate dart_frog_cli

COPY pubspec.* ./
RUN dart pub get

COPY . .

RUN dart_frog build

WORKDIR /app/build

RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM dart:stable

WORKDIR /app

COPY --from=build /app/build/bin/server /app/bin/server
COPY --from=build /app/build/public /app/public
COPY --from=build /app/database /app/database

EXPOSE 8080

CMD ["/app/bin/server"]
