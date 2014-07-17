package com.castlabs.dash {

import org.flexunit.Assert;

public class FooTest {
    public function FooTest() {
    }

    [Test( description = "This tests addition" )]
    public function simpleAdd():void
    {
        var x:int = 5 + 3;
        Assert.assertEquals( 8, x );
    }
}
}
