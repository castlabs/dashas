/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.descriptors.segments.DataSegment;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.events.SegmentEvent;
import com.castlabs.dash.utils.BandwidthMonitor;
import com.castlabs.dash.utils.Console;

import flash.events.AsyncErrorEvent;
import flash.events.ErrorEvent;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

public class DataSegmentLoader extends SegmentLoader {
    private var http:URLLoader = new URLLoader();

    public function DataSegmentLoader(segment:Segment, monitor:BandwidthMonitor) {
        super(segment, monitor)
    }

    override public function load():void {
        http.dataFormat = URLLoaderDataFormat.BINARY;

        http.addEventListener(Event.COMPLETE, onComplete);
        http.addEventListener(ErrorEvent.ERROR, onError);
        http.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
        http.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        http.addEventListener(IOErrorEvent.IO_ERROR, onError);

        _monitor.appendListeners(http);

        Console.getInstance().debug("Loading segment, url='" + getUrl() + "'");

        http.load(new URLRequest(getUrl()));
    }

    override public function close():void {
        http.close();
    }

    private function onError(event:Event):void {
        Console.getInstance().error("Connection was interrupted: " + event.toString());
        dispatchEvent(new SegmentEvent(SegmentEvent.ERROR, false, false));
    }

    protected function getUrl():String {
        return DataSegment(_segment).url;
    }

    protected function onComplete(event:Event):void {
        Console.getInstance().debug("Loaded segment, url='" + getUrl() + "'");

        var bytes:ByteArray = URLLoader(event.target).data;
        dispatchEvent(new SegmentEvent(SegmentEvent.LOADED, false, false, _segment, bytes));
    }
}
}
