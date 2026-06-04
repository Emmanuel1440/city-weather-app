<?php

namespace Tests\Feature;

use Tests\TestCase;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

class FavoriteTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_add_favorite()
    {
        $user = User::create([
            'name' => 'Test',
            'email' => 'fav@example.com',
            'password' => Hash::make('password123'),
        ]);

        $token = auth()->login($user);

        $response = $this->withHeaders([
            'Authorization' => "Bearer $token"
        ])->postJson('/api/favorites', [
            'city' => 'Nairobi'
        ]);

        $response->assertStatus(200);
    }
}