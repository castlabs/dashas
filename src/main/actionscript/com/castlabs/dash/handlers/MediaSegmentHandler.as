/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.boxes.FLVTag;
import com.castlabs.dash.boxes.MovieFragmentBox;
import com.castlabs.dash.boxes.Muxer;
import com.castlabs.dash.boxes.NalUnit;
import com.castlabs.dash.boxes.TrackFragmentHeaderBox;
import com.castlabs.dash.boxes.TrackFragmentRunBox;

import flash.utils.ByteArray;

public class MediaSegmentHandler extends SegmentHandler {
    private static var _nalUnit:NalUnit = new NalUnit(); //TODO inject
    private static const MIN_CTO:int = -33;

    protected var _messages:Vector.<FLVTag>;
    protected var _videoTimescale:uint;
    protected var _audioTimescale:uint;
    protected var _audioTimestamp:Number;
    protected var _videoTimestamp:Number;
    private var _startTimestamp:Number;

    private var _bytes:ByteArray;
    private var _movieFragmentBox:MovieFragmentBox;
    private var _videoDefaultSampleDuration:uint;
    private var _audioDefaultSampleDuration:uint;

    private var _muxer:Muxer;

    public function MediaSegmentHandler(ba:ByteArray, messages:Vector.<FLVTag>, videoDefaultSampleDuration:uint,
                                        audioDefaultSampleDuration:uint, videoTimescale:uint,
                                        audioTimescale:uint, timestamp:Number, muxer:Muxer) {
        _messages = messages;
        _videoDefaultSampleDuration = videoDefaultSampleDuration;
        _audioDefaultSampleDuration = audioDefaultSampleDuration;
        _videoTimescale = videoTimescale;
        _audioTimescale = audioTimescale;
        _audioTimestamp = timestamp;
        _videoTimestamp = timestamp;
        _startTimestamp = timestamp;
        _muxer = muxer;

        while (ba.bytesAvailable > 0) {
            parseMovieFragmentBox(ba, ba.position);
            parseMediaDataBox(ba);
        }
        mux();
    }

    public function get bytes():ByteArray {
        return _bytes;
    }

    public function get startTimestamp():Number {
        return _startTimestamp;
    }

    private function parseMovieFragmentBox(ba:ByteArray, start:uint):void {
        var offsetAndSize:Object = goToBox("moof", ba, start);
        var offset:uint = offsetAndSize.offset;
        var size:uint = offsetAndSize.size;

        _movieFragmentBox = new MovieFragmentBox(offset, size);
        _movieFragmentBox.parse(ba);
    }

    private function parseMediaDataBox(ba:ByteArray):void {
        var initPosition:Number = ba.position;
        var size:Number = ba.readUnsignedInt();
        var type:String = ba.readUTFBytes(4);

        validateType("mdat", type);
        validateSize(size);

        var videoTRunBox:TrackFragmentRunBox = _movieFragmentBox.trafs[0].truns[0];
        var samplesDuration:uint = videoTRunBox.calcSamplesDuration(_videoDefaultSampleDuration) * 1000 / _videoTimescale;
        if (_videoTimestamp + samplesDuration > 0) {
            if (_videoTimestamp < 0) {
                _startTimestamp = _videoTimestamp - _startTimestamp;
                _videoTimestamp = 0;
                _audioTimestamp = 0;
            }
            processTrackBox(ba);
        } else {
            _videoTimestamp += samplesDuration;
        }

        ba.position = initPosition + size;
    }

    private function mux():void {
        _bytes = _muxer.mux(_messages);
        _bytes.position = 0; // reset
    }

    public function processTrackBox(ba:ByteArray):void {
        validateTracksNumber(_movieFragmentBox.trafs.length);

        var headerBox:TrackFragmentHeaderBox = _movieFragmentBox.trafs[0].tfhd;
        var runBoxes:Vector.<TrackFragmentRunBox> = _movieFragmentBox.trafs[0].truns;
        for each (var runBox:TrackFragmentRunBox in runBoxes) {
            var baseDataOffset:Number = loadBaseDataOffset(headerBox);

            setVideoDefaultDurationIfNeeded(runBox, headerBox);
            loadMessages(runBox, baseDataOffset, ba, true);
        }

        if (_movieFragmentBox.trafs.length > 1) {
            headerBox = _movieFragmentBox.trafs[1].tfhd;
            runBoxes = _movieFragmentBox.trafs[1].truns;
            for each (var runBox1:TrackFragmentRunBox in runBoxes) {
                var baseDataOffset1:Number = loadBaseDataOffset(headerBox);

                setAudioDefaultDurationIfNeeded(runBox1, headerBox);
                loadMessages(runBox1, baseDataOffset1, ba, false);
            }
        }
    }

