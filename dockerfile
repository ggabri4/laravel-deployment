# Utilise l'image officielle PHP avec Apache, adaptée à Laravel
FROM php:8.2-apache

ENV APACHE_SERVER_NAME=localhost
ENV APP_ENV=dev

# Copie le script entrypoint dans le conteneur
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Installe les extensions PHP nécessaires pour Laravel
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath xml

# Installer Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs \
    build-essential 

# Active le mod_rewrite pour Apache (utile pour les routes Laravel)
RUN a2enmod rewrite

RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf
RUN echo "ServerName $APACHE_SERVER_NAME" >> /etc/apache2/apache2.conf

# Installe Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN useradd -m node
USER node

# Définit le répertoire de travail pour les commandes suivantes
WORKDIR /var/www/html

COPY package.json ./
RUN npm install

# Copie le fichier de dépendances Composer et installe les dépendances
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --no-dev

# Copie le reste du code source de l'application
COPY . .

# Génère l'autoloader optimisé de Composer
RUN composer dump-autoload --optimize && composer run-script post-root-package-install && composer run-script post-create-project-cmd

# Change la propriété du dossier /var/www au www-data utilisateur et groupe
RUN chown -R www-data:www-data /var/www/html \
    && find /var/www/html -type d -exec chmod 755 {} \; \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose le port 80
EXPOSE 80 5173

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Lance Apache en arrière-plan
CMD ["apache2-foreground"]
