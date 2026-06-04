<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index()
    {
        return response()->json(
            auth()->user()->favorites
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'city' => 'required|string|max:100'
        ]);

        $user = auth()->user();

        if ($user->favorites()->count() >= 3) {
            return response()->json([
                'message' => 'Maximum of 3 favorite cities allowed.'
            ], 422);
        }

        $exists = $user->favorites()
            ->where('city', $request->city)
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'City already exists in favorites.'
            ], 422);
        }

        $favorite = Favorite::create([
            'user_id' => $user->id,
            'city' => $request->city,
        ]);

        return response()->json([
            'message' => 'City added successfully',
            'favorite' => $favorite
        ]);
    }

    public function destroy($city)
    {
        auth()->user()
            ->favorites()
            ->where('city', $city)
            ->delete();

        return response()->json([
            'message' => 'City removed successfully'
        ]);
    }
}