$(document).ready(function() {
	displayRecentLogKeys();
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
		deleteOldLogs();
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
			timeout: 0,
			uploadProgress: function(event, position, total, percentComplete) {
				status.html("UPLOADING")
				var percentVal = percentComplete + '%';
				percent.html(percentVal);
			},
			complete: function(xhr) {
				status.html(xhr.responseJSON.message);
				status.removeClass("blinking-div");
				percent.addClass("hiddenvis");
				if(xhr.status == 200) {
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
		timeout: 0,
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

function deleteOldLogs() {
	$.ajax({
			type: "POST",
			url: "/delete",
			complete: function(xhr) {
				console.log("Cleaning old logs, status " + xhr.status);
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
				appendLogKeyCookie(logkey);
				window.location.href = analyzeurl;
			}
		}
	});
}

function getCookie(cname) {
	var name = cname + "=";
	var decodedCookie = decodeURIComponent(document.cookie);
	var ca = decodedCookie.split(';');
	for(var i = 0; i <ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0) == ' ') {
			c = c.substring(1);
		}
        	if (c.indexOf(name) == 0) {
			return c.substring(name.length, c.length);
		}
	}
	return "";
}

function appendLogKeyCookie(logkey) {
	curvals = getCookie("logkeys");
	if(curvals.length == 0) {
		document.cookie = "logkeys=" + logkey;
	} else {
		logkeyarray = curvals.split(",");
		if(!logkeyarray.includes(logkey)) {
			logkeyarray.push(logkey)
		}
		if(logkeyarray.length > 4) {
			logkeyarray.shift();
		}
		document.cookie = "logkeys=" + logkeyarray.toString();
	}
}

function displayRecentLogKeys() {
	logkeys = getCookie("logkeys");
	if(logkeys.length > 0) {
		$('#recentLogLinksHdr').toggle();
		$('#recentLogLinks').toggle();
		logkeyarray = logkeys.split(',');
		logkeyarray.forEach(function(logkey) {
			var content = "";
			content = "<a href=";
			content += "/analyze/joblist?logkey=";
			content += logkey;
			content += ">";
			content += logkey;
			content += "</a>";
			$('#recentLogLinks').append(content + " ");
		});
	}
}
