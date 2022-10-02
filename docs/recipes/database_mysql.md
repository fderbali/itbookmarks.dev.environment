# MySQL Database

## Docker Compose service
```yaml
  mysql:
    image: mysql:8
    ports:
      - 3306:3306
    environment:
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - mysqldata:/var/lib/mysql:delegated
      - ./.docker/mysql/my.cnf:/etc/mysql/conf.d/my.cnf:delegated
```

## MySQL configuration

```cnf
[mysqld]
default-authentication-plugin = mysql_native_password
collation-server              = utf8mb4_unicode_ci
character-set-server          = utf8mb4
```
