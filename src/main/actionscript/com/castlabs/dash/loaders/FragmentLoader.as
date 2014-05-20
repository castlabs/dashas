/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.boxes.Muxer;
import com.castlabs.dash.descriptors.Representation;
import com.castlabs.dash.descriptors.segments.MediaDataSegment;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.descriptors.segments.WaitSegment;
import com.castlabs.dash.events.FragmentEvent;
import com.castlabs.dash.events.SegmentEvent;
import com.castlabs.dash.events.StreamEvent;
import com.castlabs.dash.handlers.InitializationSegmentHandler;
import com.castlabs.dash.handlers.ManifestHandler;
import com.castlabs.dash.handlers.MediaSegmentHandler;
import com.castlabs.dash.utils.AdaptiveSegmentDispatcher;
import com.castlabs.dash.utils.BandwidthMonitor;
import com.castlabs.dash.utils.Console;

import flash.events.EventDispatcher;
import flash.events.TimerEvent;
import flash.utils.ByteArray;
import flash.utils.Dictionary;
import flash.utils.Timer;

public class FragmentLoader extends EventDispatcher {
    private var _manifest:ManifestHandler;
    private var _iterator:AdaptiveSegmentDispatcher;
    private var _monitor:BandwidthMonitor;
    private var _mixer:Muxer;

    private var _initializationSegmentHandlers:Dictionary = new Dictionary();
    private var _indexSegmentFlags:Dictionary = new Dictionary();

    private var _videoSegmentHandler:MediaSegmentHandler;

    private var _videoSegmentLoaded:Boolean = false;

    private var _videoSegmentLoader:SegmentLoader;

    private var _videoSegment:MediaDataSegment;

    private var _videoOffset:Number = 0;

    private var _firstSegment:Boolean = false;

    private var _waitTimer:Timer;

    public function FragmentLoader(manifest:ManifestHandler, iterator:AdaptiveSegmentDispatcher,
                                   monitor:BandwidthMonitor, mixer:Muxer) {
       _manifest = manifest;
       _iterator = iterator;
       _monitor = monitor;
       _mixer = mixer;

       _waitTimer = new Timer(250); // 250 ms
       _waitTimer.addEventListener(TimerEvent.TIMER, loadNextFragment);
    }

    public function init():void {
        loadInitializationSegments(_manifest.videoRepresentations, onInitializationVideoSegmentLoaded);

        loadIndexSegments(_manifest.videoRepresentations, onIndexSegmentLoaded);
    }

    public function seek(timestamp:Number):Number {
        close();

        _videoSegment = MediaDataSegment(_iterator.getVideoSegment(timestamp));

        _videoOffset = timestamp;

        Console.getInstance().info("Seek to video segment: " + _videoSegment);

        return timestamp; // offset
    }

    public function loadFirstFragment():void {
        logMediaBandwidth();

        _firstSegment = true;
        _videoSegmentLoader = loadSegment(_videoSegment, onVideoSegmentLoaded);
    }

    public function loadNextFragment(timerEvent:TimerEvent = null):void {
        _waitTimer.stop();

        _videoSegmentLoaded = false;

        if (!_videoSegmentLoaded) {
            var segment2:Segment = _iterator.getVideoSegment(_videoSegment.endTimestamp);

            if (segment2 is WaitSegment) {
                _waitTimer.start();
                Console.getInstance().debug("Received wait segment.");
                return;
            }

            _videoSegment = MediaDataSegment(segment2);
        }

        if (!_videoSegment) { // notify end
            dispatchEvent(new StreamEvent(StreamEvent.END));
            reset();
            return;
        }

        logMediaBandwidth();

        if (!_videoSegmentLoaded) {
            Console.getInstance().info("Next video segment: " + _videoSegment);
            _videoSegmentLoader = loadSegment(_videoSegment, onVideoSegmentLoaded);
        }
    }

    private function logMediaBandwidth():void {
        for each (var representation2:Representation in _manifest.videoRepresentations) {
            if (representation2.internalId == _videoSegment.internalRepresentationId) {
                Console.getInstance().appendVideoBandwidth(representation2.bandwidth);
                break;
            }
        }
    }

