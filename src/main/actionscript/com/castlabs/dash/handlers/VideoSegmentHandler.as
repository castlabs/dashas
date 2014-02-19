/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.boxes.FLVTag;
import com.castlabs.dash.boxes.Mixer;
import com.castlabs.dash.boxes.MovieFragmentBox;
import com.castlabs.dash.boxes.TrackFragmentBox;
import com.castlabs.dash.boxes.TrackFragmentHeaderBox;
import com.castlabs.dash.boxes.TrackFragmentRunBox;

import flash.utils.ByteArray;

public class VideoSegmentHandler extends MediaSegmentHandler {
    private static const MIN_CTO:int = -33;

    public function VideoSegmentHandler(segment:ByteArray, messages:Vector.<FLVTag>, defaultSampleDuration:uint,
                                        timescale:uint, timestamp:Number, mixer:Mixer) {
        super(segment, messages, defaultSampleDuration, timescale, timestamp, mixer);
    }

    protected override function buildMessage(sampleDuration:uint, sampleSize:uint, compositionTimeOffset:Number,
                                             dataOffset:uint, ba:ByteArray):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsVideo();
        message.timestamp = _timestamp;
        _timestamp = message.timestamp + sampleDuration * 1000 / _timescale;

        if (!isNaN(compositionTimeOffset)) {
            message.compositionTimestamp = compositionTimeOffset * 1000 / _timescale - MIN_CTO;
        }

        message.length = sampleSize;
        message.dataOffset = dataOffset;
        message.data = new ByteArray();

        ba.position = message.dataOffset;
        ba.readBytes(message.data, 0, sampleSize);

        return message;
    }

}
}
