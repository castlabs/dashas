/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.boxes {

import flash.utils.ByteArray;

public class MovieFragmentBox extends Box {
    private var _trafs:Vector.<TrackFragmentBox> = new Vector.<TrackFragmentBox>();
    private var _offset:uint;

    public function MovieFragmentBox(offset:uint, size:uint) {
        super(offset, size);
        _offset = offset;
    }

    public function get trafs():Vector.<TrackFragmentBox> {
        return _trafs;
    }

    public function get offset():uint {
        return _offset;
    }

    override protected function parseChildBox(type:String, offset:uint, size:uint, ba:ByteArray):Boolean {
        if (type == "traf") {
            parseTrackFragmentBox(offset, size, ba);
            return true;
        }

        return false;
    }

    private function parseTrackFragmentBox(offset:uint, size:uint, ba:ByteArray):void {
        var traf:TrackFragmentBox = new TrackFragmentBox(offset, size);
        traf.parse(ba);
        _trafs.push(traf);
    }
}
}