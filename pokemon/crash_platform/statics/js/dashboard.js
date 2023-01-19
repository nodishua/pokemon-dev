function DashboardChart(url, params) {
    this.url = url;
}

DashboardChart.prototype.init = function(params) {
    var responseData;
    var params = params || {};
    $.ajax({
        url: this.url,
        type: 'get',
        dataType: 'json',
        async: false,
        data: params,
        success: function (data) {
            responseData = data;
        },
        error: function () {
            alert("chart init fail!")
        },
    });

    var ctx = document.getElementById("dashboard-chart");
    var dashboardChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: responseData.xAex,
            datasets: [{
                label: "collapsellapsellapse",
                data: responseData.xDumpData,
                // lineTension: 2, Bending of lines
                backgroundColor: 'transparent',
                borderColor: '#007bff',
                borderWidth: 2,
                pointBackgroundColor: '#fff'
            },
            {
                label: "abnormal",
                fill: true,
                borderColor: "rgba(200,187,205,1)",
                pointBackgroundColor: "#fff",
                data: responseData.xExceptionData,
            }
            ]
        },
        options: {
            animation: {
                duration: 1500,
            },
            title: {
                display: false,
                text: 'Trend',
                // fontSize: 20,
            },
            scales: {
                yAxes: [{
                    ticks: {
                        beginAtZero: true,
                    },
                },]
            },
            legend: {
                display: true,
                position: 'bottom',
            },
            tooltips: {
                enable: true,
                intersect: false,
                mode: 'index',
                backgroundColor: 'rgba(0,0,0,0.8)'
            },
            onClick: function (e) {
                var point = this.getElementAtEvent(e)[0];
                if (point) {
                    var hide_time = this.data.labels[point._index];
                    var label = this.data.datasets[point._datasetIndex].label;
                    var hide_style;
                    var url;
                    if (label === "collapse") {
                        hide_style = -1;
                    } else if (label == "abnormal") {
                        hide_style = 1;
                    };
                    url = "/dashboard/datashow?hide_time=" + encodeURIComponent(hide_time) + "&hide_style=" + encodeURIComponent(hide_style);
                    window.open(url, "_blank")
                };
            }
        }
    });
}

