dash.as
=======

[MPEG-DASH](http://dashif.org/) player written in ActionScript. The project is released under the [Mozilla Public License 2.0](http://www.mozilla.org/MPL/2.0/).

## Features

* An OSMF extension;
* Basic support for manifests with a list [1];
* Basic support for manifests with a template [1];
* Basic support for manifests with a base URL [1][2];
* Audio-video playback [3];
* Adaptive bitrate streaming;
* User interface:
	* Play/Pause;
	* Seeking;
	* Fullscreen mode;
	* Duration;
	* Loaded bytes indicator;
	* Buffering indicator;

[1] A server has to have [crossdomain.xml](https://github.com/castlabs/dash.as/blob/master/utils/crossdomain.xml) file in the root context.  
[2] A server has to have custom [.htaccess](https://github.com/castlabs/dash.as/blob/master/utils/.htaccess) file in the root context.  
[3] Adobe Flash Player supports only [H.264 (MPEG-4 Part 10)  and HE-AAC (MPEG-4 Part 3) codecs](http://helpx.adobe.com/flash/kb/supported-codecs-flash-player.html).

## Known issues

* [#9](https://github.com/castlabs/dash.as/issues/9) Player doesn't resume downloading after reconnecting;

## Demo

### Prerequisites

* Adobe Flash Player is installed (at least version 10.1);

### Insturctions

1. Go to demo directory:

		$ cd <workspace>/site/demo/

1. Run simple HTTP server (with Python 3.x use `python -m http.server 8000`):

		$ python -m SimpleHTTPServer

1. Open browser and go to URL:

		http://localhost:8000/
		
## Start guide

### Input files

Create media input files in different bitrates.

#### Prerequisites

* ffmpeg is installed with libfdk_aac and libx264 library;


#### Insturctions

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
		
Convert media input files into a DASH stream.
		
#### Prerequisites

* common_transcoding-packager-encrypter is installed;

#### Insturctions
		
* Use following command to generate DASH stream with file segments (better caching):

		$ TODO use `common_transcoding-packager-encrypter` from `fixes` branch 
		
* Use following command to generate DASH stream with byte segments (smaller size):
		
		$ TODO use `common_transcoding-packager-encrypter` from `fixes` branch 
		
### Server

Copy DASH stream files into directory that is visible from the web (preferred Apache2).

#### Insturctions

1. Copy DASH stream files;

1. Copy the [crossdomain.xml](https://github.com/castlabs/dash.as/blob/master/utils/crossdomain.xml) file into the root context;

1. Copy the [.htaccess](https://github.com/castlabs/dash.as/blob/master/utils/.htaccess) file into the root context;

### Page

Add a HTML snippet to a page.

#### Insturctions

1. Copy [swfobject](https://github.com/castlabs/dash.as/tree/master/site/demo/swfobject) directory into the root context;

1. Copy [dashas.swf](https://github.com/castlabs/dash.as/blob/master/site/demo/debug/dash.as.swf) and [StrobeMediaPlayback.swf](https://github.com/castlabs/dash.as/blob/master/site/demo/debug/StrobeMediaPlayback.swf) files into a `dashas` directory in the root context;

1. Append a following snippet to the header (type absolute URL to a `Manifest.mpd` file):

        <script type="text/javascript" src="/swfobject/swfobject.js"></script>
        <script type="text/javascript">
            var flashvars = {};
            
            // absolut URL to Manifest.mpd file
            flashvars.src = encodeURIComponent("<absolute URL to Manifest.mpd file>");
            
            // absolut URL to dashas.swf file
            flashvars.plugin_DashPlugin = encodeURIComponent("<host>/dashas/dashas.swf");

            var params = {};
            params.allowfullscreen = "true";
            params.allownetworking = "true";
            params.wmode = "direct";

            swfobject.embedSWF("/dashas/StrobeMediaPlayback.swf", "placeholder", "640", "360", "10.1", "/swfobject/expressInstall.swf", flashvars, params, {});
        </script>

1. Append a following snippet to the body:

        <div id="placeholder">
            <p><span>Please install <a href="http://get.adobe.com/flashplayer/">Adobe Flash Player</a></span></p>
        </div>
	
## Development

### Build

#### Prerequisites

* gradle is installed;

#### Instructions

1. Build SWF package:

		$ cd <project_workspace>
		$ gradle clean compile
		
		
... do you prefer developing in an IDE? Read how to [import project into the IntelliJ IDEA](https://github.com/castlabs/dashas/wiki/IntelliJ-IDEA).
