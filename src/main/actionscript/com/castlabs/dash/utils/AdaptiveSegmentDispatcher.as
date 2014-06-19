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

public class AdaptiveSegmentDispatcher {
    public function AdaptiveSegmentDispatcher(manifest:ManifestHandler, bandwidthMonitor:BandwidthMonitor) {
        _manifest = manifest;
        _bandwidthMonitor = bandwidthMonitor;
    }

    private var _manifest:ManifestHandler;
    private var _bandwidthMonitor:BandwidthMonitor;
    private var _oldIndex:uint = 0;

    public function getVideoSegment(timestamp:Number):Segment {
        return findOptimalRepresentation(_manifest.videoRepresentations).getSegment(timestamp);
    }

    private function findOptimalRepresentation(representations:Vector.<Representation>):Representation {
        if (representations.length == 0) {
            return null;
        }

        var newIndex:uint = _oldIndex;
        while (true) {
            if (newIndex < 0 || newIndex > representations.length) {
                break;
            } else if (_bandwidthMonitor.userBandwidth < representations[newIndex].bandwidth) {
                newIndex--;
            } else if (newIndex < representations.length - 1 &&
                    _bandwidthMonitor.userBandwidth > representations[newIndex + 1].bandwidth * 1.1) {
                newIndex++;
            } else {
                break;
            }
        }

        if (newIndex != _oldIndex) {
            Console.getInstance().warn("Downgrade quality, originalBandwidth='" + representations[_oldIndex].bandwidth
                    + "', newBandwidth='" + representations[newIndex].bandwidth + "'");
        }
        _oldIndex = newIndex;
        return representations[newIndex];
    }
}
}
