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
import com.castlabs.dash.boxes.TrackExtendsBox;
import com.castlabs.dash.utils.Console;

import flash.errors.IllegalOperationError;
import flash.utils.ByteArray;

public class InitializationSegmentHandler extends SegmentHandler {
    private var _videoTimescale:Number = 0;
    private var _audioTimescale:Number = 0;
    private var _videoDefaultSampleDuration:uint = 0;
    private var _audioDefaultSampleDuration:uint = 0;
    private var _messages:Vector.<FLVTag> = new Vector.<FLVTag>();

    public function InitializationSegmentHandler(ba:ByteArray) {
        parseMovieBox(ba);
    }

    public function get videoTimescale():Number {
        return _videoTimescale;
    }

    public function get audioTimescale():Number {
        return _audioTimescale;
    }

    public function get videoDefaultSampleDuration():Number {
        return _videoDefaultSampleDuration;
    }

    public function get audioDefaultSampleDuration():Number {
        return _audioDefaultSampleDuration;
    }

    public function get messages():Vector.<FLVTag> {
        return _messages.concat(); // a shallow copy
    }

    private function parseMovieBox(ba:ByteArray):void {
        var offsetAndSize:Object = goToBox("moov", ba, 0);
        var offset:uint = offsetAndSize.offset;
        var size:uint = offsetAndSize.size;

        var movie:MovieBox = new MovieBox(offset, size);
        movie.parse(ba);

        var videoTrack:TrackBox = findTrackWithSpecifiedType(movie, videoTrackType());
        _videoTimescale = getTimescale(videoTrack);
        loadVideoMessages(videoTrack);
        _videoDefaultSampleDuration = loadDefaultSampleDuration(movie, videoTrack.tkhd.id);

        var audioTrack:TrackBox = findTrackWithSpecifiedType(movie, audioTrackType());
        if (audioTrack != null) {
            _audioTimescale = getTimescale(audioTrack);
            loadAudioMessages(audioTrack);
            _audioDefaultSampleDuration = loadDefaultSampleDuration(movie, audioTrack.tkhd.id);
        }
    }

    private function findTrackWithSpecifiedType(movie:MovieBox, expectedTrackType:String):TrackBox {
        for each (var track:TrackBox in movie.traks) {
            if (track.mdia.hdlr.type == expectedTrackType) {
                return track;
            }
        }

        return null;
    }

    private function getTimescale(track:TrackBox):Number {
        return track.mdia.mdhd.timescale;
    }

    private function loadVideoMessages(track:TrackBox):void {
        var sampleEntry:SampleEntry = buildSampleEntry(track);
        var message:FLVTag = buildVideoMessage(sampleEntry);
        _messages.push(message);
    }

    private function loadAudioMessages(track:TrackBox):void {
        var sampleEntry:SampleEntry = buildSampleEntry(track);
        var message:FLVTag = buildAudioMessage(sampleEntry);
        _messages.push(message);
    }

    private function loadDefaultSampleDuration(movie:MovieBox, trackId:uint):uint {
        for each (var trex:TrackExtendsBox in movie.mvex.trexs) {
            if (trackId == trex.trackId) {
                return trex.defaultSampleDuration;
            }
        }

        throw Console.getInstance().warn("Default sample duration isn't defined, trackId='" + trackId + "'");
    }

    private function buildSampleEntry(track:TrackBox):SampleEntry {
        return track.mdia.minf.stbl.stsd.sampleEntries[0];
    }

    public function toString():String {
        return "videoTimescale='" + _videoTimescale + "', videoDefaultSampleDuration='" + _videoDefaultSampleDuration
                + "', messagesCount='" + _messages.length + "'";
    }

    private function audioTrackType():String {
        return 'soun';
    }

    private function buildAudioMessage(sampleEntry:SampleEntry):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsAudio();

        message.timestamp = 0;

        message.length = sampleEntry.data.length;

        message.data = new ByteArray();
        sampleEntry.data.readBytes(message.data, 0, sampleEntry.data.length);

        message.setup = true;

        return message;
    }

    private function videoTrackType():String {
        return 'vide';
    }

    private function buildVideoMessage(sampleEntry:SampleEntry):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsVideo();

        message.timestamp = 0;

        message.length = sampleEntry.data.length;

        message.data = new ByteArray();
        sampleEntry.data.readBytes(message.data, 0, sampleEntry.data.length);

        message.frameType = FLVTag.UNKNOWN;

        message.compositionTimestamp = 0;

        message.setup = true;

        return message;
    }
}
}
