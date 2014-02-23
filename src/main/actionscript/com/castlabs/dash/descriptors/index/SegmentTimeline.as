/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.descriptors.index {
import com.castlabs.dash.dash;
import com.castlabs.dash.descriptors.segments.MediaDataSegment;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.descriptors.segments.WaitSegment;
import com.castlabs.dash.utils.Manifest;

public class SegmentTimeline extends SegmentTemplate implements SegmentIndex {
    use namespace dash;

    private var _timeShiftBuffer:Number; // seconds
    private var _segments:Vector.<Object> = new Vector.<Object>();

    public function SegmentTimeline(representation:XML) {
        super(representation);

        _timeShiftBuffer = traverseAndBuildTimeShiftBufferDepth(representation);

        update(representation);
    }

    public override function getSegment(timestamp:Number, representationId:String, bandwidth:Number, baseUrl:String,
                                        duration:Number, internalRepresentationId:Number):Segment {
        if (_segments.length == 0) {
            return null;
        }

        if (isLast(timestamp)) {
            return new WaitSegment(internalRepresentationId);
        }

        var segment:Object = null;

        if (timestamp == 0) {
            segment = _segments[0];
        } else {
            for (var i:uint = 0; i < _segments.length; i++) {
                var end:Number = seconds(_segments[i].time) + seconds(_segments[i].duration);
                if (timestamp < end) {
                    segment = _segments[i];
                    break;
                }
            }

            if (segment == null) {
                return null;
            }
        }

        var url:String = String(_segmentFilename);

        url = url.replace("$Time$", segment.time);
        url = url.replace("$RepresentationID$", representationId);

        var startTimestamp:Number = seconds(segment.time);
        var endTimestamp:Number = startTimestamp + seconds(segment.duration);

        return new MediaDataSegment(internalRepresentationId, baseUrl + url, "0-", startTimestamp, endTimestamp);
    }

    public override function update(xml:XML):void {
        removeOutdatedSegments();
        appendNewSegments(xml);
    }

    private function appendNewSegments(xml:XML):void {
        var items:XMLList = traverseAndBuildTimeline(xml);

        var time:Number = 0;
        for (var i:uint = 0; i < items.length(); i++) {

            // read time if present
            if (items[i].hasOwnProperty("@t")) {
                time = Number(items[i].@t.toString());
            }

            // read duration
            var duration:Number = Number(items[i].@d.toString());

            // read repeats if present
            var repeats:Number = 0;
            if (items[i].hasOwnProperty("@r")) {
                repeats = Number(items[i].@r.toString());
            }

            // add duplicates if repeats > 0
            for (var j:uint = 0; j <= repeats; j++) {
                if (!isTimeExists(time)) { // unique
                    _segments.push({ time: time, duration: duration});
                }

                time += duration;
            }
        }
    }

    private function isTimeExists(time:Number):Object {
        for (var i:uint = 0; i < _segments.length; i++) {
            if (time == _segments[i].time) {
                return true;
            }
        }

        return false;
    }

    private function removeOutdatedSegments():void {
        while (seconds(calculateBufferDepth()) > _timeShiftBuffer) {
            _segments.shift();
        }
    }

    private function calculateBufferDepth():Number {
        var sum:uint = 0;

        for each (var segment:Object in _segments) {
            sum += segment.duration;
        }

        return sum;
    }

    private function seconds(value:Number):Number {
        return value / _timescale;
    }

    private function isLast(timestmap:Number):Boolean {
        if (_segments.length == 0) {
            return false;
        }

        var last:uint = _segments.length - 1;
        return seconds(_segments[last].time) == timestmap;
    }

    private static function traverseAndBuildId(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find ID");
        }

        if (node.hasOwnProperty("@id")) {
            return node.@id.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildId(node.parent());
    }

    private static function traverseAndBuildTimeline(node:XML):XMLList {
        if (node == null) {
            throw new ArgumentError("Couldn't find segments");
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.SegmentTimeline.length() == 1
                && node.SegmentTemplate.SegmentTimeline.S.length() > 0) {
            return node.SegmentTemplate.SegmentTimeline.S;
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildTimeline(node.parent());
    }

    private static function traverseAndBuildTimeShiftBufferDepth(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find time shift buffer depth");
        }

        if (node.hasOwnProperty("@timeShiftBufferDepth")) {
            return Manifest.toSeconds(node.@timeShiftBufferDepth.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildTimeShiftBufferDepth(node.parent());
    }

    protected override function traverseAndBuildDuration(node:XML):Number {
        return NaN;
    }

    protected override function traverseAndBuildStartNumber(node:XML):Number {
        return NaN;
    }
}
}
