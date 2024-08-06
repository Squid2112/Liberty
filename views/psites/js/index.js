function RunCode() {
	fLinks.location.href = 'loadlinks.cfm?CODE=' + CodeForm.Code.value + '&S=' + CodeForm.Start.value + '&E=' + CodeForm.End.value + '&X=' + CodeForm.Step.value + '&F=' + CodeForm.Fill.value + '&N=' + CodeForm.FillNum.value;
}

function loadURL(url) {
	$('#fSite').attr('src',url);
}

$(document).ready(function() {
	$('#btnLinks').addClass('btnOut');
	$('#btnLinks').mouseenter(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOut');
			$(this).addClass('btnOver');
			$(this).fadeIn(130);
		}
	);
	$('#btnLinks').mouseleave(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOver');
			$(this).addClass('btnOut');
			$(this).fadeIn(130);
		}
	);

	$('#btnSite').addClass('btnOut');
	$('#btnSite').mouseenter(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOut');
			$(this).addClass('btnOver');
			$(this).fadeIn(130);
		}
	);
	$('#btnSite').mouseleave(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOver');
			$(this).addClass('btnOut');
			$(this).fadeIn(130);
		}
	);

	$('#btnRun').addClass('btnOut');
	$('#btnRun').mouseenter(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOut');
			$(this).addClass('btnOver');
			$(this).fadeIn(130);
		}
	);
	$('#btnRun').mouseleave(
		function() {
			$(this).fadeOut(130);
			$(this).removeClass('btnOver');
			$(this).addClass('btnOut');
			$(this).fadeIn(130);
		}
	);

	var w = $(window).width();
	var l = $('#sLinks').width();
	$('#fSite').width(w-l-30);

	var h = $(window).height();
	var f = $('#codeForm').height();
	$('#fSite').height(h-f-25);
	$('#sLinks').height($('#sSite').height());

	$('#btnLinks').click(function() { $('#sLinks').toggle('fast'); });
	$('#btnSite').click(function() { $('#sSite').toggle('fast'); });

	$('#btnRun').click(function() {
		var u = '?';
		u += 'code=' + $('#Code').val();
		u += '&s=' + $('#Start').val();
		u += '&e=' + $('#End').val();
		u += '&f=' + $('#Fill').val();
		u += '&x=' + $('#Step').val();
		u += '&n=' + $('#FillNum').val();
		$('#sLinks').load('/com/psites/loadlinks.cfm' + u);
	});
});