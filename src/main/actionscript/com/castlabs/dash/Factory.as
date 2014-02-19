/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash {
import com.castlabs.dash.boxes.Mixer;
import com.castlabs.dash.boxes.NalUnit;
import com.castlabs.dash.handlers.ManifestHandler;
import com.castlabs.dash.loaders.FragmentLoader;
import com.castlabs.dash.utils.AdaptiveSegmentIterator;
import com.castlabs.dash.utils.BandwidthMonitor;

public class Factory {
    public static function createFragmentLoader(manifest:ManifestHandler):FragmentLoader {
        var monitor:BandwidthMonitor = new BandwidthMonitor();
        var iterator:AdaptiveSegmentIterator = new AdaptiveSegmentIterator(manifest, monitor);
        var mixer:Mixer = new Mixer(new NalUnit());
        return new FragmentLoader(manifest, iterator, monitor, mixer);
    }
}
}
