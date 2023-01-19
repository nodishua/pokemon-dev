(function() {
    var userAgent = navigator.userAgent.toLowerCase();
    var regChrome = /chrome\/[\d]+/i;
    var c = userAgent.match(regChrome);
    if (c === null) {
        alert("Please use Chrome browser!")
    } else {
        var a = c[0].split("/");
        if (parseInt(a[1]) < 60) {
            alert("Please upgrade your browser version!")
        }
    };
})()

function ChartPie(url, canvasID, chartType, legend_s, params) {
    this.url = url;
    this.params = params || {};
    this.canvasID = canvasID;
    this.chartType = chartType;
    this.legend_s = legend_s;
}

ChartPie.prototype.color_make = function(num) {
    var radom_color = function() {
        return '#'+('00000'+(Math.random()*0x1000000<<0).toString(16)).slice(-6);
    }
    var colorA = new Array()
    for (var i = 1; i <= num; i++) {
        colorA.push(radom_color())
    }
    return colorA
};

ChartPie.prototype.init = function() {
    var responseData;

    $.ajax({
        url: this.url,
        type: 'get',
        dataType: 'json',
        async: false,
        data: this.params,
        success: function (data) {
            responseData = data;
        },
        error: function () {
            alert("chart init fail!")
        },
    });

    this.today = responseData.today_time;
    var data = {
        labels: responseData.labels,
        datasets: [
            {
                data: responseData.datas,
                backgroundColor: this.color_make(responseData.datas.length),
                // hoverBackgroundColor: [
                //     "#FF6384",
                //     "#36A2EB",
                //     "#FFCE56"
                // ]
            }]
    };

    var ctx = document.getElementById(this.canvasID);
    this.chart = new Chart(ctx, {
        type: this.chartType,
        data: data,
        options: {
            legend: {
                display: this.legend_s[0],
                position: this.legend_s[1],
            },
        }
    })
}

function initDatetimePicker() {
    $('.form-date').datetimepicker({
        language:  'zh-CN',
        format: "yyyy-mm-dd",
        weekStart: 1,
        todayBtn:  true,
        autoclose: true,
        todayHighlight: true,
        keyboardNavigation: true,
        startView: 2,
        minView: 2,
        forceParse: 0,
        pickerPosition: 'bottom-left',
    });
    $(".datetimepicker").css("margin-top", "66px");
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

// 请求异常处理
$(document).ajaxError(function(event, xhr, options, exc) {
    console.log(event, xhr, options, exc);
    alert("Error: " + xhr.status + "  " + xhr.statusText);
});