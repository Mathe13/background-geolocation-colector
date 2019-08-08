part of flt_background_geolocation;

/// Circular Geofence class provided to [BackgroundGeolocation.addGeofence] and [BackgroundGeolocation.addGeofences].
///
class Geofence {
  /// Unique identifier.
  String identifier;

  /// Circular geofence radius.
  double radius;
  double latitude;
  double longitude;

  /// Set `true` to fire on entering the geofence.
  bool notifyOnEntry;

  /// Set `true` fire on exiting the geofence.
  bool notifyOnExit;

  /// Set `true` to fire only after remaining withing geofence for [loiteringDelay] milliseconds.
  bool notifyOnDwell;

  /// The number of milliseconds the device must remain within geofence before firing [notifyOnDwell] event.
  int loiteringDelay;

  /// Arbitrary key/values to append to the recorded geofence record.
  Map<String, dynamic> extras;

  Geofence(
      {@required String identifier,
      @required double radius,
      @required double latitude,
      @required double longitude,
      bool notifyOnEntry,
      bool notifyOnExit,
      bool notifyOnDwell,
      int loiteringDelay,
      Map<String, dynamic> extras}) {
    this.identifier = identifier;
    this.radius = radius * 1.0;
    this.latitude = latitude * 1.0;
    this.longitude = longitude * 1.0;
    this.notifyOnEntry = notifyOnEntry;
    this.notifyOnExit = notifyOnExit;
    this.notifyOnDwell = notifyOnDwell;
    this.loiteringDelay = loiteringDelay;
    this.extras = extras;
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> params = {};
    if (this.identifier != null) params['identifier'] = this.identifier;
    if (this.radius != null) params['radius'] = this.radius;
    if (this.latitude != null) params['latitude'] = this.latitude;
    if (this.longitude != null) params['longitude'] = this.longitude;
    if (this.notifyOnEntry != null)
      params['notifyOnEntry'] = this.notifyOnEntry;
    if (this.notifyOnExit != null) params['notifyOnExit'] = this.notifyOnExit;
    if (this.notifyOnDwell != null)
      params['notifyOnDwell'] = this.notifyOnDwell;
    if (this.loiteringDelay != null)
      params['loiteringDelay'] = this.loiteringDelay;
    if (this.extras != null) params['extras'] = this.extras;
    return params;
  }

  String toString() {
    return '[Geofence identifier: $identifier, radius: $radius, $latitude / $longitude, notifyOnEntry:$notifyOnEntry, notifyOnExit:$notifyOnExit, notifyOnDwell: $notifyOnDwell]';
  }
}
