import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FunFactCard extends StatefulWidget {
  final String cityName;
  final int population;

  const FunFactCard({
    super.key,
    required this.cityName,
    this.population = 0,
  });

  @override
  State<FunFactCard> createState() => _FunFactCardState();
}

class _FunFactCardState extends State<FunFactCard> {
  String extract = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCitySummaryOnline(widget.cityName);
  }

  @override
  void didUpdateWidget(covariant FunFactCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityName != widget.cityName) {
      fetchCitySummaryOnline(widget.cityName);
    }
  }

  Future<void> fetchCitySummaryOnline(String name) async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final url = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(name)}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            extract = data['extract'] ?? 'A unique location with a rich history and vibrant community.';
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            extract = 'Explore climate patterns and local geography for $name.';
            isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          extract = 'Explore live weather trends and regional history for $name.';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lightbulb_rounded, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "About ${widget.cityName}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (widget.population > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "Pop: ${widget.population}",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            Text(
              extract,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}