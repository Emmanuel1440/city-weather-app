import 'package:flutter/material.dart';

class CityWeatherCard extends StatelessWidget {
  final Map<String, dynamic> cityData;
  final VoidCallback onAddFavorite;
  final bool showForecast;
  final VoidCallback onToggleForecast;
  final bool showMap;
  final VoidCallback onToggleMap;

  const CityWeatherCard({
    super.key,
    required this.cityData,
    required this.onAddFavorite,
    required this.showForecast,
    required this.onToggleForecast,
    required this.showMap,
    required this.onToggleMap,
  });

  @override
  Widget build(BuildContext context) {
    final cityName = cityData['city'] ?? 'Unknown';
    final weather = cityData['weather'] ?? {};
    final condition = (weather['condition'] ?? 'Clear').toString().toLowerCase();

    IconData getWeatherIcon(String cond) {
      if (cond.contains('rain')) return Icons.water_drop;
      if (cond.contains('cloud')) return Icons.cloud;
      if (cond.contains('wind')) return Icons.air;
      return Icons.wb_sunny_rounded;
    }

    // Specific network images for your featured cities
    String? getCityImageUrl(String name) {
      final key = name.toLowerCase().trim();
      if (key.contains('nairobi')) {
        return 'https://images.unsplash.com/photo-1614082242765-7c98ca0f3df3?auto=format&fit=crop&w=800&q=80';
      } else if (key.contains('mombasa')) {
        return 'https://images.unsplash.com/photo-1544644181-1484b3fdfc62?auto=format&fit=crop&w=800&q=80';
      } else if (key.contains('paris')) {
        return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?auto=format&fit=crop&w=800&q=80';
      } else if (key.contains('kakamega')) {
        return 'https://images.unsplash.com/photo-1590523277543-a94d2e4eb00b?auto=format&fit=crop&w=800&q=80';
      }
      // Return null for other searched cities so it uses the local asset fallback
      return null;
    }

    final imageUrl = getCityImageUrl(cityName);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // If network image exists, load it. Otherwise, use local asset image fallback!
                imageUrl != null
                    ? Image.network(
                        imageUrl,
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/default_city.jpg',
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/default_city.jpg',
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.65), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cityName.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: onAddFavorite,
                        tooltip: "Add to Favorites",
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${weather['temperature']}°C",
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          Text(
                            "Condition: ${weather['condition']}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Icon(getWeatherIcon(condition), size: 56, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 20),
                          const SizedBox(width: 6),
                          Text("Humidity: ${weather['humidity']}%", style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.air, color: Colors.cyan, size: 20),
                          const SizedBox(width: 6),
                          Text("Wind: ${weather['wind_speed']} m/s", style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade800,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onToggleForecast,
                      child: Text(showForecast ? "Hide 5-Day Forecast" : "View 5-Day Forecast for $cityName"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade50,
                        foregroundColor: Colors.blue.shade800,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: onToggleMap,
                      child: Text(showMap ? "Hide Interactive Map" : "View Interactive Map for $cityName"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}