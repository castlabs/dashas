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

window.addEventListener("load", function() {
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
}, false);