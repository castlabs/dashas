var userBandwidthChart, realUserBandwidths = [], averageUserBandwidths = [], mediaBandwidthChart, videoBandwidths = [], audioBandwidths = [];

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

function log(level, message) {
    var node = document.createElement("p");

    node.className = level;
    node.innerHTML = message;
    showOrHideMessage(level, node);

    document.getElementById("screen").appendChild(node);
}

function appendUserBandwidth(type, bandwidth) {
    if (type == 'real') {
        realUserBandwidths.push(bandwidth);
    }

    if (type == 'average') {
        averageUserBandwidths.push(bandwidth);
    }

    userBandwidthChart.load({
        columns: [
            ['real'].concat(realUserBandwidths),
            ['average'].concat(averageUserBandwidths)
        ]
    });
}

function appendMediaBandwidth(type, bandwidth) {
    if (type == 'video') {
        videoBandwidths.push(bandwidth);
    }

    if (type == 'audio') {
        audioBandwidths.push(bandwidth);
    }

    mediaBandwidthChart.load({
        columns: [
            ['video'].concat(videoBandwidths),
            ['audio'].concat(audioBandwidths)
        ]
    });
}

function loadCharts() {
    var options = {
        padding: {
            left: 75
        },
        data: {
            columns: []
        },
        axis: {
            y: {
                label: 'Bandwidth [b/s]'
            }
        },
        legend: {
            show: true
        }
    };

    options.bindto = '#userBandwidthChart';
    userBandwidthChart = c3.generate(options);

    options.bindto = '#mediaBandwidthChart';
    mediaBandwidthChart = c3.generate(options);
}

function appendConsole() {
    var node = document.createElement("div");

    node.className = 'console';
    node.innerHTML = '<h4>User\'s Bandwidth</h4><div id="userBandwidthChart" class="chart"></div><h4>Media Bandwidth</h4><div id="mediaBandwidthChart" class="chart"></div><h4>Console</h4><div class="log"><div class="buttons"><label for="error"><input id="error" type="checkbox" checked="checked" value=""> Error </label><label for="warn"><input id="warn" type="checkbox" checked="checked" value="">Warn</label><label for="info"><input id="info" type="checkbox" checked="checked" value="">Info</label><label for="debug"><input id="debug" type="checkbox" value="">Debug</label></div><div id="screen"></div></div><h4>Debug</h4><div>Use a debug SWF file: <button id="enableOrDisableDebug" type="button">Enable</button></div>';
    document.body.appendChild(node);
}

function isDebug() {
    return document.cookie.indexOf("debug=true") != -1;
}

function enableDebug() {
    var date = new Date();
    date.setTime(date.getTime() + (365*24*60*60*1000));

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

window.addEventListener("load", function() {
    appendConsole();
    loadCharts();

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