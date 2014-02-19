/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.boxes.FLVTag;
import com.castlabs.dash.boxes.MovieBox;
import com.castlabs.dash.boxes.SampleEntry;
import com.castlabs.dash.boxes.TrackBox;

import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;

public class InitializationSegmentHandler extends SegmentHandler {
    private var _timescale:Number = 0;
    private var _defaultSampleDuration:uint = 0;
    private var _messages:Vector.<FLVTag> = new Vector.<FLVTag>();

    public function InitializationSegmentHandler(ba:ByteArray) {
        parseMovieBox(ba);
    }

    public function get timescale():Number {
        return _timescale;
    }

    public function get defaultSampleDuration():Number {
        return _defaultSampleDuration;
    }

    public function get messages():Vector.<FLVTag> {
        return _messages.concat(); // a shallow copy
    }

    private function parseMovieBox(ba:ByteArray):void {
        var offsetAndSize:Object = goToBox("moov", ba);
        var offset:uint = offsetAndSize.offset;
        var size:uint = offsetAndSize.size;

        var movieBox:MovieBox = new MovieBox(offset, size);
        movieBox.parse(ba);

        loadMessagesAndTimescale(movieBox);
        loadDefaultSampleDuration(movieBox);
    }

    private function loadMessagesAndTimescale(movieBox:MovieBox):void {
        validateTracksNumber(movieBox.traks.length);

        var track:TrackBox = movieBox.traks[0];
        var sampleEntry:SampleEntry = buildSampleEntry(track);
        var message:FLVTag = buildMessage(sampleEntry);

        _timescale = track.mdia.mdhd.timescale;
        _messages.push(message);
    }

    private function loadDefaultSampleDuration(movieBox:MovieBox):void {
        if (movieBox.mvex != null) {
            validateTracksNumber(movieBox.mvex.trexs.length);
            _defaultSampleDuration = movieBox.mvex.trexs[0].defaultSampleDuration;
        }
    }

    private function buildSampleEntry(track:TrackBox):SampleEntry {
        return track.mdia.minf.stbl.stsd.sampleEntries[0];
    }

    protected function buildMessage(sampleEntry:SampleEntry):FLVTag {
        throw new IllegalOperationError("Method isn't implemented");
    }
}
}
