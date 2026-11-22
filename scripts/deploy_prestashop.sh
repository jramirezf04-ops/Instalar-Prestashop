#!/bin/bash
set -ex

# Cargar variables de entorno
source /vagrant/scripts/.env

# 1. Crear base de datos y usuario en MySQL
mysql -u root << MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# 2. Limpiar el directorio web (phpMyAdmin no se ve afectado)
rm -rf /var/www/html/*

# 3. Descargar y descomprimir PrestaShop 8.1.7 (compatible con PHP 8.1)
wget -q https://github.com/PrestaShop/PrestaShop/releases/download/8.1.7/prestashop_8.1.7.zip -O /tmp/prestashop_release.zip
mkdir -p /tmp/ps_extract
unzip -q /tmp/prestashop_release.zip -d /tmp/ps_extract
unzip -q /tmp/ps_extract/prestashop.zip -d /var/www/html

# 4. Ajustar permisos iniciales
chown -R www-data:www-data /var/www/html

# 5. Ejecutar el instalador CLI de PrestaShop (con HTTPS y puerto 8443 de Vagrant)
sudo -u www-data php /var/www/html/install/index_cli.php \
    --domain="${DOMAIN}:8443" \
    --db_server=localhost \
    --db_name="$DB_NAME" \
    --db_user="$DB_USER" \
    --db_password="$DB_PASS" \
    --name="$PS_SHOP_NAME" \
    --country="$PS_COUNTRY" \
    --language="$PS_LANGUAGE" \
    --firstname="$PS_ADMIN_FIRSTNAME" \
    --lastname="$PS_ADMIN_LASTNAME" \
    --email="$PS_ADMIN_EMAIL" \
    --password="$PS_ADMIN_PASS" \
    --ssl=1

# 6. Pasos de seguridad post-instalación: borrar carpeta install y renombrar admin
rm -rf /var/www/html/install
mv /var/www/html/admin /var/www/html/admin_ps

# 7. Limpiar archivos temporales y reiniciar Apache
rm -rf /tmp/prestashop_release.zip /tmp/ps_extract
chown -R www-data:www-data /var/www/html
systemctl restart apache2
