<?php

namespace Tests\Feature;

use Tests\TestCase;

class WeatherTest extends TestCase
{
    public function test_weather_endpoint_requires_auth()
    {
        $response = $this->getJson('/api/weather/Nairobi');

        $response->assertStatus(401);
    }
}