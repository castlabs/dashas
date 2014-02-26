/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.utils {
import flash.external.ExternalInterface;

public class Console {
    private static const ERROR:String = "error";
    private static const WARN:String = "warn";
    private static const INFO:String = "info";
    private static const DEBUG:String = "debug";

    public function Console() {
        throw new Error("It's static class");
    }

    public static function error(message:String):void {
        log(ERROR, message);
    }

    public static function warn(message:String):void {
        log(WARN, message);
    }

    public static function info(message:String):void {
        log(INFO, message);
    }

    public static function debug(message:String):void {
        log(DEBUG, message);
    }

    public static function log(level:String, message:String):void {
        trace(message);
        ExternalInterface.call("log", level, message);
    }

    public static function appendRealUserBandwidth(bandwidth:Number):void {
        appendUserBandwidth("real", bandwidth);
    }

    public static function appendAverageUserBandwidth(bandwidth:Number):void {
        appendUserBandwidth("average", bandwidth);
    }

    public static function appendUserBandwidth(type:String, bandwidth:Number):void {
        ExternalInterface.call("appendUserBandwidth", type, bandwidth);
    }

    public static function appendVideoBandwidth(bandwidth:Number):void {
        appendMediaBandwidth("video", bandwidth);
    }

    public static function appendAudioBandwidth(bandwidth:Number):void {
        appendMediaBandwidth("audio", bandwidth);
    }

    public static function appendMediaBandwidth(type:String, bandwidth:Number):void {
        ExternalInterface.call("appendMediaBandwidth", type, bandwidth);
    }
}
}