    public function close():void {
        if (_videoSegmentLoader != null) {
            _videoSegmentLoader.close();
        }

        _waitTimer.stop();

        reset();
    }

    private function onInitializationVideoSegmentLoaded(event:SegmentEvent):void {
        Console.getInstance().debug("Creating video initialization segment...");

        var handler:InitializationSegmentHandler = new InitializationSegmentHandler(event.bytes);

        Console.getInstance().debug("Created video initialization segment, " + handler.toString());

        _initializationSegmentHandlers[event.segment.internalRepresentationId] = handler;

        notifyReadyIfNeeded();
    }

    private function onIndexSegmentLoaded(event:SegmentEvent):void {
        _indexSegmentFlags[event.segment.internalRepresentationId] = true;
        notifyReadyIfNeeded();
    }

    private function loadInitializationSegments(representations:Vector.<Representation>, callback:Function):void {
        for each (var representation:Representation in representations) {
            var segment:Segment = representation.getInitializationSegment();
            loadSegment(segment, callback);
        }
    }

    private function loadIndexSegments(representations:Vector.<Representation>, callback:Function):void {
        for each (var representation:Representation in representations) {
            var segment:Segment = representation.getIndexSegment();
            loadSegment(segment, callback);
        }
    }

    private function notifyReadyIfNeeded():void {
        var expectedLength:Number = _manifest.videoRepresentations.length;
        var initializationSegmentsLoaded:Boolean = getLength(_initializationSegmentHandlers) == expectedLength;
        var indexSegmentsLoaded:Boolean = getLength(_indexSegmentFlags) == expectedLength;

        if (initializationSegmentsLoaded && indexSegmentsLoaded) {
            dispatchEvent(new StreamEvent(StreamEvent.READY, false, false, _manifest));
        }
    }

    public static function getLength(dict:Dictionary):Number {
        var n:int = 0;

        for (var key:* in dict) {
            n++;
        }

        return n;
    }

    private function onVideoSegmentLoaded(event:SegmentEvent):void {
        var _initializationSegmentHandler:InitializationSegmentHandler =
                _initializationSegmentHandlers[event.segment.internalRepresentationId];

        var offset:Number = findSmallerOffset();

        Console.getInstance().debug("Processing video segment...");

        _videoSegmentHandler = new MediaSegmentHandler(event.bytes, _initializationSegmentHandler.messages,
                _initializationSegmentHandler.videoDefaultSampleDuration, _initializationSegmentHandler.audioDefaultSampleDuration,
                _initializationSegmentHandler.videoTimescale, _initializationSegmentHandler.audioTimescale,
                (_videoSegment.startTimestamp - offset) * 1000, _mixer);

        Console.getInstance().debug("Processed video segment");

        if (_firstSegment) {
            _firstSegment = false;
            _videoOffset = _videoSegment.startTimestamp + (_videoSegmentHandler.startTimestamp / 1000.0);
        }
        _videoSegmentLoaded = true;

        notifyLoadedIfNeeded();
    }

    private function onError(event:SegmentEvent):void {
        dispatchEvent(event);
    }

    private function findSmallerOffset():Number {
        return _videoOffset
    }

    private function loadSegment(segment:Segment, callback:Function):SegmentLoader {
        var loader:SegmentLoader = SegmentLoaderFactory.create(segment, _monitor);
        loader.addEventListener(SegmentEvent.LOADED, callback);
        loader.addEventListener(SegmentEvent.ERROR, onError);
        loader.load();
        return loader;
    }

    private function notifyLoadedIfNeeded():void {
        if (_videoSegmentLoaded) {
            var bytes:ByteArray = new ByteArray();

            // _videoSegmentHandler is null if not loaded
            if (_videoSegmentHandler != null) {
                bytes.writeBytes(_videoSegmentHandler.bytes);
            }

            _videoSegmentLoaded = false;

            _videoSegmentHandler = null;

            var endTimestamp:Number;

            endTimestamp = _videoSegment.endTimestamp;

            dispatchEvent(new FragmentEvent(FragmentEvent.LOADED, false, false, bytes, endTimestamp));
        }
    }

    private function reset():void {
        _videoSegmentLoader = null;
        _videoSegmentHandler = null;
        _videoSegmentLoaded = false;
    }
}
}
