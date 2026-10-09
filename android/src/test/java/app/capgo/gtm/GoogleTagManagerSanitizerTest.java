package app.capgo.gtm;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.Test;

public class GoogleTagManagerSanitizerTest {

    @Test
    public void eventName_isSanitized() {
        assertEquals("purchase_complete_", GoogleTagManager.GTMParameterSanitizer.eventName("purchase-complete!"));
    }

    @Test
    public void stringValue_convertsBoolean() {
        assertEquals("true", GoogleTagManager.GTMParameterSanitizer.stringValue(true));
    }

    @Test
    public void latestDataLayerValue_returnsMostRecentMatchingEntry() {
        List<Map<String, Object>> entries = new ArrayList<>();
        entries.add(Map.of("currency", "USD"));
        entries.add(Map.of("event", "purchase"));
        entries.add(Map.of("currency", "EUR"));

        assertEquals("EUR", GoogleTagManager.latestDataLayerValue(entries, "currency"));
        assertEquals("purchase", GoogleTagManager.latestDataLayerValue(entries, "event"));
        assertNull(GoogleTagManager.latestDataLayerValue(entries, "missing"));
    }
}
