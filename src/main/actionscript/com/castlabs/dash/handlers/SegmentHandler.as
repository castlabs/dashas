/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.handlers {
import com.castlabs.dash.utils.Console;

import flash.utils.ByteArray;

public class SegmentHandler {
    public function SegmentHandler() {
    }

    protected function goToBox(expectedType:String, ba:ByteArray, startFrom:uint):Object {
        var offset:uint = startFrom;
        var size:uint = 0;
        var type:String;

        do {
            ba.position = offset + size;

            offset = ba.position;
            size = ba.readUnsignedInt();
            type = ba.readUTFBytes(4);

            validateSize(size);
        } while (expectedType != type && ba.bytesAvailable);

        validateType(expectedType, type);

        return { offset: offset, size: size };
    }

    protected function validateType(expectedType:String, actualType:String):void {
        if (actualType != expectedType) {
            throw Console.getInstance().logError(new Error("Couldn't find any '" + expectedType + "' box"));
        }
    }

    protected function validateSize(size:uint):void {
        if (size == 1) {
            // don't support "large box", because default size is sufficient for fragmented movie
            throw Console.getInstance().logError(new Error("Large box isn't supported"));
        }
    }

    protected function validateTracksNumber(number:int):void {
        if (number < 1) {
            throw Console.getInstance().logError(new Error("Track isn't defined"));
        }
    }
}
}
