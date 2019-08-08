part of flt_background_geolocation;

/// Configuration API.
///
/// Instances of `Config` are consumed by [BackgroundGeolocation.ready].
///
/// # Example
///
/// ```dart
/// Config params = new Config(
///   desiredAccuracy: Config.DESIRED_ACCURACY_HIGH,
///   distanceFilter: 10.0,
///   stopOnTerminate: false,
///   startOnBoot: true,
///   url: 'http://my.server.com',
///   params: {
///     "user_id": 123
///   },
///   headers: {
///     "my-auth-token":"secret-key"
///   }
/// );
///
/// BackgroundGeolocation.ready(params).then((State state) {
///   print('[ready] BackgroundGeolocation is configured and ready to use');
///
///   BackgroundGeolocation.start();
/// })
/// ```
///
class Config {
  static const int LOG_LEVEL_OFF = 0;
  static const int LOG_LEVEL_ERROR = 1;
  static const int LOG_LEVEL_WARNING = 2;
  static const int LOG_LEVEL_INFO = 3;
  static const int LOG_LEVEL_DEBUG = 4;
  static const int LOG_LEVEL_VERBOSE = 5;

  static const int DESIRED_ACCURACY_NAVIGATION = -2;
  static const int DESIRED_ACCURACY_HIGH = -1;
  static const int DESIRED_ACCURACY_MEDIUM = 10;
  static const int DESIRED_ACCURACY_LOW = 100;
  static const int DESIRED_ACCURACY_VERY_LOW = 1000;
  static const int DESIRED_ACCURACY_LOWEST = 3000;

  static const int AUTHORIZATION_STATUS_NOT_DETERMINED = 0;
  static const int AUTHORIZATION_STATUS_RESTRICTED = 1;
  static const int AUTHORIZATION_STATUS_DENIED = 2;
  static const int AUTHORIZATION_STATUS_ALWAYS = 3;
  static const int AUTHORIZATION_STATUS_WHEN_IN_USE = 4;

  static const int NOTIFICATION_PRIORITY_DEFAULT = 0;
  static const int NOTIFICATION_PRIORITY_HIGH = 1;
  static const int NOTIFICATION_PRIORITY_LOW = -1;
  static const int NOTIFICATION_PRIORITY_MAX = 2;
  static const int NOTIFICATION_PRIORITY_MIN = -2;

  // For iOS #activityType
  static const int ACTIVITY_TYPE_OTHER = 1;
  static const int ACTIVITY_TYPE_AUTOMOTIVE_NAVIGATION = 2;
  static const int ACTIVITY_TYPE_FITNESS = 3;
  static const int ACTIVITY_TYPE_OTHER_NAVIGATION = 4;

  // #persistMode
  static const int PERSIST_MODE_ALL = 2;
  static const int PERSIST_MODE_LOCATION = 1;
  static const int PERSIST_MODE_GEOFENCE = -1;
  static const int PERSIST_MODE_NONE = 0;

  Map _map;

  /// Specify the desired-accuracy of the geolocation system.
  ///
  /// | Name                                 | Location Providers           | Description                             |
  /// |--------------------------------------|------------------------------|-----------------------------------------|
  /// | [DESIRED_ACCURACY_NAVIGATION]        | (**iOS only**) GPS + Wifi + Cellular | Highest power; highest accuracy |
  /// | [DESIRED_ACCURACY_HIGH]              | GPS + Wifi + Cellular | Highest power; highest accuracy |
  /// | [DESIRED_ACCURACY_MEDIUM]            | Wifi + Cellular | Medium power; Medium accuracy; |
  /// | [DESIRED_ACCURACY_LOW]               | Wifi (low power) + Cellular | Lower power; No GPS |
  /// | [DESIRED_ACCURACY_VERY_LOW]          | Cellular only | Lowest power; lowest accuracy |
  /// | [DESIRED_ACCURACY_LOWEST]   | (**iOS only**) Lowest power; lowest accuracy |
  ///
  ///  **Note**: Only **`DESIRED_ACCURACY_HIGH`** uses GPS.  `speed`, `heading` and `altitude` are available only from GPS.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeoloction.ready(Config(
  ///   desiredAccuracy: BackgroundGeolocation.DESIRED_ACCURACY_HIGH
  /// ));
  /// ```
  /// For platform-specific information about location accuracy, see the corresponding API docs:
  /// - [Android](https://developer.android.com/reference/com/google/android/gms/location/LocationRequest.html#PRIORITY_BALANCED_POWER_ACCURACY)
  /// - [iOS](https://developer.apple.com/reference/corelocation/cllocationmanager/1423836-desiredaccuracy?language=objc)
  int desiredAccuracy;

  /// The minimum distance (measured in meters) a device must move horizontally before an update event is generated.
  ///
  /// However, by default, **`distanceFilter`** is elastically auto-calculated by the plugin:  When speed increases, **`distanceFilter`** increases;  when speed decreases, so too does **`distanceFilter`**.
  ///
  ///  **NOTE:**
  ///
  /// - To disable this behavior, configure [disableElasticity]:true.
  /// - To control the scale of the automatic `distanceFilter` calculation, see [elasticityMultiplier]
  ///
  /// `distanceFilter` is auto-scaled by rounding speed to the nearest `5 m/s` and adding `distanceFilter` meters for each `5 m/s` increment.
  ///
  /// For example, at biking speed of 7.7 m/s with a configured `distanceFilter: 30`:
  ///
  /// ```
  ///   rounded_speed = round(7.7, 5)
  ///   => 10
  ///   multiplier = rounded_speed / 5
  ///   => 10 / 5 = 2
  ///   adjusted_distance_filter = multiplier * distanceFilter
  ///   => 2 * 30 = 60 meters
  /// ```
  ///
  /// At highway speed of `27 m/s` with a configured `distanceFilter: 50`:
  ///
  /// ```
  ///   rounded_speed = round(27, 5)
  ///   => 30
  ///   multiplier = rounded_speed / 5
  ///   => 30 / 5 = 6
  ///   adjusted_distance_filter = multiplier * distanceFilter * elasticityMultipiler
  ///   => 6 * 50 = 300 meters
  /// ```
  ///
  /// Note the following real example of background-geolocation on highway 101 towards San Francisco as the driver slows down as he runs into slower traffic (locations become compressed as distanceFilter decreases)
  ///
  /// ![distanceFilter at highway speed](https://dl.dropboxusercontent.com/s/uu0hs0sediw26ar/distance-filter-highway.png?dl=1)
  ///
  /// Compare now background-geolocation in the scope of a city.  In this image, the left-hand track is from a cab-ride, while the right-hand track is walking speed.
  ///
  /// ![distanceFilter at city scale](https://dl.dropboxusercontent.com/s/yx8uv2zsimlogsp/distance-filter-city.png?dl=1)
  double distanceFilter;

  /// __`[iOS only]`__ The minimum distance the device must move beyond the stationary location for aggressive background-tracking to engage.
  ///
  /// Configuring **`stationaryRadius: 0`** has **NO EFFECT**.  In fact the plugin enforces a minimum **`stationaryRadius`** of `25` and in-practice, the native API won't respond for at least 200 meters.
  ///
  /// The following image shows the typical distance iOS requires to detect exit of the **`stationaryRadius`**, where the *green* polylines represent a transition from **stationary** state to **moving** and the *red circles* locations where the plugin entered the **stationary** state.:
  ///
  /// ![](https://dl.dropboxusercontent.com/s/vnio90swhs6xmqm/screenshot-ios-stationary-exit.png?dl=1)
  ///
  ///  **NOTE:** For more information, see [Philosophy of Operation](https://github.com/transistorsoft/flutter_background_geolocation/wiki/Philosophy-of-Operation)
  ///
  ///  **WARNING:** iOS will not detect the exact moment the device moves out of the stationary-radius.  In normal conditions, it will typically take **~200 meters** before the plugin begins tracking.
  ///
  double stationaryRadius;

  int locationTimeout;

  /// Disable automatic, speed-based [distanceFilter] scaling.
  ///
  /// Defaults to **`false`**.  Set **`true`** to disable automatic, speed-based [distanceFilter] elasticity.
  ///
  bool disableElasticity;

  /// Controls the scale of automatic speed-based [distanceFilter] elasticity.
  ///
  /// Increasing `elasticityMultiplier` will result in fewer location samples as speed increases.  A value of `0` has the same effect as [disableElasticity]:true.
  ///
  double elasticityMultiplier;

  /// Set `true` in order to disable constant background-tracking.  Locations will be recorded only periodically.
  ///
  /// Defaults to `false`.  A location will be recorded only every `500` to `1000` meters (can be higher in non urban environments; depends upon the spacing of Cellular towers).  Many of the plugin's configuration parameters **will have no effect**, such as [distanceFilter], [stationaryRadius], [activityType], etc.
  ///
  /// Using `significantChangesOnly: true` will provide **significant** power-saving at the expense of fewer recorded locations.
  ///
  /// ### iOS
  ///
  /// Engages the iOS [Significant Location Changes API](https://developer.apple.com/reference/corelocation/cllocationmanager/1423531-startmonitoringsignificantlocati?language=objc) API for only periodic location updates every 500-1000 meters.
  /// @break
  ///
  /// ⚠️ If Apple has rejected your application, refusing to grant your app the privilege of using the **`UIBackgroundMode: "location"`**, this can be a solution.
  ///
  ///
  /// ### Android
  ///
  /// A location will be recorded several times per hour while the device is in the *moving* state.  No foreground-service will be run (nor its corresponding persistent notification).
  ///
  /// ## Example **`useSignificantChanges: true`**
  /// ![](https://dl.dropboxusercontent.com/s/wdl9e156myv5b34/useSignificantChangesOnly.png?dl=1)
  ///
  /// ## Example **`useSignificantChanges: false` (Default)**
  /// ![](https://dl.dropboxusercontent.com/s/hcxby3sujqanv9q/useSignificantChangesOnly-false.png?dl=1)
  ///
  bool useSignificantChangesOnly;

  /// Automatically [BackgroundGeolocation.stop] tracking after x minutes.
  ///
  /// The plugin can optionally automatically [BackgroundGeolocation.stop] after some number of minutes elapses after the [BackgroundGeolocation.start] method was called.
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   stopAfterElapsedMinutes: 30
  /// )).then((State state) {
  ///   BackgroundGeolocation.start();  // <-- plugin will automatically #stop in 30 minutes
  /// });
  /// ```
  ///
  int stopAfterElapsedMinutes;

  /// The radius around current location to query for geofences to activate monitoring upon.
  ///
  /// The default and *minimum* is `1000` meters.  **@see** related event [BackgroundGeolocation.onGeofencesChange].  When using Geofences, the plugin activates only those in proximity (the maximum geofences allowed to be simultaneously monitored is limited by the platform, where **iOS** allows only 20 and **Android**.  However, the plugin allows you to create as many geofences as you wish (thousands even).  It stores these in its database and uses spatial queries to determine which **20** or **100** geofences to activate.
  ///
  ///  **NOTE:**
  /// - See [GeofenceEvent]
  /// - [View animation of this behavior](https://www.transistorsoft.com/shop/products/assets/images/background-geolocation-infinite-geofencing.gif)
  ///
  /// ![](https://dl.dropboxusercontent.com/s/7sggka4vcbrokwt/geofenceProximityRadius_iphone6_spacegrey_portrait.png?dl=1)
  ///
  int geofenceProximityRadius;

  /// When a device is already within a just-created geofence, fire the **enter** transition immediately.
  ///
  /// Defaults to `true`.  Set `false` to disable triggering a geofence immediately if device is already inside it.
  ///
  bool geofenceInitialTriggerEntry;

