#!/bin/sh
set -e

# Deal with the .env file if necessary
if [ ! -f /var/www/.env ]; then
    echo "Populating .env file..."

    # Create .env file with minimum content
    cat > /var/www/.env << EOF
APP_KEY=base64:TNNry7MIHEHuiSECGoRdM2Uw+1jpvAoplFvnyRw43rw=
APP_ENV=local
APP_NAME=AIBQ
APP_URL=https://api.itbookmarks.test
APP_DEBUG=true

CLIENT_URL=https://client.itbookmarks.test
LOG_CHANNEL=single

FILESYSTEM_DRIVER=public
BROADCAST_DRIVER=log
CACHE_DRIVER=file
QUEUE_CONNECTION=database

SESSION_DRIVER=file
SESSION_LIFETIME=120

DB_CONNECTION=itbookmarks
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=itbookmarksdb
DB_USERNAME=root
DB_PASSWORD=root

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_FROM_ADDRESS=fahmiderbali@gmail.com
MAIL_FROM_NAME="ITbookmarks Local"
MAIL_ENCRYPTION=

CORS_AUTHORIZED_DOMAIN=*.itbookmarks.test

SANCTUM_STATEFUL_DOMAINS=client.itbookmarks.test
SESSION_DOMAIN=.itbookmarks.test
EOF
fi

# Deal with the .env.testing file if necessary
if [ ! -f /var/www/.env.testing ]; then
    echo "Populating .env.testing file..."

    cp /var/www/.env /var/www/.env.testing
    sed -i 's/APP_ENV=local/APP_ENV=testing/' /var/www/.env.testing
    sed -i 's/TELESCOPE_ENABLED=true/TELESCOPE_ENABLED=false/' /var/www/.env.testing
fi

# Install Composer dependencies
echo 'Installing Composer dependencies...'
composer install -d /var/www

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
php /var/www/artisan migrate --seed

# Create the roles
php /var/www/artisan role:create --name=admin
php /var/www/artisan role:create --name=member

# Create the symbolic link
php /var/www/artisan storage:link
