/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.utils {
import com.castlabs.dash.descriptors.Representation;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.handlers.ManifestHandler;

//TODO change iterator suffix
public class AdaptiveSegmentIterator {
    private var _manifest:ManifestHandler;
    private var _monitor:BandwidthMonitor;

    public function AdaptiveSegmentIterator(manifest:ManifestHandler, monitor:BandwidthMonitor) {
        _manifest = manifest;
        _monitor = monitor;
    }

    public function getAudioSegment(timestamp:Number):Segment {
        return findOptimalRepresentation(_manifest.audioRepresentations).getSegment(timestamp);
    }

    public function getVideoSegment(timestamp:Number):Segment {
        return findOptimalRepresentation(_manifest.videoRepresentations).getSegment(timestamp);
    }

    private function findOptimalRepresentation(representations:Vector.<Representation>):Representation {
        if (representations.length == 0) {
            return null;
        }

        var result:Representation = representations[0];

        for each (var representation:Representation in representations) {
            if (_monitor.userBandwidth >= representation.bandwidth) {
                result = representation;
            } else {
                break;
            }
        }

        return result;
    }
}
}
