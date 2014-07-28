package com.castlabs.dash {

import flash.events.Event;

import mockolate.mock;
import mockolate.nice;
import mockolate.prepare;
import mockolate.verify;

import org.flexunit.async.Async;
import org.hamcrest.assertThat;
import org.hamcrest.object.equalTo;

public class HamcrestAndMockolateTest {
    public function HamcrestAndMockolateTest() {
    }

    [Before(async, timeout=5000)]
    public function setUp():void {
        Async.proceedOnEvent(this, prepare(Foo), Event.COMPLETE);
    }

    [Test]
    public function testFoo():void {
        var foo:Foo = nice(Foo);

        mock(foo).method('bar').returns('baz');

        var baz:String = foo.bar();

        verify(foo);

        assertThat(baz, equalTo('baz'));
    }
}
}
