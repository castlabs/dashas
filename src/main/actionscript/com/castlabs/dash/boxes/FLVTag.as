/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.boxes {
import flash.utils.ByteArray;

public class FLVTag {
    private static const VIDEO_TYPE:uint = 9;
    private static const AUDIO_TYPE:uint = 8;

    public var length:uint;
    public var timestamp:uint;
    public var compositionTimestamp:int;
    public var dataOffset:uint;
    public var data:ByteArray;
    public var setup:Boolean = false;

    private var _type:uint;

    public function FLVTag() {
    }

    public function get type():uint {
        return _type;
    }

    public function isVideo():Boolean {
        return _type == VIDEO_TYPE;
    }

    public function isAudio():Boolean {
        return _type == AUDIO_TYPE;
    }

    public function markAsVideo():void {
        _type = VIDEO_TYPE;
    }

    public function markAsAudio():void {
        _type = AUDIO_TYPE;
    }
}
}