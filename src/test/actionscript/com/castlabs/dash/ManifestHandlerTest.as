package com.castlabs.dash {

import com.castlabs.dash.handlers.ManifestHandler;

import org.flexunit.Assert;

public class ManifestHandlerTest {
    public function ManifestHandlerTest() {
    }

    [Test(description = "This tests addition")]
    public function testSegmentTemplate():void {
        var x:ManifestHandler = new ManifestHandler("", null);
        Assert.assertEquals( 8, x );
    }
}
}
