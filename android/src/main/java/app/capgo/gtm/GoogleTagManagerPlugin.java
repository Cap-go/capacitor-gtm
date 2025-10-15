package app.capgo.gtm;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.Map;

@CapacitorPlugin(name = "GoogleTagManager")
public class GoogleTagManagerPlugin extends Plugin {

    private GoogleTagManager implementation;

    @Override
    public void load() {
        implementation = new GoogleTagManager(getContext());
    }

    @PluginMethod
    public void initialize(PluginCall call) {
        String containerId = call.getString("containerId");
        if (containerId == null) {
            call.reject("Missing containerId parameter");
            return;
        }

        Double timeout = call.getDouble("timeout");

        implementation.initialize(
            containerId,
            timeout,
            new GoogleTagManager.Callback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onFailure(String error) {
                    call.reject(error);
                }
            }
        );
    }

    @PluginMethod
    public void push(PluginCall call) {
        String event = call.getString("event");
        if (event == null) {
            call.reject("Missing event parameter");
            return;
        }

        JSObject parameters = call.getObject("parameters");
        Map<String, Object> paramMap = parameters != null ? GoogleTagManager.jsObjectToMap(parameters) : null;

        implementation.push(
            event,
            paramMap,
            new GoogleTagManager.Callback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onFailure(String error) {
                    call.reject(error);
                }
            }
        );
    }

    @PluginMethod
    public void setUserProperty(PluginCall call) {
        String key = call.getString("key");
        Object value = call.getData().opt("value");

        if (key == null || value == null) {
            call.reject("Missing key or value parameter");
            return;
        }

        implementation.setUserProperty(
            key,
            value,
            new GoogleTagManager.Callback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onFailure(String error) {
                    call.reject(error);
                }
            }
        );
    }

    @PluginMethod
    public void getValue(PluginCall call) {
        String key = call.getString("key");
        if (key == null) {
            call.reject("Missing key parameter");
            return;
        }

        implementation.getValue(
            key,
            new GoogleTagManager.ValueCallback() {
                @Override
                public void onSuccess(Object value) {
                    JSObject ret = new JSObject();
                    ret.put("value", value);
                    call.resolve(ret);
                }

                @Override
                public void onFailure(String error) {
                    call.reject(error);
                }
            }
        );
    }

    @PluginMethod
    public void reset(PluginCall call) {
        implementation.reset(
            new GoogleTagManager.Callback() {
                @Override
                public void onSuccess() {
                    call.resolve();
                }

                @Override
                public void onFailure(String error) {
                    call.reject(error);
                }
            }
        );
    }
}
