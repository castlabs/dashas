[![Build Status](https://travis-ci.org/castlabs/dashas.png?branch=master)](https://travis-ci.org/castlabs/dashas)
 
dash.as
=======

[MPEG-DASH](http://dashif.org/) player written in ActionScript. Current development status is technology preview. 

The project is released under the [Mozilla Public License 2.0](http://www.mozilla.org/MPL/2.0/).

## Demo

For more information visit [examples page](http://dashas.castlabs.com/demo/index.html).

## Features

* An OSMF extension;
* Basic support for manifests with a list [1];
* Basic support for manifests with a template [1];
* Basic support for manifests with a base URL [1][2];
* Basic support for manifests with a time line;
* Audio-video playback [3];
* Adaptive bitrate streaming;
* Live streaming;
* User interface:
	* Play/Pause;
	* Seeking;
	* Fullscreen mode;
	* Duration;
	* Loaded bytes indicator;
	* Buffering indicator;

[1] A server has to have [crossdomain.xml](https://github.com/castlabs/dashas/blob/master/utils/crossdomain.xml) file in the root context.  
[2] A server has to have custom [.htaccess](https://github.com/castlabs/dashas/blob/master/utils/.htaccess) file in the root context.  
[3] Adobe Flash Player supports only [H.264 (MPEG-4 Part 10)  and HE-AAC (MPEG-4 Part 3) codecs](http://helpx.adobe.com/flash/kb/supported-codecs-flash-player.html).

### Known issues

* [#2](https://github.com/castlabs/dashas/issues/2) Player doesn't resume downloading after reconnecting;

## Quick start

### Input files

Create media input files in different bitrates.

#### Prerequisites

* ffmpeg is installed with libfdk_aac and libx264 library;


#### Instructions

1. Download source file:

		$ wget http://mirrorblender.top-ix.org/movies/sintel-1024-surround.mp4

1. Create video file encoded at 250k 436p, H.264 codec:

		$ ffmpeg -i sintel-1024-surround.mp4 -an -b:v 250k -s 1024x436 -vcodec libx264 avc1-sintel-436p-250k.mp4

1. Create audio file encoded at 500k 436p, H.264 codec:

		$ ffmpeg -i sintel-1024-surround.mp4 -an -b:v 500k -s 1024x436 -vcodec libx264 avc1-sintel-436p-500k.mp4
		
1. Create video file encoded at 1000k 436p, H.264 codec:

		$ ffmpeg -i sintel-1024-surround.mp4 -an -b:v 1000k -s 1024x436 -vcodec libx264 avc1-sintel-436p-1000k.mp4
		
1. Create video file encoded at 69k stereo, HE-AAC codec:

		$ ffmpeg -i sintel-1024-surround.mp4 -vn -ac 2 -acodec libfdk_aac -profile:a aac_he -f mp4 mp4a-sintel-69k.mp4
		
		
### Stream
		
Convert media input files into DASH stream files.
		
#### Prerequisites

* common_transcoding-packager-encrypter is installed (`fixes` branch);

#### Instructions

* Use following command to generate DASH stream with byte segments:
		
		$ dash -o <output directory> <input video files> <input audio files>
		
### Page

Finally try dash.as locally.

#### Prerequisites

* apache2 is installed;

#### Instructions

1. Create a virtual host for localhost;

1. Copy DASH stream files into a document root;

1. Copy [crossdomain.xml](https://github.com/castlabs/dashas/blob/master/utils/crossdomain.xml) and [.htaccess](https://github.com/castlabs/dashas/blob/master/utils/.htaccess) files into a document root;

1. Copy contents of the [demo](https://github.com/castlabs/dashas/tree/master/site/demo/) directory into a document root;

1. Create `index.html` file in a document root (type absolute URL to a `Manifest.mpd` file):

		<html>
		<head>
		<script type="text/javascript" src="/swfobject/swfobject.js"></script>
		<script type="text/javascript">
		    var flashvars = {};
		
		    // absolut URL to Manifest.mpd file
		    flashvars.src = encodeURIComponent("<absolute URL to Manifest.mpd file>");
		
		    // absolut URL to dashas.swf file
		    flashvars.plugin_DashPlugin = encodeURIComponent(location.href + "/dashas.swf");
		
		    var params = {};
		    params.allowfullscreen = "true";
		    params.allownetworking = "true";
		    params.wmode = "direct";
		
		    swfobject.embedSWF("/debug/StrobeMediaPlayback.swf", "placeholder", "640", "360", "10.1", "/swfobject/expressInstall.swf", flashvars, params, {});
		</script>
		</head>
		
		<body>
		<div id="placeholder">
		    <p><span>Please install <a href="http://get.adobe.com/flashplayer/">Adobe Flash Player</a></span></p>
		</div>
		</body>
		</html>
	
1. Go to `http://localhost/index.html`;
	
## Development

### Build

#### Prerequisites

* gradle is installed;

#### Instructions

* Build debug SWF package:

		$ cd <project_workspace>
		$ gradle clean compile

* Build production SWF package:

		$ cd <project_workspace>
		$ gradle -Pprofile=production clean compile

... do you prefer developing in an IDE? Read how to [import project into the IntelliJ IDEA](https://github.com/castlabs/dashas/wiki/IntelliJ-IDEA).
