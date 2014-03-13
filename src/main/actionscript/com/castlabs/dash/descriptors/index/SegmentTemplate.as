/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.descriptors.index {
import com.castlabs.dash.descriptors.segments.DataSegment;
import com.castlabs.dash.descriptors.segments.MediaDataSegment;
import com.castlabs.dash.descriptors.segments.NullSegment;
import com.castlabs.dash.descriptors.segments.Segment;

public class SegmentTemplate implements SegmentIndex {
    protected var _initializationSegmentFilename:String;
    protected var _segmentFilename:String;
    protected var _duration:Number; //TODO rename to avoid confusion with video duration
    protected var _timescale:Number;
    protected var _startNumber:Number;

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

    public function update(xml:XML):void {
    }

    private function get segmentDuration():Number {
        return _duration / _timescale;
    }

    private function calculateIndex(timestamp:Number):Number {
        return Math.round(timestamp / segmentDuration);
    }

    private function isOutOfRange(index:Number, duration:Number):Boolean {
        var predictedTimestamp:Number = segmentDuration * index;
        return predictedTimestamp >= duration;
    }

    private function traverseAndBuildInitializationFilename(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find initialization segment");
        }

        if (node.SegmentBase.length() == 1
                && node.SegmentBase.Initialization.length() == 1
                && node.SegmentBase.Initialization.hasOwnProperty("@sourceURL")) {
            return node.SegmentBase.Initialization.@sourceURL.toString();
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.Initialization.length() == 1
                && node.SegmentTemplate.Initialization.hasOwnProperty("@sourceURL")) {
            return node.SegmentTemplate.Initialization.@sourceURL.toString();
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.hasOwnProperty("@initialization")) {
            return node.SegmentTemplate.@initialization.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildInitializationFilename(node.parent());
    }

    private function traverseAndBuildSegmentFilename(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find media segment");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.hasOwnProperty("@media")) {
            return node.SegmentTemplate.@media.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildSegmentFilename(node.parent());
    }

    protected function traverseAndBuildDuration(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find duration");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.hasOwnProperty("@duration")) {
            return Number(node.SegmentTemplate.@duration.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildDuration(node.parent());
    }

    private function traverseAndBuildTimescale(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find timescale");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.hasOwnProperty("@timescale")) {
            return Number(node.SegmentTemplate.@timescale.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildTimescale(node.parent());
    }

    protected function traverseAndBuildStartNumber(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find start number");
        }

        if (node.SegmentTemplate.length() == 1 && node.SegmentTemplate.hasOwnProperty("@startNumber")) {
            return Number(node.SegmentTemplate.@startNumber.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildStartNumber(node.parent());
    }
}
}
