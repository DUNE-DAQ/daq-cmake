#!/usr/bin/env python3

import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys

if "DBT_ROOT" in os.environ:
    sys.path.append(f'{os.environ["DBT_ROOT"]}/scripts')
else:
    print("""
ERROR: daq-buildtools environment needs to be set up for this script to work. 
Exiting...""")
    sys.exit(1)

from dbt_setup_tools import error, get_time

usage_blurb=f"""
Usage
-----

This script generates much of the standard CMake/C++ code of a new
DUNE DAQ package. In general, the more you know about your package in
advance (e.g. whether it should contain DAQModules and what their
names should be, etc.) the more work this script can do for you.

Simplest usage:
{os.path.basename (__file__)} <name of new package>\n\n")

...where the directory out of which you run this script must be empty
with the possible exceptions of a README.md and/or a .git/ version 
control subdirectory. 

Arguments and options:

--main-library: package will contain a main, package-wide library which other 
                packages can link in

--python-bindings: whether there will be Python bindings to the main library. 
                   Requires the --main-library option as well.

--daq-module: for each "--daq-module <module name>" provided at the command
              line, the framework for a DAQModule will be auto-generated

--user-app: same as --daq-module, but for user applications

--test-app: same as --daq-module, but for integration test applications

For details on how to write a DUNE DAQ package, please look at the official 
daq-cmake documentation at 
https://dune-daq-sw.readthedocs.io/en/latest/packages/daq-cmake/

"""

parser = argparse.ArgumentParser(usage=usage_blurb)
parser.add_argument("--main-library", action="store_true", dest="contains_main_library", help=argparse.SUPPRESS)
parser.add_argument("--python-bindings", action="store_true", dest="contains_python_bindings", help=argparse.SUPPRESS)
parser.add_argument("--daq-module", action="append", dest="daq_modules", help=argparse.SUPPRESS)
parser.add_argument("--user-app", action="append", dest="user_apps", help=argparse.SUPPRESS)
parser.add_argument("--test-app", action="append", dest="test_apps", help=argparse.SUPPRESS)
parser.add_argument("package", nargs="?", help=argparse.SUPPRESS)

args = parser.parse_args()

if args.package is not None: 

    if re.search(r"\.", args.package):
        parent_directory = os.getcwd().split("/")[-1]
        error(f"""
You passed \".\" as the name of the package. What I *think* you want to do
is cd up one directory and pass the name of this subdirectory
"{parent_directory}"
as the argument.
""")

    if not re.search(r"^[a-z][_a-z0-9]+$", args.package):
        error(f"""
The asked-for package name of \"{args.package}\" doesn't satisfy the requirement 
that the package begin with a lowercase letter and consist only of lowercase 
letters, underscores and numbers
""")

    PACKAGE = args.package
else:
    print(usage_blurb)
    sys.exit(1)

if args.contains_python_bindings and not args.contains_main_library:
    error("""
To use the --python-bindings option you also need the --main-library option 
as you'll want python bindings to your package's main library.
""")

THIS_SCRIPTS_DIRECTORY=pathlib.Path(__file__).parent.resolve()
TEMPLATEDIR = f"{THIS_SCRIPTS_DIRECTORY}/templates"

def wipe_package_directory():
    os.chdir(PACKAGEDIR)
    if os.path.exists(f"{PACKAGEDIR}/docs/README.md"):
        shutil.move(f"{PACKAGEDIR}/docs/README.md", f"{PACKAGEDIR}/README.md")

    if os.path.exists("CMakeLists.txt"):
        os.unlink("CMakeLists.txt")

    dirs_to_delete = ["include", "src", "schema", "unittest", "apps", "cmake", "plugins", "docs", "python", "test", "pybindsrc"]

    for dirname in dirs_to_delete:
        if os.path.exists(f"{PACKAGEDIR}/{dirname}"):
            shutil.rmtree(f"{PACKAGEDIR}/{dirname}")

def make_package_subdir(dirname):
    os.makedirs(dirname, exist_ok=True)
    
    # disable .gitkeep creation until it's decided what role git will play in this script
    if False:  
        if not os.path.exists(f"{dirname}/.gitkeep"):
            open(f"{dirname}/.gitkeep", "w")

PACKAGEDIR=f"{os.getcwd()}/{PACKAGE}"
if not os.path.exists(f"{os.getcwd()}/{PACKAGE}"):
    os.makedirs(PACKAGEDIR)
else:
    files_in_dir = os.listdir(PACKAGEDIR)

    for file_in_dir in files_in_dir:
        if file_in_dir != ".git" and file_in_dir != "README.md" and file_in_dir != "docs":
            error(f"""

It looks like this directory isn't empty. This script can only be run in 
directories which are empty with the possible exceptions of a .git/ subdirectory
and/or a README.md documentation file. 

    """)

os.chdir(PACKAGEDIR)

