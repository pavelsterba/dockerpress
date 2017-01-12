#!/bin/sh

# Start nginx, FastCGI and MariaDB
service nginx start
service php7.0-fpm start
service mysql start

# Wordpress configuration is done only if config file doesn't exist
if [ ! -f /var/www/wp-config.php ]; then
    # Download latest Wordpress
    curl -o /tmp/wp.tar.gz https://wordpress.org/latest.tar.gz

    # Un-tar it
    tar xf /tmp/wp.tar.gz -C /var/www/ --strip-components=1

    # Generate passwords for database and Wordpress
    MYSQL_PASSWORD=`pwgen -c -n -1 15`
    WORDPRESS_PASSWORD=`pwgen -c -n -1 15`

    # Set MySQL root password
    mysqladmin -u root password $MYSQL_PASSWORD

    # Create user and database for Wordpress
    WORDPRESS_DB="wordpress"
    WORDPRESS_USER="wordpress"
    mysql -u root -p$MYSQL_PASSWORD -e "CREATE USER $WORDPRESS_USER@localhost IDENTIFIED BY '$WORDPRESS_PASSWORD';"
    mysql -u root -p$MYSQL_PASSWORD -e "CREATE DATABASE $WORDPRESS_DB;"
    mysql -u root -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON $WORDPRESS_DB.* TO $WORDPRESS_USER@localhost IDENTIFIED BY '$WORDPRESS_PASSWORD';"
    mysql -u root -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

    echo "MySQL root password:   $MYSQL_PASSWORD"
    echo "Wordpress user:        $WORDPRESS_USER"
    echo "Wordpress password:    $WORDPRESS_PASSWORD"
    echo "Wordpress database:    $WORDPRESS_DB"

    # Edit config file
    sed -e "s/database_name_here/$WORDPRESS_DB/
    s/username_here/$WORDPRESS_USER/
    s/password_here/$WORDPRESS_PASSWORD/
    /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
    /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /var/www/wp-config-sample.php > /var/www/wp-config.php

    # Configure permissions for Wordpress
    chown -R www-data:www-data /var/www/
    find /var/www/ -type d -exec chmod 755 {} \;
    find /var/www/ -type f -exec chmod 644 {} \;

    # Enable direct access to files
    echo "define('FS_METHOD', 'direct');" >> /var/www/wp-config.php
fi

echo "Checking nginx, PHP and MySQL status:"
DOCKERPRESS_UP_AND_RUNNING=1

# Get nginx status
service nginx status > /dev/null 2>&1
DOCKERPRESS_NGINX_STATUS=$?
if [ $DOCKERPRESS_NGINX_STATUS -eq 0 ]; then
    echo "    [ ok ] nginx is running"
else
    echo "    [FAIL] nginx is not running"
    DOCKERPRESS_UP_AND_RUNNING=0
fi

# Get PHP7 status
service php7.0-fpm status > /dev/null 2>&1
DOCKERPRESS_PHP_STATUS=$?
if [ $DOCKERPRESS_PHP_STATUS -eq 0 ]; then
    echo "    [ ok ] php is running"
else
    echo "    [FAIL] php is not running"
    DOCKERPRESS_UP_AND_RUNNING=0
fi

# Get MySQL status
service mysql status > /dev/null 2>&1
DOCKERPRESS_MYSQL_STATUS=$?
if [ $DOCKERPRESS_MYSQL_STATUS -eq 0 ]; then
    echo "    [ ok ] mysql is running"
else
    echo "    [FAIL] mysql is not running"
    DOCKERPRESS_UP_AND_RUNNING=0
fi

if [ $DOCKERPRESS_UP_AND_RUNNING -eq 1 ]; then
    echo "Wordpress is ready to go!"
    tail -f /var/log/nginx/access.log
else
    echo "Not all services are running, try to restart or recreate your container."
    echo "If the problem remains, please report it here:"
    echo "    https://github.com/pavelsterba/dockerpress/issues"
fi