  /// __`[Android only]`__ Enable high-accuracy for **geofence-only** mode (See [BackgroundGeolocation.startGeofences]).
  ///
  /// Defaults to `false`.  Runs Android's [BackgroundGeolocation.startGeofences] with a///foreground service* (along with its corresponding persitent notification;  See [foregroundService] for a list of available notification config options, including [notificationText], [notificationTitle]).
  ///
  /// Configuring `geofenceModeHighAccuracy: true` will make Android geofence triggering///*far more responsive**.  In this mode, the usual config options to control location-services will be applied:
  ///
  /// ⚠️ Warning: Will consume more power.
  ///
  /// - [desiredAccuracy] ([DESIRED_ACCURACY_MEDIUM] works well).
  /// - [locationUpdateInterval]
  /// - [distanceFilter]
  /// - [deferTime]
  ///
  /// With the default `geofenceModeHighAccuracy: false`, a device will have to move farther *into* a geofence before the *ENTER* event fires and farther *out of* a geofence before
  /// the *EXIT* event fires.
  ///
  /// The more aggressive you configure the location-update params above (at the cost of power consumption), the more responsive will be your geofence-triggering.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   geofenceModeHighAccuracy: true,
  ///   desiredAccuracy: Config.DESIRED_ACCURACY_MEDIUM,
  ///   locationUpdateInterval: 5000,
  ///   distanceFilter: 50
  /// )).then((state) {
  ///   BackgroundGeolocation.startGeofences();
  /// });
  /// ```
  ///
  /// ## Example `geofenceModeHighAccuracy: false` (Default) &mdash; Transition events **are delayed**.
  /// ![](https://dl.dropboxusercontent.com/s/6nxbuersjcdqa8b/geofenceModeHighAccuracy-false.png?dl=1)
  ///
  /// ## Example `geofenceModeHighAccuracy: true` &mdash; Transition events are **nearly instantaneous**.
  /// ![](https://dl.dropbox.com/s/w53hqn7f7n1ug1o/geofenceModeHighAccuracy-true.png?dl=1)
  ///
  bool geofenceModeHighAccuracy;

  /// The maximum location accuracy allowed for a location to be used for [Location.odometer] calculations.
  ///
  /// Defaults to `100`.  If a location arrives having **`accuracy > desiredOdometerAccuracy`**, that location will not be used to update the odometer.  If you only want to calculate odometer from GPS locations, you could set **`desiredOdometerAccuracy: 10`**.  This will prevent odometer updates when a device is moving around indoors, in a shopping mall, for example.
  ///
  double desiredOdometerAccuracy;

  /// Configure the initial tracking-state after [BackgroundGeolocation.start] is called.
  ///
  /// The plugin will immediately enter the tracking-state, by-passing the *stationary* state.  If the device is not currently moving, the stop-detection system *will* still engage.  After [stopTimeout] minutes without movement, the plugin will enter the *stationary* state, as usual.
  ///
  /// # Example
  ///
  /// ```dart
  /// State state = await BackgroundGeolocation.ready(Config(
  ///   isMoving: true
  /// ));
  ///
  /// if (!state.enabled) {
  ///   BackgroundGeolocation.start();
  /// }
  /// // Location-services are now on and the plugin is recording a location
  /// // each [distanceFilter] meters.
  /// ```
  ///
  bool isMoving;

  /// Minutes to wait in *moving* state with no movement before considering the device *stationary*.
  ///
  /// Defaults to `5` minutes.  When in the *moving* state, specifies the number of minutes to wait before turning off location-services and transitioning to *stationary* state after the ActivityRecognition System detects the device is `STILL`.  An example use-case for this configuration is to delay GPS OFF while in a car waiting at a traffic light.
  ///
  /// **Note:** [Philosophy of Operation](https://github.com/transistorsoft/flutter_background_geolocation/wiki/Philosophy-of-Operation)
  ///
  /// **WARNING:** Setting a value > 15 min is **not** recommended, particularly for Android.
  ///
  int stopTimeout;

  /// Controls the sample-rate of the activity-recognition system.
  ///
  /// Defaults to `10000` (10 seconds).  This is primarily an **Android** option, since only Android can constantly monitor the activity-detection API in the background (iOS uses a "stationary geofence" to detect device-motion).  The desired time between activity detections. Larger values will result in fewer activity detections while improving battery life. A value of 0 will result in activity detections at the fastest possible rate.
  ///
  int activityRecognitionInterval;

  /// The minimum motion-activity confidence to conclude a device is moving.
  ///
  /// Defaults to **`75`%**.  Each activity-recognition-result returned by the API is tagged with a "confidence" level expressed as a %.  You can set your desired confidence to trigger a [BackgroundGeolocation.onMotionChange] event.
  ///
  /// This setting can be helpful for poor quality Android devices missing crucial motion sensors (accelerometer, gyroscope, magnetometer) by adjusting the confidence lower.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   minimumActivityRecognitionConfidence: 50 // <-- trigger less confidently.
  /// ));
  ///
  int minimumActivityRecognitionConfidence;

  /// Disable motion-activity related stop-detection.
  ///
  /// ## iOS
  /// ----------------------------------------------------
  ///
  /// Disables the accelerometer-based **Stop-detection System**.  When disabled, the plugin will use the default iOS behavior of automatically turning off location-services when the device has stopped for **exactly 15 minutes**.  When disabled, you will no longer have control over [stopTimeout].
  ///
  /// To *completely* disable automatically turning off iOS location-services, you must also provide [pausesLocationUpdatesAutomatically]:false.
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   disableStopDetection: true,
  ///   pausesLocationUpdatesAutomatically: false
  /// ));
  /// ```
  ///  **WARNING** iOS location-services will **never** turn off with the above configuration.  Do **not** do this unless you know *exactly* why you're doing (eg: A jogging app with `[Start workout]` / `[Stop Workout]` buttons).
  ///
  ///  **iOS Stop-detection timing**
  /// ![](https://dl.dropboxusercontent.com/s/ojjdfkmua15pskh/ios-stop-detection-timing.png?dl=1)
  ///
  /// ## Android
  /// ----------------------------------------------------
  ///
  /// Location-services **will never turn OFF** if you set this to **`true`**!  It will be purely up to you or the user to execute [BackgroundGeolocation.changePace]:false or [BackgroundGeolocation.stop] to turn off location-services.
  ///
  bool disableStopDetection;

  /// Automatically [BackgroundGeolocation.stop] when the [stopTimeout] elapses.
  ///
  /// The plugin can optionally automatically stop tracking when the [stopTimeout] timer elapses.  For example, when the plugin first fires [BackgroundGeolocation.onMotionChange] into the *moving* state, the next time an *onMotionChange* event occurs into the *stationary* state, the plugin will have automatically called [BackgroundGeolocation.stop] upon itself.
  ///
  /// **WARNING:** `stopOnStationary` will **only** occur due to [stopTimeout] timer elapse.  It will **not** occur by manually executing [BackgroundGeolocation.changePace]:false.
  ///
  /// ```dart
  /// BackgroundGeolocation.ready({
  ///   stopOnStationary: true,
  ///   isMoving: true
  /// }, function(state) {
  ///   BackgroundGeolocation.start();
  /// });
  /// ```
  ///
  bool stopOnStationary;

  /// Your server **`url`** where you wish to `POST` locations to.
  ///
  /// Both the iOS and Android native code host their own robust HTTP service which can automatically upload recorded locations to your server.  This is particularly important on **Android** when running "Headless" configured with [stopOnTerminate]:false, since only the plugin's background-service is running in this state.
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'https://my-server.com/locations',
  ///   params: {
  ///     "user_id": 1234
  ///   },
  ///   headers: {
  ///     "Authorization": "Basic my-secret-key"
  ///   },
  ///   autoSync: true,
  ///   httpMethod: 'POST'
  /// ));
  /// ```
  ///
  /// __See also:__ __HTTP Guide__ at [HttpEvent].
  ///
  /// __WARNING:__ It is highly recommended to let the plugin manage uploading locations to your server, **particularly for Android** when configured with **`stopOnTerminate: false`**, since your Cordova app (where your Javascript lives) *will* terminate &mdash; only the plugin's native Android background service will continue to operate, recording locations and uploading to your server.  The plugin's native HTTP service *is* better at this task than Javascript Ajax requests, since the plugin will automatically retry on server failure.
  String url;

  /// Allows you to specify which events to persist to the SDK's internal database:  locations | geofences | all (default).
  ///
  /// Note that all recorded location and geofence events will *always* be provided to your [BackgroundGeolocation.onLocation] and [BackgroundGeolocation.onGeofence] events, just that the
  /// persistence of those events in the SDK's internal SQLite database can be limited.  Any event which has not been persisted to the SDK's internal database
  /// will also **not** therefore be uploaded to your [url] (if configured).
  ///
  /// | Name                                 | Description                                             |
  /// |--------------------------------------|---------------------------------------------------------|
  /// | [PERSIST_MODE_ALL]                   | (__DEFAULT__) Persist both geofence and location events |
  /// | [PERSIST_MODE_LOCATION]              | Persist only location events (ignore geofence events)   |
  /// | [PERSIST_MODE_GEOFENCE]              | Persist only geofence events (ignore location events)   |
  /// | [PERSIST_MODE_NONE]                  | Persist nothing (neither geofence nor location events)  |
  ///
  int persistMode;

  /// The HTTP method to use when creating an HTTP request to your configured [url].
  ///
  /// Defaults to `POST`.  Valid values are `POST`, `PUT` and `OPTIONS`.
  ///
  /// ```dart
  /// BackgroundGeolocation.ready({
  ///   url: 'http://my-server.com/locations',
  ///   method: 'PUT'
  /// });
  /// ```
  ///
  String method;

  /// The root property of the JSON schema where location-data will be attached.
  ///
  ///  **Note:** See __HTTP Guide__ at [HttpEvent] for more information.
  ///
  /// __See also:__
  /// - [locationTemplate]
  /// - [geofenceTemplate]
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   httpRootProperty: "myData",
  ///   url: "https://my.server.com"
  /// ));
  ///
  /// ```
  ///
  /// ```json
  /// {
  ///     "myData":{
  ///         "coords": {
  ///             "latitude":23.232323,
  ///             "longitude":37.373737
  ///         }
  ///     }
  /// }
  /// ```
  ///
  /// You may also specify the character **`httpRootProperty:"."`** to place your data in the *root* of the JSON:
  ///
  /// ```json
  /// {
  ///     "coords": {
  ///         "latitude":23.232323,
  ///         "longitude":37.373737
  ///     }
  /// }
  /// ```
  ///
  String httpRootProperty;

  /// Optional HTTP **`params`** appended to the JSON body of each HTTP request.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'https://my-server.com/locations',
  ///   params: {
  ///     'user_id': 1234,
  ///     'device_id': 'abc123'
  ///   }
  /// );
  /// ```
  ///
  /// Observing the HTTP request arriving at your server:
  ///
  /// ```dart
  /// POST /locations
  ///  {
  ///   "location": {
  ///     "coords": {
  ///       "latitude": 45.51927004945047,
  ///       "longitude": -73.61650072045029
  ///       .
  ///       .
  ///       .
  ///     }
  ///   },
  ///   "user_id": 1234,  // <-- params appended to the data.
  ///   "device_id": 'abc123'
  /// }
  /// ```
  ///
  Map<String, dynamic> params;

