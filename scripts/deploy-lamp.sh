#!/bin/bash

# ==============================================================================
# SCRIPT: auto_wp_lamp.sh
# DESCRIPTION: Automated LAMP + WordPress + SSL Installation
# ==============================================================================

# --- Variables & User Input ---
read -p "Enter your Domain (e.g., example.com): " DOMAIN
DB_NAME="wp_$(echo $DOMAIN | sed 's/\./_/g')"
DB_USER="wp_admin"
DB_PASS=$(openssl rand -base64 12) # Generate a secure random password
EMAIL="admin@$DOMAIN"

# --- Colors for Output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- Functions ---

lamp_install() {
    echo -e "${GREEN}[+] Installing LAMP Stack & Firewall...${NC}"
    apt update && apt upgrade -y

    # Firewall setup
    apt install ufw -y
    ufw allow OpenSSH
    ufw allow 'Apache Full'
    ufw --force enable

    # Install Stack
    apt install apache2 mariadb-server php libapache2-mod-php php-mysql \
    php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y

    # Enable Apache Modules
    a2enmod rewrite ssl headers
    systemctl restart apache2
    }

apache_virtualhost_setup() {
    echo -e "${GREEN}[+] Setting up Apache Virtual Host...${NC}"
    WEB_ROOT="/var/www/$DOMAIN"
    mkdir -p $WEB_ROOT
    chown -R www-data:www-data $WEB_ROOT
    chmod -R 755 $WEB_ROOT

    # Create VirtualHost file
    cat > /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $WEB_ROOT
    <Directory $WEB_ROOT>
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

    a2ensite $DOMAIN.conf
    a2dissite 000-default.conf
    systemctl restart apache2
}

ssl_config() {
    echo -e "${GREEN}[+] Configuring Self-Signed SSL...${NC}"
    # Generate Self-Signed Cert (For production, use Certbot/Let's Encrypt instead)
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=NG/ST=Lagos/L=Lagos/O=IT/CN=$DOMAIN"
    # Configure SSL Params
    cat > /etc/apache2/conf-available/ssl-params.conf <<EOF
SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLHonorCipherOrder On
EOF

    # Update VirtualHost with SSL
    cat >> /etc/apache2/sites-available/$DOMAIN.conf <<EOF
<VirtualHost *:443>
    ServerName $DOMAIN
    DocumentRoot $WEB_ROOT
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key
    <Directory $WEB_ROOT>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF

    a2enconf ssl-params
    systemctl reload apache2
}

db_setup() {
    echo -e "${GREEN}[+] Configuring MariaDB Database...${NC}"
    mysql -u root <<EOF
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
FLUSH PRIVILEGES;
EOF
}

wordpress_config() {
    echo -e "${GREEN}[+] Downloading and Configuring WordPress...${NC}"
    cd /tmp
      curl -O https://wordpress.org/latest.tar.gz
    tar xzvf latest.tar.gz
    cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php

    # Configure wp-config.php using sed
    sed -i "s/database_name_here/$DB_NAME/" /tmp/wordpress/wp-config.php
    sed -i "s/username_here/$DB_USER/" /tmp/wordpress/wp-config.php
    sed -i "s/password_here/$DB_PASS/" /tmp/wordpress/wp-config.php

    cp -a /tmp/wordpress/. /var/www/$DOMAIN/
    chown -R www-data:www-data /var/www/$DOMAIN/
}

execute() {
    clear
    echo "Starting Deployment for $DOMAIN..."
    lamp_install
    apache_virtualhost_setup
    ssl_config
    db_setup
    wordpress_config

    echo -e "\n${GREEN}============================================${NC}"
    echo -e " DEPLOYMENT COMPLETE"
    echo -e " Domain: https://$DOMAIN"
    echo -e " DB Name: $DB_NAME"
    echo -e " DB User: $DB_USER"
    echo -e " DB Pass: $DB_PASS"
    echo -e "${GREEN}============================================${NC}"
}

# --- Trigger Execution ---
execute
