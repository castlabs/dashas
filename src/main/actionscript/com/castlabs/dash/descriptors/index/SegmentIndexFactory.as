/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.descriptors.index {

public class SegmentIndexFactory {
    public function SegmentIndexFactory() {
    }

    static public function create(representation:XML):SegmentIndex {
        return traverseAndCreate(representation, representation);
    }

    static private function traverseAndCreate(node:XML, representation:XML):SegmentIndex {
        if (node == null) {
            throw new ArgumentError("Couldn't find media segment");
        }

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.SegmentTimeline.length() == 1) {
            return new SegmentTimeline(representation);
        }

        if (node.SegmentTemplate.length() == 1) {
            return new SegmentTemplate(representation);
        }

        if (node.SegmentList.length() == 1) {
            return new SegmentList(representation);
        }

        if (node.BaseURL.length() == 1) {
            return new SegmentRange(representation);
        }

        return traverseAndCreate(node.parent(), representation);
    }
}
}
