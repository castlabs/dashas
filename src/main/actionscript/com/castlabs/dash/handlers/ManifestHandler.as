/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.dash;
import com.castlabs.dash.descriptors.Representation;

public class ManifestHandler {
    use namespace dash;

    private var _duration:Number;
    private var _audioRepresentations:Vector.<Representation>;
    private var _videoRepresentations:Vector.<Representation>;

    private var _nextInternalRepresentationId:Number = 0;

    public function ManifestHandler(url:String, xml:XML) {
        _duration = buildDuration(xml);

        var baseUrl:String = buildBaseUrl(url);
        _audioRepresentations = buildRepresentations(baseUrl, _duration, findAudioRepresentationNodes(xml));
        _videoRepresentations = buildRepresentations(baseUrl, _duration, findVideoRepresentationNodes(xml));

        sortByBandwidth(_audioRepresentations);
        sortByBandwidth(_videoRepresentations);
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

    private static function buildBaseUrl(url:String):String {
        return url.slice(0, url.lastIndexOf("/")) + "/";
    }

    private static function buildDuration(xml:XML):Number {

        // format: "PT\d+H\d+M\d+S"; "S" means seconds, "M" means minutes and "H" means hours
        var duration:String = xml.@mediaPresentationDuration.toString();

        var match:Array;

        match = duration.match(/([\d.]+)S/);
        var seconds:Number = match ? Number(match[1]) : 0;

        match = duration.match(/([\d.]+)M/);
        var minutes:Number = match ? Number(match[1]) : 0;

        match = duration.match(/([\d.]+)H/);
        var hours:Number = match ? Number(match[1]) : 0;

        return (hours * 60 * 60) + (minutes * 60) + seconds;
    }

    private static function findVideoRepresentationNodes(xml:XML):* {
        return xml..Representation.(@mimeType == "video/mp4");
    }

    private static function findAudioRepresentationNodes(xml:XML):* {
        return xml..Representation.(@mimeType == "audio/mp4");
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
