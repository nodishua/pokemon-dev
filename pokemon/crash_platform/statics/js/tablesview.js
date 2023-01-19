function a_method(self, file, _id) {
    $(self).text('Analytical...');
    $(self).addClass("disabled");
    $.ajax({
        url: '/db/manualanalysis',
        type: 'get',
        dataType: 'json',
        async: true,
        data: {"file": file, "_id": _id},
        success: function (data) {
            $(self).text('Analyze');
            $(self).removeClass("disabled");
            if (data.ret) {
                if (file == "dmp") {
                    $('#dmptable').bootstrapTable("refresh")
                } else {
                    $('#sotable').bootstrapTable("refresh")
                }
                alert("Completed analysis")
            } else {
                alert(data.error)
            }
        },
        error: function (result) {
            $(self).text('Analyze');
            $(self).removeClass("disabled");
            alert("fail!");
        },
    })
}

$(function () {
    $("div.sidebar ul.nav a").each(function(){
        $(this).removeClass("s-active")
    });
    $("#my-tables-show").addClass("s-active");
    initDatetimePicker()

    var queryParams = function(params) {
        params.date_start = $("#index-start").val();
        if (params.date_start) {
            params.date_start += " 0:0:0"
        }
        params.date_end = $("#index-end").val();
        if (params.date_end) {
            params.date_end += " 23:59:59"
        }
        if (params.order == "desc") {
            params.order = -1
        }
        else if (params.order == "asc") {
            params.order = 1
        }
        return params;
    };
    var responseHandler = function(res) {
        return {
            "total": res.total,
            "rows": res.rows,
            "offset": res.offset,
            "limit": res.limit
        }
    };

    $('#stacktable').bootstrapTable({
        url: '/db/table_views/dmpst_db',
        method: 'post',
        contentType:"application/json",
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        showColumns: true,
        showRefresh: true,
        sortName: "lasttime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,

        columns: [
            {field: 'id', title: 'DB serial number', align: 'center'},
            {field: 'feature', title: 'description', align: 'center',
                formatter: function(value, row, index) {
                    return '<a href="/crashinfo?_id='+encodeURIComponent(row.id)+'&type=-1" target="_blank">' + value + '</a>'
                }
            },
            {field: 'report_version', title: 'Report version number', align: 'center',},
            {field: 'count', title: 'Total number of crashes', align: 'center',},
            {field: 'firsttime', title: 'First time reported', align: 'center',},
            {field: 'lasttime', title: 'last reported time', align: 'center',},
            {field: 'status', title: 'status', align: 'center',},
        ],
    });
    $('#sotable').bootstrapTable({
        url: '/db/table_views/upfile_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        // strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "ctime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,

        columns: [
            {field: 'id', title: 'DB serial number', align: 'center'},
            {field: 'version', title: 'version number', align: 'center',},
            {field: 'package_name', title: 'package name', align: 'center',},
            {field: 'time', title: 'upload time', align: 'center',},
            {field: 'name', title: 'upload file name', align: 'center',},
            {field: 'status', title: 'status', align: 'center',},
            {field: 'symbol_nums', title: 'symbol file serial number', align: 'center',},
            {field: 'op', title: 'Operation', align: 'center',
                formatter: function (value, row, index) {
                    return '<a href="#" class="btn btn-default" onclick="a_method(this, \'so\', \'' + row.id + '\')">analyze</a>'
                }
            }],
    });
    $('#dmptable').bootstrapTable({
        url: '/db/table_views/dmp_db',
        method: 'post',
        dataType: "json",
        pagination: true,
        singleSelect: false,
        search: true,
        toolbar: '#toolbar',
        striped: true,
        cache: false,
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 50, 100],
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        minimumCountColumns: 2,
        sidePagination: "server",
        // sortable: true,
        sortName: "report_time",
        sortOrder: "desc",
        responseHandler: responseHandler,
        // queryParamsType: "undefined",
        queryParams: queryParams,
        contentType: "application/json",

        columns: [
            {field: 'id', title: 'DB serial number', align: 'center'},
            {field: 'feature', title: 'description', align: 'center',},
            {field: 'report_time', title: 'Crash time', align: 'center',},
            {field: 'file_name', title: 'dmp file name', align: 'center',},
            {field: 'status', title: 'status', align: 'center',},
            {field: 'symbol_nums', title: 'Symbol file used', align: 'center',},
            {field: 'id', title: 'operation', align: 'center',
                formatter: function (value, row, index) {
                    var e = '<a href="#" class="btn btn-default" onclick="a_method(this, \'dmp\', \'' + row.id + '\')">Analyze</a>';  //row.id为每行的id
                    // var d = '<a href="#" mce_href="#" onclick="del(\'' + row.id + '\')">Check</a> ';
                    return e;
                }
            },
        ],
    });
    $('#exceptiontable').bootstrapTable({
        url: '/db/table_views/exst_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "lasttime",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,
        // classes: "table table-hover table-no-bordered",

       columns: [
            {field: 'id', title: 'DB serial number', align: 'center'},
            {field: 'feature', title: 'describe', align: 'center',
                formatter: function(value, row, index) {
                    return '<a href="/crashinfo?_id=' + encodeURIComponent(row.id) + '&type=1" target="_blank">' + value + '</a>'
                }
            },
            {field: 'report_version', title: 'Report version number', align: 'center',},
            {field: 'count', title: 'Total number of reports', align: 'center'},
            {field: 'firsttime', title: 'First time reported', align: 'center',},
            {field: 'lasttime', title: 'last reported file name', align: 'center',},
            {field: 'status', title: 'status', align: 'center',},
        ],
    });
    $('#exceptionstable').bootstrapTable({
        url: '/db/table_views/exre_db',
        method: 'post',
        dataType: "json",
        striped: true,
        pagination: true,
        sidePagination: "server",
        pageNumber: 1,
        pageSize: 10,
        pageList: [10, 20, 30, 40, 50],
        search: true,
        strictSearch: false,
        showColumns: true,
        showRefresh: true,
        sortName: "report_time",
        sortOrder: "desc",
        responseHandler: responseHandler,
        queryParams: queryParams,
        // classes: "table table-hover table-no-bordered",

       columns: [
        {field: 'id', title: 'DB serial number', align: 'center'},
        {field: 'feature', title: 'description', align: 'center',},
        {field: 'version', title: 'version number', align: 'center',},
        {field: 'package_name', title: 'package name', align: 'center',},
        {field: 'report_time', title: 'Report time', align: 'center',},
        {field: 'phone_name', title: 'phone model', align: 'center',},
        {field: 'phone_sys', title: 'system model', align: 'center',},
        {field: 'status', title: 'status', align: 'center',},
        ],
    });
    $(document).keyup(function(e) {
        if (e.keyCode === 13) {
            $('#stacktable').bootstrapTable("refresh");
            $('#sotable').bootstrapTable("refresh");
            $('#dmptable').bootstrapTable("refresh");
            $('#exceptiontable').bootstrapTable("refresh");
            $('#exceptionstable').bootstrapTable("refresh");
        }
    })
})