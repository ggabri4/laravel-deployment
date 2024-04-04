# Utilise l'image officielle PHP avec Apache, adaptée à Laravel
FROM php:8.2-apache

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

# Active le mod_rewrite pour Apache (utile pour les routes Laravel)
RUN a2enmod rewrite

# Installe Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Définit le répertoire de travail pour les commandes suivantes
WORKDIR /var/www/html

# Copie le fichier de dépendances Composer et installe les dépendances
# Remarque : Il est recommandé de copier seulement le fichier composer.json et composer.lock d'abord
# pour permettre la mise en cache des dépendances si ces fichiers ne changent pas.
COPY composer.json composer.lock ./
RUN composer install --no-scripts --no-autoloader --no-dev

# Copie le reste du code source de l'application
COPY . .

# Génère l'autoloader optimisé de Composer
RUN composer dump-autoload --optimize && composer run-script post-root-package-install && composer run-script post-create-project-cmd

# Change la propriété du dossier /var/www au www-data utilisateur et groupe
RUN chown -R www-data:www-data /var/www

# Expose le port 80
EXPOSE 80

# Lance Apache en arrière-plan
CMD ["apache2-foreground"]
