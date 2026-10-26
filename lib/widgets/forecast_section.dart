import 'package:flutter/material.dart';

class ForecastSection extends StatelessWidget {
  final List<dynamic> forecast;

  const ForecastSection({super.key, required this.forecast});

  String _getDayName(String dateStr) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final dayName = days[dateTime.weekday - 1];
      return '$dayName ${dateTime.month}/${dateTime.day}';
    } catch (_) {
      if (dateStr.length >= 10) {
        return dateStr.substring(5, 10);
      }
      return dateStr;
    }
  }

  IconData _getForecastIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain')) return Icons.grain;
    if (cond.contains('cloud')) return Icons.cloud;
    if (cond.contains('wind')) return Icons.air;
    return Icons.wb_sunny_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                SizedBox(width: 6),
                Text(
                  "5-Day Forecast",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 155,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: forecast.length,
              itemBuilder: (context, index) {
                final day = forecast[index];
                final condition = day['condition'] ?? 'Clear';
                final dateRaw = day['date'] ?? '';
                final high = day['high'] ?? '--';
                final low = day['low'] ?? '--';

                return Container(
                  width: 125,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        _getDayName(dateRaw.toString()),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                      Icon(
                        _getForecastIcon(condition),
                        color: Colors.amber.shade700,
                        size: 26, // Smaller, proportional icon size
                      ),
                      Text(
                        condition,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$high° / $low°C",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}