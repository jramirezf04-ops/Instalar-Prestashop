#!/bin/bash
set -ex

# 1. Actualizar repositorios
apt update

# 2. Instalar Apache
apt install -y apache2

# 3. Instalar MySQL Server
apt install -y mysql-server

# 4. Instalar PHP y todas las extensiones requeridas/recomendadas por PrestaShop
apt install -y php libapache2-mod-php php-mysql \
    php-curl php-gd php-intl php-mbstring php-xml \
    php-zip php-bcmath php-imagick php-soap unzip wget curl

# 5. Instalar phpMyAdmin de forma desatendida
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin

# 6. Ajustar directivas de php.ini para PrestaShop (Apache y CLI)
for INI_FILE in /etc/php/8.1/apache2/php.ini /etc/php/8.1/cli/php.ini; do
    sed -i -E 's/^;?\s*memory_limit\s*=.*/memory_limit = 256M/' "$INI_FILE"
    sed -i -E 's/^;?\s*max_input_vars\s*=.*/max_input_vars = 5000/' "$INI_FILE"
    sed -i -E 's/^;?\s*post_max_size\s*=.*/post_max_size = 128M/' "$INI_FILE"
    sed -i -E 's/^;?\s*upload_max_filesize\s*=.*/upload_max_filesize = 128M/' "$INI_FILE"
done

# 7. Aplicar configuración de Apache y habilitar módulos recomendados
cp /vagrant/conf/000-default.conf /etc/apache2/sites-available/000-default.conf
a2enmod rewrite headers

# 8. Reiniciar Apache
systemctl restart apache2
