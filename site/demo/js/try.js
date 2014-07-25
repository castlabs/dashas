if(!window.console){ window.console = { log: function() {} }; }

var realUserBandwidths = [], averageUserBandwidths = [], videoBandwidths = [], audioBandwidths = [];

var chartEmptyData = {
    labels : [],
    datasets : [{
        data : []
    }]
};

var chartOptions = {
    animation : false,
    bezierCurve: false,
    datasetFill: false,
    scaleShowGridLines: false
};

var playerBridge = null;

function onJavaScriptBridgeCreated(playerId) {
    if (playerBridge == null) {
        playerBridge = document.getElementById(playerId);
    }
}

// call from ActionScript
function handleEvents(events) {
    for (var i = 0; i < events.length; i++) {
        var event = events[i];

        if (event.id == "log") {
            log(event.level, event.message);
        }

        if (event.id == "appendUserBandwidth") {
            appendUserBandwidth(event.dataset, event.bandwidth);
        }

        if (event.id == "appendMediaBandwidth") {
            appendMediaBandwidth(event.dataset, event.bandwidth);
        }
    }
}

function log(level, message) {
    logToPageConsole(level, message);
    logToBrowserConsole(level, message);
}

function logToPageConsole(level, message) {
    if (level == 'error') {
        console.error(message);
    }
    if (level == 'warn') {
        console.warn(message);
    }
    if (level == 'info' || level == 'debug') {
        console.info(message);
    }
}

function logToBrowserConsole(level, message) {
    var node = document.createElement("p");

    node.className = level;
    node.innerHTML = message;
    showOrHideMessage(level, node);

    document.getElementById("screen").appendChild(node);
}

// workaround: firefox can't handle width and height properly
function fixChartSize(chart) {
    chart.width = 640;
    chart.height = 300;
}

function initChart(chart) {
    fixChartSize(chart);
    var context = chart.getContext("2d");
    new Chart(context).Line(chartEmptyData, chartOptions);
}

function appendUserBandwidth(dataset, bandwidth) {
    fixChartSize(document.getElementById("userBandwidthChart"));

    if (dataset == 'real') {
        realUserBandwidths.push(bandwidth);
    }

    if (dataset == 'average') {
        averageUserBandwidths.push(bandwidth);
    }

    limitTo15Entries(realUserBandwidths);
    limitTo15Entries(averageUserBandwidths);

    var data = {
        labels : buildArrayWithEmptyValues(Math.max(realUserBandwidths.length, averageUserBandwidths.length)),
        datasets : [
            {
                strokeColor : "rgba(220,220,220,1)",
                pointColor : "rgba(220,220,220,1)",
                pointStrokeColor : "#fff",
                data : realUserBandwidths
            },
            {
                pointColor : "rgba(151,187,205,1)",
                pointStrokeColor : "#fff",
                strokeColor : "rgba(151,187,205,1)",
                data : averageUserBandwidths
            }
        ]
    };

    var context = document.getElementById("userBandwidthChart").getContext("2d");
    new Chart(context).Line(data, chartOptions);
}

function appendMediaBandwidth(dataset, bandwidth) {
    fixChartSize(document.getElementById("mediaBandwidthChart"));

    if (dataset == 'video') {
        videoBandwidths.push(bandwidth);
    }

    if (dataset == 'audio') {
        audioBandwidths.push(bandwidth);
    }

    limitTo15Entries(videoBandwidths);
    limitTo15Entries(audioBandwidths);

    var data = {
        labels : buildArrayWithEmptyValues(Math.max(videoBandwidths.length, audioBandwidths.length)),
        datasets : [
            {
                strokeColor : "rgba(151,187,205,1)",
                pointStrokeColor : "#fff",
                pointColor : "rgba(151,187,205,1)",
                data : videoBandwidths
            },
            {
                strokeColor : "rgba(220,220,220,1)",
                pointStrokeColor : "#fff",
                pointColor : "rgba(220,220,220,1)",
                data : audioBandwidths
            }
        ]
    };

    var context = document.getElementById("mediaBandwidthChart").getContext("2d");
    new Chart(context).Line(data, chartOptions);
}

function limitTo15Entries(array) {
    while (array.length > 15) {
        array.shift();
    }
}