    private function loadBaseDataOffset(headerBox:TrackFragmentHeaderBox):Number {

        // otherwise point to segment's begin
        return (headerBox.baseDataOffsetPresent) ? headerBox.baseDataOffset : _movieFragmentBox.offset;
    }

    private function setVideoDefaultDurationIfNeeded(runBox:TrackFragmentRunBox, headerBox:TrackFragmentHeaderBox):void {
        if (!runBox.sampleDurationPresent && headerBox.defaultSampleDurationPresent) {
            _videoDefaultSampleDuration = headerBox.defaultSampleDuration;
        }
    }

    private function setAudioDefaultDurationIfNeeded(runBox:TrackFragmentRunBox, headerBox:TrackFragmentHeaderBox):void {
        if (!runBox.sampleDurationPresent && headerBox.defaultSampleDurationPresent) {
            _audioDefaultSampleDuration = headerBox.defaultSampleDuration;
        }
    }

    private function loadMessages(runBox:TrackFragmentRunBox, baseDataOffset:Number, ba:ByteArray, video:Boolean):void {
        var dataOffset:uint = runBox.dataOffset + baseDataOffset;
        var sampleSizes:Vector.<uint> = runBox.sampleSize;

        for (var i:uint = 0; i < sampleSizes.length; i++) {
            var sampleDuration:uint = loadSampleDuration(runBox, i, video ? _videoDefaultSampleDuration : _audioDefaultSampleDuration);
            var compositionTimeOffset:int = loadCompositionTimeOffset(runBox, i);
            var sampleDependsOn:uint = loadSampleDependsOn(runBox, i);
            var sampleIsDependedOn:uint = loadSampleIsDependedOn(runBox, i);

            var message:FLVTag = video ? buildVideoMessage(sampleDuration, sampleSizes[i], sampleDependsOn, sampleIsDependedOn,
                    compositionTimeOffset, dataOffset, ba) : buildAudioMessage(sampleDuration, sampleSizes[i], sampleDependsOn, sampleIsDependedOn,
                    compositionTimeOffset, dataOffset, ba);

            _messages.push(message);

            dataOffset = dataOffset + sampleSizes[i];
        }
    }

    private function loadSampleDuration(runBox:TrackFragmentRunBox, i:uint, def:uint):uint {
        return i < runBox.sampleDuration.length ? runBox.sampleDuration[i] : def;
    }

    private function loadCompositionTimeOffset(runBox:TrackFragmentRunBox, i:uint):int {
        return i < runBox.sampleCompositionTimeOffset.length ? runBox.sampleCompositionTimeOffset[i] : NaN;
    }

    private function loadSampleDependsOn(runBox:TrackFragmentRunBox, i:uint):uint {
        return i < runBox.sampleDependsOn.length ? runBox.sampleDependsOn[i] : 0;
    }

    private function loadSampleIsDependedOn(runBox:TrackFragmentRunBox, i:uint):uint {
        return i < runBox.sampleIsDependedOn.length ? runBox.sampleIsDependedOn[i] : 0;
    }

    protected function buildVideoMessage(sampleDuration:uint, sampleSize:uint, sampleDependsOn:uint,
                                             sampleIsDependedOn:uint, compositionTimeOffset:Number,
                                             dataOffset:uint, ba:ByteArray):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsVideo();

        message.timestamp = _videoTimestamp;
        _videoTimestamp = message.timestamp + sampleDuration * 1000 / _videoTimescale;

        message.length = sampleSize;

        message.dataOffset = dataOffset;

        message.data = new ByteArray();
        ba.position = message.dataOffset;
        ba.readBytes(message.data, 0, sampleSize);

        if (sampleDependsOn == 2) {
            message.frameType = FLVTag.I_FRAME;
        } else if (sampleDependsOn == 1 && sampleIsDependedOn == 1) {
            message.frameType = FLVTag.P_FRAME;
        } else if (sampleDependsOn == 1 && sampleIsDependedOn == 2) {
            message.frameType = FLVTag.B_FRAME;
        } else {
            message.frameType = _nalUnit.parse(message.data);
        }

        if (!isNaN(compositionTimeOffset)) {
            message.compositionTimestamp = compositionTimeOffset * 1000 / _videoTimescale - MIN_CTO;
        }

        return message;
    }


    protected function buildAudioMessage(sampleDuration:uint, sampleSize:uint, sampleDependsOn:uint,
                                             sampleIsDependedOn:uint, compositionTimeOffset:Number,
                                             dataOffset:uint, ba:ByteArray):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsAudio();

        message.timestamp = _audioTimestamp;
        _audioTimestamp = message.timestamp + sampleDuration * 1000 / _audioTimescale;

        message.length = sampleSize;

        message.dataOffset = dataOffset;

        message.data = new ByteArray();
        ba.position = message.dataOffset;
        ba.readBytes(message.data, 0, sampleSize);

        return message;
    }
}
}
