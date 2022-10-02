# Postgres Database

Replace `{TEMPLATE_DATABASE}` below.

## Docker Compose service
```yaml
  postgres:
    image: postgres:14
    restart: always
    ports:
      - 5432:5432
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: {TEMPLATE_DATABASE}
    volumes:
      - postgresdata:/var/lib/postgresql/data:delegated
```
