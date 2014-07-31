/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.utils {
import flash.events.EventDispatcher;
import flash.events.NetStatusEvent;

import org.osmf.net.NetStreamCodes;

public class SmoothMonitor {
    private static const ACCEPTED_BUFFERING_COUNT:uint = 2;

    private var _bufferingCount:Number = 0;

    public function SmoothMonitor() {
    }

    public function appendListeners(netStream:EventDispatcher):void {
        netStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
    }

    private function onNetStatus(event:NetStatusEvent):void {
        if (event.info.code == NetStreamCodes.NETSTREAM_BUFFER_EMPTY) {
            _bufferingCount++;
            Console.getInstance().warn("Registered buffering incident, bufferingCount='" + _bufferingCount + "'");
        }

        if (event.info.code == NetStreamCodes.NETSTREAM_SEEK_NOTIFY) {
            _bufferingCount = 0;
            Console.getInstance().info("Reset buffering incidents counter");
        }
    }

    public function get fix():Number {
        var fix:Number = _bufferingCount - ACCEPTED_BUFFERING_COUNT;
        return fix > 0 ? fix : 0;
    }
}
}
