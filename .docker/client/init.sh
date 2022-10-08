#!/bin/sh

# Deal with the .env.local file if necessary
if [ ! -f /var/www/.env.local ]; then
    echo "Copying .env.example file to .env.local..."
    cp /var/www/.env.example /var/www/.env.local
fi

# Install client dependencies
echo 'Installing client dependencies...'
npm install --prefix /var/www
