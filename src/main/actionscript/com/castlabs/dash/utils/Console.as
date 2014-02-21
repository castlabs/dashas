package com.castlabs.dash.utils {
import flash.external.ExternalInterface;

public class Console {
    private static const ERROR:String = "error";
    private static const WARN:String = "warn";
    private static const INFO:String = "info";
    private static const DEBUG:String = "debug";

    public function Console() {
        throw new Error("Singleton");
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

    public static function appendBandwidth(bandwidth:Number):void {
        ExternalInterface.call("appendBandwidth", bandwidth);
    }
}
}
