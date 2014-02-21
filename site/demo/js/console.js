var chart, bandwidths = [];

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

function appendBandwidth(bandwidth) {
    bandwidths.push(bandwidth);

    chart.load({
        columns: [
            ['bandwidth'].concat(bandwidths)
        ]
    });
}

function loadChart() {
    chart = c3.generate({
        bindto: '#chart',
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
            show: false
        }
    });
}

window.addEventListener("load", function() {
    loadChart();

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