import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class EmergencyHelper {
  static Future<void> triggerSOS(BuildContext context, int? seniorId) async {
    if (seniorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Senior ID is missing.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trigger Emergency?'),
        content: const Text(
            'This will alert your family members and caretakers. Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('YES, ALERT FAMILY',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirmed == true) {
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse) {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 15),
            );
          }
        }
      } catch (e) {
        debugPrint('Location error, attempting last known: $e');
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (e2) {
          debugPrint('Last known location failed: $e2');
        }
      }

      final result = await ApiService().createEmergencyAlert(
        seniorId: seniorId,
        alertType: 'SOS Emergency',
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (context.mounted) {
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Emergency Alert Sent! Your family and caretakers are being notified.'),
              backgroundColor: Colors.red));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${result['error']}')));
        }
      }
    }
  }
}
