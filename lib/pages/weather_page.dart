import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';

class WeatherHomePage extends StatefulWidget {
  final void Function(bool isDark) onThemeToggle;
  final ThemeMode themeMode;

  const WeatherHomePage({ super.key,
  required this.onThemeToggle,
   required this.themeMode});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}



class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> citiesData = [];
  bool isLoading = false;
  String error = '';

  String? token;


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

  try {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/$city'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
        print(response.body);
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
        citiesData.clear();

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
      error = e.toString();
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
              Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      child: TextField(
        controller: _controller,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            fetchWeather(value.trim());
          }
        },
        decoration: InputDecoration(
          hintText: "Search city e.g Nairobi",
          prefixIcon: const Icon(Icons.location_city),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                fetchWeather(_controller.text.trim());
              }
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
        ),
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
  margin: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          weather['city'] ?? '',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "${weather['temperature']}°C",
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          "Condition: ${weather['condition']}",
          style: const TextStyle(fontSize: 16),
        ),

        Text(
          "Humidity: ${weather['humidity']}%",
          style: const TextStyle(fontSize: 16),
        ),

        Text(
          "Wind Speed: ${weather['wind_speed']} m/s",
          style: const TextStyle(fontSize: 16),
        ),

        const SizedBox(height: 15),

        ElevatedButton.icon(
          onPressed: () => addFavorite(weather['city']),
          icon: const Icon(Icons.favorite),
          label: const Text("Add To Favorites"),
        ),

        const SizedBox(height: 20),

        const Text(
          "5 Day Forecast",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: c['forecast'].length,
            itemBuilder: (context, index) {

              final day = c['forecast'][index];

              return Card(
                margin: const EdgeInsets.all(6),
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceEvenly,
                    children: [

                      Text(
                        day['date']
                            .toString()
                            .substring(0, 10),
                      ),

                      Text(
                        day['condition'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "High: ${day['high']}°C",
                      ),

                      Text(
                        "Low: ${day['low']}°C",
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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