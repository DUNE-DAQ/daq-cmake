_JCF, Jan-06-2021: attempts will be made to keep the descriptions of the DUNE DAQ CMake function signatures here up-to-date. However, the canonical location for this documentation isn't here, but rather, is in the DUNE DAQ CMake module itself (https://github.com/DUNE-DAQ/daq-cmake/blob/dunedaq-v2.0.0/cmake/DAQ.cmake for the most recent tag (v2.0.0), https://github.com/DUNE-DAQ/daq-cmake/blob/develop/cmake/DAQ.cmake for the head of the develop branch). Above the body of each function is its description._


# daq-cmake

This package provides the cmake support for DUNE-DAQ packages.

## cmake daq functions

### daq_setup_environment:
Usage:
`daq_setup_environment()`

This macro should be called immediately after this DAQ module is
included in your DUNE DAQ project's CMakeLists.txt file; it ensures
that DUNE DAQ projects all have a common build environment. It takes 
no arguments. 

### daq_add_library:
Usage:
`daq_add_library( <file | glob expression 1> ... [LINK_LIBRARIES <lib1> ...])`

`daq_add_library` is designed to produce the main library provided by
a project for its dependencies to link in. It will compile a group
of files defined by a set of one or more individual filenames and/or
glob expressions, and link against the libraries listed after
LINK_LIBRARIES. The set of files is assumed to be in the src/
subdirectory of the project.

As an example, 
`daq_add_library(MyProj.cpp *Utils.cpp LINK_LIBRARIES ers::ers)` 
will create a library off of src/MyProj.cpp and any file in src/
ending in "Utils.cpp", and links against the ERS (Error Reporting
System) library

### daq_add_plugin:
Usage:  
`daq_add_plugin( <plugin name> <plugin type> [TEST] [LINK_LIBRARIES <lib1> ...])`

`daq_add_plugin` will build a plugin of type `<plugin type>` with the
user-defined name `<plugin name>`. It will expect that there's a file
with the name `<plugin name>.cpp` located either in the plugins/
subdirectory of the project (if the "TEST" option isn't used) or in
the test/plugins/ subdirectory of the project (if it is). Note that if the
plugin is deemed a "TEST" plugin, it's not installed as the
assumption is that it's meant for developer testing. Like
daq_add_library, daq_add_plugin can be provided a list of libraries
to link against, following the `LINK_LIBRARIES` argument.

### daq_add_application

Usage:  
`daq_add_application(<application name> <file | glob expression> ... [TEST] [LINK_LIBRARIES <lib1> ...])`

This function is designed to build a standalone application in your
project. Its first argument is simply the desired name of the
executable, followed by a list of filenames and/or file glob
expressions meant to build the executable. It expects the filenames
to be either in the apps/ subdirectory of the project, or, if the
"TEST" option is chosen, the test/apps/ subdirectory. Note that if
the plugin is deemed a "TEST" plugin, it's not installed as the
assumption is that it's meant for developer testing. Like
daq_add_library, daq_add_application can be provided a list of
libraries to link against, following the `LINK_LIBRARIES` token.

### daq_add_unit_test
Usage:  
`daq_add_unit_test(<unit test name> [LINK_LIBRARIES <lib1> ...])`

This function, when given the extension-free name of a unit test
sourcefile in unittest/, will handle the needed boost functionality
to build the unit test, as well as provide other support (CTest,
etc.). Like daq_add_library, daq_add_unit_test can be provided a
list of libraries to link against, following the `LINK_LIBRARIES`
token.

### daq_install
Usage:  
`daq_install()`

This function should be called at the bottom of a project's
`CMakeLists.txt` file in order to install the project's targets. It takes no
arguments.

## `toylibrary` Example

`Add description`
