# Wordpress

## Docker Compose service
```yaml
# Wordpress Service
  wordpress:
    build:
      context: ./src/website
      target: development
    image: {TEMPLATE_COMMAND}/wordpress
    restart: unless-stopped
    working_dir: /var/www
    environment:
      WORDPRESS_DB_HOST: mysql:3306
      WORDPRESS_DB_USER: root
      WORDPRESS_DB_PASSWORD: root
      WORDPRESS_DB_NAME: {TEMPLATE_DATABASE}
    volumes:
      - ./src/website/src:/var/www # Added to make sure all the wordpress files are available when the init process is executed otherwise, WP-CLI won't work.
      - ./.docker/wordpress/init.sh:/opt/files/init.sh
    depends_on:
      - mysql
```

## Dockerfile
```Dockerfile
#######################################
# Base stage
#######################################
FROM wordpress:5.5.1-php7.4-fpm-alpine as base

# Install packages
RUN apk update && apk --no-cache add curl \
    # PHP libraries
    php7-pdo_mysql

# Install extensions
RUN docker-php-ext-install bcmath pdo_mysql

# Install and configure WP CLI (https://wp-cli.org/)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp && wp --info

# Setup working directory
#RUN chown -R root:root /var/www/html && rm -rf /var/www/html/*
WORKDIR /var/www

#######################################
# Development stage
#######################################
FROM base as development

# Install some extra packages
RUN apk --no-cache add bash mysql-client ca-certificates

```

## Bash initialization: `init.sh`

Replace `{TEMPLATE_DOMAIN}` below.

```bash
#!/bin/bash
set -e

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

# Install wordpress
echo 'Configure Wordpress core data and admin user'
wp core install --url=wordpress.{TEMPLATE_DOMAIN} --title=Cocoapp --admin_user=admin --admin_password=password --admin_email=admin@cocoapp.test --allow-root --skip-email

# Activate enfold-appwapp theme
wp theme activate enfold-appwapp --allow-root

# Activate all plugins
wp plugin activate --all --allow-root

```