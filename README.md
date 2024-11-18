
# Time Manager - Working Time Dashboard

## Description

**Time Manager** est une application web de gestion du temps de travail qui permet aux utilisateurs de suivre leurs heures de travail de vos salariés. Elle fournit un tableau de bord intuitif pour badger les heures de début et de fin de travail, avec un système de **comparaison graphique** entre les heures demandées et les heures effectuées.

Cette application est développée avec **Elixir Phoenix** pour la partie backend et **Vuetify 3** pour le frontend. L'application est entièrement dockerisée pour simplifier le déploiement.

## Features

- **Badging des heures de travail** : Suivi des heures d'entrée et de sortie via un système de clock-in/clock-out.
- **Tableau de bord intuitif** : Visualisation claire des horaires journaliers.
- **Graphiques comparatifs** : Comparaison des heures demandées vs heures réellement effectuées.
- **Gestion des utilisateurs** : Système d'authentification et gestion des rôles.
- **Dockerisé** : Simple à installer et à déployer grâce à Docker.

## Technologies utilisées

- **Backend** : [Elixir Phoenix](https://www.phoenixframework.org/)
- **Frontend** : [Vuetify 3](https://next.vuetifyjs.com/en/) (framework Vue.js)
- **Base de données** : [PostgreSQL](https://www.postgresql.org/)
- **Containerisation** : [Docker](https://www.docker.com/)

## Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

## Installation

### 1. Cloner le dépôt

git clone <https://github.com/EpitechMscProPromo2026/T-POO-700-STG_11.git>

cd time-manager

### 2. Configuration des variables d'environnement

Créez un fichier `.env` à la racine du projet et configurez les variables nécessaires (comme la configuration de la base de données, les clés API, etc.). Un exemple de fichier `.env` :

POSTGRES_USER=postgres

POSTGRES_PASSWORD=root

POSTGRES_DB=time_manager_dev

PGADMIN_DEFAULT_EMAIL=<admin@example.com>

PGADMIN_DEFAULT_PASSWORD=root

### 3. Démarrer l'application avec Docker

L'application est dockerisée, donc vous pouvez la lancer avec Docker Compose.

docker-compose up --build

Cela démarrera tous les services nécessaires (backend, frontend, base de données).

### 4. Migration de la base de données

Une fois les conteneurs lancés, exécutez les migrations de la base de données :

docker-compose exec app mix ecto.migrate

### 5. Accéder à l'application

L'application sera accessible à l'adresse suivante :

<http://localhost:3000>

## Utilisation

1. **Badging des heures** : Les utilisateurs peuvent se connecter et utiliser le tableau de bord pour badger leur temps d'arrivée et de départ.
2. **Visualisation des heures travaillées** : Le tableau de bord affiche les heures de travail complétées, avec des graphiques pour comparer les heures demandées et les heures réellement effectuées.

## Architecture

- **Phoenix** gère les routes, le contrôle des données et les requêtes API pour le frontend.
- **Vuetify 3** fournit les composants de l'interface utilisateur.
- **Docker** permet de simplifier le déploiement et la gestion de l'environnement.
- **PostgreSQL** (ou la base de données choisie) stocke les données des utilisateurs, les heures de travail et les paramètres de l'application.

## Contribuer

Les contributions sont les bienvenues ! Si vous souhaitez contribuer, veuillez suivre ces étapes :

1. Forker le dépôt
2. Créer une nouvelle branche (`git checkout -b feature/amélioration`)
3. Committer vos modifications (`git commit -m 'Ajout d'une nouvelle fonctionnalité'`)
4. Pusher sur la branche (`git push origin feature/amélioration`)
5. Créer une Pull Request

## Auteurs

- **Léo** - Développeur Frontend / Backend
- **Sammuel** - Développeur Backend / DevOps
- **Pierre** - Développeur Backend / DevOps
- **Muhammed** - Développeur Frontend

## License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus d'informations.
