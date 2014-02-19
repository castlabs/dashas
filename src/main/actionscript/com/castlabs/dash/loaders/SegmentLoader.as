/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.utils.BandwidthMonitor;

import flash.errors.IllegalOperationError;
import flash.events.EventDispatcher;

public class SegmentLoader extends EventDispatcher {
    protected var _segment:Segment;
    protected var _monitor:BandwidthMonitor;

    public function SegmentLoader(segment:Segment, monitor:BandwidthMonitor) {
        _segment = segment;
        _monitor = monitor;
    }

    public function load():void {
        throw new IllegalOperationError("Method not implemented");
    }

    public function close():void {
        throw new IllegalOperationError("Method not implemented");
    }
}
}
