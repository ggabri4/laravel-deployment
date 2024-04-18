# Build front-end assets
FROM node:20 as frontend
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Build Laravel application
FROM php:8.2-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    libonig-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install pdo_mysql mbstring

RUN a2enmod rewrite && \
    sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName gabhub.dev" >> /etc/apache2/apache2.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Define working directory
WORKDIR /var/www/html
COPY --from=frontend --chown=www-data:www-data /app .

# Install Composer dependencies
COPY composer.json composer.lock ./
RUN composer install --no-dev

# Copy the rest of the application code
COPY --from=frontend --chown=www-data:www-data /app .

# Finalize setup by running Composer scripts and setting permissions
RUN composer run-script post-root-package-install && \
    composer run-script post-create-project-cmd && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose ports for web traffic and Vite
EXPOSE 80 5173

# Copy start script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Start Apache and run migrations
CMD ["/usr/local/bin/start.sh", "apache2-foreground"]