/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.descriptors.index {
import com.castlabs.dash.utils.Console;

public class SegmentIndexFactory {
    public function SegmentIndexFactory() {
    }

    static public function create(representation:XML):SegmentIndex {
        return traverseAndCreate(representation, representation);
    }

    static private function traverseAndCreate(node:XML, representation:XML):SegmentIndex {
        if (node == null) {
            throw Console.getInstance().logError(new Error("Couldn't find any 'SegmentTimeline', 'SegmentTemplate', " +
                    "'SegmentTemplate', 'SegmentList' or 'BaseURL' tag"));
        }

        var segmentIndex:SegmentIndex = null;

        if (node.SegmentTemplate.length() == 1
                && node.SegmentTemplate.SegmentTimeline.length() == 1) {
            Console.getInstance().info("Creating segment time line...");
            segmentIndex = new SegmentTimeline(representation);
            Console.getInstance().info("Created segment time line, " + segmentIndex.toString());
            return segmentIndex;
        }

        if (node.SegmentTemplate.length() == 1) {
            Console.getInstance().info("Creating segment template...");
            segmentIndex = new SegmentTemplate(representation);
            Console.getInstance().info("Created segment template, " + segmentIndex.toString());
            return segmentIndex;
        }

        if (node.SegmentList.length() == 1) {
            Console.getInstance().info("Creating segment list...");
            segmentIndex = new SegmentList(representation);
            Console.getInstance().info("Created segment list, " + segmentIndex.toString());
            return segmentIndex;
        }

        if (node.BaseURL.length() == 1) {
            Console.getInstance().info("Creating segment base URL...");
            segmentIndex = new SegmentRange(representation);
            Console.getInstance().info("Created segment base URL, " + segmentIndex.toString());
            return segmentIndex;
        }

        return traverseAndCreate(node.parent(), representation);
    }
}
}
