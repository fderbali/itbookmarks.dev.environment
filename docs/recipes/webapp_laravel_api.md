# Laravel API

## Docker Compose service
```yaml
  api:
    build:
      context: ./src/api.webapp
      target: development
    image: cocoapp/api.webapp
    working_dir: /var/www
    volumes:
      - ./src/api.webapp/src:/var/www
      - ./.docker/nginx/certs:/usr/local/share/ca-certificates:ro
      - ./.docker/api/init.sh:/opt/files/init.sh
    depends_on:
      - mysql
      - redis
```

## Dockerfile
```Dockerfile
#######################################
# Base stage
#######################################
FROM php:7.4-fpm-alpine as base

# Opcache variables
# Disable file timestamps per default (faster file access)
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="192" \
    PHP_OPCACHE_MAX_WASTED_PERCENTAGE="10"

# Install packages
RUN apk update && apk --no-cache add curl \
    # PHP libraries
    php7-bcmath php7-ctype php7-curl php7-dom php7-fileinfo php7-gd php7-iconv php7-json \
    php7-mbstring php7-openssl php7-pdo php7-pdo_mysql php7-phar php7-session php7-simplexml \
    php7-tokenizer php7-xml php7-xmlreader php7-xmlwriter php7-xsl php7-zip \
    # Required by the xsl extension
    libxslt-dev libgcrypt-dev \
    # Required by the zip extension
    libzip-dev \
    # Required by the gd extension
    freetype-dev libjpeg-turbo-dev libpng-dev

# Install extensions
RUN docker-php-ext-install bcmath opcache pdo_mysql xsl zip

# Configure and install the gd extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Configure PHP-FPM
COPY .docker/php/opcache.ini $PHP_INI_DIR/conf.d/opcache.ini
COPY .docker/php/php.ini $PHP_INI_DIR/conf.d/zzz_custom.ini
COPY .docker/php/php-fpm.conf $PHP_INI_DIR/php-fpm.d/zzz.conf

# Setup working directory
RUN rm -rf /var/www/*
WORKDIR /var/www


#######################################
# Queue stage
#######################################
FROM base as queue

# Install supervisor
RUN apk --no-cache add supervisor

# Configure supervisor
COPY .docker/supervisor/worker.ini /etc/supervisor.d/cocoapp.ini

# Start process
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]


#######################################
# Composer stage
#######################################
FROM base as composer

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


#######################################
# CI stage
#######################################
FROM composer as CI

# Copy application files
COPY ./src .


#######################################
# Development stage
#######################################
FROM composer as development

# Enable opcache timestamps
# Allows to make changes in realtime (respect file timestamps)
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="1"

# Install some extra packages
RUN apk --no-cache add bash mysql-client ca-certificates


#######################################
# Build stage
#######################################
FROM composer as build

# Install project dependencies
COPY src/composer* ./
RUN composer install --no-scripts --no-autoloader --verbose --prefer-dist --no-progress --no-interaction --no-dev --no-suggest

# Copy application files
COPY ./src .

# Generate optimised autoload
RUN composer dump-autoload --optimize && composer clearcache


#######################################
# Production stage
#######################################
FROM base as production

# Install extra packages
RUN apk update && apk --no-cache add \
    # Required to build mysqlnd_azure
    autoconf build-base \
    # Required to run web server
    nginx supervisor

# Configure Nginx
COPY .docker/nginx/production.conf /etc/nginx/http.d/default.conf

# Configure Crontab
COPY .docker/nginx/production.crontab /etc/crontabs/production
RUN crontab /etc/crontabs/production
RUN rm /etc/crontabs/production

# Configure Supervisor
COPY .docker/supervisor/production.ini /etc/supervisor.d/cocoapp.ini

# Copy the SSL certificate
COPY .docker/azure/BaltimoreCyberTrustRoot.crt.pem /certs/BaltimoreCyberTrustRoot.crt.pem

# Use PHP's default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Make sure the "nginx" user can access the necessary folders
RUN mkdir -p /run/nginx \
  && chown -R nginx:nginx /run \
  && chown -R nginx:nginx /var/lib/nginx \
  && chown -R nginx:nginx /var/log/nginx

# Enable SSH for Azure
ENV SSH_PASSWD "root:Docker!"
RUN apk --no-cache add dialog openssh && echo "$SSH_PASSWD" | chpasswd
RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
RUN ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
RUN ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -N '' -t dsa
RUN ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -N '' -t dsa
COPY .docker/azure/sshd_config /etc/ssh/
EXPOSE 2222

# Configure mysqlnd_azure extension
COPY .docker/azure/mysqlnd_azure.ini $PHP_INI_DIR/conf.d/mysqlnd_azure.ini
RUN pecl install mysqlnd_azure

# Remove packages used to build
RUN apk del autoconf build-base

# Copy application files – "www-data" is the PHP-FPM processes' default Unix user/group
RUN chown -R www-data:www-data /var/www
COPY --from=build --chown=www-data /var/www .

# Copy htpasswd for staging environments documentation
COPY .docker/nginx/.htpasswd /var/www/.htpasswd

# Copy and make executable the initialisation script
COPY .docker/azure/init.sh /opt/files/init.sh
RUN chmod u+x /opt/files/init.sh

# Run it
RUN chmod +x /opt/files/init.sh
CMD /opt/files/init.sh
```

