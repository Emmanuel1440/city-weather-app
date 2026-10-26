import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class InteractiveMapSection extends StatefulWidget {
  final String cityName;
  final double lat;
  final double lon;

  const InteractiveMapSection({
    super.key,
    required this.cityName,
    required this.lat,
    required this.lon,
  });

  @override
  State<InteractiveMapSection> createState() => _InteractiveMapSectionState();
}

class _InteractiveMapSectionState extends State<InteractiveMapSection> {
  double currentLat = 0.0;
  double currentLon = 0.0;
  bool isGeocoding = false;

  @override
  void initState() {
    super.initState();
    currentLat = widget.lat;
    currentLon = widget.lon;

    if (currentLat == 0.0 && currentLon == 0.0) {
      _fetchCoordinatesForCity(widget.cityName);
    }
  }

  Future<void> _fetchCoordinatesForCity(String name) async {
    setState(() => isGeocoding = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(name)},Kenya');
      final res = await http.get(url, headers: {'User-Agent': 'KenyaWeatherDashboard/1.0'});
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        if (data.isNotEmpty) {
          if (mounted) {
            setState(() {
              currentLat = double.tryParse(data[0]['lat'].toString()) ?? 0.0;
              currentLon = double.tryParse(data[0]['lon'].toString()) ?? 0.0;
              isGeocoding = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) setState(() => isGeocoding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isGeocoding) {
      return Container(
        height: 320,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text("Pinpointing location on map...", style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    // Default to Nairobi coordinates if zero
    final double mapLat = currentLat == 0.0 ? -1.286389 : currentLat;
    final double mapLon = currentLon == 0.0 ? 36.817223 : currentLon;

    final String viewType = 'map-${widget.cityName}-${mapLat.toStringAsFixed(3)}-${mapLon.toStringAsFixed(3)}';
    final double bboxOffset = 0.04;
    final String bbox = '${mapLon - bboxOffset}%2C${mapLat - bboxOffset}%2C${mapLon + bboxOffset}%2C${mapLat + bboxOffset}';
    final String mapUrl = 'https://www.openstreetmap.org/export/embed.html?bbox=$bbox&layer=mapnik&marker=$mapLat%2C$mapLon';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => html.IFrameElement()
        ..src = mapUrl
        ..style.border = 'none'
        ..width = '100%'
        ..height = '100%',
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}