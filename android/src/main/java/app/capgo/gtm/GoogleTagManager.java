package app.capgo.gtm;

import android.content.Context;
import android.util.Log;
import com.getcapacitor.JSObject;
import com.google.android.gms.common.api.PendingResult;
import com.google.android.gms.common.api.ResultCallback;
import com.google.android.gms.tagmanager.Container;
import com.google.android.gms.tagmanager.ContainerHolder;
import com.google.android.gms.tagmanager.DataLayer;
import com.google.android.gms.tagmanager.TagManager;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class GoogleTagManager {

    private static final String TAG = "GoogleTagManager";
    private Context context;
    private TagManager tagManager;
    private Container container;
    private ContainerHolder containerHolder;
    private DataLayer dataLayer;
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

        try {
            tagManager = TagManager.getInstance(context);
            dataLayer = tagManager.getDataLayer();

            // Set timeout
            long timeoutMs = timeout != null ? timeout.longValue() : 2000;

            // Load container
            PendingResult<ContainerHolder> pending = tagManager.loadContainerPreferFresh(containerId, -1);

            pending.setResultCallback(
                new ResultCallback<ContainerHolder>() {
                    @Override
                    public void onResult(ContainerHolder containerHolder) {
                        if (containerHolder != null && containerHolder.getStatus().isSuccess()) {
                            GoogleTagManager.this.containerHolder = containerHolder;
                            GoogleTagManager.this.container = containerHolder.getContainer();
                            initialized = true;
                            callback.onSuccess();
                        } else {
                            callback.onFailure("Failed to load container");
                        }
                    }
                },
                timeoutMs,
                TimeUnit.MILLISECONDS
            );
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize GTM", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void push(String event, Map<String, Object> parameters, Callback callback) {
        if (!initialized) {
            callback.onFailure("GTM not initialized");
            return;
        }

        try {
            Map<String, Object> dataLayerMap = new HashMap<>();
            dataLayerMap.put("event", event);

            if (parameters != null) {
                dataLayerMap.putAll(parameters);
            }

            dataLayer.push(dataLayerMap);
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to push event", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void setUserProperty(String key, Object value, Callback callback) {
        if (!initialized) {
            callback.onFailure("GTM not initialized");
            return;
        }

        try {
            dataLayer.push(DataLayer.mapOf(key, value));
            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to set user property", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void getValue(String key, ValueCallback callback) {
        if (!initialized || container == null) {
            callback.onFailure("GTM not initialized");
            return;
        }

        try {
            Object value = container.getString(key);
            if (value == null) {
                value = container.getDouble(key);
            }
            if (value == null) {
                value = container.getBoolean(key);
            }
            callback.onSuccess(value);
        } catch (Exception e) {
            Log.e(TAG, "Failed to get value", e);
            callback.onFailure(e.getMessage());
        }
    }

    public void reset(Callback callback) {
        try {
            if (dataLayer != null) {
                dataLayer.push(DataLayer.mapOf("gtm.clear", true));
            }

            if (containerHolder != null) {
                containerHolder.release();
            }

            tagManager = null;
            container = null;
            containerHolder = null;
            dataLayer = null;
            initialized = false;

            callback.onSuccess();
        } catch (Exception e) {
            Log.e(TAG, "Failed to reset", e);
            callback.onFailure(e.getMessage());
        }
    }

    // Helper method to convert JSObject to Map
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
}
