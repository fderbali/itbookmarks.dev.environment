# VueJs Client

## Docker Compose service
```yaml
  client:
    build:
      context: ./src/client.webapp
      target: development
    image: cocoapp/client
    restart: unless-stopped
    ports:
      - 8080:8080
    working_dir: /var/www
    volumes:
      - ./src/client.webapp/src:/var/www:delegated
      - ./.docker/nginx/certs:/usr/local/share/ca-certificates:delegated,ro
      - ./.docker/client/init.sh:/opt/files/init.sh:delegated
      - ./.docker/client/vue.config.js:/var/www/vue.config.js
    depends_on:
      - api
```

## Dockerfile
```Dockerfile
#######################################
# Base stage
#######################################
FROM node:12.2.0-alpine as base

# Setup working directory
RUN rm -rf /var/www/*
WORKDIR /var/www


#######################################
# Development stage
#######################################
FROM base as development

# Install some extra packages
RUN apk update && apk --no-cache add ca-certificates

# Start development server
CMD [ "npm", "run", "serve" ]


#######################################
# Production stage
#######################################
FROM base as production

# Copy application files
COPY ./src .

# Add `/app/node_modules/.bin` to $PATH
ENV PATH ./node_modules/.bin:$PATH

RUN npm install
RUN npm install -g http-server

# Build the app for production in a minified way
RUN npm run build

# Start app for production
CMD [ "http-server", "dist" ]
```

## Bash initialization: `init.sh`
```bash
#!/bin/sh

# Deal with the .env.local file if necessary
if [ ! -f /var/www/.env.local ]; then
    echo "Copying .env.example file to .env.local..."
    cp /var/www/.env.example /var/www/.env.local
fi

# Install client dependencies
echo 'Installing client dependencies...'
npm install --prefix /var/www

```

## Nginx configuration `api.conf`

Replace `{TEMPLATE_DOMAIN}` below.

```conf
# VueJS config
server {
    listen      443 ssl http2;
    listen      [::]:443 ssl http2;
    server_name client.{TEMPLATE_DOMAIN};

    ssl_certificate     /etc/nginx/certs/{TEMPLATE_DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/certs/{TEMPLATE_DOMAIN}.key;

    location / {
        proxy_pass         http://client:8080;
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
    server_name client.{TEMPLATE_DOMAIN};
    return      301 https://$server_name$request_uri;
}
```

## VueJs config

Replace `{TEMPLATE_DOMAIN}` below.

```json
module.exports = {
    devServer: {
        disableHostCheck: true,
        sockHost:         'client.{TEMPLATE_DOMAIN}',
        public:           'https://client.{TEMPLATE_DOMAIN}/',
        watchOptions:     {
            ignored:          /node_modules/,
            aggregateTimeout: 300,
            poll:             1000
        }
    }
};
```

## Bashly

`bashly.yml`:
```yaml
  - name: client
    short: c
    help: Client-specific commands.
    group: Client
    examples:
      - boc client <command> [options] [arguments]
      - boc c <command> [options] [arguments]
    commands:
      - name: init
        short: i
        help: Run the client application's initialization script

      - name: npm
        help: Run a npm command on the client application
        catch_all: Any npm command, argument or flag
        completions:
          - install
          - update
          - audit fix
          - require
          - remove
```

`client_init_command.sh`:
```bash
##
# Initialize client
##
service_init client
```

`client_npm_command.sh`:
```bash
##
# NPM command on client service
##
service_npm client ${other_args[*]}
```