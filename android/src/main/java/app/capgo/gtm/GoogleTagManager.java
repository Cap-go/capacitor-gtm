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
        void onError(String error);
    }

    public interface ValueCallback {
        void onValue(Object value);
        void onError(String error);
    }

    public GoogleTagManager(Context context) {
        this.context = context;
    }

    public void initialize(String containerId, long timeout, final Callback callback) {
        if (initialized) {
            callback.onSuccess();
            return;
        }

        tagManager = TagManager.getInstance(context);
        tagManager.setVerboseLoggingEnabled(true);
        dataLayer = tagManager.getDataLayer();

        PendingResult<ContainerHolder> pending = tagManager.loadContainerPreferFresh(containerId, -1);
        
        pending.setResultCallback(new ResultCallback<ContainerHolder>() {
            @Override
            public void onResult(ContainerHolder holder) {
                containerHolder = holder;
                container = holder.getContainer();
                initialized = true;
                Log.d(TAG, "Container loaded: " + containerId);
                callback.onSuccess();
            }
        }, timeout, TimeUnit.MILLISECONDS);
    }

    public void push(String event, JSObject parameters, Callback callback) {
        if (!initialized) {
            callback.onError("Google Tag Manager not initialized");
            return;
        }

        Map<String, Object> dataLayerMap = new HashMap<>();
        dataLayerMap.put("event", event);
        
        if (parameters != null) {
            Iterator<String> keys = parameters.keys();
            while (keys.hasNext()) {
                String key = keys.next();
                dataLayerMap.put(key, parameters.get(key));
            }
        }

        dataLayer.push(dataLayerMap);
        callback.onSuccess();
    }

    public void setUserProperty(String key, Object value, Callback callback) {
        if (!initialized) {
            callback.onError("Google Tag Manager not initialized");
            return;
        }

        Map<String, Object> dataLayerMap = new HashMap<>();
        dataLayerMap.put(key, value);
        dataLayer.push(dataLayerMap);
        callback.onSuccess();
    }

    public void getValue(String key, ValueCallback callback) {
        if (!initialized) {
            callback.onError("Google Tag Manager not initialized");
            return;
        }

        Object value = dataLayer.get(key);
        callback.onValue(value);
    }

    public void reset(Callback callback) {
        if (containerHolder != null) {
            containerHolder.release();
        }
        
        tagManager = null;
        container = null;
        containerHolder = null;
        dataLayer = null;
        initialized = false;
        
        callback.onSuccess();
    }
}
