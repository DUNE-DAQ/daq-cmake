#!/usr/bin/env python3

import os
import pathlib
import re
import shutil
import string
import subprocess
import sys
import tempfile

if "DBT_ROOT" in os.environ:
    sys.path.append(f'{os.environ["DBT_ROOT"]}/scripts')
else:
    print("ERROR: daq-buildtools environment needs to be set up for this script to work. Exiting...")
    sys.exit(1)

from dbt_setup_tools import error, get_time

if len(sys.argv) != 2:
    error(f"\n\nUsage:\n\n{os.path.basename(__file__)} <name of package>\n\n")

package=sys.argv[1]

#package_repo = f"https://github.com/DUNE-DAQ/{package}/"
package_repo = f"https://github.com/jcfreeman2/{package}/"  # jcfreeman2 is for testing purposes since there's no guaranteed-empty-repo in DUNE-DAQ

this_scripts_directory=pathlib.Path(__file__).parent.resolve()
templatedir = f"{this_scripts_directory}/templates"

tmpdir=tempfile.mkdtemp()
origdir=os.getcwd()
os.chdir(tmpdir)

repodir = f"{tmpdir}/{package}"
proc = subprocess.Popen(f"git clone {package_repo}" , shell=True, stdout=subprocess.PIPE)
proc.communicate()
retval = proc.returncode

if retval == 0:
    print(f"Should find package at {repodir}")
elif retval == 128:
    error(f"git was unable to find a {package_repo} repository")
else:
    error(f"Totally unexpected error (return value {retval}) occurred when running \"git clone {package_repo}\"")

def get_yes_or_no(prompt):
    answer = input(prompt)
    if re.search(r"^\s*[yY]\s*$", answer):
        return True
    elif re.search(r"^\s*[nN]\s*$", answer):
        return False

    raise ValueError

def cleanup(repodir):
    if os.path.exists(repodir):

        # This code is very cautious so that it rm -rf's the directory it expects 
        if re.search(r"^/tmp/tmp\w+/", repodir):
            shutil.rmtree(repodir)
        else:
            assert False, f"DEVELOPER ERROR: This script does not trust that the temporary github repo \"{repodir}\" is something it should delete since it doesn't look like a directory in a tempfile.mkdtemp()-generated directory"
    else:
        assert False, f"DEVELOPER ERROR: This script is unable to locate the expected repo directory {repodir}"

os.chdir(repodir)

if os.listdir(repodir) != [".git"] and os.listdir(repodir) != [".git", "README.md"]:
    error(f"""

Just ran \"git clone {package_repo}\", and it looks like this repo isn't empty. 
This script can only be run on repositories which haven't yet been worked on.
""")

find_package_calls = []
daq_codegen_calls = []
daq_add_library_calls = []
daq_add_python_bindings_calls = []
daq_add_plugin_calls = []
daq_add_application_calls = []
daq_add_unit_test_calls = []

contains_package_library=False
contains_python_bindings = False
contains_modules=False
contains_user_apps=False
contains_test_apps=False

print("")

contains_package_library = get_yes_or_no("Will your package contain a main, package-wide library [yY/nN]? ")    
if contains_package_library:
    os.makedirs(f"{repodir}/src", exist_ok=True)
    os.makedirs(f"{repodir}/include", exist_ok=True)
    daq_add_library_calls.append("daq_add_library( LIBRARIES ) # Any source files and/or dependent libraries to link in not yet determined")

if contains_package_library:
    contains_python_bindings = get_yes_or_no("Will your package contain python bindings to its classes, etc. [yY/nN]? ")
    if contains_python_bindings:
        os.makedirs(f"{repodir}/pybindsrc", exist_ok=True)
        daq_add_python_bindings_calls.append("\ndaq_add_python_bindings(*.cpp LINK_LIBRARIES ${PROJECT_NAME} ) # Any additional libraries to link in beyond the main library not yet determined\n")

        for src_filename in ["module.cpp", "renameme.cpp"]:
            shutil.copyfile(f"{templatedir}/{src_filename}", f"{repodir}/pybindsrc/{src_filename}")

