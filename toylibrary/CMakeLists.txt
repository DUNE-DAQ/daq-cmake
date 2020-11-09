cmake_minimum_required(VERSION 3.12)
project(toylibrary VERSION 1.1.0)

find_package(daq-buildtools REQUIRED)

daq_setup_environment()

# ers: for exceptions and normal output
# TRACE: for low-level debugging statements
# Boost unit_test_framework: for the unit tests
# Boost program_options: to allow command line options with descriptions/default values

find_package(ers REQUIRED)     
find_package(TRACE REQUIRED)
find_package(Boost COMPONENTS unit_test_framework program_options REQUIRED)

##############################################################################

# Note that when the ers library is linked in, it uses a "::" because
# it's in an external package, not a local CMake target. The semantics
# are <namespace>::<shared library / executable>
daq_add_library(IntPrinter.cpp LINK_LIBRARIES ers::ers)

##############################################################################
daq_add_application( toylibrary_test_program toylibrary_test_program.cxx TEST LINK_LIBRARIES ${Boost_PROGRAM_OPTIONS_LIBRARY} toylibrary )

##############################################################################
daq_add_unit_test(ValueWrapper_test)

##############################################################################

# Could add "toylibrary_test_program" to the argument list here, but
# presumably end users wouldn't care about an integration test program
# and just want the shared object library installed

daq_install()



