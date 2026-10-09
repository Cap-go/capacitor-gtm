package app.capgo.gtm;

import static org.junit.Assert.assertEquals;

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
}
