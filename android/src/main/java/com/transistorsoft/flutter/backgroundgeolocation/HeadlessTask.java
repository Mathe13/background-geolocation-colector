package com.transistorsoft.flutter.backgroundgeolocation;

import android.content.Context;
import android.content.SharedPreferences;

import com.transistorsoft.locationmanager.adapter.BackgroundGeolocation;
import com.transistorsoft.locationmanager.event.HeadlessEvent;
import com.transistorsoft.locationmanager.logger.TSLog;

import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterCallbackInformation;
import io.flutter.view.FlutterMain;

import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;

public class HeadlessTask implements MethodChannel.MethodCallHandler {
    private static final String KEY_REGISTRATION_CALLBACK_ID    = "registrationCallbackId";
    private static final String KEY_CLIENT_CALLBACK_ID          = "clientCallbackId";

    private static PluginRegistry.PluginRegistrantCallback sPluginRegistrantCallback;
    static private Long sRegistrationCallbackId;
    static private Long sClientCallbackId;

    private FlutterNativeView mBackgroundFlutterView;
    private MethodChannel mDispatchChannelChannel;
    private final AtomicBoolean mHeadlessTaskRegistered = new AtomicBoolean(false);

    private final List<HeadlessEvent> mEvents = new ArrayList<>();

    // Called by Application#onCreate.  Must be public.
    public static void setPluginRegistrant(PluginRegistry.PluginRegistrantCallback callback) {
        sPluginRegistrantCallback = callback;
    }

    // Called by FLTBackgroundGeolocationPlugin
    static boolean register(Context context, List<Object> callbacks) {
        SharedPreferences prefs = context.getSharedPreferences(HeadlessTask.class.getName(), Context.MODE_PRIVATE);

        // There is weirdness with the class of these callbacks (Integer vs Long) between assembleDebug vs assembleRelease.
        Object cb1 = callbacks.get(0);
        Object cb2 = callbacks.get(1);

        SharedPreferences.Editor editor = prefs.edit();
        if (cb1.getClass() == Long.class) {
            editor.putLong(KEY_REGISTRATION_CALLBACK_ID, (Long) cb1);
        } else if (cb1.getClass() == Integer.class) {
            editor.putLong(KEY_REGISTRATION_CALLBACK_ID, ((Integer) cb1).longValue());
        }

        if (cb2.getClass() == Long.class) {
            editor.putLong(KEY_CLIENT_CALLBACK_ID, (Long) cb2);
        } else if (cb2.getClass() == Integer.class) {
            editor.putLong(KEY_CLIENT_CALLBACK_ID, ((Integer) cb2).longValue());
        }
        editor.apply();

        sRegistrationCallbackId = prefs.getLong(KEY_REGISTRATION_CALLBACK_ID, -1);
        sClientCallbackId = prefs.getLong(KEY_CLIENT_CALLBACK_ID, -1);

        return ((sRegistrationCallbackId != -1) && (sClientCallbackId != -1));
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        TSLog.logger.debug("$ " + call.method);
        if (call.method.equalsIgnoreCase("initialized")) {
            synchronized(mHeadlessTaskRegistered) {
                mHeadlessTaskRegistered.set(true);
            }
            dispatch();
        } else {
            result.notImplemented();
        }
    }

    @Subscribe(threadMode=ThreadMode.MAIN)
    public void onHeadlessEvent(HeadlessEvent event) {

        SharedPreferences prefs = event.getContext().getSharedPreferences(getClass().getName(), Context.MODE_PRIVATE);
        sRegistrationCallbackId = prefs.getLong(KEY_REGISTRATION_CALLBACK_ID, -1);
        sClientCallbackId = prefs.getLong(KEY_CLIENT_CALLBACK_ID, -1);

        String eventName = event.getName();
        TSLog.logger.debug("\uD83D\uDC80 [HeadlessTask " + eventName + "]");

        if ((sRegistrationCallbackId == -1) || (sClientCallbackId == -1)) {
            TSLog.logger.error(TSLog.error("Invalid Headless Callback ids.  Cannot handle headless event"));
            return;
        }
        synchronized (mEvents) {
            mEvents.add(event);
            if (mBackgroundFlutterView == null) {
                initFlutterView(event.getContext());
            }
        }

        synchronized(mHeadlessTaskRegistered) {
            if (!mHeadlessTaskRegistered.get()) {
                // Queue up events while background isolate is starting
                TSLog.logger.debug("[HeadlessTask] waiting for client to initialize");
            } else {
                // Callback method name is intentionally left blank.
                dispatch();
            }
        }
    }

