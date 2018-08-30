$(document).ready(function() {
	var logkey = $("#logkeyholder").data("logkey");
	getJobList(logkey);
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
	content += '</tr></thead>';
	content += '<tbody id="jobListTableBody">';

	for(var i=0;i<jobList.length;i++) {
		var job = jobList[i];
		var jobTime = new Date(parseInt(job['epochTime'])*1000);
		var tableDateTime = jobTime.toLocaleDateString() + " " + jobTime.toLocaleTimeString();
		content += '<tr>';
		content += '<td id="jobSessionId">' + job['sessionId'] + '</td>';
		content += '<td>' + job['jobName'] + '</td>';
		content += '<td>' + tableDateTime + '</td>';
		content += '<td>' + job['jobStatus'] + '</td>';
		content += '</tr>';
	}

	content += '</tbody>';
	content += '</table>';

	$(".job-list-table-wrapper").append(content);
	adjustBlockTableWidth(4, "#jobListTable");
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