find_package_calls = []
daq_codegen_calls = []
daq_add_library_calls = []
daq_add_python_bindings_calls = []
daq_add_plugin_calls = []
daq_add_application_calls = []
daq_add_unit_test_calls = []

print("")

if args.contains_main_library:
    make_package_subdir(f"{PACKAGEDIR}/src")
    make_package_subdir(f"{PACKAGEDIR}/include/{PACKAGE}")
    daq_add_library_calls.append("daq_add_library( LINK_LIBRARIES ) # Any source files and/or dependent libraries to link in not yet determined")

if args.contains_python_bindings:
    make_package_subdir(f"{PACKAGEDIR}/pybindsrc")
    daq_add_python_bindings_calls.append("\ndaq_add_python_bindings(*.cpp LINK_LIBRARIES ${PROJECT_NAME} ) # Any additional libraries to link in beyond the main library not yet determined\n")

    for src_filename in ["module.cpp", "renameme.cpp"]:
        with open(f"{TEMPLATEDIR}/{src_filename}", "r") as inf:
            sourcecode = inf.read()

        sourcecode = sourcecode.replace("package", PACKAGE.lower())
        
        with open(f"{PACKAGEDIR}/pybindsrc/{src_filename}", "w") as outf:
            outf.write(sourcecode)

if args.daq_modules:

    for pkg in ["appfwk", "opmonlib"]:
        find_package_calls.append(f"find_package({pkg} REQUIRED)")

    make_package_subdir(f"{PACKAGEDIR}/src")
    make_package_subdir(f"{PACKAGEDIR}/plugins")
    make_package_subdir(f"{PACKAGEDIR}/schema/{PACKAGE}")

    for module in args.daq_modules:
        if not re.search(r"^[A-Z][^_]+", module):
            wipe_package_directory()
            error(f"""
Requested module name \"{module}\" needs to be in PascalCase. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ 
for more on naming conventions. Exiting...
""")

        daq_add_plugin_calls.append(f"daq_add_plugin({module} duneDAQModule LINK_LIBRARIES appfwk::appfwk) # Replace appfwk library with a more specific library when appropriate")
        daq_codegen_calls.append(f"daq_codegen({module.lower()}.jsonnet TEMPLATES Structs.hpp.j2 Nljs.hpp.j2)") 
        daq_codegen_calls.append(f"daq_codegen({module.lower()}info.jsonnet DEP_PKGS opmonlib TEMPLATES opmonlib/InfoStructs.hpp.j2 opmonlib/InfoNljs.hpp.j2)")

        for src_filename in ["RenameMe.hpp", "RenameMe.cpp", "renameme.jsonnet", "renamemeinfo.jsonnet"]:

            if pathlib.Path(src_filename).suffix in [".hpp", ".cpp"]:
                DEST_FILENAME = src_filename.replace("RenameMe", module)
                DEST_FILENAME = f"{PACKAGEDIR}/plugins/{DEST_FILENAME}"
            elif pathlib.Path(src_filename).suffix in [".jsonnet"]:
                DEST_FILENAME = src_filename.replace("renameme", module.lower())
                DEST_FILENAME = f"{PACKAGEDIR}/schema/{PACKAGE}/{DEST_FILENAME}"
            else:
                assert False, "SCRIPT ERROR: unhandled filename"

            shutil.copyfile(f"{TEMPLATEDIR}/{src_filename}", DEST_FILENAME)

            with open(f"{TEMPLATEDIR}/{src_filename}", "r") as inf:
                sourcecode = inf.read()
                    
            sourcecode = sourcecode.replace("RenameMe", module)

            # Handle the header guards
            sourcecode = sourcecode.replace("PACKAGE", PACKAGE.upper())
            sourcecode = sourcecode.replace("RENAMEME", module.upper())

            # Handle namespace
            sourcecode = sourcecode.replace("package", PACKAGE.lower())

            # And schema files
            sourcecode = sourcecode.replace("renameme", module.lower())

            with open(DEST_FILENAME, "w") as outf:
                outf.write(sourcecode)

if args.user_apps:
    make_package_subdir(f"{PACKAGEDIR}/apps")

    for user_app in args.user_apps:
        if re.search(r"[A-Z]", user_app):
            wipe_package_directory()
            error(f"""
Requested user application name \"{user_app}\" needs to be in snake_case. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ 
for more on naming conventions. Exiting...
""")
        DEST_FILENAME = f"{PACKAGEDIR}/apps/{user_app}.cxx"
        with open(f"{TEMPLATEDIR}/renameme.cxx") as inf:
            sourcecode = inf.read()

        sourcecode = sourcecode.replace("renameme", user_app)

        with open(DEST_FILENAME, "w") as outf:
            outf.write(sourcecode)

        daq_add_application_calls.append(f"daq_add_application({user_app} {user_app}.cxx LINK_LIBRARIES ) # Any libraries to link in not yet determined")
    