  /// Optional HTTP headers applied to each HTTP request.
  ///
  /// ## Example
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'https://my.server.com',
  ///   headers: {
  ///     'authorization': "Bearer <a secret key>",
  ///     'X-FOO": "BAR'
  ///   }
  /// ));
  /// ```
  ///
  /// Observing incoming requests at your server:
  ///
  /// ```
  /// POST /locations
  /// {
  ///   "host": "tracker.transistorsoft.com",
  ///   "content-type": "application/json",
  ///   "content-length": "456"
  ///   .
  ///   .
  ///   .
  ///   "authorization": "Bearer <a secret key>",
  ///   "X-FOO": "BAR"
  /// }
  /// ```
  ///
  ///  **Note:**  The plugin automatically applies a number of required headers, including `"content-type": "application/json"`
  ///
  Map<String, dynamic> headers;

  /// Optional arbitrary key/values `{}` applied to each recorded location.
  ///
  ///  **Note:**  See [HttpEvent] for more information.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'https://my-server.com/locations',
  ///   extras: {
  ///     'route_id': 1234
  ///   },
  ///   params: {
  ///     'device_id': 'abc123'
  ///   }
  /// });
  /// ```
  ///
  /// Observing incoming requests at your server:
  ///
  /// ```dart
  /// - POST /locations
  /// {
  ///   "device_id": "abc123" // <-- params appended to root of JSON
  ///   "location": {
  ///     "coords": {
  ///       "latitude": 45.51927004945047,
  ///       "longitude": -73.61650072045029,
  ///       .
  ///       .
  ///       .
  ///     },
  ///     "extras": {  // <-- extras appended to *each* location
  ///       "route_id": 1234
  ///     }
  ///   }
  /// }
  /// ```
  ///
  Map<String, dynamic> extras;

  /// Immediately upload each recorded location to your configured [url].
  ///
  /// Default is `true`.  If you've enabled HTTP feature by configuring an [url], the plugin will attempt to HTTP POST each location to your server **as it is recorded**.  If you set [autoSync], it's up to you to **manually** execute the [BackgroundGeolocation.sync] method to initiate the HTTP POST.
  ///
  /// __Note:__ The plugin will continue to persist **every** recorded location in the SQLite database until you execute [BackgroundGeolocation.sync].
  ///
  /// __See also:__
  /// - [autoSyncThreshold]
  /// - [batchSync]
  /// - [maxBatchSize]
  ///
  bool autoSync;

  /// The minimum number of persisted records the plugin must accumulate before triggering an [autoSync] action.
  ///
  /// Defaults to `0` (no threshold).  If you configure a value greater-than **`0`**, the plugin will wait until that many locations are recorded before executing HTTP requests to your server through your configured [url].
  ///
  /// Configuring an `autoSyncThreshold` in conjunction with [batchSync]:true **can conserve battery** by reducing the number of HTTP requests, since HTTP requests consume *far* more energy / second than GPS.
  ///
  int autoSyncThreshold;

  /// POST multiple locations to your [url] in a single HTTP request.
  ///
  /// Default is **`false`**.  If you've enabled HTTP feature by configuring an [url], [batchSync]: true will POST *all* the locations currently stored in native SQLite database to your server in a single HTTP POST request.  With [batchSync]: false, an HTTP POST request will be initiated for **each** location in database.
  ///
  bool batchSync;

  /// Controls the number of records attached to **each** batch HTTP request.
  ///
  /// Defaults to `-1` (no maximum).  If you've enabled HTTP feature by configuring an [url] with [batchSync]: true, this parameter will limit the number of records attached to **each** batch request.  If the current number of records exceeds the **`maxBatchSize`**, multiple HTTP requests will be generated until the location queue is empty.
  ///
  /// The plugin can potentially accumulate mega-bytes worth of location-data if operating in a disconnected environment for long periods.  You will not want to [batchSync]:true a large amount of data in a single HTTP request.
  ///
  int maxBatchSize;

  /// Optional custom template for rendering `location` JSON request data in HTTP requests.
  ///
  /// The `locationTemplate` will be evaluated for variables using Ruby `erb`-style tags:
  ///
  /// ```erb
  /// <%= variable_name %>
  /// ```
  ///
  ///  **See also:**
  /// - __HTTP Guide__ at [HttpEvent].
  /// - [geofenceTemplate]
  /// - [httpRootProperty]
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '{"lat":<%= latitude %>,"lng":<%= longitude %>,"event":"<%= event %>",isMoving:<%= isMoving %>}'
  /// ));
  ///
  /// // Or use a compact [Array] template!
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '[<%=latitude%>, <%=longitude%>, "<%=event%>", <%=is_moving%>]'
  /// ))
  /// ```
  ///
  ///  ## Warning:  quoting `String` data.
  ///
  /// The plugin does not automatically apply double-quotes around `String` data.  The plugin will attempt to JSON encode your template exactly as you're configured.
  ///
  /// The following will generate an error:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '{"timestamp": <%= timestamp %>}'
  /// ));
  /// ```
  ///
  /// Since the template-tag `timestamp` renders a string, the rendered String will look like this:
  ///
  /// ```json
  /// {"timestamp": 2018-01-01T12:01:01.123Z}
  /// ```
  ///
  /// The correct `locationTemplate` is:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '{"timestamp": "<%= timestamp %>"}'
  /// ));
  /// ```
  ///
  /// ```json
  /// {"timestamp": "2018-01-01T12:01:01.123Z"}
  /// ```
  ///
  /// ## Configured [extras]:
  ///
  /// If you've configured [extras], these key-value pairs will be merged *directly* onto your location data.  For example:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   httpRootProperty: 'data',
  ///   locationTemplate: '{"lat":<%= latitude %>,"lng":<%= longitude %>}',
  ///   extras: {
  ///     "foo": "bar"
  ///   }
  /// )
  /// ```
  ///
  /// Will result in JSON:
  /// ```json
  /// {
  ///     "data": {
  ///         "lat":23.23232323,
  ///         "lng":37.37373737,
  ///         "foo":"bar"
  ///     }
  /// }
  /// ```
  ///
  /// ## Template Tags
  ///
  /// | Tag                   | Type     | Description |
  /// |-----------------------|----------|-------------|
  /// | `latitude`            | `Float`  |             |
  /// | `longitude`           | `Float`  |             |
  /// | `speed`               | `Float`  | Meters      |
  /// | `heading`             | `Float`  | Degrees     |
  /// | `accuracy`            | `Float`  | Meters      |
  /// | `altitude`            | `Float`  | Meters      |
  /// | `altitude_accuracy`   | `Float`  | Meters      |
  /// | `timestamp`           | `String` |ISO-8601     |
  /// | `uuid`                | `String` |Unique ID    |
  /// | `event`               | `String` |`motionchange,geofence,heartbeat,providerchange` |
  /// | `odometer`            | `Float`  | Meters      |
  /// | `activity.type`       | `String` | `still,on_foot,running,on_bicycle,in_vehicle,unknown`|
  /// | `activity.confidence` | `Integer`| 0-100%      |
  /// | `battery.level`       | `Float`  | 0-100%      |
  /// | `battery.is_charging` | `Boolean`| Is device plugged in?|
  ///
  String locationTemplate;

  /// Optional custom template for rendering `geofence` JSON request data in HTTP requests.
  ///
  /// The `geofenceTemplate` is similar to [locationTemplate] with the addition of two extra `geofence.*` tags.
  ///
  /// The `geofenceTemplate` will be evaluated for variables using Ruby `erb`-style tags:
  ///
  /// ```erb
  /// <%= variable_name %>
  /// ```
  ///
  ///  **See also:**
  /// - [HttpEvent]
  /// - [locationTemplate]
  /// - [httpRootProperty]
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   geofenceTemplate: '{ "lat":<%= latitude %>, "lng":<%= longitude %>, "geofence":"<%= geofence.identifier %>:<%= geofence.action %>" }'
  /// ));
  ///
  /// // Or use a compact [Array] template!
  /// BackgroundGeolocation.Config((
  ///   geofenceTemplate: '[<%= latitude %>, <%= longitude %>, "<%= geofence.identifier %>", "<%= geofence.action %>"]'
  /// )
  /// ```
  ///
  /// ## Warning:  quoting `String` data.
  ///
  /// The plugin does not automatically apply double-quotes around `String` data.  The plugin will attempt to JSON encode your template exactly as you're configured.
  ///
  /// The following will generate an error:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '{"timestamp": <%= timestamp %>}'
  /// ));
  /// ```
  ///
  /// Since the template-tag `timestamp` renders a string, the rendered String will look like this:
  ///
  /// ```json
  /// {"timestamp": 2018-01-01T12:01:01.123Z}
  /// ```
  ///
  /// The correct `locationTemplate` is:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationTemplate: '{"timestamp": "<%= timestamp %>"}'
  /// ));
  /// ```
  ///
  /// ```json
  /// {"timestamp": "2018-01-01T12:01:01.123Z"}
  /// ```
  ///
  /// ## Template Tags
  ///
  /// The tag-list is identical to [locationTemplate] with the addition of `geofence.identifier` and `geofence.action`.
  ///
  /// | Tag                   | Type     | Description |
  /// |-----------------------|----------|-------------|
  /// | **`geofence.identifier`** | `String` | Which geofence?|
  /// | **`geofence.action`** | `String` | `ENTER/EXIT`|
  /// | `latitude`            | `Float`  |             |
  /// | `longitude`           | `Float`  |             |
  /// | `speed`               | `Float`  | Meters      |
  /// | `heading`             | `Float`  | Degrees     |
  /// | `accuracy`            | `Float`  | Meters      |
  /// | `altitude`            | `Float`  | Meters      |
  /// | `altitude_accuracy`   | `Float`  | Meters      |
  /// | `timestamp`           | `String` |ISO-8601     |
  /// | `uuid`                | `String` |Unique ID    |
  /// | `event`               | `String` |`motionchange,geofence,heartbeat,providerchange` |
  /// | `odometer`            | `Float`  | Meters      |
  /// | `activity.type`       | `String` | `still,on_foot,running,on_bicycle,in_vehicle,unknown`|
  /// | `activity.confidence` | `Integer`| 0-100%      |
  /// | `battery.level`       | `Float`  | 0-100%      |
  /// | `battery.is_charging` | `Boolean`| Is device plugged in?|
  ///
  String geofenceTemplate;

  /// Maximum number of days to store a geolocation in plugin's SQLite database.
  ///
  /// When your server fails to respond with **`HTTP 200 OK`**, the plugin will continue periodically attempting to upload to your server server until **`maxDaysToPersist`** when it will give up and remove the location from the database.
  ///
  int maxDaysToPersist;

  /// Maximum number of records to persist in plugin's SQLite database.
  ///
  /// Default `-1` means **no limit**.
  ///
  int maxRecordsToPersist;

  /// Controls the order that locations are selected from the database (and uploaded to your server).
  ///
  /// Defaults to ascending (`ASC`), where oldest locations are synced first.  Descending (`DESC`) uploads latest locations first.
  ///
  String locationsOrderDirection;

  /// HTTP request timeout in **milliseconds**.
  ///
  /// HTTP request timeouts will fire the [BackgroundGeolocation.onHttp].  Defaults to `60000 ms`.
  ///
  /// ```dart
  /// BackgroundGeolocation.onHttp((HttpEvent response) {
  ///   bool success = response.success;
  ///   if (!success) {
  ///     print('[onHttp] FAILURE: $response');
  ///   }
  /// });
  ///
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'https://my-server.com/locations',
  ///   httpTimeout: 3000
  /// );
  /// ```
  ///
  int httpTimeout;