contains_modules = get_yes_or_no("Will your package contain DAQModule(s) [yY/nN]? ")
if contains_modules:

    for filename in ["RenameMe.hpp", "RenameMe.cpp"]:
        assert os.path.exists(f"{templatedir}/{filename}")

    for pkg in ["appfwk", "opmonlib"]:
        find_package_calls.append(f"find_package({pkg} REQUIRED)")

    os.makedirs(f"{repodir}/src", exist_ok=True)
    os.makedirs(f"{repodir}/plugins", exist_ok=True)
    os.makedirs(f"{repodir}/schema/{package}", exist_ok=True)

    modules = input("""
If you know the name(s) of your DAQModule(s), please type them here on a single line, separated by spaces, no quotes.
If you hit <Enter> without typing any names this will create a DAQModule called RenameMe which you should edit later:
""")
    modules = modules.split()
        
    if len(modules) == 0:
        modules = ["RenameMe"]

    for module in modules:
        if not re.search(r"^[A-Z][^_]+", module):
            cleanup(repodir)
            error(f"""
Requested module name \"{module}\" needs to be in PascalCase. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ for more on naming conventions.
Exiting...
""")

        daq_add_plugin_calls.append(f"daq_add_plugin({module} duneDAQModule LINK_LIBRARIES ) # Any libraries to link in not yet determined")
        daq_codegen_calls.append(f"daq_codegen({module.lower()}.jsonnet TEMPLATES Structs.hpp.j2 Nljs.hpp.j2)") 
        daq_codegen_calls.append(f"daq_codegen({module.lower()}info.jsonnet DEP_PKGS opmonlib TEMPLATES opmonlib/InfoStructs.hpp.j2 opmonlib/InfoNljs.hpp.j2)")

        for src_filename in ["RenameMe.hpp", "RenameMe.cpp", "renameme.jsonnet", "renamemeinfo.jsonnet"]:

            if pathlib.Path(src_filename).suffix in [".hpp", ".cpp"]:
                dest_filename = src_filename.replace("RenameMe", module)
                dest_filename = f"{repodir}/plugins/{dest_filename}"
            elif pathlib.Path(src_filename).suffix in [".jsonnet"]:
                dest_filename = src_filename.replace("renameme", module.lower())
                dest_filename = f"{repodir}/schema/{package}/{dest_filename}"
            else:
                assert False, "DEVELOPER ERROR: unhandled filename"

            shutil.copyfile(f"{templatedir}/{src_filename}", dest_filename)

            with open(f"{templatedir}/{src_filename}", "r") as inf:
                sourcecode = inf.read()
                    
            sourcecode = sourcecode.replace("RenameMe", module)

            # Handle the header guards
            sourcecode = sourcecode.replace("PACKAGE", package.upper())
            sourcecode = sourcecode.replace("RENAMEME", module.upper())

            # Handle namespace
            sourcecode = sourcecode.replace("package", package.lower())

            # And schema files
            sourcecode = sourcecode.replace("renameme", module.lower())

            with open(dest_filename, "w") as outf:
                outf.write(sourcecode)

contains_user_apps = get_yes_or_no("Will your package contain any apps for end users [yY/nN]? ")
if contains_user_apps:
    os.makedirs(f"{repodir}/apps", exist_ok=True)

    user_apps = input("""
If you know the name(s) of your user application(s), please type them here on a single line, separated by spaces, no quotes.
If you hit <Enter> without typing any names this will create an application called renameme which you should edit later:
""")
    user_apps = user_apps.split()

    if len(user_apps) == 0:
        user_apps = ["renameme"]

    for user_app in user_apps:
        if re.search(r"[A-Z]", user_app):
            cleanup(repodir)
            error(f"""
            Requested user application name \"{user_app}\" needs to be in snake_case. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ for more on naming conventions.
Exiting...
""")
        dest_filename = f"{repodir}/apps/{user_app}.cxx"
        with open(f"{templatedir}/renameme.cxx") as inf:
            sourcecode = inf.read()

        sourcecode = sourcecode.replace("renameme", user_app)

        with open(dest_filename, "w") as outf:
            outf.write(sourcecode)

        daq_add_application_calls.append(f"daq_add_application({user_app} {user_app}.cxx LINK_LIBRARIES ) # Any libraries to link in not yet determined")
    
