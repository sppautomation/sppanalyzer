$(document).ready(function() {
	var logkey = $("#logkeyholder").data("logkey");
	getJobList(logkey);
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

function getJobSessionInfo(logkey, sessionId) {
	jobdetailsurl = "/analyze/jobdetails?logkey=" + logkey + "&jobsession=" + sessionId
	$.ajax({
		type: "GET",
		url: jobdetailsurl,
		beforeSend: function() {
		},
		complete: function(xhr) {
			renderJobDetails(xhr.responseJSON);
		}
	});
}

function renderJobDetails(jobDetails) {
	content = '';
	content += '<div id="jobLogDetailsWrapper">';
	content += '<div id="backToJoblist" class="joblist-button">BACK</div>';
	content += '<div id="jobListDetails">';
	for (var i=0;i<jobDetails.length;i++) {
		if(jobDetails[i].includes("] ERROR"))
			content += '<span style="background-color:red;">';
		else if(jobDetails[i].includes("] WARN"))
			content += '<span style="background-color:yellow;">';
		else
			content += '<span>';
		content += jobDetails[i] + '</span></br></br>';
	}
	content += '</div></div>';

	$("#sectionTitle").html("JOB DETAILS");
	$('#jobListTable').hide();
	$('#backToUpload').hide();
	$(".job-list-table-wrapper").append(content);

	$("#backToJoblist").click(function() {
		$("#jobLogDetailsWrapper").remove();
		$('#jobListTable').show();
		$('#backToUpload').show();
		$("#sectionTitle").html("JOB LIST");
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
			content += '<tr style="background-color:yellow;">';
		else if(job['Result'].toUpperCase() == "FAILED")
			content += '<tr style="background-color:red;">';
		else
			content += '<tr>';
		content += '<td><div class="jobSessionId">' + job['JobID'] + '</div></td>';
		content += '<td>' + job['SLA'] + '</td>';
		content += '<td>' + tableDateTime + '</td>';
		content += '<td>' + job['Result'] + '</td>';
		content += '<td>' + job['Targets'].replace(/:/g,", ") + '</td>';
		content += '</tr>';
	}

	content += '</tbody>';
	content += '</table>';

	$(".job-list-table-wrapper").append(content);
	adjustBlockTableWidth(4, "#jobListTable");

	$(".jobSessionId").click(function() {
		getJobSessionInfo($("#logkeyholder").data("logkey"), $(this).html());
	});
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

