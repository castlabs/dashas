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

public class SegmentList implements SegmentIndex {
    use namespace dash;

    private var _initializationSegmentFilename:String;
    private var _segmentsFilenames:Vector.<String>;
    private var _duration:Number; //TODO rename to avoid confusion with video duration
    private var _timescale:Number;

    public function SegmentList(representation:XML) {
        _initializationSegmentFilename = traverseAndBuildInitializationSegmentFilename(representation);
        _segmentsFilenames = buildAndTraverseSegmentFilenames(representation);
        _duration = traverseAndBuildDuration(representation);
        _timescale = traverseAndBuildTimescale(representation);
    }

    public function getInitializationSegment(representationId:String, bandwidth:Number, baseUrl:String,
                                             internalRepresentationId:Number):Segment {
        return new DataSegment(internalRepresentationId, baseUrl + _initializationSegmentFilename);
    }

    public function getIndexSegment(representationId:String, bandwidth:Number, baseUrl:String,
                                    internalRepresentationId:Number):Segment {
        return new NullSegment(internalRepresentationId);
    }

    public function getSegment(timestamp:Number, representationId:String, bandwidth:Number, baseUrl:String,
                               duration:Number, internalRepresentationId:Number):Segment {
        var index:Number = calculateIndex(timestamp);

        if (index < 0 || index >= _segmentsFilenames.length) {
            return null;
        }

        var startTimestamp:Number = index * segmentDuration;
        var endTimestamp:Number = startTimestamp + segmentDuration;

        return new MediaDataSegment(internalRepresentationId, baseUrl + _segmentsFilenames[index], "0-",
                startTimestamp, endTimestamp);
    }

    public function update(xml:XML):void {
    }

    private function get segmentDuration():Number {
        return _duration / _timescale;
    }

    private function calculateIndex(timestamp:Number):Number {
        return int(timestamp / segmentDuration);
    }

    private static function buildAndTraverseSegmentFilenames(node:XML):Vector.<String> {
        if (node == null) {
            throw new ArgumentError("Couldn't find media segment");
        }

        if (node.SegmentList.length() == 1 && node.SegmentList.length() > 0) {
            var segments:Vector.<String> = new Vector.<String>();

            for each (var item:XML in node.SegmentList.SegmentURL) {
                segments.push(item.@media.toString());
            }

            return segments;
        }

        return buildAndTraverseSegmentFilenames(node.parent());
    }

    private static function traverseAndBuildInitializationSegmentFilename(node:XML):String {
        if (node == null) {
            throw new ArgumentError("Couldn't find initialization segment");
        }

        if (node.SegmentBase.length() == 1
                && node.SegmentBase.Initialization.length() == 1
                && node.SegmentBase.Initialization.@sourceURL != null) {
            return node.SegmentBase.Initialization.@sourceURL.toString();
        }

        if (node.SegmentList.length() == 1
                && node.SegmentList.Initialization.length() == 1
                && node.SegmentList.Initialization.@sourceURL != null) {
            return node.SegmentList.Initialization.@sourceURL.toString();
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildInitializationSegmentFilename(node.parent());
    }

    private static function traverseAndBuildDuration(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find duration");
        }

        if (node.SegmentList.length() == 1 && node.SegmentList.@duration != null) {
            return Number(node.SegmentList.@duration.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildDuration(node.parent());
    }

    private static function traverseAndBuildTimescale(node:XML):Number {
        if (node == null) {
            throw new ArgumentError("Couldn't find timescale");
        }

        if (node.SegmentList.length() == 1 && node.SegmentList.@timescale != null) {
            return Number(node.SegmentList.@timescale.toString());
        }

        // go up one level in hierarchy, e.g. adaptionSet and period
        return traverseAndBuildTimescale(node.parent());
    }
}
}
