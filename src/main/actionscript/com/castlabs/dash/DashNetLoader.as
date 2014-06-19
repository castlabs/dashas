/*
 * Copyright (c) 2014 castLabs GmbH
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

package com.castlabs.dash {
import com.castlabs.dash.events.ManifestEvent;
import com.castlabs.dash.events.StreamEvent;
import com.castlabs.dash.handlers.ManifestHandler;
import com.castlabs.dash.loaders.ManifestLoader;
import com.castlabs.dash.utils.Console;

import flash.net.NetConnection;
import flash.net.NetStream;

import org.osmf.events.MediaError;

import org.osmf.events.MediaErrorEvent;

import org.osmf.media.MediaResourceBase;
import org.osmf.media.URLResource;
import org.osmf.net.NetConnectionFactoryBase;
import org.osmf.net.NetLoader;
import org.osmf.net.NetStreamLoadTrait;
import org.osmf.net.StreamingURLResource;
import org.osmf.traits.LoadState;

public class DashNetLoader extends NetLoader {
    public function DashNetLoader(factory:NetConnectionFactoryBase = null) {
        super(factory);
    }

    override public function canHandleResource(resource:MediaResourceBase):Boolean {
        return true;
    }

    override protected function createNetStream(connection:NetConnection, resource:URLResource):NetStream {
        var netStream:NetStream = new DashNetStream(connection);
        return netStream;
    }

    override protected function processFinishLoading(loadTrait:NetStreamLoadTrait):void {
        var stream:DashNetStream = loadTrait.netStream as DashNetStream;
        stream.addEventListener(StreamEvent.READY, onReady);

        function onReady(event:StreamEvent):void {
            if (event.manifest.live && loadTrait.resource is StreamingURLResource) {
                StreamingURLResource(loadTrait.resource).streamType = "live";
            } else {
                var timeTrait:DashTimeTrait = new DashTimeTrait(stream, event.manifest.duration);
                loadTrait.setTrait(timeTrait);
                loadTrait.setTrait(new DashSeekTrait(timeTrait, loadTrait, stream));
            }

            updateLoadTrait(loadTrait, LoadState.READY);
        }

        var manifest:URLResource = loadTrait.resource as URLResource;
        loadManifest(loadTrait, manifest.url, stream);
    }

    private function loadManifest(loadTrait:NetStreamLoadTrait, url:String, stream:DashNetStream):void {
        var loader:ManifestLoader = new ManifestLoader(url);

        loader.addEventListener(ManifestEvent.LOADED, onLoad);
        loader.addEventListener(ManifestEvent.ERROR, onError);

        function onLoad(event:ManifestEvent):void {
            Console.getInstance().info("Creating manifest...");

            var manifest:ManifestHandler = new ManifestHandler(event.url, event.xml);

            Console.getInstance().info("Created manifest, " + manifest.toString());

            stream.manifest = manifest;
        }

        function onError(event:ManifestEvent):void {
            loadTrait.dispatchEvent(new MediaErrorEvent(MediaErrorEvent.MEDIA_ERROR, false, false, new MediaError(7)));
        }

        loader.load();
    }
}
}
