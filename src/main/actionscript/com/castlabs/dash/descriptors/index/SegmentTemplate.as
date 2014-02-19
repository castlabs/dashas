/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.descriptors.index {
import com.castlabs.dash.dash;
import com.castlabs.dash.descriptors.segments.DataSegment;
import com.castlabs.dash.descriptors.segments.MediaDataSegment;
import com.castlabs.dash.descriptors.segments.NullSegment;
import com.castlabs.dash.descriptors.segments.Segment;

public class SegmentTemplate implements SegmentIndex {
    use namespace dash;

    private var _initializationSegmentFilename:String;
    private var _segmentFilename:String;
    private var _duration:Number; //TODO rename to avoid confusion with video duration
    private var _timescale:Number;
    private var _startNumber:Number;

    public function SegmentTemplate(representation:XML) {
        _initializationSegmentFilename = traverseAndBuildInitializationFilename(representation);
        _segmentFilename = traverseAndBuildSegmentFilename(representation);
        _duration = traverseAndBuildDuration(representation);
        _timescale = traverseAndBuildTimescale(representation);
        _startNumber = traverseAndBuildStartNumber(representation);
    }

    public function getInitializationSegment(representationId:String, bandwidth:Number, baseUrl:String,
                                             internalRepresentationId:Number):Segment {
        var url:String = String(_initializationSegmentFilename);

        url = url.replace("$RepresentationID$", representationId);
        url = url.replace("$Bandwidth$", bandwidth);

        return new DataSegment(internalRepresentationId, baseUrl + url);
    }

    public function getIndexSegment(representationId:String, bandwidth:Number, baseUrl:String,
                                    internalRepresentationId:Number):Segment {
        return new NullSegment(internalRepresentationId);
    }

    public function getSegment(timestamp:Number, representationId:String, bandwidth:Number, baseUrl:String,
                               duration:Number, internalRepresentationId:Number):Segment {
        var index:Number = calculateIndex(timestamp);

        if (isOutOfRange(index, duration)) {
            return null;
        }

        var url:String = String(_segmentFilename);

        url = url.replace("$Number$", _startNumber + index);
        url = url.replace("$RepresentationID$", representationId);
        url = url.replace("$Bandwidth$", bandwidth);

        var startTimestamp:Number = index * segmentDuration;
        var endTimestamp:Number = startTimestamp + segmentDuration;

        return new MediaDataSegment(internalRepresentationId, baseUrl + url, "0-", startTimestamp, endTimestamp);
    }

    private function get segmentDuration():Number {
        return _duration / _timescale;
    }

    private function calculateIndex(timestamp:Number):Number {
        return int(timestamp / segmentDuration);
    }

    private function isOutOfRange(index:Number, duration:Number):Boolean {
        var predictedTimestamp:Number = segmentDuration * index;
        return predictedTimestamp >= duration;
    }

    private static function traverseAndBuildInitializationFilename(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find initialization segment");
        }

        if (node.SegmentBase.length() == 1
                && node.SegmentBase.Initialization.length() == 1
                && node.SegmentBase.Initialization.@sourceURL != null) {
            return node.SegmentBase.Initialization.@sourceURL.toString();
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.Initialization.length() == 1
                && node.SegmentTemplate.Initialization.@sourceURL != null) {
            return node.SegmentTemplate.Initialization.@sourceURL.toString();
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.@initialization != null) {
            return node.SegmentTemplate.@initialization.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildInitializationFilename(node.parent());
    }

    private static function traverseAndBuildSegmentFilename(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find media segment");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.@media != null) {
            return node.SegmentTemplate.@media.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildSegmentFilename(node.parent());
    }

    private static function traverseAndBuildDuration(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find duration");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.@duration != null) {
            return Number(node.SegmentTemplate.@duration.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildDuration(node.parent());
    }

    private static function traverseAndBuildTimescale(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find timescale");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.@timescale != null) {
            return Number(node.SegmentTemplate.@timescale.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildTimescale(node.parent());
    }

    private static function traverseAndBuildStartNumber(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find start number");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.@startNumber != null) {
            return Number(node.SegmentTemplate.@startNumber.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildStartNumber(node.parent());
    }
}
}