contains_test_apps = get_yes_or_no("Will your package contains any apps meant for integration testing the package [yY/nN]? ")
if contains_test_apps:
    os.makedirs(f"{repodir}/test/apps", exist_ok=True)

    test_apps = input("""
If you know the name(s) of your integration test application(s), please type them here on a single line, separated by spaces, no quotes.
If you hit <Enter> without typing any names this will create an application called renameme which you should edit later:
""")
    test_apps = test_apps.split()

    if len(test_apps) == 0:
        test_apps = ["renameme"]

    for test_app in test_apps:
        if re.search(r"[A-Z]", test_app):
            cleanup(repodir)
            error(f"""
            Requested test application name \"{test_app}\" needs to be in snake_case. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ for more on naming conventions.
Exiting...
""")
        dest_filename = f"{repodir}/test/apps/{test_app}.cxx"
        with open(f"{templatedir}/renameme.cxx") as inf:
            sourcecode = inf.read()
    
        sourcecode = sourcecode.replace("renameme", test_app)

        with open(dest_filename, "w") as outf:
            outf.write(sourcecode)

        daq_add_application_calls.append(f"daq_add_application({test_app} {test_app}.cxx TEST LINK_LIBRARIES ) # Any libraries to link in not yet determined")

os.makedirs(f"{repodir}/unittest", exist_ok=True)
shutil.copyfile(f"{templatedir}/Placeholder_test.cxx", f"{repodir}/unittest/Placeholder_test.cxx")
daq_add_unit_test_calls.append("daq_add_unit_test(Placeholder_test LINK_LIBRARIES)  # Any libraries to link in not yet determined")
find_package_calls.append("find_package(Boost COMPONENTS unit_test_framework REQUIRED)")

os.makedirs(f"{repodir}/docs", exist_ok=True)
if not os.path.exists(f"{repodir}/README.md"):
    with open(f"{repodir}/docs/README.md", "w") as outf:
        generation_time = get_time("as_date")
        outf.write(f"# No Official User Documentation Has Been Written Yet ({generation_time})\n")
else:
    print("A pre-existing README.md file has been found in the base of this repo. Will move this into a docs/ subdirectory")
    shutil.move(f"{repodir}/README.md", f"{repodir}/docs/README.md")

def print_cmakelists_section(list_of_calls, section_of_webpage = None):
    for i, line in enumerate(list_of_calls):
        if i == 0 and section_of_webpage is not None:
            cmakelists.write(f"\n# See https://dune-daq-sw.readthedocs.io/en/latest/packages/daq-cmake/#{section_of_webpage}\n") 
        cmakelists.write("\n" + line)

    if len(list_of_calls) > 0:
        cmakelists.write("""

##############################################################################

""")

with open("CMakeLists.txt", "w") as cmakelists:
    generation_time = get_time("as_date")
    cmakelists.write(f"""

# This is a skeleton CMakeLists.txt file, auto-generated on {generation_time}. 
# The developer(s) of this package should delete this comment as well
# as adding dependent targets, packages, etc.  which the
# auto-generator can't know about. For details on how to write a
# package, please see
# https://dune-daq-sw.readthedocs.io/en/latest/packages/daq-cmake/

cmake_minimum_required(VERSION 3.12)
project({package} VERSION 0.0.0)

find_package(daq-cmake REQUIRED)

daq_setup_environment()

""")

    print_cmakelists_section(find_package_calls)
    print_cmakelists_section(daq_codegen_calls, "daq_codegen")
    print_cmakelists_section(daq_add_library_calls, "daq_add_library")
    print_cmakelists_section(daq_add_python_bindings_calls, "daq_add_python_bindings")
    print_cmakelists_section(daq_add_plugin_calls, "daq_add_plugin")
    print_cmakelists_section(daq_add_application_calls, "daq_add_application")
    print_cmakelists_section(daq_add_unit_test_calls, "daq_add_unit_test")

    cmakelists.write("daq_install()\n\n")

if False:  # While developing the script, don't delete the local repo at the end
    cleanup(repodir)
