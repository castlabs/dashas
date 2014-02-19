/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.descriptors.segments.DataSegment;
import com.castlabs.dash.descriptors.segments.NullSegment;
import com.castlabs.dash.descriptors.segments.ReflexiveSegment;
import com.castlabs.dash.descriptors.segments.Segment;
import com.castlabs.dash.utils.BandwidthMonitor;

public class SegmentLoaderFactory {
    public function SegmentLoaderFactory() {
    }

    static public function create(segment:Segment, monitor:BandwidthMonitor):SegmentLoader {
        if (segment is ReflexiveSegment) {
            return new ReflexiveSegmentLoader(segment, monitor);
        }

        // TODO Does MediaDataSegment pass?
        if (segment is DataSegment) {
            return new DataSegmentLoader(segment, monitor);
        }

        if (segment is NullSegment) {
            return new NullSegmentLoader(segment, monitor);
        }

        throw new ArgumentError("Unknown segment type");
    }
}
}
