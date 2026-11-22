#!/bin/bash
set -ex

# Cargar variables de entorno
source /vagrant/scripts/.env

# 1. Instalar Certbot
apt update
apt install -y certbot

# 2. Solicitar certificado SSL mediante desafío DNS-01 (para entorno local)
certbot certonly --manual --preferred-challenges dns \
    --agree-tos --email "$CERTBOT_EMAIL" -d "$DOMAIN"

# 3. Habilitar módulo SSL en Apache
a2enmod ssl

# 4. Configurar VirtualHost HTTPS (puerto 443)
cat << VHOST > /etc/apache2/sites-available/000-default-ssl.conf
<VirtualHost *:443>
    ServerName ${DOMAIN}
    DocumentRoot /var/www/html

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
VHOST

# 5. Activar el sitio HTTPS y reiniciar Apache
a2ensite 000-default-ssl.conf
systemctl restart apache2
