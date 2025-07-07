import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'City Weather App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.transparent,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        cardColor: Colors.grey[850],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.white70),
        ),
      ),
      themeMode: _themeMode,
      home: WeatherHomePage(onThemeToggle: _toggleTheme, themeMode: _themeMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final void Function(bool isDark) onThemeToggle;
  final ThemeMode themeMode;

  const WeatherHomePage({
    required this.onThemeToggle,
    required this.themeMode,
  });

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> citiesData = [];
  bool isLoading = false;
  String error = '';

  Map<String, String> cityFacts = {
    'nairobi': 'Fun Fact: Nairobi is known as the Green City in the Sun!',
    'paris': 'Fun Fact: Paris is home to the Eiffel Tower.',
    'tokyo': 'Fun Fact: Tokyo is the most populated city in the world!',
    'new york': 'Fun Fact: The Statue of Liberty was a gift from France.',
  };

  Future<void> fetchWeather(String city) async {
    if (city.isEmpty) return;
    setState(() {
      isLoading = true;
      error = '';
    });

    final apiKey = 'b1a52188e43974fb55ccbafa03fe06a4';
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

        final imageMap = {
          'nairobi': 'assets/images/nairobi.jpg',
          'paris': 'assets/images/paris.jpg',
          'tokyo': 'assets/images/tokyo.jpg',
          'new york': 'assets/images/newyork.jpg',
        };

        final imagePath =
            imageMap[city.toLowerCase()] ?? 'assets/images/default.jpg';

        final fact =
            cityFacts[city.toLowerCase()] ??
            'Fun Fact: This city is full of surprises!';

        setState(() {
          citiesData.add({
            'city': city,
            'weather': weatherData,
            'forecast': forecastData,
            'imagePath': imagePath,
            'fact': fact,
            'towns': [
              '${city} Central',
              '${city} North',
              '${city} South',
            ]
          });
          isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        List<String> history = prefs.getStringList('search_history') ?? [];
        if (!history.contains(city)) {
          history.add(city);
          await prefs.setStringList('search_history', history);
        }
      } else {
        setState(() {
          error = 'City not found.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Something went wrong.';
        isLoading = false;
      });
    }
  }

  Widget forecastChart(List<dynamic> forecastData) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < forecastData.length) {
                      final date = DateTime.parse(forecastData[index]['dt_txt']);
                      return Text(
                        ['S', 'M', 'T', 'W', 'T', 'F', 'S'][date.weekday % 7],
                        style: TextStyle(fontSize: 12),
                      );
                    }
                    return Text('');
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: forecastData
                    .asMap()
                    .entries
                    .map((entry) => FlSpot(entry.key.toDouble(), entry.value['main']['temp'].toDouble()))
                    .toList(),
                isCurved: true,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
                color: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget cityCard(Map<String, dynamic> cityData) {
    final weatherData = cityData['weather'];
    final forecastData = cityData['forecast'];
    final cityImagePath = cityData['imagePath'];
    final funFact = cityData['fact'];
    final towns = cityData['towns'] ?? [];

    final iconCode = weatherData['weather'][0]['icon'];
    final iconUrl = 'http://openweathermap.org/img/wn/$iconCode@4x.png';

    return FadeInUp(
      duration: Duration(milliseconds: 600),
      child: Card(
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 10,
        margin: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                      child: Image.asset(
                        cityImagePath,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Image.network(iconUrl, width: 40, height: 40),
                              SizedBox(width: 10),
                              Text(
                                '${weatherData['name']}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${weatherData['weather'][0]['main']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            '${weatherData['main']['temp']}°C',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            funFact,
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                          ExpansionTile(
                            title: Text("View Towns"),
                            children: towns
                                .map<Widget>((town) => ListTile(
                                      title: Text(town),
                                      subtitle: Text("Forecast same as main city"),
                                    ))
                                .toList(),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5-Day Forecast',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: forecastData.length,
                      itemBuilder: (context, index) {
                        final dayData = forecastData[index];
                        final date = DateTime.parse(dayData['dt_txt']);
                        final iconCode = dayData['weather'][0]['icon'];
                        final iconUrl =
                            'http://openweathermap.org/img/wn/$iconCode@2x.png';
                        final temp = dayData['main']['temp'].round();
                        final dayOfWeek = [
                          'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                          [date.weekday % 7];

                        return ZoomIn(
                          duration: Duration(milliseconds: 400 + index * 100),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.deepPurple.shade50,
                            margin: EdgeInsets.symmetric(horizontal: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayOfWeek,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Image.network(iconUrl, width: 40, height: 40),
                                  Text('$temp°C'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  forecastChart(forecastData),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City Weather Forecast'),
        backgroundColor: Colors.deepPurple.withOpacity(0.8),
        elevation: 4,
        actions: [
          Switch(
            value: widget.themeMode == ThemeMode.dark,
            onChanged: (val) => widget.onThemeToggle(val),
            activeColor: Colors.white,
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade50],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FadeInDown(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Enter city name',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search, color: Colors.deepPurple),
                        onPressed: () => fetchWeather(
                            _controller.text.trim().toLowerCase()),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 8),
                      Text('Loading...'),
                    ],
                  ),
                ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(error,
                      style: TextStyle(color: Colors.redAccent)),
                ),
              ...citiesData.map((city) => cityCard(city)).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