## Bash initialization: `init.sh`
```bash
#!/bin/bash
set -e

# Install Composer dependencies
echo 'Installing Composer dependencies...'
composer install -d /var/www

# Deal with the .env file if necessary
if [ ! -f /var/www/.env ]; then
    echo "Populating .env file..."

    # Create .env file with minimum content
    cat > /var/www/.env << EOF
APP_KEY=base64:TNNry7MIHEHuiSECGoRdM2Uw+1jpvAoplFvnyRw43rw=
APP_ENV=local
APP_NAME=api
APP_URL=https://api.cocoapp.test
APP_DEBUG=true
CLIENT_URL=https://client.cocoapp.test
LOG_CHANNEL=single
BROADCAST_DRIVER=log
CACHE_DRIVER=array
FILESYSTEM_CLOUD=azure
QUEUE_CONNECTION=redis
REDIS_HOST=redis
MAIL_DRIVER=log
DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE={TEMPLATE_DATABASE}
DB_USERNAME=api
DB_PASSWORD=api
EOF
fi

# Deal with the .env.testing file if necessary
if [ ! -f /var/www/.env.testing ]; then
    echo "Populating .env.testing file..."

    cp /var/www/.env /var/www/.env.testing
    sed -i 's/APP_ENV=local/APP_ENV=testing/' /var/www/.env.testing
    sed -i 's/TELESCOPE_ENABLED=true/TELESCOPE_ENABLED=false/' /var/www/.env.testing
fi

# Make sure the MySQL database is available
echo 'Waiting for MySQL to be available'
count=1
while [ $count -le 10 ] && ! mysql -uroot -proot -hmysql -P3306 -e 'exit' ; do
    sleep 5
    ((count++))
done
if [ "$count" -ge 10 ]; then
    echo >&2 'error: failed to connect to MySQL after 10 attempts'
    exit 1
fi
echo 'MySQL connection successful!'

# Database
echo 'Creating the database...'
php /var/www/artisan migrate

```

## Nginx configuration `api.conf`

Replace `{TEMPLATE_DOMAIN}` below.

```conf
# Regular Laravel server config, with TLS and proper domain name
server {
    listen      443 ssl http2;
    listen      [::]:443 ssl http2;
    server_name api.{TEMPLATE_DOMAIN};
    root        /var/www/api/public;

    ssl_certificate     /etc/nginx/certs/{TEMPLATE_DOMAIN}.crt;
    ssl_certificate_key /etc/nginx/certs/{TEMPLATE_DOMAIN}.key;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";

    client_max_body_size 5M;

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass  api:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME /var/www/public/$fastcgi_script_name;
        include       fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}

# Redirect to TLS server config
server {
    listen      80;
    listen      [::]:80;
    server_name api.{TEMPLATE_DOMAIN};
    return      301 https://$server_name$request_uri;
}
```