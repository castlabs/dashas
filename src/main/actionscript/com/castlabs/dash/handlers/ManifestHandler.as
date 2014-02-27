/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.descriptors.Representation;
import com.castlabs.dash.events.ManifestEvent;
import com.castlabs.dash.loaders.ManifestLoader;
import com.castlabs.dash.utils.Manifest;

import flash.events.TimerEvent;
import flash.utils.Timer;

public class ManifestHandler {
    private var _url:String;

    private var _live:Boolean;
    private var _duration:Number;
    private var _audioRepresentations:Vector.<Representation>;
    private var _videoRepresentations:Vector.<Representation>;

    private var _nextInternalRepresentationId:Number = 0;

    private var _updateTimer:Timer;

    public function ManifestHandler(url:String, xml:XML) {
        _url = url;

        _live = buildLive(xml);
        _duration = buildDuration(xml);

        var baseUrl:String = buildBaseUrl(url);
        _audioRepresentations = buildRepresentations(baseUrl, _duration, findAudioRepresentationNodes(xml));
        _videoRepresentations = buildRepresentations(baseUrl, _duration, findVideoRepresentationNodes(xml));

        sortByBandwidth(_audioRepresentations);
        sortByBandwidth(_videoRepresentations);

        var minimumUpdatePeriod:Number = buildMinimumUpdatePeriod(xml);
        if (_live && minimumUpdatePeriod) {
            _updateTimer = new Timer(minimumUpdatePeriod * 1000);
            _updateTimer.addEventListener(TimerEvent.TIMER, onUpdate);
            _updateTimer.start();
        }
    }

    public function get live():Boolean {
        return _live;
    }

    public function get duration():Number {
        return _duration;
    }

    public function get audioRepresentations():Vector.<Representation> {
        return _audioRepresentations;
    }

    public function get videoRepresentations():Vector.<Representation> {
        return _videoRepresentations
    }

    private function onUpdate(timerEvent:TimerEvent):void {
        var loader:ManifestLoader = new ManifestLoader(_url);
        loader.addEventListener(ManifestEvent.LOADED, onLoad);

        function onLoad(event:ManifestEvent):void {
            for each (var representation1:Representation in _videoRepresentations) {
                representation1.update(event.xml..AdaptationSet.(@mimeType == "video/mp4")[0]);
            }

            for each (var representation2:Representation in _audioRepresentations) {
                representation2.update(event.xml..AdaptationSet.(@mimeType == "audio/mp4")[0]);
            }
        }

        loader.load();
    }

    private function buildMinimumUpdatePeriod(xml:XML):Number {
        if (xml.hasOwnProperty("@minimumUpdatePeriod")) {
            return Manifest.toSeconds(xml.@minimumUpdatePeriod.toString());
        }

        return NaN;
    }

    private static function buildBaseUrl(url:String):String {
        return url.slice(0, url.lastIndexOf("/")) + "/";
    }

    private static function buildDuration(xml:XML):Number {
        if (xml.hasOwnProperty("@mediaPresentationDuration")) {
            return Manifest.toSeconds(xml.@mediaPresentationDuration.toString());
        }

        return NaN;
    }

    private static function buildLive(xml:XML):Boolean {
        if (xml.hasOwnProperty("@type")) {
            return xml.@type.toString() == "dynamic";
        }
        return false;
    }

    private static function findVideoRepresentationNodes(xml:XML):* {
        return findAdaptionSetNode("video/mp4", xml).Representation;
    }

    private static function findAudioRepresentationNodes(xml:XML):* {
        return findAdaptionSetNode("audio/mp4", xml).Representation;
    }

    private static function findAdaptionSetNode(mimeType:String, xml:XML):* {
        var adaptationSet:* = xml..AdaptationSet.(attribute('mimeType') == mimeType);
        if (adaptationSet.length() == 1) {
            return adaptationSet;
        } else {
            return xml..Representation.(@mimeType == mimeType)[0].parent();
        }
    }

    private function buildRepresentations(baseUrl:String, duration:Number, nodes:XMLList):Vector.<Representation> {
        var representations:Vector.<Representation> = new Vector.<Representation>();

        for each (var node:XML in nodes) {
            representations.push(new Representation(_nextInternalRepresentationId++, baseUrl, duration, node));
        }

        return representations;
    }

    private static function sortByBandwidth(representations:Vector.<Representation>):void {
        representations.sort(function compare(a:Representation, b:Representation):Number {
            if (a.bandwidth < b.bandwidth) {
                return -1; // a should appear before b
            }

            if (a.bandwidth > b.bandwidth) {
                return 1; // b should appear before a
            }

            return 0; // a equals b
        });
    }
}
}
