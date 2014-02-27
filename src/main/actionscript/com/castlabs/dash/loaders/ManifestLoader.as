/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash.loaders {
import com.castlabs.dash.events.ManifestEvent;
import com.castlabs.dash.utils.Console;

import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.IOErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;

public class ManifestLoader extends EventDispatcher {
    private var _url:String;

    public function ManifestLoader(url:String) {
        _url = url;
    }

    public function load():void {
        var http:URLLoader = new URLLoader();

        http.dataFormat = URLLoaderDataFormat.TEXT;
        http.addEventListener(Event.COMPLETE, onComplete);
        http.addEventListener(IOErrorEvent.IO_ERROR, function(event:Event):void {
            Console.warn("Connection was interrupted:" + event.toString());
        });

        http.load(new URLRequest(_url));
    }

    private function onComplete(event:Event):void {
        var response:String = URLLoader(event.target).data;
        var xml:XML = removeNamespacesAndBuildXml(response);
        dispatchEvent(new ManifestEvent(ManifestEvent.LOADED, false, false, _url, xml));
    }

    private function removeNamespacesAndBuildXml(response:String):XML {

        // define the regex pattern to remove the namespaces from the string
        var xmlnsPattern:RegExp = new RegExp("(xmlns|xsi)[^\"]*\"[^\"]*\"", "gi");

        // remove the namespaces from the string representation of the XML
        var responseWithRemovedNamespaces:String = response.replace(xmlnsPattern, "");

        return new XML(responseWithRemovedNamespaces);
    }
}
}
