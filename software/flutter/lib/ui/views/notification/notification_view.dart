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
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.black,
            title: Text(
              'NOTIFICATIONS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () => model.fetchNotifications(),
              ),
            ],
          ),
          body: model.isBusy
              ? Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          )
              : CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activities',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Monitor your device locations and activities',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              model.notifications.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 64,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'New activities will appear here',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final notification = model.notifications[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (notification['snapshotUrl'] != null &&
                                  notification['snapshotUrl'] != '')
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    notification['snapshotUrl'],
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                        Container(
                                          height: 200,
                                          color: Colors.white10,
                                          child: Center(
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                              color: Colors.white24,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text(
                                          notification['name'] ??
                                              'Unknown Device',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.map_outlined,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            model.locationData =
                                                LocationData(
                                                  latitude: notification[
                                                  'latitude'] ??
                                                      0.0,
                                                  longitude: notification[
                                                  'longitude'] ??
                                                      0.0,
                                                  snapshotUrl:
                                                  notification[
                                                  'snapshotUrl'] ??
                                                      '',
                                                );
                                            model.openMap(context);
                                          },
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Lat: ${notification['latitude']?.toStringAsFixed(6) ?? 'Unknown'}, Long: ${notification['longitude']?.toStringAsFixed(6) ?? 'Unknown'}',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: model.notifications.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}