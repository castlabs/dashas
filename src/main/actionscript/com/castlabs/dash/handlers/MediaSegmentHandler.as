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
import com.castlabs.dash.boxes.TrackFragmentHeaderBox;
import com.castlabs.dash.boxes.TrackFragmentRunBox;

import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;

public class MediaSegmentHandler extends SegmentHandler {
    protected var _messages:Vector.<FLVTag>;
    protected var _timescale:uint;
    protected var _timestamp:Number;

    private var _bytes:ByteArray;
    private var _movieFragmentBox:MovieFragmentBox;
    private var _defaultSampleDuration:uint;

    private var _mixer:Mixer;

    public function MediaSegmentHandler(ba:ByteArray, messages:Vector.<FLVTag>, defaultSampleDuration:uint,
                                        timescale:uint, timestamp:Number, mixer:Mixer) {
        _messages = messages;
        _defaultSampleDuration = defaultSampleDuration;
        _timescale = timescale;
        _timestamp = timestamp;

        _mixer = mixer;

        parseMovieFragmentBox(ba);
        parseMediaDataBox(ba);
    }

    public function get bytes():ByteArray {
        return _bytes;
    }

    private function parseMovieFragmentBox(ba:ByteArray):void {
        var offsetAndSize:Object = goToBox("moof", ba);
        var offset:uint = offsetAndSize.offset;
        var size:uint = offsetAndSize.size;

        _movieFragmentBox = new MovieFragmentBox(offset, size);
        _movieFragmentBox.parse(ba);
    }

    private function parseMediaDataBox(ba:ByteArray):void {
        var size:Number = ba.readUnsignedInt();
        var type:String = ba.readUTFBytes(4);

        validateType("mdat", type);
        validateSize(size);

        processTrackBox(ba);

        _bytes = _mixer.mix(_messages);
        _bytes.position = 0; // reset
    }

    public function processTrackBox(ba:ByteArray):void {
        validateTracksNumber(_movieFragmentBox.trafs.length);

        var headerBox:TrackFragmentHeaderBox = _movieFragmentBox.trafs[0].tfhd;
        var runBoxes:Vector.<TrackFragmentRunBox> = _movieFragmentBox.trafs[0].truns;

        for each (var runBox:TrackFragmentRunBox in runBoxes) {
            var sampleDurations:Vector.<uint> = runBox.sampleDuration;
            var baseDataOffset:Number = loadBaseDataOffset(headerBox);

            setDefaultDurationIfNeeded(runBox, headerBox, sampleDurations);
            loadMessages(runBox, baseDataOffset, sampleDurations, ba);
        }
    }

    private function loadBaseDataOffset(headerBox:TrackFragmentHeaderBox):Number {

        // otherwise point to segment's begin
        return (headerBox.baseDataOffsetPresent) ? headerBox.baseDataOffset : _movieFragmentBox.offset;
    }

    private function setDefaultDurationIfNeeded(runBox:TrackFragmentRunBox, headerBox:TrackFragmentHeaderBox,
                                                sampleDurations:Vector.<uint>):void {

        // check tfhd for default duration
        if (!runBox.sampleDurationPresent && headerBox.defaultSampleDurationPresent) {
            for (var h:uint = 0; h < sampleDurations.length; h++) {
                sampleDurations[h] = headerBox.defaultSampleDuration;
            }
        }

        // check trex for default duration
        if (!runBox.sampleDurationPresent && _defaultSampleDuration) {
            for (var k:uint = 0; k < sampleDurations.length; k++) {
                sampleDurations[k] = _defaultSampleDuration;
            }
        }
    }

    private function loadMessages(runBox:TrackFragmentRunBox, baseDataOffset:Number,
                                  sampleDurations:Vector.<uint>, ba:ByteArray):void {
        var dataOffset:uint = runBox.dataOffset + baseDataOffset;
        var sampleSizes:Vector.<uint> = runBox.sampleSize;

        for (var i:uint = 0; i < sampleSizes.length; i++) {
            var compositionTimeOffset:int = loadCompositionTimeOffset(runBox, i);
            var message:FLVTag = buildMessage(sampleDurations[i], sampleSizes[i],
                    compositionTimeOffset, dataOffset, ba);

            _messages.push(message);

            dataOffset = dataOffset + sampleSizes[i];
        }
    }

    private function loadCompositionTimeOffset(runBox:TrackFragmentRunBox, i:uint):int {
        var compositionTimeOffsets:Vector.<int> = runBox.sampleCompositionTimeOffset;
        return (compositionTimeOffsets.length > 0) ? compositionTimeOffsets[i] : NaN;
    }

    protected function buildMessage(sampleDuration:uint, sampleSize:uint, compositionTimeOffset:Number,
                                    dataOffset:uint, ba:ByteArray):FLVTag {
        throw new IllegalOperationError("Method isn't implemented");
    }
}
}
