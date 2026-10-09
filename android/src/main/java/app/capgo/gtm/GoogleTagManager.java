package app.capgo.gtm;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import com.getcapacitor.JSObject;
import com.google.firebase.FirebaseApp;
import com.google.firebase.analytics.FirebaseAnalytics;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

public class GoogleTagManager {

    private static final String TAG = "GoogleTagManager";

    private final Context context;
    private FirebaseAnalytics firebaseAnalytics;
    private final List<Map<String, Object>> dataLayerEntries = new ArrayList<>();
    private boolean initialized = false;

    public interface Callback {
        void onSuccess();
        void onFailure(String error);
    }

    public interface ValueCallback {
        void onSuccess(Object value);
        void onFailure(String error);
    }

    public GoogleTagManager(Context context) {
        this.context = context;
    }

    public void initialize(String containerId, Double timeout, Callback callback) {
        if (initialized) {
            callback.onSuccess();
            return;
        }

        if (containerId == null || !containerId.startsWith("GTM-")) {
            callback.onFailure("Invalid container ID. Expected format GTM-XXXXXX");
            return;
        }

        try {
            if (FirebaseApp.getApps(context).isEmpty() && FirebaseApp.initializeApp(context) == null) {
                callback.onFailure("Firebase is not configured (missing google-services.json)");
                return;
            }

            firebaseAnalytics = FirebaseAnalytics.getInstance(context);
            firebaseAnalytics.setUserProperty("gtm_container_id", containerId);
            initialized = true;
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize Firebase Analytics", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void push(String event, Map<String, Object> parameters, Callback callback) {
        if (!initialized || firebaseAnalytics == null) {
            callback.onFailure("GTM not initialized");
            return;
        }

        try {
            Map<String, Object> payload = new HashMap<>();
            if (parameters != null) {
                payload.putAll(parameters);
            }
            payload.put("event", event);
            recordDataLayer(payload);

            Bundle bundle = GTMParameterSanitizer.toBundle(parameters);
            firebaseAnalytics.logEvent(GTMParameterSanitizer.eventName(event), bundle);
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to push event", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void setUserProperty(String key, Object value, Callback callback) {
        if (!initialized || firebaseAnalytics == null) {
            callback.onFailure("GTM not initialized");
            return;
        }

        try {
            Map<String, Object> entry = new HashMap<>();
            entry.put(key, value);
            recordDataLayer(entry);
            firebaseAnalytics.setUserProperty(GTMParameterSanitizer.userPropertyName(key), GTMParameterSanitizer.userPropertyValue(value));
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to set user property", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void getValue(String key, ValueCallback callback) {
        if (!initialized) {
            callback.onFailure("GTM not initialized");
            return;
        }

        callback.onSuccess(latestDataLayerValue(key));
    }

    public void reset(Callback callback) {
        try {
            if (firebaseAnalytics != null) {
                firebaseAnalytics.resetAnalyticsData();
            }

            dataLayerEntries.clear();
            firebaseAnalytics = null;
            initialized = false;
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to reset", e);
            callback.onFailure(e.getMessage());
        }
    }

    private void recordDataLayer(Map<String, Object> values) {
        dataLayerEntries.add(new HashMap<>(values));
    }

    private Object latestDataLayerValue(String key) {
        return latestDataLayerValue(dataLayerEntries, key);
    }

    static Object latestDataLayerValue(List<Map<String, Object>> entries, String key) {
        for (int i = entries.size() - 1; i >= 0; i--) {
            Map<String, Object> entry = entries.get(i);
            if (entry.containsKey(key)) {
                return entry.get(key);
            }
        }
        return null;
    }

    public static Map<String, Object> jsObjectToMap(JSObject jsObject) {
        Map<String, Object> map = new HashMap<>();
        Iterator<String> keys = jsObject.keys();
        while (keys.hasNext()) {
            String key = keys.next();
            try {
                Object value = jsObject.get(key);
                map.put(key, value);
            } catch (Exception e) {
                Log.e(TAG, "Failed to convert key: " + key, e);
            }
        }
        return map;
    }

    static final class GTMParameterSanitizer {

        private GTMParameterSanitizer() {}

        static String eventName(String name) {
            return sanitize(name, 40);
        }

        static String parameterName(String name) {
            return sanitize(name, 40);
        }

        static String userPropertyName(String name) {
            return sanitize(name, 24);
        }

        static String userPropertyValue(Object value) {
            String valueString = stringValue(value);
            if (valueString == null) {
                return null;
            }
            if (valueString.length() <= 36) {
                return valueString;
            }
            return valueString.substring(0, 36);
        }

        static String stringValue(Object value) {
            if (value == null) {
                return null;
            }
            if (value instanceof String) {
                return (String) value;
            }
            if (value instanceof Boolean) {
                return (Boolean) value ? "true" : "false";
            }
            return String.valueOf(value);
        }

        static Bundle toBundle(Map<String, Object> parameters) {
            Bundle bundle = new Bundle();
            if (parameters == null) {
                return bundle;
            }

            for (Map.Entry<String, Object> entry : parameters.entrySet()) {
                putAnalyticsValue(bundle, parameterName(entry.getKey()), entry.getValue());
            }
            return bundle;
        }

        private static void putAnalyticsValue(Bundle bundle, String key, Object value) {
            if (value == null) {
                return;
            }

            if (value instanceof String) {
                bundle.putString(key, (String) value);
                return;
            }
            if (value instanceof Integer) {
                bundle.putLong(key, ((Integer) value).longValue());
                return;
            }
            if (value instanceof Long) {
                bundle.putLong(key, (Long) value);
                return;
            }
            if (value instanceof Double) {
                bundle.putDouble(key, (Double) value);
                return;
            }
            if (value instanceof Float) {
                bundle.putDouble(key, ((Float) value).doubleValue());
                return;
            }
            if (value instanceof Boolean) {
                bundle.putString(key, ((Boolean) value) ? "true" : "false");
                return;
            }

            bundle.putString(key, String.valueOf(value));
        }

        private static String sanitize(String value, int maxLength) {
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < value.length(); i++) {
                char character = value.charAt(i);
                if (Character.isLetterOrDigit(character) || character == '_') {
                    builder.append(character);
                } else {
                    builder.append('_');
                }
            }

            String cleaned = builder.toString();
            if (cleaned.isEmpty()) {
                return "event";
            }

            if (cleaned.length() <= maxLength) {
                return cleaned;
            }

            return cleaned.substring(0, maxLength);
        }
    }
}
