
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

####################################################################################################

# daq_setup_environment:
# Usage:
# daq_setup_environment()
#
# This macro should be called immediately after this DAQ module is
# included in your DUNE DAQ project's CMakeLists.txt file; it ensures
# that DUNE DAQ projects all have a common build environment. It takes 
# no arguments. 

macro(daq_setup_environment)

  set(CMAKE_CXX_STANDARD 17)
  set(CMAKE_CXX_EXTENSIONS OFF)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)

  set(BUILD_SHARED_LIBS ON)

  # Include directories within CMAKE_SOURCE_DIR and CMAKE_BINARY_DIR should take precedence over everything else
  set(CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE ON)

  # All code for the project should be able to see the project's public include directory
  include_directories( ${CMAKE_CURRENT_SOURCE_DIR}/include )

  # Needed for clang-tidy (called by our linters) to work
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

  set(CMAKE_INSTALL_CMAKEDIR   ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}/cmake ) # Not defined in GNUInstallDirs

  add_compile_options( -g -pedantic -Wall -Wextra -fdiagnostics-color=always )

  enable_testing()

endmacro()


####################################################################################################
# _daq_set_target_output_dirs
# This utility function updates the target output properties and points
# them to the chosen project subdirectory in the build directory tree.
macro( _daq_set_target_output_dirs target output_dir )
  set_target_properties(${target}
    PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${output_dir}"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${output_dir}"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/${output_dir}"
  )

endmacro()

####################################################################################################
macro( _daq_define_exportname )
  set( DAQ_PROJECT_EXPORTNAME ${PROJECT_NAME}Targets )
endmacro()


####################################################################################################
# daq_add_library:
# Usage:
# daq_add_library( <file | glob expression 1> ... [LINK_LIBRARIES <lib1> ...])
#
# daq_add_library is designed to produce the main library provided by
# a project for its dependencies to link in. It will compile a group
# of files defined by a set of one or more individual filenames and/or
# glob expressions, and link against the libraries listed after
# LINK_LIBRARIES. The set of files is assumed to be in the src/
# subdirectory of the project.
#
# As an example, 
# daq_add_library(MyProj.cpp *Utils.cpp LINK_LIBRARIES ers::ers) 
# will create a library off of src/MyProj.cpp and any file in src/
# ending in "Utils.cpp", and links against the ERS (Error Reporting
# System) library

function(daq_add_library)

  cmake_parse_arguments(LIBOPTS "" "" "LINK_LIBRARIES" ${ARGN})

  set(libname ${PROJECT_NAME})

  set(LIB_PATH "src")

  set(libsrcs)
  foreach(f ${LIBOPTS_UNPARSED_ARGUMENTS})

    if(${f} MATCHES ".*\\*.*")  # An argument with an "*" in it is treated as a glob

      set(fpaths)
      file(GLOB fpaths CONFIGURE_DEPENDS ${LIB_PATH}/${f})

      if (fpaths)
        set(libsrcs ${libsrcs} ${fpaths})
      else()
        message(WARNING "When defining list of files from which to build library \"${libname}\", no files in ${CMAKE_CURRENT_SOURCE_DIR}/${LIB_PATH} match the glob \"${f}\"")
      endif()
    else()
       # may be generated file, so just add
      set(libsrcs ${libsrcs} ${LIB_PATH}/${f})
    endif()
  endforeach()

  add_library(${libname} SHARED ${libsrcs})
  target_link_libraries(${libname} PUBLIC ${LIBOPTS_LINK_LIBRARIES}) 
  target_include_directories(${libname} PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> )

  _daq_set_target_output_dirs( ${libname} ${LIB_PATH} )

  _daq_define_exportname()
  install(TARGETS ${libname} EXPORT ${DAQ_PROJECT_EXPORTNAME} )

endfunction()

####################################################################################################
# daq_add_plugin:
# Usage:
# daq_add_plugin( <plugin name> <plugin type> [TEST] [LINK_LIBRARIES <lib1> ...])
#
# daq_add_plugin will build a plugin of type <plugin type> with the
# user-defined name <plugin name>. It will expect that there's a file
# with the name <plugin name>.cpp located either in the plugins/
# subdirectory of the project (if the "TEST" option isn't used) or in
# the test/plugins/ subdirectory of the project (if it is). Note that if the
# plugin is deemed a "TEST" plugin, it's not installed as the
# assumption is that it's meant for developer testing. Like
# daq_add_library, daq_add_plugin can be provided a list of libraries
# to link against, following the LINK_LIBRARIES argument.

function(daq_add_plugin pluginname plugintype)

  cmake_parse_arguments(PLUGOPTS "TEST" "" "LINK_LIBRARIES" ${ARGN})

  set(pluginlibname "${PROJECT_NAME}_${pluginname}_${plugintype}")

  set(PLUGIN_PATH "plugins")
  if(${PLUGOPTS_TEST})
    set(PLUGIN_PATH "test/${PLUGIN_PATH}")
  endif()
  

  add_library( ${pluginlibname} MODULE ${PLUGIN_PATH}/${pluginname}.cpp )
  target_link_libraries(${pluginlibname} ${PLUGOPTS_LINK_LIBRARIES}) 

  _daq_set_target_output_dirs( ${pluginlibname} ${PLUGIN_PATH} )


  if ( ${PLUGOPTS_TEST} )
    target_include_directories(${pluginlibname} PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/test/include> )
  else()
    _daq_define_exportname()
    install(TARGETS ${pluginlibname} EXPORT ${DAQ_PROJECT_EXPORTNAME} DESTINATION ${CMAKE_INSTALL_LIBDIR})
  endif()

  endfunction()

