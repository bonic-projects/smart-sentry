import 'package:flutter/material.dart';
import 'package:smart_sentry/models/locatio_model.dart';
import 'package:smart_sentry/ui/views/notification/notification_viewmodel.dart';
import 'package:stacked/stacked.dart';

class NotificationView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<NotificationViewModel>.reactive(
      viewModelBuilder: () => NotificationViewModel(),
      onModelReady: (model) => model.fetchNotifications(),
      builder: (context, model, child) {
        if (model.isBusy) {
          return Scaffold(
            appBar: AppBar(title: const Text('Notifications')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => model.fetchNotifications(),
              ),
            ],
          ),
          body: model.notifications.isEmpty
              ? const Center(child: Text('No notifications available'))
              : ListView.builder(
                  itemCount: model.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = model.notifications[index];
                    return ListTile(
                      leading: notification['snapshotUrl'] != null &&
                              notification['snapshotUrl'] != ''
                          ? Image.network(
                              notification['snapshotUrl'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image),
                            )
                          : const Icon(Icons.broken_image),
                      title: Text(notification['name'] ?? 'No Name Available'),
                      subtitle: Text(
                          'Location: ${notification['latitude'] ?? 'Unknown Latitude'}, ${notification['longitude'] ?? 'Unknown Longitude'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.location_on),
                        onPressed: () {
                          model.locationData = LocationData(
                            latitude: notification['latitude'] ?? 0.0,
                            longitude: notification['longitude'] ?? 0.0,
                            snapshotUrl: notification['snapshotUrl'] ?? '',
                          );
                          model.openMap(context);
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
