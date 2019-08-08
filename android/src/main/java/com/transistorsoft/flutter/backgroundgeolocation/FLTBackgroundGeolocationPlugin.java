package com.transistorsoft.flutter.backgroundgeolocation;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterNativeView;

import com.google.android.gms.common.GoogleApiAvailability;
import com.transistorsoft.flutter.backgroundgeolocation.streams.ActivityChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.ConnectivityChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.EnabledChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.GeofenceStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.GeofencesChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.HeartbeatStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.HttpStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.LocationStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.MotionChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.PowerSaveChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.ProviderChangeStreamHandler;
import com.transistorsoft.flutter.backgroundgeolocation.streams.ScheduleStreamHandler;
import com.transistorsoft.locationmanager.adapter.BackgroundGeolocation;
import com.transistorsoft.locationmanager.adapter.TSConfig;
import com.transistorsoft.locationmanager.adapter.callback.*;
import com.transistorsoft.locationmanager.data.LocationModel;
import com.transistorsoft.locationmanager.device.DeviceSettingsRequest;
import com.transistorsoft.locationmanager.event.TerminateEvent;
import com.transistorsoft.locationmanager.geofence.TSGeofence;
import com.transistorsoft.locationmanager.location.TSCurrentPositionRequest;
import com.transistorsoft.locationmanager.location.TSLocation;
import com.transistorsoft.locationmanager.location.TSWatchPositionRequest;
import com.transistorsoft.locationmanager.logger.TSLog;
import com.transistorsoft.locationmanager.scheduler.TSScheduleManager;
import com.transistorsoft.locationmanager.util.Sensors;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * FlutterBackgroundGeolocationPlugin
 */
public class FLTBackgroundGeolocationPlugin implements MethodCallHandler, Application.ActivityLifecycleCallbacks, PluginRegistry.ViewDestroyListener {
    public static final String PLUGIN_ID                  = "com.transistorsoft/flutter_background_geolocation";
    private static final String METHOD_CHANNEL_NAME         = PLUGIN_ID + "/methods";

    private static final String ACTION_RESET             = "reset";
    private static final String ACTION_READY             = "ready";

    private static final String ACTION_REGISTER_HEADLESS_TASK = "registerHeadlessTask";
    private static final String ACTION_GET_STATE         = "getState";
    private static final String ACTION_GET_LOG           = "getLog";
    private static final String ACTION_EMAIL_LOG         = "emailLog";
    private static final String ACTION_START_SCHEDULE    = "startSchedule";
    private static final String ACTION_STOP_SCHEDULE     = "stopSchedule";
    private static final String ACTION_LOG               = "log";
    private static final String ACTION_REQUEST_SETTINGS  = "requestSettings";
    private static final String ACTION_SHOW_SETTINGS     = "showSettings";

    private static final String JOB_SERVICE_CLASS         = "com.transistorsoft.flutter.backgroundgeolocation.HeadlessTask";

