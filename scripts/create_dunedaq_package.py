#!/usr/bin/env python3

import os
import pathlib
import re
import shutil
import string
import subprocess
import sys
import tempfile

if "DBT_ROOT" not in os.environ:
    print("ERROR: daq-buildtools environment needs to be set up for this script to work. Exiting...")
    sys.exit(1)
else:
    sys.path.append(f'{os.environ["DBT_ROOT"]}/scripts')

from dbt_setup_tools import error

if len(sys.argv) != 2:
    error(f"\n\nUsage:\n\n{os.path.basename(__file__)} <name of package>\n\n")

package=sys.argv[1]
print(f"Package is {package}")

#package_repo = f"https://github.com/DUNE-DAQ/{package}/"
package_repo = f"https://github.com/jcfreeman2/{package}/"

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

        # This code is very cautious to be certain to rm -rf the directory it expects 
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

with open("CMakeLists.txt", "w") as cmakelists:
    cmakelists.write(f"""
cmake_minimum_required(VERSION 3.12)
project({package} VERSION 0.0.0)

find_package(daq-cmake REQUIRED)

daq_setup_environment()
""")

    contains_modules = get_yes_or_no("Will your package contain DAQModule(s) [yY/nN]? ")
    if contains_modules:

        for filename in ["RenameMe.hpp", "RenameMe.cpp"]:
            assert os.path.exists(f"{templatedir}/{filename}")

        # Will likely replace this with a list which gets augmented as various yes/no questions get asked, before being formatted into CMakeLists.txt at the end

        cmakelists.write("""
find_package(appfwk REQUIRED)

""")

        os.mkdir(f"{repodir}/plugins")

        modules = input("""
If you know the name(s) of your DAQModule(s), please type them here on a single line, separated by spaces, no quotes.
If you hit <Enter> without typing any names this will create a DAQModule called RenameMe which you should edit later:
""")
        modules = modules.split()
        
        if len(modules) == 0:
            for filename in ["RenameMe.hpp", "RenameMe.cpp"]:
                shutil.copyfile(f"{templatedir}/{filename}", f"{repodir}/plugins/{filename}")

        for module in modules:
            if not re.search(r"^[A-Z][^_]+", module):
                cleanup(repodir)
                error(f"""
Suggested module name \"{module}\" needs to be in PascalCase. 
Please see https://dune-daq-sw.readthedocs.io/en/latest/packages/styleguide/ for more.
""")

            for filename in ["RenameMe.hpp", "RenameMe.cpp"]:

                newfilename = filename.replace("RenameMe", module)
                shutil.copyfile(f"{templatedir}/{filename}", f"{repodir}/plugins/{newfilename}")

                with open(f"{templatedir}/{filename}", "r") as inf:
                    sourcecode = inf.read()
                    
                sourcecode = sourcecode.replace("RenameMe", module)

                # Handle the header guards
                sourcecode = sourcecode.replace("PACKAGE", package.upper())
                sourcecode = sourcecode.replace("RENAMEME", module.upper())

                # Handle namespace
                sourcecode = sourcecode.replace("package", package.lower())

                with open(f"{repodir}/plugins/{newfilename}", "w") as outf:
                    outf.write(sourcecode)
                 
    cmakelists.write("""

######################################################################

daq_install()
"""
)

if False:  # While developing the script, don't delete the repo at the end
    cleanup(repodir)


    