  /// Controls whether to continue location-tracking after application is **terminated**.
  ///
  /// Defaults to **`true`**.  When the user terminates the app, the plugin will [BackgroundGeolocation.stop] tracking.  Set this to **`false`** to continue tracking after application terminate.
  ///
  /// If you *do* configure **`stopOnTerminate: false`**, your Flutter application **will** terminate at that time.  However, both Android and iOS differ in their behavior *after* this point:
  ///
  /// ## iOS
  ///
  /// Before an iOS app terminates, the plugin will ensure that a **stationary geofence** of [stationaryRadius] meters is created around the last known position.  When the user moves beyond the stationary geofence (typically ~200 meters), iOS will completely reboot your application in the background, including your Flutter application and the plugin will resume tracking.  iOS maintains geofence monitoring at the OS level, in spite of application terminate / device reboot.
  ///
  /// In the following image, imagine the user terminated the application at the **"red circle"** on the right then continued moving:  Once the device moves by about 200 meters, exiting the "stationary geofence", iOS reboots the app and tracking resumes.
  ///
  ///  **Note:** [Demo Video of `stopOnTerminate: false`](https://www.youtube.com/watch?v=aR6r8qV1TI8&t=214s)
  ///
  /// ![](https://dl.dropboxusercontent.com/s/1uip231l3gds68z/screenshot-stopOnTerminate-ios.png?dl=0)
  ///
  /// ## Android
  ///
  /// Unlike iOS, the Android plugin's tracking will **not** pause at all when user terminates the app.  However, only the plugin's native background service continues to operate, **"headless"** (in this case, you should configure an [url] in order for the background-service to continue uploading locations to your server).
  ///
  ///  **See also:**
  /// - [Android Headless Mode](https://github.com/transistorsoft/flutter_background_geolocation/wiki/Android-Headless-Mode)
  /// - [enableHeadless]
  ///
  bool stopOnTerminate;

  /// Controls whether to resume location-tracking after device is **rebooted**.
  ///
  /// Defaults to **`false`**.  Set **`true`** to engage background-tracking after the device reboots.
  ///
  /// ## iOS
  ///
  /// iOS cannot **immediately** engage tracking after a device reboot.  Just like [stopOnTerminate]:false, iOS will not re-boot your app until the device moves beyond the **stationary geofence** around the last known location.  In addition, iOS subscribes to "background-fetch" events, which typically fire about every 15 minutes &mdash; these too are capable of rebooting your app after a device reboot.
  ///
  /// ## Android
  ///
  /// Android will reboot the plugin's background-service *immediately* after device reboot.  However, just like [stopOnTerminate]:false, the plugin will be running "headless" without your Application code.  If you wish for your Flutter Application to boot as well, you may configure any of the following **`forceReloadOnXXX`** options:
  /// - [forceReloadOnLocationChange]
  /// - [forceReloadOnMotionChange]
  /// - [forceReloadOnGeofence]
  /// - [forceReloadOnBoot]
  /// - [forceReloadOnHeartbeat]
  ///
  ///  **See also:** [enableHeadless]
  ///
  bool startOnBoot;

  /// Controls the rate (in seconds) the [BackgroundGeolocation.onHeartbeat] event will fire.
  ///
  ///  **WARNING:**
  /// - On **iOS** the **`heartbeat`** event will fire only when configured with [preventSuspend]: true.
  /// - Android *minimum* interval is `60` seconds.  It is **impossible** to have a `heartbeatInterval` faster than this on Android.
  ///
  ///  **See also:** [BackgroundGeolocation.onHeartbeat]
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   heartbeatInterval: 60
  /// ));
  ///
  /// BackgroundGeolocation.onHeartbeat((HeartbeatEvent event) {
  ///   print('[onHeartbeat] $event');
  ///
  ///   // You could request a new location if you wish.
  ///   BackgroundGeolocation.getCurrentPosition(
  ///     samples: 1,
  ///     persist: true
  ///   ).then((Location location) {
  ///     print('[getCurrentPosition] $location');
  ///   });
  /// })
  ///
  int heartbeatInterval;