    // Send event to Client.
    private void dispatch() {
        synchronized (mEvents) {
            for (HeadlessEvent event : mEvents) {
                JSONObject response = new JSONObject();
                try {
                    response.put("callbackId", sClientCallbackId);
                    response.put("event", event.getName());
                    response.put("params", getEventObject(event));
                    mDispatchChannelChannel.invokeMethod("", response);
                } catch (JSONException e) {
                    TSLog.logger.error(TSLog.error(e.getMessage()));
                    e.printStackTrace();
                }
            }
            mEvents.clear();
        }
    }

    private Object getEventObject(HeadlessEvent event) {
        String name = event.getName();
        Object result = null;
        if (name.equals(BackgroundGeolocation.EVENT_TERMINATE)) {
            result = event.getTerminateEvent();
        } else if (name.equals(BackgroundGeolocation.EVENT_LOCATION)) {
            result = event.getLocationEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_MOTIONCHANGE)) {
            result = event.getMotionChangeEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_HTTP)) {
            result = event.getHttpEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_PROVIDERCHANGE)) {
            result = event.getProviderChangeEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_ACTIVITYCHANGE)) {
            result = event.getActivityChangeEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_SCHEDULE)) {
            result = event.getScheduleEvent();
        } else if (name.equals(BackgroundGeolocation.EVENT_BOOT)) {
            result = event.getBootEvent();
        } else if (name.equals(BackgroundGeolocation.EVENT_GEOFENCE)) {
            result = event.getGeofenceEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_HEARTBEAT)) {
            result = event.getHeartbeatEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_CONNECTIVITYCHANGE)) {
            result = event.getConnectivityChangeEvent().toJson();
        } else if (name.equals(BackgroundGeolocation.EVENT_POWERSAVECHANGE)) {
            result = event.getPowerSaveChangeEvent().isPowerSaveMode();
        } else if (name.equals(BackgroundGeolocation.EVENT_ENABLEDCHANGE)) {
            result = event.getEnabledChangeEvent();
        } else {
            TSLog.logger.warn(TSLog.warn("Unknown Headless Event: " + name));
        }
        return result;
    }

    private void initFlutterView(Context context) {
        FlutterMain.ensureInitializationComplete(context, null);
        FlutterCallbackInformation callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(sRegistrationCallbackId);
        if (callbackInfo == null) {
            TSLog.logger.error(TSLog.error("Fatal: failed to find callback"));
            return;
        }
        mBackgroundFlutterView = new FlutterNativeView(context, true);

        // Create the Transmitter channel
        mDispatchChannelChannel = new MethodChannel(mBackgroundFlutterView, FLTBackgroundGeolocationPlugin.PLUGIN_ID + "/headless", JSONMethodCodec.INSTANCE);
        mDispatchChannelChannel.setMethodCallHandler(this);

        sPluginRegistrantCallback.registerWith(mBackgroundFlutterView.getPluginRegistry());

        // Dispatch back to client for initialization.
        FlutterRunArguments args = new FlutterRunArguments();
        args.bundlePath = FlutterMain.findAppBundlePath(context);
        args.entrypoint = callbackInfo.callbackName;
        args.libraryPath = callbackInfo.callbackLibraryPath;
        mBackgroundFlutterView.runFromBundle(args);
    }
}
