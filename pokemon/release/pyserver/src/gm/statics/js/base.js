// Sleep function, pause program, 1000ms
function sleep(sleepTime) {
	var start = new Date().getTime();
	while (true) {
		if (new Date().getTime() - start > sleepTime) {
			break;
		};
	};
};

// WebSocket
function BaseWebSocket(url) {
    if ("WebSocket" in window) {
    	/*
    	Send a message
		this.ws.onopen = function() {
			this.send("hello, world")
		}
		Receiving message
		this.ws.onmessage = function(MessageEvent) {
			console.log(MessageEvent)
		}
    	*/
    	this.url = 'ws://' + url;
        this.ws = new WebSocket(this.url);
        this.readyState = function() {
        	/*
                0 -It means that the connection has not been established.
                1 -Means that the connection has been established and communicates.
                2 -indicates that the connection is being closed.
                3 -It means that the connection has been closed or the connection cannot be opened.
            */
        	return this.ws.readyState;
        };
        this.close = function() {
        	this.ws.close();
        };
        this.ws.onerror = function(err) {
            console.log(this.url, ":", err);
        };
        this.ws.onclose = function() {
            console.log(this.url, ":closed")
        };
    } else {
    	alert("Do not support WebSocket");
    }
};

// Remove String
String.prototype.trim = function() {
    return this.replace(/(^\s*)|(\s*$)/g, "");
}

// Request abnormal treatment
$(document).ajaxError(function(event, xhr, options, exc) {
    console.log(event, xhr, options, exc);
    if (xhr.status === 504) {
        alert("Sorry, You don't have enough permissions, Please contact the administrator");
    } else {
        alert("Error: " + xhr.status + "  " + xhr.statusText);
    }
});

// At the beginning of the Ajax request
$(document).ajaxStart(function(){
    console.log('ajax request start---');
    $("#ajax-loading").modal("show");
});

// When the Ajax request ends
$(document).ajaxStop(function(){
    console.log('ajax request end---');
    changeCopyrightPosition();
    $("#ajax-loading").modal("hide");
});

// framework language
const userLocale = $('footer').attr('language')

// copyright
function changeCopyrightPosition() {
    let w = $(window).height();
    let b = $('.main').height() + 75;
    console.log(w, b)
    if (b >= w-16) {
        $('#copyright').css('margin-top', 0)
    } else {
        $('#copyright').css('margin-top', w - b - 16 + 'px')
    }
    $('#copyright').css('display', 'block')
}

function prettyJSON(s) {
    let n = "";
    let cl = 0;
    let cr = 0;
    let sj = "  ";

    for (let i=0; i<s.length; i++) {

        if (s[i] === "{" || s[i] === "[") {
            cl += 1;
            n += s[i] + "\n";
            for (let c=0; c<cl-cr; c++) {
                n += sj;
            }
        }
        else if (s[i] === ",") {
            n += s[i] + "\n";
            for (let c=0; c<cl-cr; c++) {
                n += sj;
            }
        }
        else if (s[i] === "]" || s[i] === "}") {
            cr += 1;
            n += "\n"
            for (let c=0; c<cl-cr; c++) {
                n += sj;
            }
            n += s[i];
        }
        else {
            n += s[i];
        }
    }
    return n;
}

function paddingInputDate($ele, days=0) {
    let n = new Date();
    let n_s = n.getTime();
    n.setTime(n_s - 1000*60*60*24*days);
    let d = n.getDate();
    let m = n.getMonth() + 1;
    if (m < 10) {
        m = "0" + m;
    }
    if (d < 10) {
        d = "0" + d;
    }
    let f = n.getFullYear() + '-' + m + '-' + d;
    $ele.val(f)
}