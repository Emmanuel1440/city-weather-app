import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/weather_page.dart';
import 'pages/favorites_page.dart';
import 'pages/settings_page.dart';


void main() {
  runApp(CityWeatherApp());
}


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

    theme: ThemeData.light().copyWith(
      primaryColor: Colors.deepPurple,
    ),

    darkTheme: ThemeData.dark(),

    themeMode: _themeMode,

    initialRoute: '/login',

    routes: {
      '/login': (context) => const LoginPage(),

      '/register': (context) => const RegisterPage(),

      '/home': (context) => MainNavigation(
            onThemeToggle: _toggleTheme,
            themeMode: _themeMode,
          ),
    },
  );
}
}

/* 
   NAVIGATION SHELL
 */
class MainNavigation extends StatefulWidget {
  final void Function(bool) onThemeToggle;
  final ThemeMode themeMode;

  const MainNavigation({required this.onThemeToggle, required this.themeMode});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  List<Widget> get pages => [
        WeatherHomePage(
          onThemeToggle: widget.onThemeToggle,
          themeMode: widget.themeMode,
        ),

        const FavoritesPage(),

        SettingsPage(
          onThemeToggle: widget.onThemeToggle,
          themeMode: widget.themeMode,
        ),
      ];

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: IndexedStack(
      index: index,
      children: pages,
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: index,
      onTap: (i) => setState(() => index = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud),
          label: "Weather",
        ),
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