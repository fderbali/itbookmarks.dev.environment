# Mailhog

## Docker Compose service

Replace `{TEMPLATE_DOMAIN}` below.

```yaml
  # Mailhog Service
  mailhog:
    image: mailhog/mailhog:latest
    privileged: true
    user: root
    ports:
      - 1025:1025
      - 8025:8025
    environment:
      MH_HOSTNAME: mail.{TEMPLATE_DOMAIN}
      MH_MAILDIR_PATH: /maildir
      MH_STORAGE: maildir
    volumes:
      - maildata:/maildir:delegated

  #...

  # Volumes
volumes:

  maildata:
```

## Nginx configuration file

Replace `{TEMPLATE_DOMAIN}` below.

```conf
# Mailhog config
server {
    listen      443 ssl http2;
    listen      [::]:443 ssl http2;
    server_name mail.{TEMPLATE_DOMAIN};

    ssl_certificate     /etc/nginx/certs/{TEMPLATE_DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/certs/{TEMPLATE_DOMAIN}.key;

    location / {
        resolver 127.0.0.11 valid=30s;
        set $upstream mailhog;

        proxy_pass         http://$upstream:8025;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        proxy_set_header   Host $host;
    }
}

# Redirect to TLS server config
server {
    listen      80;
    listen      [::]:80;
    server_name mail.{TEMPLATE_DOMAIN};
    return      301 https://$server_name$request_uri;
}

```