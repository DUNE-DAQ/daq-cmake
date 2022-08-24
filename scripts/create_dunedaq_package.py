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
package_repo = f"https://github.com/jcfreeman2/{package}/"  # jcfreeman2 is for testing purposes

this_scripts_directory=pathlib.Path(__file__).parent.resolve()
templatedir = f"{this_scripts_directory}/templates"

tmpdir=tempfile.mkdtemp()
origdir=os.getcwd()
os.chdir(tmpdir)

proc = subprocess.Popen(f"git clone {package_repo}" , shell=True, stdout=subprocess.PIPE)
out = proc.communicate()
retval = proc.returncode

repodir = f"{tmpdir}/{package}"

if retval == 0:
    print(f"Should find package at {repodir}")
elif retval == 128:
    error(f"git was unable to find a {package_repo} repository")
else:
    error(f"Totally unexpected error occurred when running \"git clone {package_repo}\"")

def get_yes_or_no(prompt):
    answer = input(prompt)
    if re.search(r"[yY]", answer):
        return True
    elif re.search(r"[nN]", answer):
        return False

    raise ValueError

def cleanup(repodir):
    if os.path.exists(repodir):

        # This code is very cautious so that it rm -rf's the directory it expects 
        if re.search(r"/tmp\w+/", repodir):
            shutil.rmtree(repodir)
        else:
            assert False, f"DEVELOPER ERROR: This script does not trust that the temporary github repo \"{repodir}\" is something it should delete since it doesn't look like a directory in a tempfile.mkdtemp()-generated directory"
    else:
        assert False, f"DEVELOPER ERROR: This script is unable to locate the expected repo directory {repodir}"

os.chdir(repodir)

if os.path.exists("CMakeLists.txt"):
    error(f"""

After running \"git clone {package_repo}\", it looks like this repo isn't empty. 
This script can only be run on repositories which haven't yet been worked on.
""")

find_package_calls = []
daq_codegen_calls = []
daq_add_plugin_calls = []

contains_modules = get_yes_or_no("Will your package contain DAQModule(s) [yY/nN]? ")
if contains_modules:

    for filename in ["RenameMe.hpp", "RenameMe.cpp"]:
        assert os.path.exists(f"{templatedir}/{filename}")

    for pkg in ["appfwk", "opmonlib"]:
        find_package_calls.append(f"find_package({pkg} REQUIRED)")

    os.makedirs(f"{repodir}/plugins")
    os.makedirs(f"{repodir}/schema/{package}")

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
Suggested module name \"{module}\" needs to be in PascalCase. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ for more.
""")

        daq_add_plugin_calls.append(f"daq_add_plugin({module} duneDAQModule LINK_LIBRARIES ) # Libraries to link in not yet determined\n")
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
                assert False, "DEVELOPER ERROR: unknown file extension"

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

    for line in find_package_calls:
        cmakelists.write("\n" + line)

    cmakelists.write("""

##############################################################################

""")
    
    for line in daq_codegen_calls:
        cmakelists.write("\n" + line)

    cmakelists.write("""

##############################################################################

""")

    for line in daq_add_plugin_calls:
        cmakelists.write("\n" + line)

    cmakelists.write("""

######################################################################

daq_install()
"""
)

if False:  # While developing the script, don't delete the repo at the end
    cleanup(repodir)