####################################################################################################
# daq_add_application:
# Usage:
# daq_add_application(<application name> <file | glob expression> ... [TEST] [LINK_LIBRARIES <lib1> ...])
#
# This function is designed to build a standalone application in your
# project. Its first argument is simply the desired name of the
# executable, followed by a list of filenames and/or file glob
# expressions meant to build the executable. It expects the filenames
# to be either in the apps/ subdirectory of the project, or, if the
# "TEST" option is chosen, the test/apps/ subdirectory. Note that if
# the plugin is deemed a "TEST" plugin, it's not installed as the
# assumption is that it's meant for developer testing. Like
# daq_add_library, daq_add_application can be provided a list of
# libraries to link against, following the LINK_LIBRARIES token.

function(daq_add_application appname)

  cmake_parse_arguments(APPOPTS "TEST" "" "LINK_LIBRARIES" ${ARGN})

  set(APP_PATH "apps")
  if(${APPOPTS_TEST})
    set(APP_PATH "test/${APP_PATH}")
  endif()

  set(appsrcs)
  foreach(f ${APPOPTS_UNPARSED_ARGUMENTS})

    if(${f} MATCHES ".*\\*.*")   # An argument with an "*" in it is treated as a glob

      set(fpaths)
      file(GLOB fpaths CONFIGURE_DEPENDS ${APP_PATH}/${f})

      if (fpaths)
        set(appsrcs ${appsrcs} ${fpaths})
      else()
        message(WARNING "When defining list of files from which to build application \"${appname}\", no files in ${CMAKE_CURRENT_SOURCE_DIR}/${APP_PATH} match the glob \"${f}\"")
      endif()
    else()
       # may be generated file, so just add
      set(appsrcs ${appsrcs} ${APP_PATH}/${f})
    endif()
  endforeach()

  
  add_executable(${appname} ${appsrcs})
  target_link_libraries(${appname} PUBLIC ${APPOPTS_LINK_LIBRARIES}) 

  _daq_set_target_output_dirs( ${appname} ${APP_PATH} )

  if( ${APPOPTS_TEST} )
    target_include_directories(${appname} PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/test/include> )
  else()
    _daq_define_exportname()
    install(TARGETS ${appname} EXPORT ${DAQ_PROJECT_EXPORTNAME} )
  endif()

endfunction()


####################################################################################################
# daq_add_unit_test:
#
# Usage: daq_add_unit_test(<unit test name> [LINK_LIBRARIES <lib1> ...])
#
# This function, when given the extension-free name of a unit test
# sourcefile in unittest/, will handle the needed boost functionality
# to build the unit test, as well as provide other support (CTest,
# etc.). Like daq_add_library, daq_add_unit_test can be provided a
# list of libraries to link against, following the LINK_LIBRARIES
# token.
#

function(daq_add_unit_test testname)

  cmake_parse_arguments(UTEST "" "" "LINK_LIBRARIES" ${ARGN})

  set(UTEST_PATH "unittest")

  add_executable( ${testname} ${UTEST_PATH}/${testname}.cxx )
  target_link_libraries( ${testname} ${UTEST_LINK_LIBRARIES} ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY})
  target_compile_definitions(${testname} PRIVATE "BOOST_TEST_DYN_LINK=1")
  add_test(NAME ${testname} COMMAND ${testname})

  _daq_set_target_output_dirs( ${testname} ${UTEST_PATH} )

endfunction()

####################################################################################################

# daq_install:
# Usage:
# daq_install()
#
# This function should be called at the bottom of a project's
# CMakeLists.txt file in order to install the project's targets. It takes no
# arguments.

function(daq_install) 

  get_property(listoftargets DIRECTORY PROPERTY BUILDSYSTEM_TARGETS)	 	     

  if (listoftargets)
    _daq_define_exportname()
    install(EXPORT ${DAQ_PROJECT_EXPORTNAME} FILE ${DAQ_PROJECT_EXPORTNAME}.cmake NAMESPACE ${PROJECT_NAME}:: DESTINATION ${CMAKE_INSTALL_CMAKEDIR} )
  endif()

  install(DIRECTORY include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h??")
  install(DIRECTORY cmake/ DESTINATION ${CMAKE_INSTALL_CMAKEDIR} FILES_MATCHING PATTERN "*.cmake")

  set(versionfile        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake)
  set(configfiletemplate ${CMAKE_CURRENT_SOURCE_DIR}/cmake/${PROJECT_NAME}Config.cmake.in)
  set(configfile         ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake)

  if (DEFINED PROJECT_VERSION)
    write_basic_package_version_file(${versionfile} COMPATIBILITY ExactVersion)
  else()
    message(FATAL_ERROR "Error: the PROJECT_VERSION CMake variable needs to be defined in order to install. The way to do this is by adding the version to the project() call at the top of your CMakeLists.txt file, e.g. \"project(${PROJECT_NAME} VERSION 1.0.0)\"")
  endif()

  if (EXISTS ${configfiletemplate})
    configure_package_config_file(${configfiletemplate} ${configfile} INSTALL_DESTINATION ${CMAKE_INSTALL_CMAKEDIR})
  else()
     message(FATAL_ERROR "Error: unable to find needed file ${configfiletemplate} for ${PROJECT_NAME} installation")
  endif()

  install(FILES ${versionfile} ${configfile} DESTINATION ${CMAKE_INSTALL_CMAKEDIR})

endfunction()

####################################################################################################
