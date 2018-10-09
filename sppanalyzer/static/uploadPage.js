$(document).ready(function() {
	var inputs = document.querySelectorAll( '#file' );
	Array.prototype.forEach.call( inputs, function( input )
	{
		var label = input.nextElementSibling,
		labelVal = label.innerHTML;
		input.addEventListener( 'change', function( e )
		{
			var fileName = '';
			if(this.files && this.files.length > 1)
				fileName = ( this.getAttribute( 'data-multiple-caption' ) || '' ).replace( '{count}', this.files.length );
			else
				fileName = e.target.value.split( '\\' ).pop();
			if( fileName )
				label.querySelector( 'span' ).innerHTML = fileName;
			else
				label.innerHTML = labelVal;
		});
	});

	$("#uploadSubmit").click(function() {
		$('#uploadForm').submit();
	});

	$(".logviewbutton").click(function() {
		analyzeLogs();
	});

	$(function() {
		var percent = $('#percent');
		var status = $('#status');
		$('#uploadForm').ajaxForm({
			beforeSend: function() {
				status.empty();
				var percentVal = '0%';
				percent.html(percentVal);
				$("#uploadSubmit").addClass("hiddenvis");
				status.removeClass("hiddenvis");
				percent.removeClass("hiddenvis");
				status.addClass("blinking-div");
			},
			uploadProgress: function(event, position, total, percentComplete) {
				status.html("UPLOADING")
				var percentVal = percentComplete + '%';
				percent.html(percentVal);
			},
			complete: function(xhr) {
				status.html(xhr.responseJSON.message);
				status.removeClass("blinking-div");
				percent.addClass("hiddenvis");
				if(xhr.response == 200) {
					unpackLogs(xhr.responseJSON.fullfilepath,
					xhr.responseJSON.filename,
					xhr.responseJSON.logkey);
				} else {
					$("#uploadSubmit").removeClass("hiddenvis");
				}
			}
		});
	});
});

function unpackLogs(fullfilepath, filename, logkey) {
	//can refactor this at some point to just need logkey
	var status = $('#status');
	var keyname = $('#keyname');
	var logkeyinput = $('#logkeyinput');
	encodedfilepath = encodeURIComponent(fullfilepath);
	console.log("Upload clicked. Trying to unpack now.");
	unpackurl = "/unpack?fullfilepath=" + encodedfilepath + "&filename=" + filename + "&logkey=" + logkey
	$.ajax({
		type: "POST",
		url: unpackurl,
		beforeSend: function() {
			status.addClass("blinking-div");
			status.html("UNPACKING");
		},
		complete: function(xhr) {
			status.removeClass("blinking-div");
			status.html(xhr.responseJSON.message);
			keyname.removeClass("hiddenvis");
			keyname.html("LOG KEY: " + xhr.responseJSON.logkey);
			logkeyinput.val(xhr.responseJSON.logkey);
			$("#uploadSubmit").removeClass("hiddenvis");
		}
	});
}

function analyzeLogs() {
	var logkey = $('#logkeyinput').val();
	if(logkey.length < 10 || logkey.length > 10) {
		alert("Log key invalid");
		return;
	}
	analyzeurl = "/analyze/joblist?logkey=" + logkey;
	$.ajax({
		type: "GET",
		url: analyzeurl,
		complete: function(xhr) {
			//if JSON we have some message besides page content
			//right now we either find log key exists or don't
			if(xhr.responseJSON) {
				alert(xhr.responseJSON.message);
			} else {
				window.location.href = analyzeurl;
			}
		}
	});
}
