/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.DashContext;
import com.castlabs.dash.descriptors.segments.DataSegment;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.events.SegmentEvent;

import flash.events.AsyncErrorEvent;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.utils.ByteArray;

public class DataSegmentLoader extends SegmentLoader {
    private var status:int = 0;
    private var http:URLLoader = new URLLoader();

    public function DataSegmentLoader(context:DashContext, segment:Segment) {
        super(context, segment)
    }

    override public function load():void {
        http.dataFormat = URLLoaderDataFormat.BINARY;

        http.addEventListener(HTTPStatusEvent.HTTP_STATUS, onStatus);
        http.addEventListener(Event.COMPLETE, onComplete);
        http.addEventListener(ErrorEvent.ERROR, onError);
        http.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onError);
        http.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
        http.addEventListener(IOErrorEvent.IO_ERROR, onError);

        _context.bandwidthMonitor.appendListeners(http);

        _context.console.debug("Loading segment, url='" + getUrl() + "'");

        http.load(new URLRequest(getUrl()));
    }

    override public function close():void {
        http.close();
    }

    private function onStatus(event:HTTPStatusEvent):void {
        status = event.status;
    }

    private function onError(event:Event):void {
        _context.console.error("Connection was interrupted: " + event.toString());
        dispatchEvent(_context.buildSegmentEvent(SegmentEvent.ERROR, false, false));
    }

    protected function getUrl():String {
        return DataSegment(_segment).url;
    }

    protected function onComplete(event:Event):void {
        _context.console.debug("Loaded segment, url='" + getUrl() + "', status='" + status + "'");

        if (DataSegment(_segment).isRange && status == 200) {
            _context.console.error("Partial content wasn't returned. Please make sure that range requests " +
                    "are handle properly on the server side: https://github.com/castlabs/dashas/wiki/htaccess");
            dispatchEvent(_context.buildSegmentEvent(SegmentEvent.ERROR, false, false));
            return;
        }

        var bytes:ByteArray = URLLoader(event.target).data;
        dispatchEvent(_context.buildSegmentEvent(SegmentEvent.LOADED, false, false, _segment, bytes));
    }
}
}
