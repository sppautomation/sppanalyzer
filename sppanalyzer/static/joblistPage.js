$(document).ready(function() {
	var logkey = $("#logkeyholder").data("logkey");
	getJobList(logkey);
	getApplianceDetails(logkey);
	$("#backToUpload").click(function() {
                window.location.href = '/upload';
        });
});

function getJobList(logkey) {
	analyzeurl = "/analyze/joboverview?logkey=" + logkey;
	$.ajax({
		type: "GET",
		url: analyzeurl,
		beforeSend: function() {
			$(".job-list-table-wrapper").addClass('loading-overlay');
		},
		complete: function(xhr) {
			$(".job-list-table-wrapper").removeClass('loading-overlay');
			renderJobList(xhr.responseJSON);
		}
	});
}

function getApplianceDetails(logkey) {
	appdeturl = "/analyze/applianceinfo?logkey=" + logkey;
	$.ajax({
                type: "GET",
                url: appdeturl,
                beforeSend: function() {
                },
                complete: function(xhr) {
                        setApplianceDetails(xhr.responseJSON);
                }
        });
}

function getJobSessionInfo(logkey, sessionId) {
	jobdetailsurl = "/analyze/jobdetails?logkey=" + logkey + "&jobsession=" + sessionId
	$.ajax({
		type: "GET",
		url: jobdetailsurl,
		beforeSend: function() {
		},
		complete: function(xhr) {
			$(".job-list-table-wrapper").removeClass('loading-overlay');
			renderJobDetails(xhr.responseJSON, sessionId);
		}
	});
}

function setApplianceDetails(details) {
	this.applianceDetails = details;
	$('h1').html(details.name);
	$('h2').html(details.date);
	$('h5').html(details.release.version + " " + details.release.build)
}

function renderJobDetails(jobDetails, sessionId) {
	content = '';
	content += '<div id="jobLogDetailsWrapper">';
	content += '<div id="backToJoblist" class="joblist-button">BACK</div>';
	content += '<div id="toggleInfo" class="joblist-button">TOGGLE INFO</div>';
	content += '<div id="jobListDetails">';
	for (var i=0;i<jobDetails.length;i++) {
		if(jobDetails[i].includes("] ERROR"))
			content += '<div class="error-msg">';
		else if(jobDetails[i].includes("] WARN"))
			content += '<div class="warn-msg">';
		else
			content += '<div class="info-msg">';
		content += jobDetails[i] + '</div>';
	}
	content += '</div></div>';

	$("#sectionTitle").html(sessionId);
	$('#jobListTable').hide();
	$('#backToUpload').hide();
	$(".job-list-table-wrapper").append(content);

	$("#backToJoblist").click(function() {
		$("#jobLogDetailsWrapper").remove();
		$('#jobListTable').show();
		$('#backToUpload').show();
		$("#sectionTitle").html(window.applianceDetails.date);
	});

	$("#toggleInfo").click(function() {
		$('.info-msg').toggle()
	});
}

function renderJobList(jobList) {
	jobList.sort(function(a,b) {
		if (a['epochTime'] == b['epochTime']) return 0;
		return a['epochTime'] < b['epochTime'] ? 1 : -1;
	});
	content = '';
	content += '<table id="jobListTable">';
	content += '<thead id="jobListTableHead"><tr>';
	content += '<th>Session ID</th>';
	content += '<th>Name</th>';
	content += '<th>Time</th>';
	content += '<th>Status</th>';
	content += '<th>Resources</th>';
	content += '</tr></thead>';
	content += '<tbody id="jobListTableBody">';

	for(var i=0;i<jobList.length;i++) {
		var job = jobList[i];
		var jobTime = new Date(parseInt(job['StartDateTime'])*1000);
		var tableDateTime = jobTime.toLocaleDateString() + " " + jobTime.toLocaleTimeString();
		if(job['Result'].toUpperCase() != "COMPLETED" && job['Result'].toUpperCase() != "FAILED")
			content += '<tr style="background-color:#e0da3c;">';
		else if(job['Result'].toUpperCase() == "FAILED")
			content += '<tr style="background-color:#cc3830;">';
		else
			content += '<tr>';
		content += '<td><div class="jobSessionId">' + job['JobID'] + '</div></td>';
		content += '<td>' + job['JobType'] + " " + job['SLA'] + '</td>';
		content += '<td>' + tableDateTime + '</td>';
		content += '<td>' + job['Result'] + '</td>';
		content += '<td>' + job['Targets'].replace(/:/g,", ") + '</td>';
		content += '</tr>';
	}

	content += '</tbody>';
	content += '</table>';

	$(".job-list-table-wrapper").append(content);
	adjustBlockTableWidth(4, "#jobListTable");

	$(".jobSessionId").click(function(e) {
		$(".job-list-table-wrapper").addClass('loading-overlay');
		getJobSessionInfo($("#logkeyholder").data("logkey"), $(this).html());
	});

	$('#jobListTable').tablesorter({sortList: [[2,1]]});
}

function adjustBlockTableWidth(numCols, tableSelector) {
	for (var i=0; i<numCols; i++)
	{
		var thWidth=$(tableSelector).find("th:eq("+i+")").width();
		var tdWidth=$(tableSelector).find("td:eq("+i+")").width();
		if (thWidth<tdWidth) {
			$(tableSelector).find("th:eq("+i+")").width(tdWidth);
		}
		else {
			$(tableSelector).find("td:eq("+i+")").width(thWidth);
		}
	}
}

