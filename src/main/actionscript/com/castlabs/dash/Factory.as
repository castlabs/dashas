/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash {
import com.castlabs.dash.boxes.Muxer;
import com.castlabs.dash.handlers.ManifestHandler;
import com.castlabs.dash.loaders.FragmentLoader;
import com.castlabs.dash.utils.AdaptiveSegmentDispatcher;
import com.castlabs.dash.utils.BandwidthMonitor;

public class Factory {
    public static function createFragmentLoader(manifest:ManifestHandler):FragmentLoader {
        var monitor:BandwidthMonitor = new BandwidthMonitor();
        var iterator:AdaptiveSegmentDispatcher = new AdaptiveSegmentDispatcher(manifest, monitor);
        var mixer:Muxer = new Muxer();
        return new FragmentLoader(manifest, iterator, monitor, mixer);
    }
}
}
