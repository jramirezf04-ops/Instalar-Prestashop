# Instalación de PrestaShop con LAMP y HTTPS en Vagrant

En esta práctica de **Implantación de Aplicaciones Web** he automatizado la instalación de **PrestaShop 8.1.7** sobre una pila **LAMP** (Apache, MySQL y PHP 8.1) usando **Vagrant** y **VirtualBox** en local, junto con **phpMyAdmin** y certificado HTTPS de **Let's Encrypt** mediante **DuckDNS**.

## Datos del entorno

| Componente | Especificación |
| :--- | :--- |
| **Sistema Operativo** | Ubuntu 22.04 LTS (`bento/ubuntu-22.04`) |
| **Recursos de la VM** | 2 CPUs · 2048 MB RAM · Hostname `JavierRamirezPrestashop` |
| **Redirección de puertos** | `8080 → 80` (HTTP) · `8443 → 443` (HTTPS) |
| **Pila LAMP** | Apache 2 · MySQL 8.0 · PHP 8.1 + extensiones requeridas |
| **Gestión de BD** | phpMyAdmin |
| **Dominio y SSL/TLS** | `javierramirez-iaw.duckdns.org` (apuntando a `127.0.0.1`) · Certbot (desafío DNS-01) |
| **Aplicación** | PrestaShop 8.1.7 (instalación desatendida por CLI) |


## Estructura del repositorio

```text
Instalar-Prestashop/
├── README.md
├── Vagrantfile
├── conf/
│   └── 000-default.conf
├── images/
│   ├── administracion.png
│   ├── entrar_prestashop.png
│   ├── prestashop.png
│   └── tienda.png
└── scripts/
    ├── install_lamp.sh
    ├── setup_letsencrypt_https.sh
    └── deploy_prestashop.sh
```

> **Nota de seguridad:** El archivo `scripts/.env` con las credenciales reales no se incluye en el repositorio para proteger las contraseñas. Más abajo se detalla su estructura para reproducir el despliegue.


## Proceso de despliegue paso a paso

### 1. Aprovisionamiento de la máquina virtual

El archivo `Vagrantfile` define una máquina virtual Ubuntu 22.04 LTS con VirtualBox y redirección de los puertos `80` y `443` del invitado a los puertos `8080` y `8443` del equipo anfitrión.

```powershell
vagrant up
vagrant ssh
```

La carpeta del proyecto queda sincronizada automáticamente en `/vagrant` dentro de la máquina virtual.


### 2. Instalación de la pila LAMP y phpMyAdmin

El script `scripts/install_lamp.sh` automatiza:
- Actualización de repositorios e instalación de **Apache**, **MySQL Server** y **PHP 8.1**.
- Instalación de las extensiones requeridas y recomendadas por PrestaShop (`php-mysql`, `php-curl`, `php-gd`, `php-intl`, `php-mbstring`, `php-xml`, `php-zip`, `php-bcmath`, `php-imagick`, `php-soap`).
- Instalación desatendida de **phpMyAdmin**.
- Ajuste de directivas en `/etc/php/8.1/apache2/php.ini` y `/etc/php/8.1/cli/php.ini`:
  - `memory_limit = 256M`
  - `max_input_vars = 5000`
  - `post_max_size = 128M`
  - `upload_max_filesize = 128M`
- Despliegue del VirtualHost `conf/000-default.conf` con `AllowOverride All` y habilitación de los módulos `mod_rewrite` y `mod_headers`.

```bash
sudo bash /vagrant/scripts/install_lamp.sh
```

#### Verificación de requisitos (`phppsinfo.php`) y phpMyAdmin

Para comprobar que el entorno cumple todos los requisitos de PrestaShop antes del despliegue, se descargó `phppsinfo.php` en `/var/www/html`:

```bash
sudo wget -q https://raw.githubusercontent.com/PrestaShop/php-ps-info/master/phppsinfo.php -O /var/www/html/phppsinfo.php
sudo chown www-data:www-data /var/www/html/phppsinfo.php
```

- **Comprobación de requisitos:** `http://localhost:8080/phppsinfo.php` (usuario y contraseña por defecto: `prestashop`).
- **Acceso a phpMyAdmin:** `http://localhost:8080/phpmyadmin/`.

### 3. Variables de entorno (`scripts/.env`)

Antes de ejecutar los scripts de HTTPS y despliegue de la tienda, se crea el archivo `/vagrant/scripts/.env` con las variables de configuración:

```bash
DOMAIN="javierramirez-iaw.duckdns.org"
CERTBOT_EMAIL="tu_correo@ejemplo.com"

DB_NAME="prestashop"
DB_USER="ps_user"
DB_PASS="CAMBIAR_PASSWORD"

PS_SHOP_NAME="Tienda Javier Ramirez"
PS_COUNTRY="es"
PS_LANGUAGE="es"
PS_ADMIN_FIRSTNAME="Javier"
PS_ADMIN_LASTNAME="Ramirez"
PS_ADMIN_EMAIL="admin@javierramirez-iaw.duckdns.org"
PS_ADMIN_PASS="CAMBIAR_PASSWORD"
```


### 4. Configuración de HTTPS con Let's Encrypt (DNS-01)

Al trabajar en un entorno local con Vagrant (sin IP pública expuesta en el puerto 80), el script `scripts/setup_letsencrypt_https.sh` solicita el certificado SSL/TLS de Let's Encrypt mediante el desafío **DNS-01** utilizando un subdominio de **DuckDNS** apuntando a `127.0.0.1`:

```bash
sudo bash /vagrant/scripts/setup_letsencrypt_https.sh
```

Durante la ejecución:
1. Certbot genera un registro `TXT` temporal para `_acme-challenge.javierramirez-iaw.duckdns.org`.
2. Se actualiza el registro `TXT` a través de la API de DuckDNS y se verifica su propagación.
3. Tras emitirse el certificado, el script habilita el módulo `ssl`, genera `/etc/apache2/sites-available/000-default-ssl.conf`, activa el sitio HTTPS y reinicia Apache.


### 5. Despliegue automatizado de PrestaShop por CLI

El script `scripts/deploy_prestashop.sh` realiza el despliegue completo sin intervención manual:
1. Crea la base de datos y el usuario específico en MySQL con las variables de `scripts/.env`.
2. Limpia `/var/www/html`, descarga **PrestaShop 8.1.7** y descomprime los archivos con propietario `www-data`.
3. Ejecuta el instalador CLI (`install/index_cli.php`) configurando el dominio con el puerto mapeado (`javierramirez-iaw.duckdns.org:8443`) y `--ssl=1`.
4. Aplica medidas de seguridad post-instalación: elimina el directorio `/var/www/html/install` y renombra `/var/www/html/admin` a `/var/www/html/admin_ps`.
5. Limpia los archivos temporales y reinicia Apache.

```bash
sudo bash /vagrant/scripts/deploy_prestashop.sh
```


## Verificación final

Tras completar todos los scripts, tanto la tienda pública como el panel de administración quedan accesibles bajo HTTPS con certificado válido:

- **Front-Office (Tienda):** `https://javierramirez-iaw.duckdns.org:8443/`
- **Back-Office (Administración):** `https://javierramirez-iaw.duckdns.org:8443/admin_ps/`

![Verificación del entorno PrestaShop](images/prestashop.png)

![Front-Office de la tienda con HTTPS](images/tienda.png)

![Inicio de sesión del panel de administración](images/entrar_prestashop.png)

![Panel de administración (Back-Office) de PrestaShop](images/administracion.png)
