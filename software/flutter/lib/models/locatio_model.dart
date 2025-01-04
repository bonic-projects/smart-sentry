class LocationData {
  double? latitude;
  double? longitude;
  String? snapshotUrl;

  LocationData({
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.snapshotUrl = '',
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      snapshotUrl: json['snapshotUrl'] as String? ?? '',
    );
  }
}
