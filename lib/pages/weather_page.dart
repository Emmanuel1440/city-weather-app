import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../widgets/city_weather_card.dart';
import '../widgets/forecast_section.dart';
import '../widgets/interactive_map_section.dart';
import '../widgets/fun_fact_card.dart';

class WeatherHomePage extends StatefulWidget {
  final void Function(bool isDark) onThemeToggle;
  final ThemeMode themeMode;

  const WeatherHomePage({
    super.key,
    required this.onThemeToggle,
    required this.themeMode,
  });

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> defaultCitiesData = [];
  Map<String, dynamic>? searchedCityData;

  bool isLoading = false;
  String error = '';
  String? token;

  bool showForecast = false;
  bool showMap = false;

  final List<String> initialCities = ['Nairobi', 'Mombasa', 'Paris'];

  @override
  void initState() {
    super.initState();
    loadTokenAndDefaultCities();
  }

  Future<void> loadTokenAndDefaultCities() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");

    setState(() => isLoading = true);
    for (String city in initialCities) {
      await fetchWeatherSilently(city);
    }
    setState(() => isLoading = false);
  }

  Future<void> fetchWeatherSilently(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/$city'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        final forecastResponse = await http.get(
          Uri.parse('$baseUrl/forecast/$city'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          defaultCitiesData.removeWhere((c) => c['city'].toString().toLowerCase() == city.toLowerCase());
          defaultCitiesData.add({
            'city': weatherData['city'] ?? city,
            'weather': weatherData,
            'forecast': forecastData,
          });
        });
      }
    } catch (_) {}
  }

  Future<void> fetchWeather(String city) async {
    if (city.isEmpty) return;

    setState(() {
      isLoading = true;
      error = '';
      showForecast = false;
      showMap = false;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather/$city'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);

        final forecastResponse = await http.get(
          Uri.parse('$baseUrl/forecast/$city'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        final forecastData = json.decode(forecastResponse.body);

        setState(() {
          searchedCityData = {
            'city': weatherData['city'] ?? city,
            'weather': weatherData,
            'forecast': forecastData,
          };
          isLoading = false;
        });
        _controller.clear();
      } else {
        setState(() {
          error = "City not found";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Connection error: $e";
        isLoading = false;
      });
    }
  }

// ADD to FAVORITE METHOD WITH CLEAN TITLE-CASE FORMATTING
  Future<void> addFavorite(String city) async {
    if (token == null) return;

    // Normalize city name: Trim spaces and convert to Title Case (e.g., "webuye" -> "Webuye")
    final cleanedCity = city.trim().toLowerCase();
    final formattedCity = cleanedCity.isEmpty 
        ? city 
        : cleanedCity[0].toUpperCase() + cleanedCity.substring(1);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/favorites"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: jsonEncode({"city": formattedCity}),
      );

      String snackMessage = "";
      Color snackBgColor = Colors.blueAccent;

      if (res.statusCode == 200 || res.statusCode == 201) {
        snackMessage = "Added $formattedCity to favorites!";
        snackBgColor = Colors.blue.shade700;
      } else {
        try {
          final errorBody = jsonDecode(res.body);
          snackMessage = errorBody['message'] ?? errorBody['error'] ?? "Already in favorites!";
        } catch (_) {
          snackMessage = "Already in favorites or request failed.";
        }
        snackBgColor = Colors.orange.shade800;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackMessage),
            backgroundColor: snackBgColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void clearSearch() {
    setState(() {
      searchedCityData = null;
      showForecast = false;
      showMap = false;
      error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.blue.shade50.withOpacity(0.4),
      appBar: AppBar(
        title: const Text("Weather Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Icon(isDark ? Icons.dark_mode : Icons.light_mode, size: 20),
              const SizedBox(width: 6),
              Switch(
                value: isDark,
                onChanged: widget.onThemeToggle,
                activeColor: Colors.white,
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar & Clear Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (value) => fetchWeather(value.trim()),
                          decoration: InputDecoration(
                            hintText: "Search any city or town ...",
                            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent),
                              onPressed: () => fetchWeather(_controller.text.trim()),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    if (searchedCityData != null) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: clearSearch,
                        child: const Text("Back to Default"),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                if (isLoading && defaultCitiesData.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else if (error.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                else if (searchedCityData != null) ...[
                  // Display Searched City Card
                  CityWeatherCard(
                    cityData: searchedCityData!,
                    onAddFavorite: () => addFavorite(searchedCityData!['city']),
                    showForecast: showForecast,
                    onToggleForecast: () {
                      setState(() => showForecast = !showForecast);
                      if (showForecast) _scrollToBottom();
                    },
                    showMap: showMap,
                    onToggleMap: () {
                      setState(() => showMap = !showMap);
                      if (showMap) _scrollToBottom();
                    },
                  ),

                  // Safe Population & Fun Fact Engagement Card
                  Builder(
                    builder: (context) {
                      int popCount = 0;
                      try {
                        final forecastRaw = searchedCityData!['forecast'];
                        if (forecastRaw is Map && forecastRaw['city'] is Map) {
                          final popRaw = forecastRaw['city']['population'];
                          if (popRaw != null) {
                            popCount = int.tryParse(popRaw.toString()) ?? 0;
                          }
                        }
                      } catch (_) {}

                      return FunFactCard(
                        cityName: searchedCityData!['city'],
                        population: popCount,
                      );
                    },
                  ),

                  // Toggleable Forecast Section with Safe List Extraction
                  if (showForecast) ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final rawForecast = searchedCityData!['forecast'];
                        List forecastList = [];
                        if (rawForecast is Map && rawForecast.containsKey('list')) {
                          forecastList = rawForecast['list'] ?? [];
                        } else if (rawForecast is List) {
                          forecastList = rawForecast;
                        }
                        return ForecastSection(forecast: forecastList);
                      },
                    ),
                  ],

                  // Toggleable Map Section with Safe Coordinates
                  if (showMap) ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        double safeLat = 0.0;
                        double safeLon = 0.0;
                        try {
                          final weather = searchedCityData!['weather'];
                          if (weather is Map) {
                            final coord = weather['coord'];
                            if (coord is Map) {
                              safeLat = double.tryParse(coord['lat'].toString()) ?? 0.0;
                              safeLon = double.tryParse(coord['lon'].toString()) ?? 0.0;
                            } else {
                              safeLat = double.tryParse((weather['latitude'] ?? 0).toString()) ?? 0.0;
                              safeLon = double.tryParse((weather['longitude'] ?? 0).toString()) ?? 0.0;
                            }
                          }
                        } catch (_) {}

                        return InteractiveMapSection(
                          cityName: searchedCityData!['city'],
                          lat: safeLat,
                          lon: safeLon,
                        );
                      },
                    ),
                  ],
                ] else ...[
                  // Default Featured Cities (Nairobi, Mombasa, Paris)
                  const Text(
                    "Featured Cities",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisExtent: 420,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: defaultCitiesData.length,
                    itemBuilder: (context, index) {
                      final c = defaultCitiesData[index];
                      return CityWeatherCard(
                        cityData: c,
                        onAddFavorite: () => addFavorite(c['city']),
                        showForecast: false,
                        onToggleForecast: () => fetchWeather(c['city']),
                        showMap: false,
                        onToggleMap: () => fetchWeather(c['city']),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}