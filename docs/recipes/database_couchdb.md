# CouchDB

## Docker Compose service

Replace `{TEMPLATE_DATABASE}` below.

```yaml
  # CouchDB Service
  couchdb:
    image: couchdb:3
    ports:
      - 5984:5984
      - 6984:6984
    environment:
      COUCHDB_USER: admin
      COUCHDB_PASSWORD: admin
      NODENAME: {TEMPLATE_DATABASE}
    volumes:
      - couchdb_data:/opt/couchdb/data:delegated
      - ./.docker/certs:/etc/couchdb/certs:delegated
      - ./.docker/couchdb/local.d/{TEMPLATE_DATABASE}.ini:/opt/couchdb/etc/local.d/{TEMPLATE_DATABASE}.ini:delegated
```

## Ini configuration file

Replace `{TEMPLATE_DOMAIN}` below.

```ini
[couchdb]
single_node = true
uuid = 0d2a09bd390c3e13b2ef403ac298f8e8

[admins]
admin = -pbkdf2-aa4eb757da37ddef2c249696ed5617da96624535,cdddaa60a9a71920de3380cc48738940,10

[couch_httpd_auth]
secret = 84c6b778edfbb298e7494b1b9985ddfd

[httpd]
enable_cors = true

[ssl]
enable = true
cert_file = /etc/nginx/certs/{TEMPLATE_DOMAIN}.crt
key_file = /etc/nginx/certs/{TEMPLATE_DOMAIN}.key

[cors]
credentials = true
origins = http://localhost, https://localhost, http://client.{TEMPLATE_DOMAIN}, https://client.{TEMPLATE_DOMAIN}
methods = GET,POST,PUT,OPTIONS,DELETE
```