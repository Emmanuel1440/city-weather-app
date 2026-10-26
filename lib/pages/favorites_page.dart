import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with WidgetsBindingObserver {
  List<Map<String, dynamic>> favoriteCities = [];
  bool isLoading = true;
  String? token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fetchFavorites();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      fetchFavorites();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchFavorites(); // Auto-refetches whenever the page gains focus or is visited
  }

  Future<void> fetchFavorites() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/favorites"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List rawFavorites = jsonDecode(res.body);
        List<Map<String, dynamic>> fetchedList = [];

        for (var fav in rawFavorites) {
          final cityName = fav['city'] ?? 'Unknown';
          final favId = fav['id'];

          final wRes = await http.get(
            Uri.parse("$baseUrl/weather/$cityName"),
            headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
          );

          if (wRes.statusCode == 200) {
            final wData = jsonDecode(wRes.body);
            fetchedList.add({'id': favId, 'city': cityName, 'weather': wData});
          } else {
            fetchedList.add({'id': favId, 'city': cityName, 'weather': null});
          }
        }

        if (mounted) {
          setState(() {
            favoriteCities = fetchedList;
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

Future<void> removeFavorite(dynamic id, String city) async {
    if (token == null) return;

    try {
      // Pass the city name to match your Laravel route /favorites/{city}
      final res = await http.delete(
        Uri.parse("$baseUrl/favorites/${Uri.encodeComponent(city)}"),
        headers: {
          "Authorization": "Bearer $token", 
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        setState(() {
          favoriteCities.removeWhere((item) => item['city'].toString().toLowerCase() == city.toLowerCase());
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Removed $city from favorites"),
              backgroundColor: Colors.blue.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete: ${res.body}"),
              backgroundColor: Colors.orange.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Favorite Locations", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchFavorites,
            tooltip: "Refresh Favorites",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchFavorites,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : favoriteCities.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.blue.shade200),
                            const SizedBox(height: 12),
                            const Text(
                              "No favorite cities saved yet!",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 6),
                            const Text("Tap the heart icon on any searched city to save it here.", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 380,
                            mainAxisExtent: 160,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: favoriteCities.length,
                          itemBuilder: (context, index) {
                            final item = favoriteCities[index];
                            final city = item['city'];
                            final weather = item['weather'];
                            final temp = weather != null ? "${weather['temperature']}°C" : "--";
                            final condition = weather != null ? weather['condition'] : "Saved Location";

                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.indigo.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              city.toString().toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              condition.toString(),
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.white70),
                                          onPressed: () => removeFavorite(item['id'], city),
                                          tooltip: "Remove Favorite",
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          temp,
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amberAccent,
                                          ),
                                        ),
                                        const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 24),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}