# Despliegue automatizado de PrestaShop sobre pila LAMP con HTTPS (Vagrant + VirtualBox)

Práctica de **Implantación de Aplicaciones Web** centrada en la automatización completa del despliegue de **PrestaShop 8.1.7** sobre una pila **LAMP** (Linux, Apache, MySQL, PHP 8.1) en entorno local reproducible mediante **Vagrant** y **VirtualBox**, incluyendo **phpMyAdmin** y certificado SSL/TLS válido de **Let's Encrypt** con **DuckDNS**.


## Arquitectura y entorno

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
Instalar_Prestashop/
├── .gitignore
├── README.md
├── Vagrantfile
├── conf/
│   └── 000-default.conf
├── images/
│   ├── phppsinfo.png
│   ├── phpmyadmin.png
│   ├── prestashop-front.png
│   └── prestashop-back.png
└── scripts/
    ├── .env.example
    ├── install_lamp.sh
    ├── setup_letsencrypt_https.sh
    └── deploy_prestashop.sh
```

> **Nota de seguridad:** El archivo `scripts/.env` con las credenciales reales y el directorio `.vagrant/` están excluidos del control de versiones mediante `.gitignore`. Para reproducir la práctica, copia `scripts/.env.example` como `scripts/.env` y rellena tus valores.


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
sudo wget -q [https://raw.githubusercontent.com/PrestaShop/php-ps-info/master/phppsinfo.php](https://raw.githubusercontent.com/PrestaShop/php-ps-info/master/phppsinfo.php) -O /var/www/html/phppsinfo.php
sudo chown www-data:www-data /var/www/html/phppsinfo.php
```

- **Comprobación de requisitos:** `http://localhost:8080/phppsinfo.php` (usuario y contraseña por defecto: `prestashop`).
- **Acceso a phpMyAdmin:** `http://localhost:8080/phpmyadmin/`.

![Verificación de requisitos con phppsinfo](images/phppsinfo.png)

![Acceso a phpMyAdmin](images/phpmyadmin.png)
