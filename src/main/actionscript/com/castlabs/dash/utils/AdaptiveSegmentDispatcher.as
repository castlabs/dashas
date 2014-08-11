/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.utils {
import com.castlabs.dash.DashContext;
import com.castlabs.dash.descriptors.Representation;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.handlers.ManifestHandler;

public class AdaptiveSegmentDispatcher {
    private var _context:DashContext;

    public function AdaptiveSegmentDispatcher(context:DashContext) {
        _context = context;
    }

    public function getAudioSegment(timestamp:Number):Segment {
        return findOptimalRepresentation(_context.manifestHandler.audioRepresentations).getSegment(timestamp);
    }

    public function getVideoSegment(timestamp:Number):Segment {
        return findOptimalRepresentation(_context.manifestHandler.videoRepresentations).getSegment(timestamp);
    }

    private function findOptimalRepresentation(representations:Vector.<Representation>):Representation {
        if (representations.length == 0) {
            return null;
        }

        var index:int = 0;

        for (var i:uint = 0;  i < representations.length; i++) {
            if (_context.bandwidthMonitor.userBandwidth >= representations[i].bandwidth) {
                index = i;
            } else {
                break;
            }
        }

        var oldIndex:int = index;

        index -= _context.smoothMonitor.fix;
        if (index < 0) {
            index = 0;
        }

        if (index != oldIndex) {
            _context.console.warn("Downgrade quality, originalBandwidth='" + representations[oldIndex].bandwidth
                    + "', newBandwidth='" + representations[index].bandwidth + "'");
        }

        return representations[index];
    }
}
}
