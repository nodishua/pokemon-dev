$.prototype.switchSidebarConStatus = function() {
	$(".s-active").removeClass("s-active");
	$(this).addClass("s-active");
};

function setSidebarActive(u) {
	let eleJQSelector1 = ".sidebar a[href='" + u + "']";
	$(eleJQSelector1).switchSidebarConStatus();
	let eleID = $(eleJQSelector1).parent().parent().parent().attr("id");
	let eleJQSelector2 = ".sidebar-menu a[href='#" + eleID + "']";
	$(eleJQSelector2).trigger("click");
};

function servBtnClick(self) {
	$("#serv-select").val($(self).attr("id"));
	$("#serv-select-modal").modal('hide');
};

function channelBtnClick(self) {
	$("#channel-select").val($(self).attr("id"));
	$("#channel-select-modal").modal('hide');
}

function date2int(ss) {
	let si = ss.split('-').join('');
	si = parseInt(si);
	return si;
}

function getStartAndEndDate() {
	let r = [null, null];
	let s = $('#start-date').val();
	let e = $('#end-date').val();

	if (s && e) {
		s = date2int(s);
		e = date2int(e)
		if (s > e) {
			return null;
		}
		return [s, e];
	}
	else if (s)
		r[0] = date2int(s);
	else if (e)
		r[1] = date2int(e);

	return r;
}

function resetCanvas(id, fu) {
	let $id = '#' + id;
    $($id).remove();
    let div = document.getElementById(fu);
    let canvas = document.createElement("canvas");
    canvas.setAttribute("id", id);
    canvas.setAttribute("width", 900);
    canvas.setAttribute("height", 200);
    div.appendChild(canvas)
};

const ChartOptions = {
	animation: { // Animation effect setting
		duration: 1500, // Animation time
	},
	title: {
        display: false,
        text: 'Chart',
        // fontSize: 20,
    },
    scales: {
        yAxes: [{
            ticks: {
                beginAtZero: true
            }
        }],
    },
    legend: {
        display: true,
        position: 'top',
    },
    tooltips: { // Prompting tool, which is the frame that indicates the number of numbers after the mouse finger
    	enabled: true,
    	intersect: false,
    	// if true, the tooltip mode applies only when the mouse position intersects // with an element. If false, the mode will be applied at all times.
    	mode: 'index',
    	// custom: customTooltips,
    },
};

$(function() {
	'use strict'

	// Left navigation bar
	$(".sidebar-menu a").on("click", function() {
		let self = $(this);
		let id = self.attr('href').substring(1);
		if ($('#'+id).hasClass('in')) {
			let arrows = self.children("span.glyphicon-chevron-down");
			arrows.removeClass("glyphicon-chevron-down");
			arrows.addClass("glyphicon-chevron-up");
			self.parent().parent().removeClass("ss-active");
			self.children("div").removeClass("s-active");
			$(`${self.attr("href")} ul`).removeClass("ss-active");
		} else {
			let arrows = self.children("span.glyphicon-chevron-up");
			arrows.removeClass("glyphicon-chevron-up");
			arrows.addClass("glyphicon-chevron-down");
			self.parent().parent().addClass("ss-active");
			self.children("div").addClass("s-active");
			$(`${self.attr("href")} ul`).addClass("ss-active");
		}
	});
	setSidebarActive(window.location.pathname);

	changeCopyrightPosition();

	// Member add
	$("#account-name").change(function() {
		let name = $(this).val();
		if (name === "") {
			return;
		};
		$.ajax({
			url: "/create_account",
			type: "get",
			async: true,
			dataType: "json",
			data: {name: name},
			success: function(rep) {
				if (rep.ret) {
					$("#account-name-remove").addClass("hidden");
					$("#account-name-ok").removeClass("hidden");
				} else {
					$("#account-name-ok").addClass("hidden");
					$("#account-name-remove").removeClass("hidden");
				}
			}
		})
	})
	const verify_pwd = function() {
		let current_pwd = $("#confirm-pwd").val();
		if (current_pwd === "") {
			return;
		}
		let origin_pwd = $("#account-pwd").val();
		if (current_pwd === origin_pwd) {
			$("#confirm-pwd-remove").addClass("hidden");
			$("#confirm-pwd-ok").removeClass("hidden");
		} else {
			$("#confirm-pwd-ok").addClass("hidden");
			$("#confirm-pwd-remove").removeClass("hidden");
		}
	}
	$("#confirm-pwd").change(verify_pwd)
	$("#account-pwd").change(verify_pwd)
	$("#create-account").on("click", function() {
		let self = $(this);
		self.attr("disabled", true);
		let pwd = $("#confirm-pwd").val();
		let origin_pwd = $("#account-pwd").val();
		let name = $("#account-name").val();
		let name_usable_verify = $("#account-name-remove").hasClass("hidden");
		if (name !== "" && pwd !== "" && pwd === origin_pwd && name_usable_verify) {
			$.ajax({
				url: "/create_account",
				type: "post",
				async: true,
				dataType: "json",
				contentType: "application/json",
				data: JSON.stringify({
					name: name,
					pwd: pwd,
					level: parseInt($("#power-level").val()),
				}),
				success: function(rep) {
					alert(rep.data);
					$(".check-op").addClass("hidden");
					$("#create-account-err").html("");
					$("#confirm-pwd").val("");
					$("#account-pwd").val("");
					$("#account-name").val("");
					self.removeAttr("disabled");
				}
			})
		} else {
			$("#create-account-err").html("error: Please fill in the correct information");
			self.removeAttr("disabled");
		}
	})
})