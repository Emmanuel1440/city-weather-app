import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = "http://10.0.2.2:8000/api";

void main() {
  runApp(CityWeatherApp());
}

/* =========================
   ROOT APP
========================= */
class CityWeatherApp extends StatefulWidget {
  @override
  _CityWeatherAppState createState() => _CityWeatherAppState();
}

class _CityWeatherAppState extends State<CityWeatherApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('theme_mode') ?? 'system';

    setState(() {
      _themeMode = themeStr == 'light'
          ? ThemeMode.light
          : themeStr == 'dark'
          ? ThemeMode.dark
          : ThemeMode.system;
    });
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });

    await prefs.setString('theme_mode', isDark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(primaryColor: Colors.deepPurple),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MainNavigation(onThemeToggle: _toggleTheme, themeMode: _themeMode),
    );
  }
}

/* =========================
   NAVIGATION SHELL
========================= */
class MainNavigation extends StatefulWidget {
  final void Function(bool) onThemeToggle;
  final ThemeMode themeMode;

  const MainNavigation({required this.onThemeToggle, required this.themeMode});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  late final pages = [
    WeatherHomePage(
      onThemeToggle: widget.onThemeToggle,
      themeMode: widget.themeMode,
    ),
    FavoritesPage(),
    SettingsPage(
      onThemeToggle: widget.onThemeToggle,
      themeMode: widget.themeMode,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: "Weather"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}

/* =========================
   WEATHER PAGE
========================= */
class WeatherHomePage extends StatefulWidget {
  final void Function(bool isDark) onThemeToggle;
  final ThemeMode themeMode;

  const WeatherHomePage({required this.onThemeToggle, required this.themeMode});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> citiesData = [];
  bool isLoading = false;
  String error = '';

  String? token;

  final apiKey = 'YOUR_OPENWEATHER_API_KEY';

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
      error = '';
    });

    final currentUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';

    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final currentRes = await http.get(Uri.parse(currentUrl));
      final forecastRes = await http.get(Uri.parse(forecastUrl));

      if (currentRes.statusCode == 200 && forecastRes.statusCode == 200) {
        final weatherData = json.decode(currentRes.body);
        final fullForecast = json.decode(forecastRes.body);

        final forecastData = fullForecast['list']
            .where((item) {
              final date = DateTime.parse(item['dt_txt']);
              return date.hour >= 11 && date.hour <= 13;
            })
            .take(5)
            .toList();

        setState(() {
          citiesData.add({
            'city': city,
            'weather': weatherData,
            'forecast': forecastData,
          });
          isLoading = false;
        });
      } else {
        setState(() {
          error = "City not found";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Network error";
        isLoading = false;
      });
    }
  }

  /* =========================
     ADD FAVORITE
  ========================= */
  Future<void> addFavorite(String city) async {
    final res = await http.post(
      Uri.parse("$baseUrl/favorites"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"city": city}),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.statusCode == 200 ? "Added favorite" : "Failed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather Dashboard"),
        actions: [
          Switch(
            value: widget.themeMode == ThemeMode.dark,
            onChanged: widget.onThemeToggle,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Enter city"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => fetchWeather(_controller.text.trim()),
                ),
              ],
            ),
          ),

          if (isLoading) const CircularProgressIndicator(),
          if (error.isNotEmpty)
            Text(error, style: const TextStyle(color: Colors.red)),

          Expanded(
            child: ListView(
              children: citiesData.map((c) {
                final weather = c['weather'];

                return Card(
                  child: ListTile(
                    title: Text(weather['name']),
                    subtitle: Text("${weather['main']['temp']}°C"),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () => addFavorite(weather['name']),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
   FAVORITES PAGE (FULL API)
========================= */
class FavoritesPage extends StatefulWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List favorites = [];
  String? token;

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    final res = await http.get(
      Uri.parse("$baseUrl/favorites"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        favorites = jsonDecode(res.body);
      });
    }
  }

  Future<void> deleteFavorite(String city) async {
    await http.delete(
      Uri.parse("$baseUrl/favorites/$city"),
      headers: {"Authorization": "Bearer $token"},
    );

    fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: favorites.isEmpty
          ? const Center(child: Text("No favorites yet"))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final city = favorites[index];

                return ListTile(
                  title: Text(city.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteFavorite(city),
                  ),
                );
              },
            ),
    );
  }
}

/* =========================
   SETTINGS PAGE
========================= */
class SettingsPage extends StatelessWidget {
  final void Function(bool) onThemeToggle;
  final ThemeMode themeMode;

  const SettingsPage({required this.onThemeToggle, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SwitchListTile(
          title: const Text("Dark Mode"),
          value: themeMode == ThemeMode.dark,
          onChanged: onThemeToggle,
        ),
      ),
    );
  }
}
