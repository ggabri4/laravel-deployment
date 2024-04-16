FROM php:8.2-apache

# Define environment variables
ENV APACHE_SERVER_NAME=localhost
ENV APP_ENV=dev

# Install PHP extensions required for Laravel
RUN apt-get update && \
    apt-get install -y \
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
    && docker-php-ext-install -j$(nproc) gd pdo pdo_mysql mbstring exif pcntl bcmath xml

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs build-essential 

# Copy necessary scripts and perform initial configuration
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && \
    a2enmod rewrite && \
    sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf && \
    echo "ServerName $APACHE_SERVER_NAME" >> /etc/apache2/apache2.conf

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Define working directory and permissions
WORKDIR /var/www/html
RUN chown -R www-data:www-data /var/www/html

# Install Composer and npm dependencies
COPY composer.json composer.lock package.json ./
RUN composer install --no-scripts --no-autoloader --no-dev && \
    npm install

# Copy the rest of the application code
COPY . /var/www/html

# Finalize setup by optimizing autoloader and setting permissions
RUN composer dump-autoload --optimize && \
    composer run-script post-root-package-install && \
    composer run-script post-create-project-cmd && \
    find /var/www/html -type d -exec chmod 755 {} \; && \
    find /var/www/html -type f -exec chmod 644 {} \; && \
    chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose ports for web traffic and Vite
EXPOSE 80 5173

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
