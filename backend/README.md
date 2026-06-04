# City Weather API

## Setup Instructions

### Install dependencies
composer install

### Setup environment
cp .env.example .env

Set:
OPENWEATHER_API_KEY=its in .env
DB_DATABASE=weather_app

### Generate app key
php artisan key:generate

### Run migrations
php artisan migrate

### Start server
php artisan serve