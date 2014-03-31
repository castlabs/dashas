/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.boxes {
import flash.utils.ByteArray;

public class HandlerReferenceBox extends FullBox {

    // 'vide', 'soun' or other values
    private var _type:String;

    public function HandlerReferenceBox(offset:uint, size:uint) {
        super(offset, size);
    }

    public function get type():String {
        return _type;
    }

    override protected function parseBox(ba:ByteArray):void {

        // skip QUICKTIME type
        ba.position += 4;

        _type = ba.readUTFBytes(4);
    }
}
}
