#!/bin/bash

# Configurer le ServerName pour Apache
echo "ServerName ${APACHE_SERVER_NAME:-localhost}" >> /etc/apache2/apache2.conf

# Vérifier si nous sommes en environnement de développement
if [ "$APP_ENV" = "dev" ]; then
    # Démarrer Vite pour le développement de ressources
    echo "Starting Vite for development..."
    cd /var/www/html
    npm run dev &
fi

# Si nous sommes en environnement de production
if [ "$APP_ENV" = "prod" ]; then
    # Démarrer des tâches spécifiques à la production, si nécessaire
    echo "Running production-specific tasks..."
    # Par exemple, compiler les assets pour la production
    npm run build
fi

# Exécuter le serveur web Apache en foreground
exec apache2-foreground
