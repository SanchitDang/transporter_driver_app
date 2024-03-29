import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WarehouseDialog extends StatelessWidget {
  final double latitude;
  final double longitude;

  WarehouseDialog({required this.latitude, required this.longitude});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Drop off Location"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Open in Google Maps"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _launchGoogleMaps();
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  // Function to launch Google Maps with given latitude and longitude
  void _launchGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}