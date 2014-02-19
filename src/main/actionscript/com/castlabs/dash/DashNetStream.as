/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash {
import com.castlabs.dash.events.FragmentEvent;
import com.castlabs.dash.events.StreamEvent;
import com.castlabs.dash.handlers.ManifestHandler;
import com.castlabs.dash.loaders.FragmentLoader;

import flash.events.NetStatusEvent;
import flash.events.TimerEvent;
import flash.net.NetConnection;
import flash.net.NetStream;
import flash.net.NetStreamAppendBytesAction;
import flash.utils.ByteArray;
import flash.utils.Timer;

import org.osmf.net.NetStreamCodes;

public class DashNetStream extends NetStream {
    private const MIN_BUFFER_TIME:Number = 5;

    // actions
    private const PLAY:uint = 1;
    private const PAUSE:uint = 2;
    private const RESUME:uint = 3;
    private const STOP:uint = 4;
    private const SEEK:uint = 5;
    private const BUFFER:uint = 6;

    // states
    private const PLAYING:uint = 1;
    private const BUFFERING:uint = 2;
    private const SEEKING:uint = 3;
    private const PAUSED:uint = 4;
    private const STOPPED:uint = 5;

    private var _state:uint = STOPPED;

    private var _loader:FragmentLoader;

    private var _loaded:Boolean = false;

    private var _offset:Number = 0;
    private var _loadedTimestamp:Number = 0;
    private var _duration:Number = 0;

    private var _bufferTimer:Timer;

    public function DashNetStream(connection:NetConnection) {
        super(connection);

        addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);

        _bufferTimer = new Timer(250); // 250 ms
        _bufferTimer.addEventListener(TimerEvent.TIMER, onBufferTimer);
    }

    override public function play(...rest):void {
        super.play(null);

        appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
        appendFileHeader();

        notifyPlayStart();

        _bufferTimer.start();

        jump();

        updateState(PLAY);
    }

    private function onBufferTimer(timerEvent:TimerEvent):void {
        var bufferTime:Number = _loadedTimestamp - time;

        switch(_state) {
            case PLAYING:
                if (!_loaded && bufferTime < MIN_BUFFER_TIME) {
                    pause();
                    notifyBufferEmpty();
                    updateState(BUFFER);
                    return;
                }
                break;
            case BUFFERING:
                if (bufferTime > MIN_BUFFER_TIME) {
                    resume();
                    notifyBufferFull();
                    return;
                }
                break;
        }
    }

    override public function pause():void {
        super.pause();
        updateState(PAUSE);
    }

    override public function resume():void {
        switch (_state) {
            case PAUSED:
            case BUFFERING:
                super.resume();
                break;
            case STOPPED:
                play();
                break;
            case SEEKING:
                jump();
                break;
        }

        updateState(RESUME);
    }

    override public function seek(offset:Number):void {
        switch (_state) {
            case PAUSED:
            case SEEKING:
            case STOPPED:
                _loader.close();
                _offset = offset;
                super.seek(_offset);
                break;
            case PLAYING:
            case BUFFERING:
                _loader.close();
                _offset = offset;
                super.seek(_offset);
                jump();
                break;
        }

        updateState(SEEK);
    }

    override public function get time():Number {
        return super.time + _offset;
    }

    override public function close():void {
        super.close();

        appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
        appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);

        _bufferTimer.stop();

        notifyPlayStop();

        reset();

        updateState(STOP);
    }

    override public function get bytesLoaded():uint {
        if (_loadedTimestamp == 0) {

            //WORKAROUND ScrubBar:531 ignores zero value
            return 1;
        }

        // seconds
        return _loadedTimestamp;
    }

    override public function get bytesTotal():uint {
        if (_loadedTimestamp == 0) {

            //WORKAROUND ScrubBar:531 ignore zero value; generate smallest possible fraction
            return uint.MAX_VALUE;
        }

        // seconds
        return _duration;
    }

    public function set manifest(manifest:ManifestHandler):void {
        _duration = manifest.duration;

        _loader = Factory.createFragmentLoader(manifest);
        _loader.addEventListener(StreamEvent.READY, onReady);
        _loader.addEventListener(FragmentEvent.LOADED, onLoaded);
        _loader.addEventListener(StreamEvent.END, onEnd);
        _loader.init();
    }

    private function appendFileHeader():void {
        var output:ByteArray = new ByteArray();
        output.writeByte(0x46);	// 'F'
        output.writeByte(0x4c); // 'L'
        output.writeByte(0x56); // 'V'
        output.writeByte(0x01); // version 0x01

        var flags:uint = 0;

        flags |= 0x01;

        output.writeByte(flags);

        var offsetToWrite:uint = 9; // minimum file header byte count

        output.writeUnsignedInt(offsetToWrite);

        var previousTagSize0:uint = 0;

        output.writeUnsignedInt(previousTagSize0);

        appendBytes(output);
    }

    private function updateState(action:Number):void {
        switch (action) {
            case PLAY:
                trace("PLAY");
                trace("PLAYING");
                _state = PLAYING;
                break;
            case PAUSE:
                trace("PAUSE");
                trace("PAUSED");
                _state = PAUSED;
                break;
            case RESUME:
                trace("RESUME");
                trace("PLAYING");
                _state = PLAYING;
                break;
            case STOP:
                trace("STOP");
                trace("STOPPED");
                _state = STOPPED;
                break;
            case SEEK:
                trace("SEEK");
                switch (_state) {
                    case PAUSED:
                        trace("SEEKING");
                        _state = SEEKING;
                        break;
                    case PLAYING:
                    case BUFFERING:
                        trace("PLAYING");
                        _state = PLAYING;
                        break;
                }
                break;
            case BUFFER:
                trace("BUFFER");
                trace("BUFFERING");
                _state = BUFFERING;
                break;
        }
    }

    private function jump():void {
        _offset = _loader.seek(_offset);
        _loadedTimestamp = 0;

        super.seek(_offset);

        appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);

        _loader.loadFirstFragment();
    }

    private function notifyPlayStart():void {
        dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
                { code: NetStreamCodes.NETSTREAM_PLAY_START, level: "status" }));
    }

    private function notifyPlayStop():void {
        dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
                { code: NetStreamCodes.NETSTREAM_PLAY_STOP, level: "status" }));
    }

    private function notifyPlayUnpublish():void {
        dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
                { code: NetStreamCodes.NETSTREAM_PLAY_UNPUBLISH_NOTIFY, level: "status" }));
    }

    private function notifyBufferFull():void {
        dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
                { code: NetStreamCodes.NETSTREAM_BUFFER_FULL, level: "status" }));
    }

    private function notifyBufferEmpty():void {
        dispatchEvent(new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
                { code: NetStreamCodes.NETSTREAM_BUFFER_EMPTY, level: "status" }));
    }

    private function reset():void {
        _offset = 0;
        _loadedTimestamp = 0;
        _loaded = false;
    }

    private function onReady(event:StreamEvent):void {
        dispatchEvent(event);
    }

    private function onLoaded(event:FragmentEvent):void {
        _loadedTimestamp = event.endTimestamp;
        appendBytes(event.bytes);
        _loader.loadNextFragment();
    }

    private function onNetStatus(event:NetStatusEvent):void {
        switch(event.info.code) {
            case NetStreamCodes.NETSTREAM_BUFFER_EMPTY:
                if  (_loaded) {
                    close();
                    notifyPlayUnpublish();
                }
                break;
            case NetStreamCodes.NETSTREAM_PLAY_STREAMNOTFOUND:
                close();
                break;
            default:
                trace(event.info.code);
        }
    }

    private function onEnd(event:StreamEvent):void {
        _loaded = true;
        _loadedTimestamp = _duration;
    }
}
}
