/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.events {
import flash.events.Event;

public class StreamEvent extends Event {
    public static const READY:String = "streamReady";
    public static const END:String = "streamEnd";

    private var _info:Object;

    public function StreamEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false, info:Object = null) {
        super(type, bubbles, cancelable);
        _info = info;
    }

    //TODO change into more verbose field with type
    public function get info():Object {
        return _info;
    }

    // override to support re-dispatching
    override public function clone():Event {
        return new StreamEvent(type, bubbles, cancelable, info);
    }
}
}
