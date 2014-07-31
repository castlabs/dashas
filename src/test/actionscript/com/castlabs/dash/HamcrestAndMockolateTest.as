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
        Async.proceedOnEvent(this, prepare(Foo, Bar), Event.COMPLETE);
    }

    [Test]
    public function testFoo():void {
        var foo:Foo = nice(Foo);

        mock(foo).method('bar').returns('baz');

        var baz:String = foo.bar();

        verify(foo);

        assertThat(baz, equalTo('baz'));
    }

    [Test]
    public function testContext():void {
        var b:Bar = nice(Bar);

        mock(b).method('foo').returns('baz');

        var baz:String = b.foo();

        // unmocked methods return null
        var bar:String = b.bar();

        verify(b);

        assertThat(baz, equalTo('baz'));
        assertThat(bar, equalTo(null));
    }
}
}