  /// Configures an automated, cron-like schedule for the plugin to [BackgroundGeolocation.start] / [BackgroundGeolocation.stop] tracking at pre-defined times.
  ///
  /// ```dart
  ///   "{DAY(s)} {START_TIME}-{END_TIME}"
  /// ```
  ///
  /// - The `START_TIME`, `END_TIME` are in **24h format**.
  /// - The `DAY` param corresponds to the `Locale.US`, such that **Sunday=1**; **Saturday=7**).
  /// - You may configure a single day (eg: `1`), a comma-separated list-of-days (eg: `2,4,6`) or a range (eg: `2-6`)
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   .
  ///   .
  ///   .
  ///   schedule: [
  ///     '1 17:30-21:00',    // Sunday: 5:30pm-9:00pm
  ///     '2-6 9:00-17:00',   // Mon-Fri: 9:00am to 5:00pm
  ///     '2,4,6 20:00-00:00',// Mon, Web, Fri: 8pm to midnight (next day)
  ///     '7 10:00-19:00'     // Sat: 10am-7pm
  ///   ]
  /// )).then((State state) {
  ///   // Start the Scheduler
  ///   BackgroundGeolocation.startSchedule();
  /// });
  ///
  /// // Listen to #onSchedule events:
  /// BackgroundGeolocation.onSchedule((State state) {
  ///   bool enabled = state.enabled;
  ///   print('[onSchedule] - enabled? $enabled');
  /// });
  /// .
  /// .
  /// .
  /// // Later when you want to stop the Scheduler (eg: user logout)
  /// BackgroundGeolocation.stopSchedule();
  /// // You must explicitly stop tracking if currently enabled
  /// BackgroundGeolocation.stop();
  ///
  /// // Or modify the schedule with usual #setConfig method
  /// BackgroundGeolocation.setConfig(Config(
  ///   schedule: [
  ///     '1-7 9:00-10:00',
  ///     '1-7 11:00-12:00',
  ///     '1-7 13:00-14:00',
  ///     '1-7 15:00-16:00',
  ///     '1-7 17:00-18:00',
  ///     '2,4,6 19:00-22:00'
  ///   ]
  /// ));
  /// ```
  ///
  /// ## Literal Dates
  ///
  /// The schedule can also be configured with a literal start date of the form:
  ///
  /// ```
  ///   "yyyy-mm-dd HH:mm-HH:mm"
  /// ```
  ///
  /// eg:
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   schedule: [
  ///     "2018-01-01 09:00-17:00"
  ///   ]
  /// ));
  /// ```
  ///
  /// Or **two** literal dates to specify both a start **and** stop date (note the format here is a bit ugly):
  ///
  /// ```
  ///   "yyyy-mm-dd-HH:mm yyyy-mm-dd-HH:mm"
  /// ```
  ///
  /// ```dart
  /// schedule: [
  ///     "2018-01-01-09:00 2019-01-01-17:00"  // <-- track for 1 year
  ///   ]
  /// ```
  ///
  /// ## Scheduling Geofences-only or Location + Geofences Tracking
  ///
  /// You can choose to schedule either geofences-only (ie: [BackgroundGeolocation.startGeofences] or location + geofences (ie: [BackgroundGeolocation.start]) tracking with each configured schedule by appending the text `geofence` or `location` (default):
  ///
  /// In the following schedule, the SDK will engage *location + geofences* tracking between 9am to 5pm.  From 6pm to midnight, only *geofences* will be monitored.
  ///
  /// ```dart
  /// schedule: [
  ///   "1-7 09:00-17:00 location",
  ///   "1-7 18:00-12:00 geofence"
  /// ]
  /// ```
  ///
  /// Since `location` is the default tracking-mode, it can be omitted:
  ///
  /// ```dart
  /// schedule: [
  ///   "1-7 09:00-10:00",  // <-- location is default
  ///   "1-7 10:00-11:00 geofence"
  ///   "1-7 12:00-13:00",
  ///   "1-7 13:00-14:00 geofence"
  /// ```
  ///
  /// ## iOS
  ///
  /// iOS **cannot** evaluate the Schedule at the *exact* time you configure -- it can only evaluate the **`schedule`** *periodically*, whenever your app comes alive.
  ///
  /// When the app is running in a scheduled **off** period, iOS will continue to monitor the low-power, [significant location changes API (SLC)](https://developer.apple.com/reference/corelocation/cllocationmanager/1423531-startmonitoringsignificantlocati?language=objc) in order to ensure periodic schedule evaluation.  **SLC** is required in order guarantee periodic schedule-evaluation when you're configured [stopOnTerminate]:false, since the iOS Background Fetch API is halted if user *manually* terminates the app.  **SLC** will awaken your app whenever a "significant location change" occurs, typically every `1000` meters.  If the `schedule` is currently in an **off** period, this location will **not** be persisted nor will it be sent to the [BackgroundGeolocation.onLocation] event -- only the **`schedule`** will be evaluated.
  ///
  /// When a **`schedule`** is provided on iOS, it will be evaluated in the following cases:
  ///
  /// - Application `pause` / `resume` events.
  /// - Whenever a location is recorded (including **SLC**)
  /// - Background fetch event
  ///
  /// ## Android
  ///
  /// The Android Scheduler uses [`AlarmManager`](https://developer.android.com/reference/android/app/AlarmManager#setExactAndAllowWhileIdle(int,%20long,%20android.app.PendingIntent)) and *typically* operates on-the-minute.
  ///
  List<String> schedule;

  /// Configure the plugin to emit sound effects and local-notifications during development.
  ///
  /// Defaults to **`false`**.  When set to **`true`**, the plugin will emit debugging sounds and notifications for life-cycle events of [BackgroundGeolocation].
  ///
  /// ## iOS
  ///
  /// In you wish to hear debug sounds in the background, you must manually enable the background-mode:
  ///
  /// **`[x] Audio and Airplay`** background mode in *Background Capabilities* of XCode.
  ///
  /// ![](https://dl.dropboxusercontent.com/s/fl7exx3g8whot9f/enable-background-audio.png?dl=1)\
  ///
  ///  **See also:** [Debugging Sounds](https://github.com/transistorsoft/flutter_background_geolocation/wiki/Debug-Sounds)
  ///
  bool debug;

  /// Controls the volume of recorded events in the plugin's logging database.
  ///
  /// [BackgroundGeolocation] contains powerful logging features.  By default, the plugin boots with a value of [Config.LOG_LEVEL_VERBOSE], storing [Config.logMaxDays] (default `3`) days worth of logs in its SQLite database.
  ///
  /// The following log-levels are defined as **constants** on this [Config] class:
  ///
  /// | Label                      |
  /// |----------------------------|
  /// | [Config.LOG_LEVEL_OFF]     |
  /// | [Config.LOG_LEVEL_ERROR]   |
  /// | [Config.LOG_LEVEL_WARNING] |
  /// | [Config.LOG_LEVEL_INFO]    |
  /// | [Config.LOG_LEVEL_DEBUG]   |
  /// | [Config.LOG_LEVEL_VERBOSE] |
  ///
  /// ## Example log data:
  ///
  ///```
  /// 09-19 11:12:18.716 ╔═════════════════════════════════════════════
  /// 09-19 11:12:18.716 ║ BackgroundGeolocation Service started
  /// 09-19 11:12:18.716 ╠═════════════════════════════════════════════
  /// 09-19 11:12:18.723 [c.t.l.BackgroundGeolocationService d]
  /// 09-19 11:12:18.723   ✅  Started in foreground
  /// 09-19 11:12:18.737 [c.t.l.ActivityRecognitionService a]
  /// 09-19 11:12:18.737   🎾  Start activity updates: 10000
  /// 09-19 11:12:18.761 [c.t.l.BackgroundGeolocationService k]
  /// 09-19 11:12:18.761   🔴  Stop heartbeat
  /// 09-19 11:12:18.768 [c.t.l.BackgroundGeolocationService a]
  /// 09-19 11:12:18.768   🎾  Start heartbeat (60)
  /// 09-19 11:12:18.778 [c.t.l.BackgroundGeolocationService a]
  /// 09-19 11:12:18.778   🔵  setPace: null → false
  /// 09-19 11:12:18.781 [c.t.l.adapter.TSConfig c] ℹ️   Persist config
  /// 09-19 11:12:18.794 [c.t.locationmanager.util.b a]
  /// 09-19 11:12:18.794   ℹ️  LocationAuthorization: Permission granted
  /// 09-19 11:12:18.842 [c.t.l.http.HttpService flush]
  /// 09-19 11:12:18.842 ╔═════════════════════════════════════════════
  /// 09-19 11:12:18.842 ║ HTTP Service
  /// 09-19 11:12:18.842 ╠═════════════════════════════════════════════
  /// 09-19 11:12:19.000 [c.t.l.BackgroundGeolocationService onActivityRecognitionResult] still (100%)
  /// 09-19 11:12:21.314 [c.t.l.l.SingleLocationRequest$2 onLocationResult]
  /// 09-19 11:12:21.314 ╔═════════════════════════════════════════════
  /// 09-19 11:12:21.314 ║ SingleLocationRequest: 1
  /// 09-19 11:12:21.314 ╠═════════════════════════════════════════════
  /// 09-19 11:12:21.314 ╟─ 📍  Location[fused 45.519239,-73.617058 hAcc=15]999923706055 vAcc=2 sAcc=??? bAcc=???
  /// 09-19 11:12:21.327 [c.t.l.l.TSLocationManager onSingleLocationResult]
  /// 09-19 11:12:21.327   🔵  Acquired motionchange position, isMoving: false
  /// 09-19 11:12:21.342 [c.t.l.l.TSLocationManager a] 15.243
  /// 09-19 11:12:21.405 [c.t.locationmanager.data.a.c persist]
  /// 09-19 11:12:21.405   ✅  INSERT: bca5acc8-e358-4d8f-827f-b8c0d556b7bb
  /// 09-19 11:12:21.423 [c.t.l.http.HttpService flush]
  /// 09-19 11:12:21.423 ╔═════════════════════════════════════════════
  /// 09-19 11:12:21.423 ║ HTTP Service
  /// 09-19 11:12:21.423 ╠═════════════════════════════════════════════
  /// 09-19 11:12:21.446 [c.t.locationmanager.data.a.c first]
  /// 09-19 11:12:21.446   ✅  Locked 1 records
  /// 09-19 11:12:21.454 [c.t.l.http.HttpService a]
  /// 09-19 11:12:21.454   🔵  HTTP POST: bca5acc8-e358-4d8f-827f-b8c0d556b7bb
  /// 09-19 11:12:22.083 [c.t.l.http.HttpService$a onResponse]
  /// 09-19 11:12:22.083   🔵  Response: 200
  /// 09-19 11:12:22.100 [c.t.locationmanager.data.a.c destroy]
  /// 09-19 11:12:22.100   ✅  DESTROY: bca5acc8-e358-4d8f-827f-b8c0d556b7bb
  /// 09-19 11:12:55.226 [c.t.l.BackgroundGeolocationService onActivityRecognitionResult] still (100%)
  ///```
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   logLevel: BackgroundGeolocation.LOG_LEVEL_VERBOSE
  /// });
  /// ```
  ///
  ///  **See also:**
  /// - [BackgroundGeolocation.log]
  /// - [BackgroundGeolocation.emailLog]
  /// - [logMaxDays]
  ///
  ///  **WARNING:**  When submitting your app to production, take care to configure the **`logLevel`** appropriately (eg: **`LOG_LEVEL_ERROR`**) since the logs can grow to several megabytes over a period of [logMaxDays].
  ///
  int logLevel;

  /// Maximum number of days to persist a log-entry in database.
  ///
  /// Defaults to **`3`** days.
  ///
  ///  **See also:**
  /// - [logLevel]
  ///
  int logMaxDays;

  /// Forces [BackgroundGeolocation.ready] to apply supplied [Config] with each application launch.
  ///
  /// Optionally, you can specify **`reset: true`** to [BackgroundGeolocation.ready].  This will essentially *force* the supplied [Config] to be applied with each launch of your application.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready({
  ///   reset: true,  // <-- set true to ALWAYS apply supplied config; not just at first launch.
  ///   distanceFilter: 50
  /// }, (state) => {
  ///   console.log('Ready with reset: true: ', state.distanceFilter);
  /// });
  /// ```
  ///
  bool reset;

  //
  // iOS Options
  //

  // Geolocation Options

  /// __`[iOS only]`__ Configure iOS location API to *never* automatically turn off.
  ///
  ///  **WARNING:** This option should generally be left `undefined`.  You should only specify this option if you know *exactly* what you're doing.
  ///
  /// The default behavior of the plugin is to turn **off** location-services *automatically* when the device is detected to be stationary for [stopTimeout] minutes.  When set to `false`, location-services will **never** be turned off (and [disableStopDetection] will automatically be set to `true`) -- it's your responsibility to turn them off when you no longer need to track the device.  This feature should **not** generally be used.  [preventSuspend] will no longer work either.
  ///
  bool pausesLocationUpdatesAutomatically;

  /// __`[iOS only]`__ Defines the *desired* iOS location-authorization request you *wish* for the user to authorize.
  ///
  /// **`locationAuthorizationRequest`** tells the plugin the mode it *expects* to have been authorized with *by the user*.  If the user changes this mode in their settings, the plugin will detect this (See [locationAuthorizationAlert]).  Defaults to **`Always`**.  **`WhenInUse`** will display a **blue bar** at top-of-screen informing user that location-services are on.
  ///
  /// ![](https://dl.dropboxusercontent.com/s/88y3i4nkqq3o9ee/ios-location-authorization-dialog.png?dl=1)
  ///
  /// If you configure **`Any`**, the plugin allow the user to choose either `Always` or `WhenInUse`.   The plugin will **not** show the [locationAuthorizationAlert] dialog when the user changes the selection in `Privacy->Location Services`.
  ///
  ///  **WARNING:**  Configuring **`WhenInUse`** will disable many of the plugin's features, since iOS forbids any API which operates in the background to operate (such as **geofences**, which the plugin relies upon to automatically engage background tracking).
  ///
  String locationAuthorizationRequest;

  /// __`[iOS only]`__ Controls the text-elements of the plugin's location-authorization dialog.
  ///
  /// When you configure the plugin [locationAuthorizationRequest] `Always` or `WhenInUse` and the user *changes* the mode in the app's location-services settings or disabled location-services, the plugin will display an Alert dialog directing the user to the **Settings** screen.  **`locationAuthorizationAlert`** allows you to configure all the Strings for that Alert popup and accepts an `Map` containing the following keys:
  ///
  /// __WARNING:__ If you choose to configure `locationAuthorizationAlert`, you must provide **ALL** the following options -- not just *some*.
  ///
  /// ##### `@config {String} titleWhenOff [Location services are off]`  The title of the alert if user changes, for example, the location-request to `WhenInUse` when you requested `Always`.
  ///
  /// ##### `@config {String} titleWhenNotEnabled [Background location is not enabled]`  The title of the alert when user disables location-services or changes the authorization request to `Never`
  ///
  /// ##### `@config {String} instructions [To use background location, you must enable {locationAuthorizationRequest} in the Location Services settings]`  The body text of the alert.
  ///
  /// ##### `@config {String} cancelButton [Cancel]` Cancel button label
  ///
  /// ##### `@config {String} settingsButton [Settings]` Settings button label
  ///
  /// ![](s/wyoaf16buwsw7ed/docs-locationAuthorizationAlert.jpg?dl=1)
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   locationAuthorizationAlert: {
  ///     'titleWhenNotEnabled': 'Yo, location-services not enabled',
  ///     'titleWhenOff': 'Yo, location-services OFF',
  ///     'instructions': 'You must enable 'Always' in location-services, buddy',
  ///     'cancelButton': 'Cancel',
  ///     'settingsButton': 'Settings'
  ///   }
  /// })
  /// ```
  ///
  Map<String, dynamic> locationAuthorizationAlert;

  /// Disables automatic authorization alert when plugin detects the user has disabled location authorization.
  ///
  /// You will be responsible for handling disabled location authorization by listening to the [BackgroundGeolocation.onProviderChange] event.
  ///
  /// By default, the plugin automatically shows a native alert (configured via [locationAuthorizationAlert] and [locationAuthorizationRequest] to the user when location-services are disabled, directing them to the settings screen.  If you **do not** desire this automated behavior, set `disableLocationAuthorizationAlert: true`.
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.onProviderChange((ProviderChangeEvent event) {
  ///   print('[onProviderChange] $event');
  ///
  ///   if (!provider.enabled) {
  ///     alert('Please enable location services');
  ///   }
  /// });
  ///
  /// BackgroundGeolocation.ready(Config(
  ///   disableLocationAuthorizationAlert: true
  /// ));
  /// ```
  ///
  bool disableLocationAuthorizationAlert;

  // Activity Recognition Options

  /// __`[iOS only]`__ Presumably, this affects iOS stop-detect algorithm.  Apple is vague about what exactly this option does.
  ///
  /// Available values are defined as constants upon this [Config] class.
  ///
  /// | Name                                          |
  /// |-----------------------------------------------|
  /// | [Config.ACTIVITY_TYPE_OTHER]                  |
  /// | [Config.ACTIVITY_TYPE_AUTOMOTIVE_NAVIGATION]  |
  /// | [Config.ACTIVITY_TYPE_FITNESS]                |
  /// | [Config.ACTIVITY_TYPE_OTHER_NAVIGATION]       |
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   activityType: Config.ACTIVITY_TYPE_OTHER
  /// );
  /// ```
  ///
  ///  **Note:**  For more information, see [Apple docs](https://developer.apple.com/reference/corelocation/cllocationmanager/1620567-activitytype?language=objc).
  ///
  int activityType;

  /// __`[iOS only]`__ Allows the iOS stop-detection system to be delayed from activating.
  ///
  /// Defaults to **`0`** (no delay).  Allows the stop-detection system to be delayed from activating.  When the stop-detection system *is* engaged, location-services will be temporarily turned **off** and only the accelerometer is monitored.  Stop-detection will only engage if this timer expires.  The timer is canceled if any movement is detected before expiration.  If a value of **`0`** is specified, the stop-detection system will engage as soon as the device is detected to be stationary.
  ///
  /// You can experience the iOS stop-detection system at work by configuring [debug]:true.  After the device stops moving (stopped at a traffic light, for example), the plugin will emit sound-effects and local-notifications about "Location-services: OFF / ON".
  ///
  int stopDetectionDelay;

  /// __`[iOS only]`__ Disable the plugin requesting "Motion & Fitness" authorization from the User.
  ///
  /// Defaults to **`false`**.  Set **`true`** to disable iOS [`CMMotionActivityManager`](https://developer.apple.com/reference/coremotion/cmmotionactivitymanager)-based motion-activity updates (eg: `walking`, `in_vehicle`).  This feature requires a device having the **M7** co-processor (ie: iPhone 5s and up).
  ///
  ///  **Note:** This feature will ask the user for "Health updates" permission using the **`NSMotionUsageDescription`** in your `Info.plist`.  If you do not wish to ask the user for the "Health updates", set this option to `true`; However, you will no longer receive accurate activity data in the recorded locations.
  ///
  ///  **WARNING:** The plugin is **HIGHLY** optimized for motion-activity-updates.  If you **do** disable this, the plugin *will* drain more battery power.  You are **STRONGLY** advised against disabling this.  You should explain to your users with an appropriate `NSMotionUsageDescription` in your `Info.plist` file, for example:
  ///
  /// > "Motion activity detection increases battery efficiency by intelligently toggling location-tracking" off when your device is detected to be stationary.
  ///
  bool disableMotionActivityUpdates;

  // Application Options

  /// __`[iOS only]`__ Prevent iOS from suspending your application in the background after location-services have been switched off.
  ///
  /// Defaults to **`false`**.  Set **`true`** to prevent **iOS** from suspending your application after location-services have been switched off while running in the background.  Must be used in conjunction with a [heartbeatInterval].
  ///
  ///  **Note:** When a device is unplugged form power with the screen off, iOS will *still* throttle [BackgroundGeolocation.onHeartbeat] events about 2 minutes after entering the background state.  However, if the screen is lit up or even the *slightest* device-motion is detected, [BackgroundGeolocation.onHeartbeat] events will immediately resume.
  ///
  ///  **WARNING:** **`preventSuspend: true`** should **only** be used in **very** specific use-cases and should typically **not** be used as it *will* have a **very noticeable impact on battery performance.**  You should carefully manage **`preventSuspend`**, engaging it for controlled periods-of-time.  You should **not** expect to run your app in this mode 24 hours / day, 7 days-a-week.
  ///
  /// ## Exampler
  ///
  /// ```dart
  /// BackgroundGeolocation.onHeartbeat((HeartbeatEvent event) {
  ///   print('[onHeartbeat] $event');
  /// });
  ///
  /// BackgroundGeolocation.ready(Config(
  ///   preventSuspend: true,
  ///   heartbeatInterval: 60
  /// ));
  /// ```
  ///
  bool preventSuspend;

  //
  // Android Options
  //

  // Geolocation Options

  /// __`[Android only]`__ Set the desired interval for active location updates, in milliseconds.
  ///
  ///  **Note:** To use **`locationUpdateInterval`** you **must** also configure [distanceFilter]:0, since [distanceFilter] *overrides* **`locationUpdateInterval`**.
  ///
  /// Set the desired interval for active location updates, in milliseconds.
  ///
  /// The location client will actively try to obtain location updates for your application at this interval, so it has a direct influence on the amount of power used by your application. Choose your interval wisely.
  ///
  /// This interval is inexact. You may not receive updates at all (if no location sources are available), or you may receive them slower than requested. You may also receive them faster than requested (if other applications are requesting location at a faster interval).
  ///
  /// Applications with only the coarse location permission may have their interval silently throttled.\
  ///
  ///  **Note:** For more information, see the [Android docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#setInterval(long))
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready({
  ///   distanceFilter: 0,            // Must be 0 or locationUpdateInterval is ignored!
  ///   locationUpdateInterval: 5000  // Get a location every 5 seconds
  /// });
  /// ```
  ///
  int locationUpdateInterval;

  /// __`[Android only]`__ Explicitly set the fastest interval for location updates, in milliseconds.
  ///
  /// This controls the fastest rate at which your application will receive location updates, which might be faster than [locationUpdateInterval] in some situations (for example, if other applications are triggering location updates).
  ///
  /// This allows your application to passively acquire locations at a rate faster than it actively acquires locations, saving power.
  ///
  /// Unlike [locationUpdateInterval], this parameter is exact. Your application will never receive updates faster than this value.
  ///
  /// If you don't call this method, a fastest interval will be set to **30000 (30s)**.
  ///
  /// An interval of `0` is allowed, but **not recommended**, since location updates may be extremely fast on future implementations.
  ///
  /// If **`fastestLocationUpdateInterval`** is set slower than [locationUpdateInterval], then your effective fastest interval is [locationUpdateInterval].
  ///
  ///  **Note:** See [Android docs](https://developers.google.com/android/reference/com/google/android/gms/location/LocationRequest.html#setFastestInterval(long))
  ///
  int fastestLocationUpdateInterval;

  /// __`[Android only]`__ Sets the maximum wait time in milliseconds for location updates.
  ///
  /// Defaults to `0` (no defer).  If you pass a value at least 2x larger than the interval specified with [locationUpdateInterval], then location delivery may be delayed and multiple locations can be delivered at once. Locations are determined at the [locationUpdateInterval] rate, but can be delivered in batch after the interval you set in this method. This **can consume less battery** and **give more accurate locations**, depending on the device's hardware capabilities. You should set this value to be as large as possible for your needs if you don't need immediate location delivery.
  ///
  int deferTime;

  /// __`[Android only]`__ Allow recording locations which are duplicates of the previous.
  ///
  /// By default, the Android plugin will ignore a received location when it is *identical* to the previous location.  Set `true` to override this behavior and record *every* location, regardless if it is identical to the last location.
  ///
  /// In the logs, you will see a location being ignored:
  /// ```
  /// TSLocationManager:   ℹ️  IGNORED: same as last location
  /// ```
  ///
  /// An identical location is often generated when changing state from *stationary* -> *moving*, where a single location is first requested (the [BackgroundGeolocation.onMotionChange] location) before turning on regular location updates.  Changing geolocation config params can also generate a duplicate location (eg: changing [distanceFilter]).
  ///
  bool allowIdenticalLocations;

  /// __`[Android-only]`__ Enable extra timestamp meta data to be appended to each recorded location, including system-time.
  ///
  /// Some developers have reported GPS [Location.timestamp] issues with some Android devices.  This option will append extra meta-data related to the device's system time.
  ///
  /// ## Java implementation
  ///
  /// ```Java
  /// if (enableTimestampMeta) {
  ///     JSONObject timestampMeta = new JSONObject();
  ///     timestampMeta.put("time", mLocation.getTime());
  ///     if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
  ///         timestampMeta.put("systemClockElaspsedRealtime", SystemClock.elapsedRealtimeNanos()/1000000);
  ///         timestampMeta.put("elapsedRealtime", mLocation.getElapsedRealtimeNanos()/1000000);
  ///     } else {
  ///         timestampMeta.put("systemTime", System.currentTimeMillis());
  ///     }
  ///     data.put("timestampMeta", timestampMeta);
  /// }
  /// ```
  ///
  bool enableTimestampMeta;

  /// Experimental filter to ignore anomalous locations that suddenly jump an unusual distance from last.
  /// The SDK will calculate an apparent speed and distance relative to last known location.  If the location suddenly
  /// teleports from last location, it will be ignored.
  ///
  /// __`Android-only`__ The measurement is in meters/second.  The default is to throw away any location which apparently moved at 300 meters/second from last known location.
  ///
  int speedJumpFilter;

  // Activity Recognition Options

  /// __`[Android-only]`__ Configures a comma-separated list of motion-activities which are allow to trigger location-tracking.
  ///
  /// These are the comma-delimited list of [activity-names](https://developers.google.com/android/reference/com/google/android/gms/location/DetectedActivity) returned by the `ActivityRecognition` API which will trigger a state-change from **stationary** to **moving**.  By default, the plugin will trigger on **any** of the **moving-states**:
  ///
  /// | Activity Name  |
  /// |----------------|
  /// | `in_vehicle`   |
  /// | `on_bicycle`   |
  /// | `on_foot`      |
  /// | `running`      |
  /// | `walking`      |
  ///
  ///
  /// If you wish, you can configure the plugin to only engage the **moving** state for vehicles-only by providing just `"in_vehicle"`, for example.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Only trigger tracking for vehicles
  /// BackgroundGeolocation.ready(Config(
  ///   triggerActivities: 'in_vehicle'
  /// );
  ///
  /// // Only trigger tracking for on_foot, walking and running
  /// BackgroundGeolocation.ready(Config(
  ///   triggerActivities: 'on_foot, walking, running'
  /// );
  /// ```
  ///
  String triggerActivities;

  // Application Options

  /// __`[Android only]`__ Enables "Headless" operation allowing you to respond to events after you app has been terminated with [stopOnTerminate]:false.
  ///
  /// Defaults to __`false`__.  In this Android terminated state, where only the plugin's foreground-service remains running, you can respond to all the plugin's events with your own Dart callback.
  ///
  /// __Note__:
  /// - Requires [stopOnTerminate]:false.
  /// - If you've configured [stopOnTerminate]:false, [BackgroundGeolocation] will continue to record locations (and post them to your configured [url]) *regardless of* __`enabledHeadless: true`__.  You should enable this option *only if* you have to perform some custom work during the headless state (for example, posting a local notification).
  /// - With __`enableHeadless: true`__, you **must** also register a `function` to be executed in headless-state with [BackgroundGeolocation.registerHeadlessTask].
  ///
  /// For more information, see:
  /// - [BackgroundGeolocation.registerHeadlessTask]
  /// - Wiki [Android Headless Mode](https://github.com/transistorsoft/flutter_background_geolocation/wiki/Android-Headless-Mode).
  ///
  /// ## Android Setup
  ///
  /// Create either `Application.kt` or `Application.java` in the same directory as `MainActivity`.
  ///
  /// For `Application.kt`, use the following:
  ///
  /// ```java
  /// import io.flutter.app.FlutterApplication;
  /// import io.flutter.plugin.common.PluginRegistry;
  /// import io.flutter.plugins.GeneratedPluginRegistrant;
  ///
  /// import com.transistorsoft.flutter.backgroundgeolocation.FLTBackgroundGeolocationPlugin;
  ///
  /// class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
  ///   override fun onCreate() {
  ///     super.onCreate();
  ///     FLTBackgroundGeolocationPlugin.setPluginRegistrant(this);
  ///   }
  ///
  ///   override fun registerWith(registry: PluginRegistry) {
  ///     GeneratedPluginRegistrant.registerWith(registry);
  ///   }
  /// }
  /// ```
  ///
  /// For `Application.java`, use the following:
  ///
  /// ```java
  /// import io.flutter.app.FlutterApplication;
  /// import io.flutter.plugin.common.PluginRegistry;
  /// import io.flutter.plugins.GeneratedPluginRegistrant;
  ///
  /// import com.transistorsoft.flutter.backgroundgeolocation.FLTBackgroundGeolocationPlugin;
  ///
  /// public class Application extends FlutterApplication implements PluginRegistry.PluginRegistrantCallback {
  ///   @Override
  ///   public void onCreate() {
  ///     super.onCreate();
  ///     FLTBackgroundGeolocationPlugin.setPluginRegistrant(this);
  ///   }
  ///
  ///   @Override
  ///   public void registerWith(PluginRegistry registry) {
  ///     GeneratedPluginRegistrant.registerWith(registry);
  ///   }
  /// }
  /// ```
  ///
  /// Which must also be referenced in `AndroidManifest.xml`:
  ///
  /// ```xml
  ///     <application
  ///         android:name=".Application"
  ///         ...
  /// ```
  ///
  /// Finally, in your `main.dart`, [BackgroundGeolocation.registerHeadlessTask]:
  ///
  /// ```dart
  /// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
  ///
  /// /// Receives all events from BackgroundGeolocation while app is terminated:
  /// void headlessTask(bg.HeadlessEvent headlessEvent) async {
  ///   print('[HeadlessTask]: $headlessEvent');
  ///
  ///   // Implement a `case` for only those events you're interested in.
  ///   switch(headlessEvent.name) {
  ///     case bg.Event.TERMINATE:
  ///       bg.State state = headlessEvent.event;
  ///       print('- State: $state');
  ///       break;
  ///     case bg.Event.HEARTBEAT:
  ///       bg.HeartbeatEvent event = headlessEvent.event;
  ///       print('- HeartbeatEvent: $event');
  ///       break;
  ///     case bg.Event.LOCATION:
  ///       bg.Location location = headlessEvent.event;
  ///       print('- Location: $location');
  ///       break;
  ///     case bg.Event.MOTIONCHANGE:
  ///       bg.Location location = headlessEvent.event;
  ///       print('- Location: $location');
  ///       break;
  ///     case bg.Event.GEOFENCE:
  ///       bg.GeofenceEvent geofenceEvent = headlessEvent.event;
  ///       print('- GeofenceEvent: $geofenceEvent');
  ///       break;
  ///     case bg.Event.GEOFENCESCHANGE:
  ///       bg.GeofencesChangeEvent event = headlessEvent.event;
  ///       print('- GeofencesChangeEvent: $event');
  ///       break;
  ///     case bg.Event.SCHEDULE:
  ///       bg.State state = headlessEvent.event;
  ///       print('- State: $state');
  ///       break;
  ///     case bg.Event.ACTIVITYCHANGE:
  ///       bg.ActivityChangeEvent event = headlessEvent.event;
  ///       print('ActivityChangeEvent: $event');
  ///       break;
  ///     case bg.Event.HTTP:
  ///       bg.HttpEvent response = headlessEvent.event;
  ///       print('HttpEvent: $response');
  ///       break;
  ///     case bg.Event.POWERSAVECHANGE:
  ///       bool enabled = headlessEvent.event;
  ///       print('ProviderChangeEvent: $enabled');
  ///       break;
  ///     case bg.Event.CONNECTIVITYCHANGE:
  ///       bg.ConnectivityChangeEvent event = headlessEvent.event;
  ///       print('ConnectivityChangeEvent: $event');
  ///       break;
  ///     case bg.Event.ENABLEDCHANGE:
  ///       bool enabled = headlessEvent.event;
  ///       print('EnabledChangeEvent: $enabled');
  ///       break;
  ///   }
  /// }
  ///
  /// void main() {
  ///   runApp(HelloWorld());
  ///
  ///   // Register your headlessTask:
  ///   BackgroundGeolocation.registerHeadlessTask(headlessTask);
  /// }
  /// ```
  ///
  bool enableHeadless;

  /// __`[Android only]`__ Configure the plugin service to run as a more robust "Foreground Service".
  ///
  /// ## Android 8.0+
  ///
  /// Defaults to `true` and cannot be set to `false`.  Due to strict new [Background Execution Limits](https://www.youtube.com/watch?v=Pumf_4yjTMc) in Android 8, the plugin *enforces* **`foregroundService: true`**.
  ///
  /// A persistent notification is required by the operating-system with a foreground-service.  It **cannot** be hidden.
  ///
  /// ## Android < 8.0
  ///
  /// Defaults to **`false`**.  When the Android OS is under memory pressure from other applications (eg: a phone call), the OS can and will free up memory by terminating other processes and scheduling them for re-launch when memory becomes available.  If you find your tracking being **terminated unexpectedly**, *this* is why.
  ///
  /// If you set this option to **`true`**, the plugin will run its Android service in the foreground, **supplying the ongoing notification to be shown to the user while in this state**.  Running as a foreground-service makes the tracking-service **much** more immune to OS killing it due to memory/battery pressure.  By default services are background, meaning that if the system needs to kill them to reclaim more memory (such as to display a large page in a web browser).
  ///
  ///  **Note:** See related config options:
  /// - [notificationTitle]
  /// - [notificationText]
  /// - [notificationColor]
  /// - [notificationPriority]
  /// - [notificationSmallIcon]
  /// - [notificationLargeIcon]
  ///
  /// :blue_book: For more information, see the [Android Service](https://developer.android.com/reference/android/app/Service.html#startForeground(int,%20android.app.Notification)) docs.
  ///
  bool foregroundService;

  /// Force launch your terminated App after a [BackgroundGeolocation.onLocation] event.
  ///
  /// When the user terminates your Android app with [BackgroundGeolocation] configured with [stopOnTerminate]:false, the foreground `MainActivity` (where your Flutter app lives) *will* terminate -- only the plugin's pure native background-service is running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnLocationChange;

  /// Force launch your terminated App after a [BackgroundGeolocation.onMotionChange] event.
  ///
  /// When the user terminates your Android app with [BackgroundGeolocation] configured with [stopOnTerminate]:false, the foreground `MainActivity` (where your Flutter app lives) *will* terminate -- only the plugin's pure native background-service is running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnMotionChange;

  /// Force launch your terminated App after a [BackgroundGeolocation.onGeofence] event.
  ///
  /// When the user terminates your Android app with [BackgroundGeolocation] configured with [stopOnTerminate]:false, the foreground `MainActivity` (where your Flutter app lives) *will* terminate -- only the plugin's pure native background-service is running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnGeofence;

  /// Force launch your terminated App after a device reboot.
  ///
  /// When the user reboots their device with [BackgroundGeolocation] configured with [startOnBoot]:true, only the plugin's pure native background-service begins running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnBoot;

  /// Force launch your terminated App after a [BackgroundGeolocation.onHeartbeat] event.
  ///
  /// When the user terminates your Android app with [BackgroundGeolocation] configured with [stopOnTerminate]:false, the foreground `MainActivity` (where your Flutter app lives) *will* terminate -- only the plugin's pure native background-service is running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnHeartbeat;

  /// Force launch your terminated App after a [BackgroundGeolocation.onSchedule] event.
  ///
  /// When the user terminates your Android app with [BackgroundGeolocation] configured with [stopOnTerminate]:false, the foreground `MainActivity` (where your Flutter app lives) *will* terminate -- only the plugin's pure native background-service is running, **"headless"**, in this case.  The background service will continue tracking the location.  However, the background service *can* optionally **re-launch** your foreground application.
  ///
  ///  **WARNING:** When the background service re-launches your application, it will *briefly* appear in the foreground before *immediately* minimizing.  If the user has their phone on at the time, they will see a brief flash of your app appearing and minimizing.
  ///
  bool forceReloadOnSchedule;

  /// When running the service with [foregroundService]: true, Android requires a persistent notification in the Notification Bar.  This will control the **priority** of that notification as well as the position of the notificaiton-bar icon.
  ///
  /// The following `notificationPriority` values defined as static constants upon the [Config] object:
  ///
  /// | Value                                  | Description                           |
  /// |----------------------------------------|---------------------------------------|
  /// | [Config.NOTIFICATION_PRIORITY_DEFAULT] | Notification weighted to top of list; notification-bar icon weighted left                                       |
  /// | [Config.NOTIFICATION_PRIORITY_HIGH]    | Notification **strongly** weighted to top of list; notification-bar icon **strongly** weighted to left          |
  /// | [Config.NOTIFICATION_PRIORITY_LOW]     | Notification weighted to bottom of list; notification-bar icon weighted right                                   |
  /// | [Config.NOTIFICATION_PRIORITY_MAX]     | Same as `NOTIFICATION_PRIORITY_HIGH`  |
  /// | [Config.NOTIFICATION_PRIORITY_MIN]     | Notification **strongly** weighted to bottom of list; notification-bar icon **hidden**                          |
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   foregroundService: true,
  ///   notificationPriority: Config.NOTIFICATION_PRIORITY_MIN
  /// ));
  /// ```
  ///
  int notificationPriority;

  /// Configure the *title* of the persistent notification in the Notification Bar when running with [foregroundService]:true
  ///
  /// Defaults to the application name from `AndroidManifest`.  When running the service with [foregroundService]: true, Android requires a persistent notification.  This will configure the **title** of that notification.
  ///
  String notificationTitle;

  /// Configure the *text* of the persistent notification in the Notification Bar when running with [foregroundService]:true
  ///
  /// Defaults to *"Location service activated"*.  When running the service with [foregroundService]: true, Android requires a persistent notification.  This will configure the **text** of that notification.
  ///
  String notificationText;

  /// Configure the *color* of the persistent notification icon in the Notification Bar when running with [foregroundService]:true
  ///
  /// Defaults to `null`.  When running the service with [foregroundService]: true, Android requires a persistent notification.  This will configure the **color** of the notification **icon** (API >= 21).
  ///
  /// Supported formats are:
  /// - `#RRGGBB`
  /// - `#AARRGGBB`
  ///
  String notificationColor;

  /// Configure the *small icon* of the persistent notification in the Notification Bar when running with [foregroundService]:true
  ///
  /// When running the service with [foregroundService]: true, Android requires a persistent notification in the Notification Bar.  This allows you customize that icon.  Defaults to your application icon.
  ///
  /// **NOTE** You must specify the **`type`** (`drawable|mipmap`) of resource you wish to use in the following format:
  ///
  /// `{type}/icon_name`,
  ///
  /// **WARNING:** Do not append the file-extension (eg: `.png`)
  ///
  /// ## Example
  ///
  /// ```dart
  /// // 1. drawable
  /// BackgroundGeolocation.ready(Config(
  ///   notificationSmallIcon: "drawable/my_custom_notification_small_icon"
  /// ));
  ///
  /// // 2. mipmap
  /// BackgroundGeolocation.ready(Config(
  ///   notificationSmallIcon: "mipmap/my_custom_notification_small_icon"
  /// ));
  /// ```
  ///
  String notificationSmallIcon;

  /// Configure the *large icon* of the persistent notification in the Notification Bar when running with [foregroundService]:true
  ///
  /// When running the service with [foregroundService]: true, Android requires a persistent notification in the Notification Bar.  This allows you customize that icon.  Defaults to your application icon.
  ///
  /// **NOTE** You must specify the **`type`** (`drawable|mipmap`) of resource you wish to use in the following format:
  ///
  /// `{type}/icon_name`,
  ///
  /// **WARNING:** Do not append the file-extension (eg: `.png`)
  ///
  /// ## Example
  ///
  /// ```dart
  /// // 1. drawable
  /// BackgroundGeolocation.ready(Config(
  ///   notificationSmallIcon: "drawable/my_custom_notification_small_icon"
  /// ));
  ///
  /// // 2. mipmap
  /// BackgroundGeolocation.ready(Config(
  ///   notificationSmallIcon: "mipmap/my_custom_notification_small_icon"
  /// ));
  /// ```
  ///
  String notificationLargeIcon;

  /// Configure the name of the plugin's notification-channel used to display the [foregroundService] notification.
  ///
  /// On Android O+, the plugin's foreground-service needs to create a "Notification Channel".  The name of this channel can be seen in Settings->App & Notifications->Your App.  Defaults to your application's name from `AndroidManifest`.
  ///
  /// ![](https://dl.dropboxusercontent.com/s/zgcxau7lyjfuaw9/android-notificationChannelName.png?dl=1)\
  ///
  /// ## Example
  ///
  /// ```dart
  /// BackgroundGeolocation.ready(Config(
  ///   notificationChannelName: "Location Tracker"
  /// ));
  ///
  /// // or with #setConfig
  /// BackgroundGeolocation.setConfig(Config(
  ///   notificationChannelName: "My new channel name"
  /// ));
  /// ```
  ///
  String notificationChannelName;

  Config(
      {
      // Geolocation Options
      this.desiredAccuracy,
      this.distanceFilter,
      this.stationaryRadius,
      this.locationTimeout,
      this.disableElasticity,
      this.elasticityMultiplier,
      this.stopAfterElapsedMinutes,
      this.geofenceProximityRadius,
      this.geofenceInitialTriggerEntry,
      this.desiredOdometerAccuracy,
      this.useSignificantChangesOnly,
      // ActivityRecognition
      this.isMoving,
      this.stopTimeout,
      this.activityRecognitionInterval,
      this.minimumActivityRecognitionConfidence,
      this.disableStopDetection,
      this.stopOnStationary,
      // HTTP & Persistence
      this.url,
      this.persistMode,
      this.method,
      this.httpRootProperty,
      this.params,
      this.headers,
      this.extras,
      this.autoSync,
      this.autoSyncThreshold,
      this.batchSync,
      this.maxBatchSize,
      this.locationTemplate,
      this.geofenceTemplate,
      this.maxDaysToPersist,
      this.maxRecordsToPersist,
      this.locationsOrderDirection,
      this.httpTimeout,
      // Application
      this.stopOnTerminate,
      this.startOnBoot,
      this.heartbeatInterval,
      this.schedule,
      // Logging & Debug
      this.debug,
      this.logLevel,
      this.logMaxDays,
      this.reset,

      ////
      // iOS Options
      //

      // Geolocation Options
      this.pausesLocationUpdatesAutomatically,
      this.locationAuthorizationRequest,
      this.locationAuthorizationAlert,
      this.disableLocationAuthorizationAlert,
      // Activity Recognition Options
      this.activityType,
      this.stopDetectionDelay,
      this.disableMotionActivityUpdates,
      // Application Options
      this.preventSuspend,

      ////
      // Android Options
      //

      // Geolocation Options
      this.locationUpdateInterval,
      this.fastestLocationUpdateInterval,
      this.deferTime,
      this.allowIdenticalLocations,
      this.enableTimestampMeta,
      this.speedJumpFilter,
      this.geofenceModeHighAccuracy,
      // Activity Recognition Options
      this.triggerActivities,
      // Application Options
      this.enableHeadless,
      this.foregroundService,
      this.forceReloadOnLocationChange,
      this.forceReloadOnMotionChange,
      this.forceReloadOnGeofence,
      this.forceReloadOnBoot,
      this.forceReloadOnHeartbeat,
      this.forceReloadOnSchedule,
      this.notificationPriority,
      this.notificationTitle,
      this.notificationText,
      this.notificationColor,
      this.notificationSmallIcon,
      this.notificationLargeIcon,
      this.notificationChannelName});

  Config set(String key, dynamic value) {
    if (_map == null) {
      _map = new Map<String, dynamic>();
    }
    _map[key] = value;
    return this;
  }

  Map toMap() {
    if (_map != null) {
      return _map;
    }
    Map config = {};
    // Geolocation Options
    if (desiredAccuracy != null) config['desiredAccuracy'] = desiredAccuracy;
    if (distanceFilter != null) config['distanceFilter'] = distanceFilter;
    if (stationaryRadius != null) config['stationaryRadius'] = stationaryRadius;
    if (locationTimeout != null) config['locationTimeout'] = locationTimeout;
    if (disableElasticity != null)
      config['disableElasticity'] = disableElasticity;
    if (elasticityMultiplier != null)
      config['elasticityMultiplier'] = elasticityMultiplier;
    if (stopAfterElapsedMinutes != null)
      config['stopAfterElapsedMinutes'] = stopAfterElapsedMinutes;
    if (geofenceProximityRadius != null)
      config['geofenceProximityRadius'] = geofenceProximityRadius;
    if (geofenceInitialTriggerEntry != null)
      config['geofenceInitialTriggerEntry'] = geofenceInitialTriggerEntry;
    if (desiredOdometerAccuracy != null)
      config['desiredOdometerAccuracy'] = desiredOdometerAccuracy;
    if (useSignificantChangesOnly != null)
      config['useSignificantChangesOnly'] = useSignificantChangesOnly;
    // ActivityRecognition
    if (isMoving != null) config['isMoving'] = isMoving;
    if (stopTimeout != null) config['stopTimeout'] = stopTimeout;
    if (activityRecognitionInterval != null)
      config['activityRecognitionInterval'] = activityRecognitionInterval;
    if (minimumActivityRecognitionConfidence != null)
      config['minimumActivityRecognitionConfidence'] =
          minimumActivityRecognitionConfidence;
    if (disableStopDetection != null)
      config['disableStopDetection'] = disableStopDetection;
    if (stopOnStationary != null) config['stopOnStationary'] = stopOnStationary;
    // HTTP & Persistence
    if (url != null) config['url'] = url;
    if (persistMode != null) config['persistMode'] = persistMode;
    if (method != null) config['method'] = method;
    if (httpRootProperty != null) config['httpRootProperty'] = httpRootProperty;
    if (params != null) config['params'] = params;
    if (headers != null) config['headers'] = headers;
    if (extras != null) config['extras'] = extras;
    if (autoSync != null) config['autoSync'] = autoSync;
    if (autoSyncThreshold != null)
      config['autoSyncThreshold'] = autoSyncThreshold;
    if (batchSync != null) config['batchSync'] = batchSync;
    if (maxBatchSize != null) config['maxBatchSize'] = maxBatchSize;
    if (locationTemplate != null) config['locationTemplate'] = locationTemplate;
    if (geofenceTemplate != null) config['geofenceTemplate'] = geofenceTemplate;
    if (maxDaysToPersist != null) config['maxDaysToPersist'] = maxDaysToPersist;
    if (maxRecordsToPersist != null)
      config['maxRecordsToPersist'] = maxRecordsToPersist;
    if (locationsOrderDirection != null)
      config['locationsOrderDirection'] = locationsOrderDirection;
    if (httpTimeout != null) config['httpTimeout'] = httpTimeout;
    // Application
    if (stopOnTerminate != null) config['stopOnTerminate'] = stopOnTerminate;
    if (startOnBoot != null) config['startOnBoot'] = startOnBoot;
    if (heartbeatInterval != null)
      config['heartbeatInterval'] = heartbeatInterval;
    if (schedule != null) config['schedule'] = schedule;
    // Logging & Debug
    if (debug != null) config['debug'] = debug;
    if (logLevel != null) config['logLevel'] = logLevel;
    if (logMaxDays != null) config['logMaxDays'] = logMaxDays;
    if (reset != null) config['reset'] = reset;

    ////
    // iOS Options
    //

    // Geolocation Options
    if (pausesLocationUpdatesAutomatically != null)
      config['pausesLocationUpdatesAutomatically'] =
          pausesLocationUpdatesAutomatically;
    if (locationAuthorizationRequest != null)
      config['locationAuthorizationRequest'] = locationAuthorizationRequest;
    if (locationAuthorizationAlert != null)
      config['locationAuthorizationAlert'] = locationAuthorizationAlert;
    if (disableLocationAuthorizationAlert != null)
      config['disableLocationAuthorizationAlert'] =
          disableLocationAuthorizationAlert;
    // Activity Recognition Options
    if (activityType != null) config['activityType'] = activityType;
    if (stopDetectionDelay != null)
      config['stopDetectionDelay'] = stopDetectionDelay;
    if (disableMotionActivityUpdates != null)
      config['disableMotionActivityUpdates'] = disableMotionActivityUpdates;
    // Application Options
    if (preventSuspend != null) config['preventSuspend'] = preventSuspend;

    ////
    // Android Options
    //

    // Geolocation Options
    if (locationUpdateInterval != null)
      config['locationUpdateInterval'] = locationUpdateInterval;
    if (fastestLocationUpdateInterval != null)
      config['fastestLocationUpdateInterval'] = fastestLocationUpdateInterval;
    if (deferTime != null) config['deferTime'] = deferTime;
    if (allowIdenticalLocations != null)
      config['allowIdenticalLocations'] = allowIdenticalLocations;
    if (enableTimestampMeta != null)
      config['enableTimestampMeta'] = enableTimestampMeta;
    if (speedJumpFilter != null) config['speedJumpFilter'] = speedJumpFilter;
    // Activity Recognition Options
    if (triggerActivities != null)
      config['triggerActivities'] = triggerActivities;
    if (geofenceModeHighAccuracy != null)
      config['geofenceModeHighAccuracy'] = geofenceModeHighAccuracy;
    // Application Options
    if (enableHeadless != null) config['enableHeadless'] = enableHeadless;
    if (foregroundService != null)
      config['foregroundService'] = foregroundService;
    if (forceReloadOnLocationChange != null)
      config['forceReloadOnLocationChange'] = forceReloadOnLocationChange;
    if (forceReloadOnMotionChange != null)
      config['forceReloadOnMotionChange'] = forceReloadOnMotionChange;
    if (forceReloadOnGeofence != null)
      config['forceReloadOnGeofence'] = forceReloadOnGeofence;
    if (forceReloadOnBoot != null)
      config['forceReloadOnBoot'] = forceReloadOnBoot;
    if (forceReloadOnHeartbeat != null)
      config['forceReloadOnHeartbeat'] = forceReloadOnHeartbeat;
    if (forceReloadOnSchedule != null)
      config['forceReloadOnSchedule'] = forceReloadOnSchedule;
    if (notificationPriority != null)
      config['notificationPriority'] = notificationPriority;
    if (notificationTitle != null)
      config['notificationTitle'] = notificationTitle;
    if (notificationText != null) config['notificationText'] = notificationText;
    if (notificationColor != null)
      config['notificationColor'] = notificationColor;
    if (notificationSmallIcon != null)
      config['notificationSmallIcon'] = notificationSmallIcon;
    if (notificationLargeIcon != null)
      config['notificationLargeIcon'] = notificationLargeIcon;
    if (notificationChannelName != null)
      config['notificationChannelName'] = notificationChannelName;

    return config;
  }

  static final DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();

  /// Returns a Map suitable for attaching to [params] and posting to the Transistor Software Demo Server at `http://tracker.transistorsoft.com`.
  ///
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Required by Demo Server.
  /// Map deviceParams = await bg.Config.deviceParams;
  /// String username = 'my-unique-username'; // Eg Github username
  ///
  /// BackgroundGeolocation.ready(Config(
  ///   url: 'http://tracker.transistorsoft.com/locations/$username',
  ///   params: deviceParams
  /// ));
  /// ```
  ///
  /// View your tracking at [http://tracker.transistorsoft.com/my-unique-username](http://tracker.transistorsoft.com/my-unique-username).
  ///
  /// ![](https://dl.dropboxusercontent.com/s/3abuyyhioyypk8c/screenshot-tracker-transistorsoft.png?dl=1)
  ///
  static Future<Map<String, dynamic>> get deviceParams async {
    Map<String, dynamic> response;
    try {
      RegExp re = new RegExp(r"[\s\.,]");
      if (defaultTargetPlatform == TargetPlatform.android) {
        AndroidDeviceInfo info = await deviceInfo.androidInfo;
        String uuid =
            '${info.model}-${info.version.release}'.replaceAll(re, '-');
        response = {
          'device': {
            'uuid': uuid,
            'model': info.model,
            'platform': 'Android',
            'manufacturer': info.manufacturer,
            'version': info.version.release,
            'framework': 'Flutter'
          }
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        IosDeviceInfo info = await deviceInfo.iosInfo;
        String uuid =
            '${info.utsname.machine}-${info.systemVersion}'.replaceAll(re, '-');
        response = {
          'device': {
            'uuid': uuid,
            'model': info.utsname.machine,
            'platform': 'iOS',
            'manufacturer': 'Apple',
            'version': info.systemVersion,
            'framework': 'Flutter'
          }
        };
      }
    } on PlatformException {
      response = {'Error:': 'Failed to get platform version.'};
    }
    return response;
  }
}
