/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.boxes.FLVTag;
import com.castlabs.dash.boxes.SampleEntry;

import flash.utils.ByteArray;

public class InitializationVideoSegmentHandler extends InitializationSegmentHandler {
    public function InitializationVideoSegmentHandler(ba:ByteArray) {
        super(ba);
    }

    protected override function buildMessage(sampleEntry:SampleEntry):FLVTag {
        var message:FLVTag = new FLVTag();

        message.markAsVideo();
        message.timestamp = 0;
        message.compositionTimestamp = 0;
        message.length = sampleEntry.data.length;
        message.setup = true;

        message.data = new ByteArray();
        sampleEntry.data.readBytes(message.data, 0, sampleEntry.data.length);

        return message;
    }
}
}