if args.test_apps:
    make_package_subdir(f"{PACKAGEDIR}/test/apps")

    for test_app in args.test_apps:
        if re.search(r"[A-Z]", test_app):
            wipe_package_directory()
            error(f"""
Requested test application name \"{test_app}\" needs to be in snake_case. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ 
for more on naming conventions. Exiting...
""")
        DEST_FILENAME = f"{PACKAGEDIR}/test/apps/{test_app}.cxx"
        with open(f"{TEMPLATEDIR}/renameme.cxx") as inf:
            sourcecode = inf.read()
    
        sourcecode = sourcecode.replace("renameme", test_app)

        with open(DEST_FILENAME, "w") as outf:
            outf.write(sourcecode)

        daq_add_application_calls.append(f"daq_add_application({test_app} {test_app}.cxx TEST LINK_LIBRARIES ) # Any libraries to link in not yet determined")

make_package_subdir(f"{PACKAGEDIR}/unittest")
shutil.copyfile(f"{TEMPLATEDIR}/Placeholder_test.cxx", f"{PACKAGEDIR}/unittest/Placeholder_test.cxx")
daq_add_unit_test_calls.append("daq_add_unit_test(Placeholder_test LINK_LIBRARIES)  # Placeholder_test should be replaced with real unit tests")
find_package_calls.append("find_package(Boost COMPONENTS unit_test_framework REQUIRED)")

make_package_subdir(f"{PACKAGEDIR}/docs")
if not os.path.exists(f"{PACKAGEDIR}/README.md") and not os.path.exists(f"{PACKAGEDIR}/docs/README.md"):
    with open(f"{PACKAGEDIR}/docs/README.md", "w") as outf:
        GENERATION_TIME = get_time("as_date")
        outf.write(f"# No Official User Documentation Has Been Written Yet ({GENERATION_TIME})\n")
elif os.path.exists(f"{PACKAGEDIR}/README.md"):  # i.e., README.md isn't (yet) in the docs/ subdirectory
    os.chdir(PACKAGEDIR)
    
    #if not os.path.exists(".git"):
    if True: # until a decision's been made, for the time being assume the package directory isn't a git repo
        shutil.move("README.md", "docs/README.md")
    else:
        proc = subprocess.Popen(f"git mv README.md docs/README.md", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        proc.communicate()
        RETVAL = proc.returncode
        if RETVAL != 0:
            wipe_package_directory()
            error(f"There was a problem attempting a git mv of README.md to docs/README.md in {PACKAGEDIR}; exiting...")

make_package_subdir(f"{PACKAGEDIR}/cmake")
config_template_html=f"https://raw.githubusercontent.com/DUNE-DAQ/daq-cmake/dunedaq-v2.6.0/configs/Config.cmake.in"

proc = subprocess.Popen(f"curl -o {PACKAGEDIR}/cmake/{PACKAGE}Config.cmake.in -O {config_template_html}", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
proc.communicate()
RETVAL = proc.returncode

if RETVAL != 0:
    wipe_package_directory()
    error(f"There was a problem trying to pull down {config_template_html} from the web; exiting...")

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
    GENERATION_TIME = get_time("as_date")
    cmakelists.write(f"""

# This is a skeleton CMakeLists.txt file, auto-generated on
# {GENERATION_TIME}.  The developer(s) of this package should delete
# this comment as well as adding dependent targets, packages,
# etc. specific to the package. For details on how to write a package,
# please see
# https://dune-daq-sw.readthedocs.io/en/latest/packages/daq-cmake/

cmake_minimum_required(VERSION 3.12)
project({PACKAGE} VERSION 0.0.0)

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

os.chdir(PACKAGEDIR)

if False:  # disable code until its decided what role git will play in this script
    # Only need .gitkeep if the directory is otherwise empty
    for filename, ignored, ignored in os.walk(PACKAGEDIR):
        if os.path.isdir(filename) and os.listdir(filename) != [".gitkeep"]:
            if os.path.exists(f"{filename}/.gitkeep"):
                os.unlink(f"{filename}/.gitkeep")

    proc = subprocess.Popen("git add -A", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.communicate()
    RETVAL = proc.returncode

    if RETVAL != 0:
        wipe_package_directory()
        error(f"""
    There was a problem trying to "git add" the newly-created files and directories in {PACKAGEDIR}; exiting...
    """)

    COMMAND=" ".join(sys.argv)
    proc = subprocess.Popen(f"git commit -m \"This {os.path.basename (__file__)}-generated boilerplate for the {PACKAGE} package was created by this command: {COMMAND}\"", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    proc.communicate()
    RETVAL = proc.returncode

    if RETVAL != 0:
        wipe_package_directory()
        error(f"""
    There was a problem trying to auto-generate the commit off the newly auto-generated files in {PACKAGEDIR}. Exiting...
    """)

print(f"""
This script has created the boilerplate for your new package in
{PACKAGEDIR}. 
Please review it before you start making your own edits. 

For details on how to write a DUNE DAQ package, please look at the 
official daq-cmake documentation at 
https://dune-daq-sw.readthedocs.io/en/latest/packages/daq-cmake/
""")
