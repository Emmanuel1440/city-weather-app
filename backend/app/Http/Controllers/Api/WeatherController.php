<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;

class WeatherController extends Controller
{
    public function current($city)
    {
        $response = Http::get(
            'https://api.openweathermap.org/data/2.5/weather',
            [
                'q' => $city,
                'appid' => env('OPENWEATHER_API_KEY'),
                'units' => 'metric',
            ]
        );

        if (!$response->successful()) {
            return response()->json([
                'message' => 'City not found'
            ], 404);
        }

        $data = $response->json();

        return response()->json([
            'city' => $data['name'],
            'temperature' => $data['main']['temp'],
            'condition' => $data['weather'][0]['main'],
            'humidity' => $data['main']['humidity'],
            'wind_speed' => $data['wind']['speed'],
        ]);
    }

    public function forecast($city)
    {
        $response = Http::get(
            'https://api.openweathermap.org/data/2.5/forecast',
            [
                'q' => $city,
                'appid' => env('OPENWEATHER_API_KEY'),
                'units' => 'metric',
            ]
        );

        if (!$response->successful()) {
            return response()->json([
                'message' => 'City not found'
            ], 404);
        }

        $forecast = collect($response->json()['list'])
            ->groupBy(function ($item) {
                return substr($item['dt_txt'], 0, 10);
            })
            ->take(5)
            ->map(function ($day) {
                return [
                    'date' => $day->first()['dt_txt'],
                    'high' => collect($day)->max('main.temp_max'),
                    'low' => collect($day)->min('main.temp_min'),
                    'condition' => $day->first()['weather'][0]['main'],
                ];
            })
            ->values();

        return response()->json($forecast);
    }
}