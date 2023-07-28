FROM debian:bookworm AS compiler
WORKDIR /app
RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    apt-get update && apt-get install -y --no-install-recommends make clang gcc postgresql-server-dev-15
COPY --link . .
RUN make

FROM postgres:bookworm
COPY --from=compiler /app/pgencrypt.so /usr/lib/postgresql/15/lib/
COPY --from=compiler /app/pgencrypt.control /app/pgencrypt--*.sql /usr/share/postgresql/15/extension/
RUN mkdir -p /docker-entrypoint-initdb.d
COPY ./initdb-pgencrypt.sh /docker-entrypoint-initdb.d/10_pgencrypt.sh
COPY ./update-pgencrypt.sh /usr/local/bin
