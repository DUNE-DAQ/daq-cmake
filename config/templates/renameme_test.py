import pytest

import integrationtest.data_file_checks as data_file_checks
import integrationtest.log_file_checks as log_file_checks
import integrationtest.data_classes as data_classes

# Use the integrationtest_drunc plugin
pytest_plugins = "integrationtest.integrationtest_drunc" 

# Load pre-configured objects from this OKS database file
object_databases = ["config/daqsystemtest/integrationtest-objects.data.xml"]

# Create a meta-configuration. This is used by integrationtest_drunc to configure daqconf
config_obj  = data_classes.drunc_config()

# Declare the set of configurations to be tested, as a dictionary of name: drunc_config() pairs or as a list of drunc_config() objects
confgen_arguments = [config_obj]

# The commands to run in nanorc, as a list (this is read by integrationtest_drunc)
nanorc_command_list="boot conf start --run-number 1 enable-triggers wait 10 disable-triggers wait 2 drain-dataflow wait 2 stop-trigger-sources stop scrap terminate".split()

# The tests themselves

def test_nanorc_success(run_nanorc):
    # Check that nanorc completed correctly
    assert run_nanorc.completed_process.returncode==0

def test_log_files(run_nanorc):
    # Check that there are no warnings or errors in the log files
    assert log_file_checks.logs_are_error_free(run_nanorc.log_files)

def test_data_file(run_nanorc):
    # Run some tests on the output data file
    assert len(run_nanorc.data_files)==1

    data_file=data_file_checks.DataFile(run_nanorc.data_files[0])
    assert data_file_checks.sanity_check(data_file)
    assert data_file_checks.check_link_presence(data_file, n_links=1)
    assert data_file_checks.check_fragment_sizes(data_file, min_frag_size=22344, max_frag_size=22344)
