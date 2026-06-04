<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\WeatherController;
Route::prefix('auth')->group(function () {

    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    
});

Route::middleware('auth:api')->group(function () {
    
    Route::get('/favorites', [FavoriteController::class, 'index']);

    Route::post('/favorites', [FavoriteController::class, 'store']);

    Route::delete('/favorites/{city}', [FavoriteController::class, 'destroy']);
    Route::get('/weather/{city}', [WeatherController::class, 'current']);
    Route::get('/forecast/{city}', [WeatherController::class, 'forecast']);
});