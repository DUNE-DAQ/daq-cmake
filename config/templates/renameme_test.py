import pytest

import integrationtest.data_file_checks as data_file_checks
import integrationtest.log_file_checks as log_file_checks
import integrationtest.data_classes as data_classes

pytest_plugins = "integrationtest.integrationtest_drunc" 

# Values which we'll compare the results to in order to determine success or failure
expected_number_of_data_files = 1


ignored_logfile_problems = {
    "-controller": [
        "Worker with pid \\d+ was terminated due to signal",
        "Connection '.*' not found on the application registry",
    ],
    "connectivity-service": [
        "errorlog: -",
    ],
}


# Load pre-configured objects from this OKS database file
object_databases = ["config/daqsystemtest/integrationtest-objects.data.xml"]

# Create a meta-configuration. This is used by integrationtest_drunc to configure daqconf
config_obj  = data_classes.drunc_config()

# Declare the set of configurations to be tested, as a dictionary of name: drunc_config() pairs or as a list of drunc_config() objects
confgen_arguments = [config_obj]

# The commands for run control to run, as a list (this is read by integrationtest_drunc).
nanorc_command_list="boot conf start --run-number 1 enable-triggers wait 10 disable-triggers wait 2 drain-dataflow wait 2 stop-trigger-sources stop scrap terminate".split()

# The tests themselves

def test_nanorc_success(run_nanorc):
    # Check that run control returned zero (i.e., completed without an error value)
    assert run_nanorc.completed_process.returncode==0

def test_log_files(run_nanorc):

    assert log_file_checks.logs_are_error_free(run_nanorc.log_files,
                                               show_all_problems=True,
                                               print_logfilename_for_problems=True,
                                               excluded_substring_map=ignored_logfile_problems
                                               )
                                               

def test_data_file(run_nanorc):

    assert len(run_nanorc.data_files)==expected_number_of_data_files

    data_file=data_file_checks.DataFile(run_nanorc.data_files[0])
    assert data_file_checks.sanity_check(data_file)
