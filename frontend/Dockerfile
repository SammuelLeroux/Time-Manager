# Étape 1: Environnement de développement
FROM node:lts-alpine AS development

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste du code de l'application
COPY . .

# Exposer le port 3000 pour le développement (Vite)
EXPOSE 3000

# Commande pour démarrer Vite en mode développement (avec rechargement à chaud)
CMD ["npm", "run", "dev"]

# Étape 2: Environnement de build pour la production
FROM node:lts-alpine AS build

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances de production uniquement
RUN npm install

# Copier le reste de l'application
COPY . .

# Construire l'application pour la production
RUN npm run build

# Étape 3: Serveur Nginx pour la production
FROM nginx:stable-alpine AS production

# Copier les fichiers générés dans le dossier dist par Vite dans le répertoire Nginx par défaut
COPY --from=build /app/dist /usr/share/nginx/html

# Exposer le port 80 pour Nginx
EXPOSE 80

# Commande pour démarrer Nginx en production
CMD ["nginx", "-g", "daemon off;"]