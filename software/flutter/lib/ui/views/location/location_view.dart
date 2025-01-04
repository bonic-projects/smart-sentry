import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'location_viewmodel.dart';

class LocationView extends StatelessWidget {
  const LocationView({super.key});

  // Updated regex to handle more general IP format checks.
  bool isValidIp(String ipAddress) {
    final RegExp ipRegex = RegExp(
        r"^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$");

    return ipRegex.hasMatch(ipAddress);
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LocationViewModel>.reactive(
      viewModelBuilder: () => LocationViewModel(),
      onModelReady: (model) => model.init(), // Initialize the ViewModel here
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Location and Snapshot'),
            backgroundColor: Colors.greenAccent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: model.ipController,
                    onChanged: (value) {
                      model.saveIPAddress(value); // Save IP on text change
                    },
                    decoration: const InputDecoration(
                      labelText: 'Enter IP Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final ipAddress = model.ipController.text;
                      if (isValidIp(ipAddress)) {
                        model.startListening(ipAddress);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a valid IP address!'),
                          ),
                        );
                      }
                    },
                    child: const Text('Start Listening'),
                  ),
                  const SizedBox(height: 20),
                  Text('Latitude: ${model.latitude ?? 'Fetching...'}'),
                  Text('Longitude: ${model.longitude ?? 'Fetching...'}'),
                  const SizedBox(height: 20),
                  model.snapshot != null
                      ? Image.memory(
                    model.snapshot!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : const Text('No snapshot fetched yet.'),
                ],
              ),
            ),
          ),
        );
      },
    );

  }
}
