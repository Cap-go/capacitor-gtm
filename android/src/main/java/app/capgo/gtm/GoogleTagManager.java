package app.capgo.gtm;

import com.getcapacitor.Logger;

public class GoogleTagManager {

    public String echo(String value) {
        Logger.info("Echo", value);
        return value;
    }
}
