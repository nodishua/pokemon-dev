function switchStatus(status) {
    var processed;
    if (status === -1) {
        processed = false;
    } else {
        processed = true;
    };
    var datas = {
        "_id": parseInt($("#stack-id").text()),
        "style": parseInt($("#stack-style").attr("params")),
        "processed": processed,
        "comments": $("#switch-status-content").val()
    };

    $.ajax({
        url: '/crashinfo/switchstatus',
        type: 'post',
        dataType: 'json',
        contentType: 'application/json',
        async: true,
        data: JSON.stringify(datas),
        beforeSend: function(XMLHttpRequest) {
            if (datas.comments === "") {
                $("#switch-status-error").text("Don't be empty!");
                return false;
            } else {
                return true;
            }
        },
        success: function (data) {
            if (data.ret) {
                alert("Successfully handle");
                window.location.reload();
            } else {
                alert("Failed to handle")
            }
        },
        error: function () {
            alert("fail")
        },
    });
};

function showMore(_id, style) {
    $.ajax({
        url: '/crashinfo/info',
        type: 'get',
        dataType: 'json',
        contentType: 'application/x-www-form-urlencoded',
        async: true,
        data: {"_id": _id, "style": style},
        success: function (response) {
            $("#extra_info").html(response.htmlText);
            $("#crash-con").text(response.crashCon);
            $("#crash-thr").text(response.crashThread);
            $("#crash-all").text(response.crashAll);
            $("#app_debug").text(response.app_debug);
        },
        error: function (result) {
            alert("fail!");
        }
    })
};

$(function() {
    var StackID = parseInt($("#stack-id").text());
    var StackStyle = parseInt($("#stack-style").attr("params"));

    function versionShowDivs() {
        var html = document.getElementById("full-version").innerHTML;
        var reg = new RegExp("<div>[^<>]*</div>", "g");
        return html.match(reg);
    }
    var divs = versionShowDivs();
    if (divs.length > 2) {
        var fullVersion = document.getElementById("full-version");
        var fullBtn = document.getElementById("full-btn");
        fullVersion.innerHTML = divs[0] + divs[1];
        function fullShow() {
            var html = '';
            for (var i in divs) {
                html += divs[i];
            }
            fullVersion.innerHTML = html;
            fullBtn.innerHTML = "收起";
            fullBtn.onclick = packUp;
        }
        function packUp() {
            fullVersion.innerHTML = divs[0] + divs[1];
            fullBtn.innerHTML = "...alll";
            fullBtn.onclick = fullShow;
        }
        fullBtn.innerHTML = "...alll";
        fullBtn.onclick = fullShow;
    }

    var chartPE = new ChartPie(
            "/crashinfo/chartpie",
            "crashinfo-equipment-chart",
            "pie",
            [true, 'right'],
            {"_id": StackID, "style": StackStyle, "type": "phone"}
        );
    var chartPS = new ChartPie(
            "/crashinfo/chartpie",
            "crashinfo-system-chart",
            "pie",
            [true, 'right'],
            {"_id": StackID, "style": StackStyle, "type": "sys"}
        );
    var chartSDK = new ChartPie(
            "/crashinfo/chartpie",
            "crashinfo-sdk-chart",
            "pie",
            [true, 'right'],
            {"_id": StackID, "style": StackStyle, "type": "sdk"}
        );
    chartPE.init();
    chartPS.init();
    chartSDK.init();

    var frequencyChartInit = function(queryType) {
        var responseData;

        $.ajax({
            url: '/crashinfo/frequencychart',
            type: 'get',
            dataType: 'json',
            async: false,
            contentType: 'application/json',
            data: {"queryType": queryType, "_id": StackID, "style": StackStyle},
            success: function (data) {
                if (data.ret) {
                    responseData = data;
                } else {
                    alert("chart init fail!")
                }
            },
            error: function () {
                alert("chart Request failed！")
            },
        });

        var ctx = document.getElementById("crashinfo-frequency-chart");
        var chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: responseData.xAex,
                datasets: [{
                    label: "错误",
                    fill: false,
                    borderColor: "#007bff",
                    borderWidth: 2,
                    pointBackgroundColor: "#fff",
                    data: responseData.xData,
                }]
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
                            beginAtZero: true
                        }
                    }]
                },
                legend: {
                    display: true,
                    position: 'bottom',
                },
                tooltips: {
                    enable: true,
                    intersect: false,
                    backgroundColor: 'rgba(0,0,0,0.8)'
                }
            }
        });
    };
    frequencyChartInit(24)

    $('#crashinfo-table').bootstrapTable({
        url: '/crashinfo/table',
        method: 'get',
        dataType: "json",
        striped: false,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 7,
        pageList: [10, 20, 30, 40, 50],
        sortName: "report_time",
        sortOrder: "desc",
        classes: "table table-hover table-no-bordered",
        queryParams: function(params) {
            params._id = StackID
            params.style = StackStyle
            return params
        },
        responseHandler: function(res) {
            return {
                "total": res.total,
                "rows": res.rows,
                "limit": res.limit,
                "offset": res.offset,
            }
        },
        columns: [
            {field: 'id', title: 'serial number', align: 'center',
                formatter: function (value, row, index) {
                        var e = '<a href="javascript:;" onclick="showMore(\'' + row.id + '\',\'' + StackStyle + '\')">' + value + '</a>';
                        if (index === 0) {
                            showMore(row.id, StackStyle)
                        }
                        return e;
                    }
                },
            {field: 'report_time', title: 'Report time', align: 'center',
                formatter: function (value, row, index) {
                    var e = '<a href="javascript:;" onclick="showMore(\'' + row.id + '\',\'' + StackStyle + '\')">' + value + '</a>';
                    return e;
                }
            },
        ],
    });

    var resetCrashCanvas = function() {
        $("#crashinfo-frequency-chart").remove();
        var div = document.getElementById("div-crashinfo-frequency-chart");
        var canvas = document.createElement("canvas");
        canvas.setAttribute("id", "crashinfo-frequency-chart");
        canvas.setAttribute("width", 600);
        canvas.setAttribute("height", 80);
        div.appendChild(canvas)
    };
    $("#ch-chart-select").change(function() {
        var d = parseInt($("#ch-chart-select option:selected").attr("option_value"))
        resetCrashCanvas()
        frequencyChartInit(d)
    });

    $("#crash_comment button").on("click", function() {
        var comments = $("#crash_comment textarea").val()
        if (comments === "") {
            alert("Can not be empty")
        } else {
            var datas = {
                "_id": StackID,
                "style": StackStyle,
                "comment": comments
            }

            $.ajax({
                url: "/crashinfo/comment",
                type: "post",
                dataType: "json",
                contentType: "application/json",
                async:true,
                data: JSON.stringify(datas),
                success: function(response) {
                    if (response.ret) {
                        var strData = "<p>" + response.data.name + " " + response.data.time + "：</p><pre>" + response.data.comments + "</pre>"
                        $("#crash_comment_view").append(strData)
                        $("#crash_comment textarea").val("")
                    } else {
                        alert("add failed")
                    }
                }
            })
        }
    })
})