$(document).ready(function() {
    if (window.location.pathname === "/") {
        var resetDDCanvas = function() {
            $("#dashboard-chart").remove();
            var div = document.getElementById("div-dashboard-chart");
            var canvas = document.createElement("canvas");
            canvas.setAttribute("id", "dashboard-chart");
            canvas.setAttribute("width", 900);
            canvas.setAttribute("height", 120);
            div.appendChild(canvas)
        };

        var chartMap = {
            1: new DashboardChart("/dashboard/chart"),
            2: null,
            3: new DashboardChart("/dashboard/efectuser"),
            4: null,
        };
        chartMap[1].init({"queryType": 24});

        var chartIssueP1 = new ChartPie("/dashboard/issuestatistics1", "dashboard-chart-pie1", "doughnut", [true, 'right'])
        var chartIssueP2 = new ChartPie("/dashboard/issuestatistics2", "dashboard-chart-pie2", "doughnut", [true, 'right'])
        chartIssueP1.init()
        chartIssueP2.init()
        var todayTime = chartIssueP1.today;
        var colorL = chartIssueP1.chart.data.datasets[0].backgroundColor;

        var show_ss2 = document.getElementById("show-time-period-ss");
        var ss2 = document.getElementById("time-period-ss");
        show_ss2.onclick = function(e){
            var date = new Date();
            var nowHour = date.getHours();
            var html = '<option option-value="">0:00 - 23:59</option><br />';
            for (var i = nowHour; i >= 0; i--) {
                html += '<option option-value='+i+'>'+i+':00 - '+i+':59</option>';
            }
            $(ss2).html(html)
            if (ss2.style.display == 'block') {
                ss2.style.display = 'none';
            } else {
                ss2.style.display = 'block';
            }
        }
        ss2.onchange  = function() {
            var option = this.options[this.selectedIndex];
            show_ss2.value = option.innerHTML;
            this.style.display = 'none';
            top3()
        }
        var top3 = function() {
            var hour = $(ss2).children("option:selected").attr("option-value");
            if (hour === undefined) {
                hour = "";
            }
            $.ajax({
                url: "/dashboard/top3",
                type: "get",
                dataType: 'json',
                async: true,
                data: {"hour": hour},
                success: function (rep) {
                    var data = rep.data;
                    var htmlText;
                    for (var i=0; i<data.length; i++) {
                        if (data[i][1].length > 135) {
                            data[i][1] = data[i][1].substr(1, 130) + "~~~";
                        }
                    }
                    if (data.length === 0) {
                        htmlText = '<span>Endless data can be displayed</span>'
                    } else if (data.length === 1) {
                        data = data[0]
                        var a1 = '<a href="/crashinfo?ident='+encodeURIComponent(data[0])+'&type='+encodeURIComponent(data[2])+'" target="_blank">'+data[1]+'</a>';
                        htmlText = '<table class="table"><tbody><tr><td>1</td><td>' + a1 + '</td><td>' + data[3] + 'Second-rate</td></tr></tbody></table>';
                    } else if (data.length === 2) {
                        var a1 = '<a href="/crashinfo?ident='+encodeURIComponent(data[0][0])+'&type='+encodeURIComponent(data[0][2])+'" target="_blank">'+data[0][1]+'</a>';
                        var a2 = '<a href="/crashinfo?ident='+encodeURIComponent(data[1][0])+'&type='+encodeURIComponent(data[1][2])+'" target="_blank">'+data[1][1]+'</a>';
                        htmlText = '<table class="table"><tbody><tr><td>1</td><td>' + a1 + '</td><td>' + data[0][3] + 'Second-rate</td></tr><tr><td>2</td><td>';
                        htmlText += a2 + '</td><td>' + data[1][3] + 'Second-rate</td></tr></tbody></table>';
                    } else {
                        var a1 = '<a href="/crashinfo?ident='+encodeURIComponent(data[0][0])+'&type='+encodeURIComponent(data[0][2])+'" target="_blank">'+data[0][1]+'</a>';
                        var a2 = '<a href="/crashinfo?ident='+encodeURIComponent(data[1][0])+'&type='+encodeURIComponent(data[1][2])+'" target="_blank">'+data[1][1]+'</a>';
                        var a3 = '<a href="/crashinfo?ident='+encodeURIComponent(data[2][0])+'&type='+encodeURIComponent(data[2][2])+'" target="_blank">'+data[2][1]+'</a>';
                        htmlText = '<table class="table"><tbody><tr><td>1</td><td>' + a1 + '</td><td>' + data[0][3] + 'Second-rate</td></tr><tr><td>2</td><td>';
                        htmlText += a2 + '</td><td>' + data[1][3] + 'Second-rate</td></tr><tr><td>3</td><td>' + a3 + '</td><td>' + data[2][3] + 'Second-rate</td></tr></tbody></table>';
                    }
                    $("#top3").html(htmlText)
                },
                error: function () {
                    alert("top3 Request failed!")
                },
            })
        }
        top3()

        $("#chart-btn a").on("click", function() {
            $(this).siblings().removeClass("btn-info");
            $(this).addClass("btn-info");
            var i = parseInt($(this).attr("btn-param"));
            var d = parseInt($('select[params="0"]').val());
            resetDDCanvas();
            chartMap[i].init({"queryType": d});
        })

        $('select[params="0"]').change(function() {
            var d = parseInt($(this).children("option:selected").attr("option_value"));
            var p = parseInt($('div[id="chart-btn"]').find('a[class="btn btn-info"]').attr("btn-param"))
            resetDDCanvas();
            chartMap[p].init({"queryType": d})
        })

        var queryType = {
            queryParams: {
                "style": 0,
                "processed": 0,
                "days": 7,
                "version": "",
            },
        };
    } else {
        var queryType = {
            queryParams: {
                "style": parseInt($("#my-hide-style").text()),
                "processed": 0,
                "version": "",
                "times": $("#my-hide-time").text(),
                "end_time": $("#my-end-time").text()
            },
        };
    };

    $('#dashboard-table').bootstrapTable({
        url: '/dashboard/table',
        method: 'get',
        dataType: 'json',
        cache: false,
        striped: true,
        pagination: true,
        sidePagination: "client",
        // paginationVAlign: "top",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        searchOnEnterKey: true,
        showColumns: true,
        showRefresh: true,
        sortName: "lasttime",
        sortOrder: "desc",
        classes: "table table-hover table-no-bordered",
        queryParams: queryType.queryParams,
        columns: [
             {field: 'type', title: 'Error', align: 'center',
                formatter: function(value, row, index) {
                    if (value === -1) {
                        return 'collapse';
                    } else if (value === 1) {
                        return 'abnormal';
                    } else {
                        return '??';
                    }
                }
            },
            {field: 'id', title: 'serial number', align: 'center'},
            {field: 'feature', title: 'wrong description', align: 'center',
                formatter: function(value, row, index) {
                    if (value.length > 135) {
                        value = value.substr(0, 130) + "~~~";
                    }
                    if (row.status) {
                        return '<a href="/crashinfo?_id='+encodeURIComponent(row.id)+'&type='+encodeURIComponent(row['type'])+'" target="_blank"><s>'+value+'</s></a>'
                    }
                    return '<a href="/crashinfo?_id=' + encodeURIComponent(row.id)+'&type='+encodeURIComponent(row['type'])+'" target="_blank">' + value + '</a>'
                }
            },
            {field: 'firsttime', title: 'The first Second -RATE report time', align: 'center', sortable: true},
            {field: 'lasttime', title: 'Last report time', align: 'center', sortable: true},
            {field: 'count', title: 'Report the number of Second -Rate', align: 'center', sortable: true},
            {field: 'imei_member', title: 'Influence users', align: 'center', sortable: true},
            {field: 'status', title: 'state', align: 'center',
                formatter: function(value, row, index) {
                    if (value === false)
                        var display = "Not processed";
                    else
                        var display = "Processed";
                    var d = new Date(row.lasttime);
                    var ds = new Date(row.firsttime);
                    var dc = new Date(todayTime);
                    var e = undefined;
                    if (d >= dc) {
                        e = '<strong><span style="color: ' + colorL[1] + ';">' + display + '</span></strong>';
                    };
                    if (ds >= dc) {
                        e = '<strong><span style="color: ' + colorL[0] + ';">' + display + '</span></strong>';
                    };
                    if (e === undefined) {
                        return display;
                    }
                    return e;
                }
            },
        ],
    });

    // 滚动select
    var show_ss1 = document.getElementById("show-version-ss");
    var ss1 = document.getElementById("version-ss");
    show_ss1.onclick = function(e){
        if (ss1.style.display == 'block') {
            ss1.style.display = 'none';
        } else {
            ss1.style.display = 'block';
        }
    }
    ss1.onchange  = function() {
        var option = this.options[this.selectedIndex];
        show_ss1.value = option.innerHTML;
        this.style.display = 'none';
    }

    $(".search-group select").each(function(index, ele) {
        $(ele).change(function() {
            var d = parseInt($(ele).children("option:selected").attr("option_value"));
            var i = parseInt($(ele).attr("params"))

            switch (i) {
                case 1: queryType.queryParams.days = d;
                break;
                case 2: queryType.queryParams.processed = d;
                break;
                case 3: queryType.queryParams.style = d;
                break;
                case 4:
                    var v = $(ele).val();
                    if (v === "All versions") {
                        queryType.queryParams.version = "";
                    } else {
                        queryType.queryParams.version = v;
                    };
                    break;
                default: alert("error params!!!");
            }
            $('#dashboard-table').bootstrapTable("refresh", queryType.queryParams)
        })
    });

});