function buildArrayWithEmptyValues(length) {
    var array = [];

    for (var i = 0; i < length; i++) {
        array[i] = "";
    }

    return array;
}

function isDebug() {
    return document.cookie.indexOf("debug=true") != -1;
}

function enableDebug() {
    var date = new Date();
    date.setTime(date.getTime() + (365*24*60*60*1000)); // 1 year

    var expires = date.toGMTString();

    document.cookie="debug=true; expires=" + expires;
}

function disabledDebug() {
    document.cookie="debug=; expires=Thu, 01 Jan 1970 00:00:00 GMT";
}

function initEnableOrDisableDebug() {
    var e = document.getElementById("enableOrDisableDebug");

    if (isDebug()) {
        e.textContent = "Disable";
        document.getElementById("performance-issue").style.display = "block";
    } else {
        e.textContent = "Enable";
    }
}

function showOrHideMessages(level) {
    var nodes = document.getElementById("screen").getElementsByClassName(level);
    for (var i = 0; i < nodes.length; i++) {
        showOrHideMessage(level, nodes[i]);
    }
}

function showOrHideMessage(level, node) {
    if (document.getElementById(level).checked) {
        node.style.display = "block";
    } else {
        node.style.display = "none";
    }
}

function resetChartsAndLogs() {

    // charts
    realUserBandwidths = [];
    averageUserBandwidths = [];
    videoBandwidths = [];
    audioBandwidths = [];

    appendUserBandwidth(null, null);
    appendMediaBandwidth(null, null);

    // logs
    var node = document.getElementById("screen");
    while (node.firstChild) {
        node.removeChild(node.firstChild);
    }
}

function load() {
    unloadSwf();
    resetChartsAndLogs();
    loadSwf(document.getElementById("url").value);
}

function unloadSwf() {
    swfobject.removeSWF("placeholder");
}

function loadSwf(manifestUrl) {

    // reset bridge to allow initialization
    playerBridge = null;

    document.getElementById("placeholder-wrapper").innerHTML = "<div id='placeholder'><p><span>Please install <a href='http://get.adobe.com/flashplayer/'>Adobe Flash Player</a></span></p></div>";

    var timestamp = new Date().getTime();

    var flashvars = {};
    flashvars.src = encodeURIComponent(manifestUrl);
    flashvars.plugin_DashPlugin = encodeURIComponent(location.href + "/../"  + (isDebug() ? "debug" : "production") + "/dashas.swf?t=" + timestamp + "&log=true");
    flashvars.javascriptCallbackFunction = "onJavaScriptBridgeCreated";

    var params = {};
    params.allowfullscreen = "true";
    params.allownetworking = "true";
    params.wmode = "direct";

    swfobject.embedSWF("./StrobeMediaPlayback.swf?=" + timestamp, "placeholder", "640", "360", "10.1", "./swfobject/expressInstall.swf", flashvars, params, {});
}

window.addEventListener("load", function() {
    initChart(document.getElementById("userBandwidthChart"));
    initChart(document.getElementById("mediaBandwidthChart"));

    document.getElementById("error").onchange = function() {
        showOrHideMessages("error");
    };
    document.getElementById("warn").onchange = function() {
        showOrHideMessages("warn");
    };
    document.getElementById("info").onchange = function() {
        showOrHideMessages("info");
    };
    document.getElementById("debug").onchange = function() {
        showOrHideMessages("debug");
    };

    initEnableOrDisableDebug();
    document.getElementById("enableOrDisableDebug").onclick = function() {
        if (isDebug()) {
            disabledDebug();
        } else {
            enableDebug();
        }

        location.reload();
    };

    // hide alerts if press close button
    var elements = document.getElementsByClassName("close");
    for (var i = 0; i < elements.length; i++) {
        elements[i].onclick = function() {
            this.parentNode.style.display = 'none';
            return false;
        };
    }

    // on click load button
    document.getElementById("load").onclick = function() {
        load();
        return false;
    };

    // on change examples selects
    document.getElementById("examples").onchange = function() {
        document.getElementById("url").value = this.value;
        load();

        // select "Examples" option
        this.selectedIndex = 0;
    };

    // load manifest if any
    load();

}, false);