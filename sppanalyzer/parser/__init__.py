import re

catalog_matcher = re.compile("catalog")
on_demand_restore_matcher = re.compile("onDemandRestore")
maintenance_matcher = re.compile("Maintenance")
vmware_matcher = re.compile("vmware_")
hyper_v_matcher = re.compile("hyperv_")
oracle_matcher = re.compile("oracle_")
sql_matcher = re.compile("sql_")
db2_matcher = re.compile("db2_")

job_pattern = re.compile("[0-9]{13} ===== Starting job for policy .*\. id")
vm_job_pattern = re.compile("[0-9]{13} vmWrapper .* type vm")
job_app_pattern = re.compile("[0-9]{13} Options for database .*")
completion_pattern = re.compile("[0-9]{13} .* completed.*with status .*")
completion_type_matcher = re.compile("(COMPLETED|PARTIAL|FAILED|RESOURCE ACTIVE)")
job_id_pattern = re.compile("[0-9]{13}")


class Parser:

    def __init__(self, log_path):
        self.log_path = log_path

    @staticmethod
    def get_timestamp_from_id(job_id):
        return job_id[:-3]

    @staticmethod
    def job_classifier(job_name):
        job_type, sla_name = None, None
        if catalog_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "Catalog"
        elif on_demand_restore_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "On-Demand Restore"
        elif maintenance_matcher.search(job_name):
            job_type = "SPP"
            sla_name = "Maintenance"
        elif vmware_matcher.search(job_name):
            job_type = "VMware"
            sla_name = "_".join(job_name.split("_")[1:])
        elif hyper_v_matcher.search(job_name):
            job_type = "Hyper-V"
            sla_name = "_".join(job_name.split("_")[1:])
        elif oracle_matcher.search(job_name):
            job_type = "Oracle"
            sla_name = "_".join(job_name.split("_")[1:])
        elif sql_matcher.search(job_name):
            job_type = "SQL"
            sla_name = "_".join(job_name.split("_")[1:])
        elif db2_matcher.search(job_name):
            job_type = "DB2"
            sla_name = "_".join(job_name.split("_")[1:])
        else:
            job_type = "SPP"
            sla_name = job_name
        return sla_name, job_type

    def get_joboverview_data(self):
        universal_dict = {}
        for line in open(self.log_path, "r"):
            line = re.sub("\s+", " ", line)
            res = job_pattern.search(line)
            if (res):
                job_id = res.group(0)[0:13]
                job_name = " ".join(res.group(0).split(" ")[6:-9])
                universal_dict[job_id] = {}
                universal_dict[job_id]["JobID"] = job_id
                universal_dict[job_id]["StartDateTime"] = get_timestamp_from_id(job_id)
                universal_dict[job_id]["SLA"], universal_dict[job_id]["JobType"] = job_classifier(job_name)
                universal_dict[job_id]["Targets"] = ""
                continue
            vm = vm_job_pattern.search(line)
            if vm:
                key = vm.group(0).split(' ')[0]
                val = vm.group(0).split(' ')[2]
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                universal_dict[key]["Targets"] = universal_dict[key]["Targets"] + f":{val}" if universal_dict[key][
                    "Targets"] else f"{val}"
                continue
            job_apps = job_app_pattern.search(line)
            if job_apps:
                key = job_apps.group(0).split(' ')[0]
                val = job_apps.group(0).split(' ')[4][0:-3]
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                universal_dict[key]["Targets"] = universal_dict[key]["Targets"] + f":{val}" if universal_dict[key][
                    "Targets"] else f"{val}"
                continue
            completion = completion_pattern.search(line)
            if completion:
                completion_type = completion_type_matcher.search(line)
                key = job_id_pattern.search(line).group(0)
                if universal_dict.get(key) is None:
                    universal_dict[key] = {}
                    universal_dict[key]["JobId"] = key
                if completion_type:
                    universal_dict[key]["Result"] = completion_type.group(0)
                else:
                    universal_dict[key]["Result"] = "UNKNOWN"

        ret = [universal_dict[i] for i in universal_dict]
        return ret