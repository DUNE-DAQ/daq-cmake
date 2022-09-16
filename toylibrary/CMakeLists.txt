
cmake_minimum_required(VERSION 3.12)
project(toylibrary VERSION 2.0.0)

find_package(daq-cmake REQUIRED)

daq_setup_environment()

# logging: for printing output and exception handling (see https://dune-daq-sw.readthedocs.io/en/latest/packages/logging/)
# Boost unit_test_framework: for the unit tests
# Boost program_options: to allow command line options with descriptions/default values

find_package(logging REQUIRED)
find_package(Boost COMPONENTS unit_test_framework program_options REQUIRED)

##############################################################################
# This call to daq_add_library will create a shared object library named after
# the package, i.e. "toylibrary" - referred to elsewhere here by the
# variable ${PROJECT_NAME}

# Note that when the logging library is linked in, it uses a "::" because
# it's in an external package, not a local CMake target. The semantics
# are <namespace>::<shared library>

daq_add_library(IntPrinter.cpp LINK_LIBRARIES logging::logging) 

##############################################################################

daq_add_python_bindings(*.cpp LINK_LIBRARIES ${PROJECT_NAME} ) 

##############################################################################

daq_add_application(toylibrary_test_program toylibrary_test_program.cxx TEST LINK_LIBRARIES ${Boost_PROGRAM_OPTIONS_LIBRARY} ${PROJECT_NAME}) 

##############################################################################

daq_add_unit_test(ValueWrapper_test LINK_LIBRARIES ${PROJECT_NAME})

##############################################################################

daq_install()

