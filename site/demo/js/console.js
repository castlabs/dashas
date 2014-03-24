if(!window.console){ window.console = {log: function(){} }; }

var userBandwidthChart, realUserBandwidths = [], averageUserBandwidths = [], mediaBandwidthChart, videoBandwidths = [], audioBandwidths = [];

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

function showOrHideMessage(level, node) {
    if (document.getElementById(level).checked) {
        node.style.display = "block";
    } else {
        node.style.display = "none";
    }
}

function showOrHideMessages(level) {
    var nodes = document.getElementsByClassName(level);
    for (var i = 0; i < nodes.length; i++) {
        showOrHideMessage(level, nodes[i]);
    }
}

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

function appendUserBandwidth(dataset, bandwidth) {
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

function buildArrayWithEmptyValues(length) {
    var array = [];

    for (var i = 0; i < length; i++) {
        array[i] = "";
    }

    return array;
}

function limitTo15Entries(array) {
    while (array.length > 15) {
        array.shift();
    }
}

function appendMediaBandwidth(dataset, bandwidth) {
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

function appendConsole() {
    var node = document.createElement("div");

    node.className = 'console';
    node.innerHTML = '<h4>User\'s Bandwidth</h4><div class="legend"><span class="legend1">average</span><span class="legend2">real</span></div><canvas id="userBandwidthChart" width="640" height="300"></canvas><h4>Media Bandwidth</h4><div class="legend"><span class="legend1">video</span><span class="legend2">audio</span></div><canvas id="mediaBandwidthChart" width="640" height="300"></canvas><h4>Console</h4><div class="log"><div class="buttons"><label for="error"><input id="error" type="checkbox" checked="checked" value=""> Error </label><label for="warn"><input id="warn" type="checkbox" checked="checked" value="">Warn</label><label for="info"><input id="info" type="checkbox" checked="checked" value="">Info</label><label for="debug"><input id="debug" type="checkbox" value="">Debug</label></div><div id="screen"></div></div><h4>Debug</h4><div>Use a debug SWF file: <button id="enableOrDisableDebug" type="button">Enable</button></div>';
    document.body.appendChild(node);
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

        var n = document.createElement("p");
        n.className = "performance-warning";
        n.innerHTML = "You're using a debug SWF file. Dropped frames during playback can occur.";

        document.body.insertBefore(n, document.getElementsByClassName("console")[0]);
    } else {
        e.textContent = "Enable";
    }
}

function initCharts() {
    var context = null;

    context = document.getElementById("userBandwidthChart").getContext("2d");
    new Chart(context).Line(chartEmptyData, chartOptions);

    context = document.getElementById("mediaBandwidthChart").getContext("2d");
    new Chart(context).Line(chartEmptyData, chartOptions);
}

window.addEventListener("load", function() {
    appendConsole();

    initCharts();

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
    }
}, false);