    private boolean mIsInitialized;
    private Intent mLaunchIntent;
    private Context mContext;
    private PluginRegistry.Registrar mRegistrar;

    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
        FLTBackgroundGeolocationPlugin plugin = new FLTBackgroundGeolocationPlugin(registrar);
        final MethodChannel channel = new MethodChannel(registrar.messenger(), METHOD_CHANNEL_NAME);
        channel.setMethodCallHandler(plugin);
        registrar.addViewDestroyListener(plugin);
    }

    private FLTBackgroundGeolocationPlugin(PluginRegistry.Registrar registrar) {
        Activity activity = registrar.activity();

        mContext = registrar.context().getApplicationContext();

        if (activity != null) {
            mIsInitialized = false;
            mRegistrar = registrar;

            mLaunchIntent = activity.getIntent();

            BackgroundGeolocation.getInstance(mContext, mLaunchIntent);

            // We need to know when activity is created / destroyed.
            activity.getApplication().registerActivityLifecycleCallbacks(this);

            // Init stream-handlers
            new LocationStreamHandler().register(registrar);
            new MotionChangeStreamHandler().register(registrar);
            new ActivityChangeStreamHandler().register(registrar);
            new GeofencesChangeStreamHandler().register(registrar);
            new GeofenceStreamHandler().register(registrar);
            new HeartbeatStreamHandler().register(registrar);
            new HttpStreamHandler().register(registrar);
            new ScheduleStreamHandler().register(registrar);
            new ConnectivityChangeStreamHandler().register(registrar);
            new EnabledChangeStreamHandler().register(registrar);
            new ProviderChangeStreamHandler().register(registrar);
            new PowerSaveChangeStreamHandler().register(registrar);

            // Allow desiredAccuracy configuration as CLLocationAccuracy
            TSConfig config = TSConfig.getInstance(registrar.context().getApplicationContext());
            config.useCLLocationAccuracy(true);

            config.updateWithBuilder()
                    .setHeadlessJobService(JOB_SERVICE_CLASS)
                    .commit();
        }
    }

    public static void setPluginRegistrant(PluginRegistry.PluginRegistrantCallback callback) {
        HeadlessTask.setPluginRegistrant(callback);
    }

    private void initializeLocationManager(Activity activity) {
        mIsInitialized = true;

        if (activity == null) {
            return;
        }

        if (mLaunchIntent.hasExtra("forceReload")) {
            activity.moveTaskToBack(true);
        }
        // Handle play-services connect errors.
        BackgroundGeolocation.getInstance(mContext, mLaunchIntent).onPlayServicesConnectError((new TSPlayServicesConnectErrorCallback() {
            @Override
            public void onPlayServicesConnectError(int errorCode) {
                handlePlayServicesConnectError(errorCode);
            }
        }));
    }

    // Shows Google Play Services error dialog prompting user to install / update play-services.
    private void handlePlayServicesConnectError(Integer errorCode) {
        Activity activity = mRegistrar.activity();
        if (activity == null) {
            return;
        }
        GoogleApiAvailability.getInstance().getErrorDialog(activity, errorCode, 1001).show();
    }

    @SuppressWarnings("unchecked")
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equalsIgnoreCase(ACTION_READY)) {
            Map<String, Object> params = (Map<String, Object>) call.arguments;
            ready(params, result);
        } else if (call.method.equals(ACTION_GET_STATE)) {
            getState(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_START)) {
            start(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_STOP)) {
            stop(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_START_GEOFENCES)) {
            startGeofences(result);
        } else if (call.method.equalsIgnoreCase(ACTION_START_SCHEDULE)) {
            startSchedule(result);
        } else if (call.method.equalsIgnoreCase(ACTION_STOP_SCHEDULE)) {
            stopSchedule(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_START_BACKGROUND_TASK)) {
            startBackgroundTask(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_FINISH)) {
            stopBackgroundTask((int) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(ACTION_RESET)) {
            reset(call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_SET_CONFIG)) {
            setConfig((Map) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_CHANGE_PACE)) {
            changePace(call, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_CURRENT_POSITION)) {
            getCurrentPosition((Map) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_WATCH_POSITION)) {
            watchPosition((Map) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_LOCATIONS)) {
            getLocations(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_INSERT_LOCATION)) {
            insertLocation((Map) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_COUNT)) {
            getCount(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_DESTROY_LOCATIONS)) {
            destroyLocations(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_SYNC)) {
            sync(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_ODOMETER)) {
            getOdometer(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_SET_ODOMETER)) {
            setOdometer((Double) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_ADD_GEOFENCE)) {
            addGeofence((Map) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_ADD_GEOFENCES)) {
            addGeofences((List) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_REMOVE_GEOFENCE)) {
            removeGeofence((String) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_REMOVE_GEOFENCES)) {
            removeGeofences(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_GEOFENCES)) {
            getGeofences(result);
        } else if (call.method.equalsIgnoreCase(ACTION_GET_LOG)) {
            getLog(result);
        } else if (call.method.equalsIgnoreCase(ACTION_EMAIL_LOG)) {
            emailLog((String) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_DESTROY_LOG)) {
            destroyLog(result);
        } else if (call.method.equalsIgnoreCase(ACTION_LOG)) {
            Map<String, String> args = (Map) call.arguments;
            log(args.get("level"), args.get("message"), result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_SENSORS)) {
            getSensors(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_IS_POWER_SAVE_MODE)) {
            isPowerSaveMode(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_IS_IGNORING_BATTERY_OPTIMIZATIONS)) {
            isIgnoringBatteryOptimizations(result);
        } else if (call.method.equalsIgnoreCase(ACTION_REQUEST_SETTINGS)) {
            requestSettings((List) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(ACTION_SHOW_SETTINGS)) {
            showSettings((List) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_PLAY_SOUND)) {
            playSound((String) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(ACTION_REGISTER_HEADLESS_TASK)) {
            registerHeadlessTask((List<Object>) call.arguments, result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_GET_PROVIDER_STATE)) {
            getProviderState(result);
        } else if (call.method.equalsIgnoreCase(BackgroundGeolocation.ACTION_REQUEST_PERMISSION)) {
            requestPermission(result);
        } else {
            result.notImplemented();
        }
    }

    // experimental Flutter Headless (NOT READY)
    private void registerHeadlessTask(List<Object> callbacks, Result result) {
        if (HeadlessTask.register(mContext, callbacks)) {
            result.success(true);
        } else {
            result.error("Failed to registerHeadlessTask.  Callback IDs: " + callbacks.toString(), null, null);
        }
    }

    private void getState(Result result) {
        resultWithState(result);
    }

    private void ready(Map<String, Object> params, final Result result) {
        TSConfig config = TSConfig.getInstance(mContext);

        if (config.isFirstBoot()) {
            if (!applyConfig(params, result)) {
                return;
            }
        } else if (params.containsKey("reset") && (boolean) params.get("reset")) {
            config.reset();
            if (!applyConfig(params, result)) {
                return;
            }
        } else {

        }

        BackgroundGeolocation.getInstance(mContext).ready(new TSCallback() {
          @Override public void onSuccess() { resultWithState(result); }
          @Override public void onFailure(String error) {
            result.error(error, null, null);
          }
        });
    }

    private void start(final Result result) {
        BackgroundGeolocation.getInstance(mContext).start(new TSCallback() {
          @Override public void onSuccess() { resultWithState(result); }
          @Override public void onFailure(String error) {
            result.error(error, null, null);
          }
        });
    }

    @SuppressWarnings("unchecked")
    private void setConfig(Map<String, Object> config, Result result) {
        if (!applyConfig(config, result)) return;
        resultWithState(result);
    }

    @SuppressWarnings("unchecked")
    private void reset(Object args, Result result) {
        TSConfig config = TSConfig.getInstance(mContext);
        config.reset();

        if (args != null) {
            if (args.getClass() == HashMap.class) {
                Map<String, Object> params = (HashMap) args;

                if (!applyConfig(params, result)) return;
            }
        }
        resultWithState(result);
    }
    private void startGeofences(final Result result) {
        BackgroundGeolocation.getInstance(mContext).startGeofences(new TSCallback() {
            @Override public void onSuccess() { resultWithState(result); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void startSchedule(Result result) {
        if (BackgroundGeolocation.getInstance(mContext).startSchedule()) {
            resultWithState(result);
        } else {
            result.error("Failed to start schedule.  Did you configure a #schedule?", null, null);
        }
    }

    private void stopSchedule(Result result) {
        BackgroundGeolocation.getInstance(mContext).stopSchedule();
        resultWithState(result);
    }

    private void stop(final Result result) {
        final BackgroundGeolocation bgGeo = BackgroundGeolocation.getInstance(mContext);
        bgGeo.stop(new TSCallback() {
          @Override public void onSuccess() {
            resultWithState(result);
          }
          @Override public void onFailure(String error) {
            result.error(error, null, null);
          }
        });
    }

    private void changePace(MethodCall call, final Result result) {
        final boolean isMoving = (boolean) call.arguments;
        BackgroundGeolocation.getInstance(mContext).changePace(isMoving, new TSCallback() {
            @Override public void onSuccess() {
                result.success(isMoving);
            }
            @Override public void onFailure(String error) {
                result.error(error, null, null);
            }
        });
    }

    @SuppressWarnings("unchecked")
    private void getCurrentPosition(Map<String, Object> options, final Result result) {
        TSCurrentPositionRequest.Builder builder = new TSCurrentPositionRequest.Builder(mContext);

        builder.setCallback(new TSLocationCallback() {
            @Override public void onLocation(TSLocation tsLocation) {
                result.success(tsLocation.toMap());
            }
            @Override public void onError(Integer errorCode) {
                result.error(errorCode.toString(), null, null);
            }
        });

        if (options.containsKey("samples"))         { builder.setSamples((int) options.get("samples")); }
        if (options.containsKey("persist"))         { builder.setPersist((boolean) options.get("persist")); }
        if (options.containsKey("timeout"))         { builder.setTimeout((int) options.get("timeout")); }
        if (options.containsKey("maximumAge"))      { builder.setMaximumAge((long) options.get("maximumAge")); }
        if (options.containsKey("desiredAccuracy")) { builder.setDesiredAccuracy((int) options.get("desiredAccuracy")); }
        if (options.containsKey("extras")) {
            Object extras = options.get("extras");
            if (extras.getClass() == HashMap.class) {
                try {
                    builder.setExtras(mapToJson(options));
                } catch (JSONException e) {
                    result.error(e.getMessage(), null, null);
                    e.printStackTrace();
                    return;
                }
            }
        }

        BackgroundGeolocation.getInstance(mContext).getCurrentPosition(builder.build());
    }

    @SuppressWarnings("unchecked")
    private void watchPosition(Map<String, Object> options, final Result result) {
        TSWatchPositionRequest.Builder builder = new TSWatchPositionRequest.Builder(mContext);

        builder.setCallback(new TSLocationCallback() {
            @Override public void onLocation(TSLocation tsLocation) {
                //sendEvent(EVENT_WATCHPOSITION, jsonToMap(tsLocation.toJson()));
                //Map<String, Object> data = tsLocation.toMap();
            }
            @Override public void onError(Integer error) {
                result.error(error.toString(), null, null);
            }
        });

        if (options.containsKey("interval")) {
            builder.setInterval((long) options.get("interval"));
        }
        if (options.containsKey("persist")) {
            builder.setPersist((boolean) options.get("persist"));
        }
        if (options.containsKey("desiredAccuracy")) {
            builder.setDesiredAccuracy((int) options.get("desiredAccuracy"));
        }
        if (options.containsKey("extras")) {
            try {
                builder.setExtras(mapToJson((Map) options.get("extras")));
            } catch (JSONException e) {
                result.error(e.getMessage(), null, null);
            }
        }
        BackgroundGeolocation.getInstance(mContext).watchPosition(builder.build());
        result.success(true);
        //success.invoke();
    }

    private void getLocations(final Result result) {
        BackgroundGeolocation.getInstance(mContext).getLocations(new TSGetLocationsCallback() {
            @Override public void onSuccess(List<LocationModel> records) {
                JSONArray rs = new JSONArray();
                for (LocationModel location : records) {
                    rs.put(location.json);
                }
                try {
                    result.success(toList(rs));
                } catch (JSONException e) {
                    result.error(e.getMessage(), null, null);
                }
            }
            @Override public void onFailure(Integer error) { result.error(error.toString(), null, null); }
        });
    }

    private void insertLocation(Map<String, Object> params, final Result result) {
        JSONObject json;
        try {
            json = mapToJson(params);
        } catch (JSONException e) {
            result.error(e.getMessage(), null, null);
            e.printStackTrace();
            return;
        }
        BackgroundGeolocation.getInstance(mContext).insertLocation(json, new TSInsertLocationCallback() {
            @Override public void onSuccess(String uuid) { result.success(uuid); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void getCount(Result result) {
        result.success(BackgroundGeolocation.getInstance(mContext).getCount());
    }

    private void destroyLocations(final Result result) {
        BackgroundGeolocation.getInstance(mContext).destroyLocations(new TSCallback() {
            @Override public void onSuccess() { result.success(true); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void sync(final Result result) {
        BackgroundGeolocation.getInstance(mContext).sync(new TSSyncCallback() {
            @Override public void onSuccess(List<LocationModel> records) {
                try {
                    JSONArray rs = new JSONArray();
                    for (LocationModel location : records) {
                        rs.put(location.json);
                    }
                    result.success(toList(rs));
                } catch (JSONException e) {
                    result.error(e.getMessage(), null, null);
                }
            }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void getOdometer(Result result) {
        result.success(BackgroundGeolocation.getInstance(mContext).getOdometer().doubleValue());
    }

    private void setOdometer(Double odometer, final Result result) {
        BackgroundGeolocation.getInstance(mContext).setOdometer(odometer.floatValue(), new TSLocationCallback() {
            @Override public void onLocation(TSLocation location) {
                result.success(location.toMap());
            }
            @Override public void onError(Integer errorCode) {
                result.error(errorCode.toString(), null, null);
            }
        });
    }

    private void addGeofence(Map<String, Object> params, final Result result) {
        try {
            BackgroundGeolocation.getInstance(mContext).addGeofence(buildGeofence(params), new TSCallback() {
                @Override public void onSuccess() { result.success(true); }
                @Override public void onFailure(String error) { result.error(error, null, null); }
            });
        } catch (TSGeofence.Exception e) {
            result.error(e.getMessage(), null, null);
        }
    }

    private void addGeofences(List<Map<String, Object>> data, final Result result) {
        List<TSGeofence> geofences = new ArrayList<>();
        for (int n=0;n<data.size();n++) {
            try {
                geofences.add(buildGeofence(data.get(n)));
            } catch (TSGeofence.Exception e) {
                result.error(e.getMessage(), null, null);
                return;
            }
        }

        BackgroundGeolocation.getInstance(mContext).addGeofences(geofences, new TSCallback() {
            @Override public void onSuccess() {
                result.success(true);
            }
            @Override public void onFailure(String error) {
                result.error(error, null, null);
            }
        });
    }

    private void removeGeofence(String identifier, final Result result) {
        BackgroundGeolocation.getInstance(mContext).removeGeofence(identifier, new TSCallback() {
            @Override public void onSuccess() { result.success(true);
            }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void removeGeofences(final Result result) {
        List<String> identifiers = new ArrayList<>();
        BackgroundGeolocation.getInstance(mContext).removeGeofences(identifiers, new TSCallback() {
            @Override public void onSuccess() { result.success(true); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void getGeofences(final Result result) {
        BackgroundGeolocation.getInstance(mContext).getGeofences(new TSGetGeofencesCallback() {
            @Override public void onSuccess(List<TSGeofence> geofences) {
                try {
                    List<Map<String, Object>> rs = new ArrayList<>();
                    for (TSGeofence geofence : geofences) {
                        Map<String, Object> data = new HashMap<>();
                        data.put("identifier", geofence.getIdentifier());
                        data.put("latitude", geofence.getLatitude());
                        data.put("longitude", geofence.getLongitude());
                        data.put("radius", geofence.getRadius());
                        data.put("notifyOnEntry", geofence.getNotifyOnEntry());
                        data.put("notifyOnExit", geofence.getNotifyOnExit());
                        data.put("notifyOnDwell", geofence.getNotifyOnDwell());
                        data.put("loiteringDelay", geofence.getLoiteringDelay());
                        if (geofence.getExtras() != null) {
                            data.put("extras", jsonToMap(geofence.getExtras()));
                        }
                        rs.add(data);
                    }
                    result.success(rs);
                } catch (JSONException e) {
                    e.printStackTrace();
                    result.error(e.getMessage(), null, null);
                }
            }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    @SuppressWarnings("unchecked")
    private TSGeofence buildGeofence(Map<String, Object> config) throws TSGeofence.Exception {
        TSGeofence.Builder builder = new TSGeofence.Builder();
        if (config.containsKey("identifier"))       { builder.setIdentifier((String) config.get("identifier")); }
        if (config.containsKey("latitude"))         { builder.setLatitude((Double) config.get("latitude")); }
        if (config.containsKey("longitude"))        { builder.setLongitude((Double) config.get("longitude")); }
        if (config.containsKey("radius")) {
            Double radius = (Double) config.get("radius");
            builder.setRadius(radius.floatValue());
        }
        if (config.containsKey("notifyOnEntry"))    { builder.setNotifyOnEntry((boolean) config.get("notifyOnEntry")); }
        if (config.containsKey("notifyOnExit"))     { builder.setNotifyOnExit((boolean) config.get("notifyOnExit")); }
        if (config.containsKey("notifyOnDwell"))    { builder.setNotifyOnDwell((boolean) config.get("notifyOnDwell")); }
        if (config.containsKey("loiteringDelay"))   { builder.setLoiteringDelay((int) config.get("loiteringDelay")); }
        try {
            if (config.containsKey("extras")) {
                builder.setExtras(mapToJson((HashMap) config.get("extras")));
            }
        } catch (JSONException e) {
            throw new TSGeofence.Exception(e.getMessage());
        }
        return builder.build();
    }

    private void startBackgroundTask(final Result result) {
        BackgroundGeolocation.getInstance(mContext).startBackgroundTask(new TSBackgroundTaskCallback() {
            @Override public void onStart(int taskId) { result.success(taskId); }
        });
    }

    private void stopBackgroundTask(int taskId, Result result) {
        BackgroundGeolocation.getInstance(mContext).stopBackgroundTask(taskId);
        result.success(taskId);
    }

    private void getLog(final Result result) {
        BackgroundGeolocation.getInstance(mContext).getLog(new TSGetLogCallback() {
            @Override public void onSuccess(String log) { result.success(log); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void emailLog(String email, final Result result) {
        BackgroundGeolocation.getInstance(mContext).emailLog(email, mRegistrar.activity(), new TSEmailLogCallback() {
            @Override public void onSuccess() { result.success(true); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void destroyLog(final Result result) {
        BackgroundGeolocation.getInstance(mContext).destroyLog(new TSCallback() {
            @Override public void onSuccess() { result.success(true); }
            @Override public void onFailure(String error) { result.error(error, null, null); }
        });
    }

    private void log(String level, String message, Result result) {
        TSLog.log(level, message);
        result.success(true);
    }

    private void getSensors(Result result) {
        Sensors sensors = Sensors.getInstance(mContext);
        Map<String, Object> params = new HashMap<>();
        params.put("platform", "android");
        params.put("accelerometer", sensors.hasAccelerometer());
        params.put("magnetometer", sensors.hasMagnetometer());
        params.put("gyroscope", sensors.hasGyroscope());
        params.put("significant_motion", sensors.hasSignificantMotion());
        result.success(params);
    }

    private void isPowerSaveMode(Result result) {
        result.success(BackgroundGeolocation.getInstance(mContext).isPowerSaveMode());
    }

    private void isIgnoringBatteryOptimizations(Result result) {
        result.success(BackgroundGeolocation.getInstance(mContext).isIgnoringBatteryOptimizations());
    }

    private void requestSettings(List<Object> args, Result result) {
        String action = (String) args.get(0);

        DeviceSettingsRequest request = BackgroundGeolocation.getInstance(mContext).requestSettings(action);
        if (request != null) {
            result.success(request.toMap());
        } else {
            result.error("0", "Failed to find " + action + " screen for device " + Build.MANUFACTURER + " " + Build.MODEL + "@" + Build.VERSION.RELEASE, null);
        }
    }

    private void showSettings(List<Object> args, Result result) {
        String action = (String) args.get(0);
        boolean didShow = BackgroundGeolocation.getInstance(mContext).showSettings(action);
        if (didShow) {
            result.success(didShow);
        } else {
            result.error("0", "Failed to find " + action + " screen for device " + Build.MANUFACTURER + " " + Build.MODEL + "@" + Build.VERSION.RELEASE, null);
        }
    }

    private void getProviderState(Result result) {
        result.success(BackgroundGeolocation.getInstance(mContext).getProviderState().toMap());
    }

    private void requestPermission(final Result result) {
        BackgroundGeolocation.getInstance(mContext).requestPermission(new TSRequestPermissionCallback() {
            @Override public void onSuccess(int status) { result.success(status); }
            @Override public void onFailure(int status) { result.error("DENIED", null, status); }
        });
    }

    private void playSound(String name, Result result) {
        BackgroundGeolocation.getInstance(mContext).startTone(name);
        result.success(true);
    }

    ////
    // Utility Methods
    //
    @SuppressWarnings("unchecked")
    private JSONObject mapToJson(Map<String, Object> map) throws JSONException {
        JSONObject jsonData = new JSONObject();
        for (String key : map.keySet()) {
          Object value = map.get(key);
          if (value instanceof Map<?, ?>) {
              value = mapToJson((Map<String, Object>) value);
          } else if (value instanceof List<?>) {
              value = listToJson((List<Object>) value);
          }
          jsonData.put(key, value);
        }
        return jsonData;
    }

    private JSONArray listToJson(List<Object> list) throws JSONException {
        JSONArray jsonData = new JSONArray();
        for (Object value : list) {
            jsonData.put(value);
        }
        return jsonData;
    }
    private static Map<String, Object> jsonToMap(JSONObject json) throws JSONException {
        Map<String, Object> retMap = new HashMap<>();

        if(json != JSONObject.NULL) {
            retMap = toMap(json);
        }
        return retMap;
    }




    private static Map<String, Object> toMap(JSONObject object) throws JSONException {
        Map<String, Object> map = new HashMap<>();

        Iterator<String> keysItr = object.keys();
        while(keysItr.hasNext()) {
            String key = keysItr.next();
            Object value = object.get(key);

            if(value instanceof JSONArray) {
                value = toList((JSONArray) value);
            }

            else if(value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            map.put(key, value);
        }
        return map;
    }

    private static List<Object> toList(JSONArray array) throws JSONException {
        List<Object> list = new ArrayList<>();
        for(int i = 0; i < array.length(); i++) {
            Object value = array.get(i);
            if(value instanceof JSONArray) {
                value = toList((JSONArray) value);
            }

            else if(value instanceof JSONObject) {
                value = toMap((JSONObject) value);
            }
            list.add(value);
        }
        return list;
    }

    private Map<String, Object> setHeadlessJobService(Map<String, Object> config) {
        config.put("headlessJobService", JOB_SERVICE_CLASS);
        return config;
    }

    private boolean applyConfig(Map<String, Object> params, Result result) {
        TSConfig config = TSConfig.getInstance(mContext);

        try {
            config.updateWithJSONObject(mapToJson(setHeadlessJobService(params)));
        } catch (JSONException e) {
            result.error(e.getMessage(), null, null);
            e.printStackTrace();
            return false;
        }
        return true;
    }

    private void resultWithState(Result result) {
        try {
            result.success(jsonToMap(TSConfig.getInstance(mContext).toJson()));
        } catch (JSONException e) {
            e.printStackTrace();
            result.error(e.getMessage(), null, null);
        }
    }

    @Override
    // TODO this is part of attempt to implement Flutter Headless callbacks.  Not yet working.
    public boolean onViewDestroy(FlutterNativeView nativeView) {
        //return HeadlessTask.setSharedFlutterView(nativeView);
        return true;
    }

    @Override
    public void onActivityCreated(Activity activity, Bundle bundle) { }
    @Override
    public void onActivityPaused(Activity activity) {
    }

    @Override
    public void onActivityResumed(Activity activity) {
        TSScheduleManager.getInstance(activity).cancelOneShot(TerminateEvent.ACTION);
    }
    @Override
    public void onActivityStarted(Activity activity) {
        if (!mIsInitialized) {
            initializeLocationManager(activity);
        }
    }
    @Override
    public void onActivityStopped(Activity activity) {
        TSConfig config = TSConfig.getInstance(activity);
        if (config.getEnabled() && config.getEnableHeadless() && !config.getStopOnTerminate()) {
            TSScheduleManager.getInstance(activity).oneShot(TerminateEvent.ACTION, 10000);
        }
    }

    @Override
    public void onActivitySaveInstanceState(Activity activity, Bundle bundle) { }

    @Override
    public void onActivityDestroyed(Activity activity) {
        if (mRegistrar.activity() == null) {
            BackgroundGeolocation.getInstance(mContext).onActivityDestroy();
            activity.getApplication().unregisterActivityLifecycleCallbacks(this);
        }
    }

}
