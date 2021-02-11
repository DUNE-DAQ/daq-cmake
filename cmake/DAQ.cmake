
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)
include(moo)

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


  set(CMAKE_CODEGEN_BASEDIR "${CMAKE_CURRENT_BINARY_DIR}/codegen")

  set(CMAKE_INSTALL_CMAKEDIR   ${CMAKE_INSTALL_LIBDIR}/${PROJECT_NAME}/cmake ) # Not defined in GNUInstallDirs
  set(CMAKE_INSTALL_PYTHONDIR  ${CMAKE_INSTALL_LIBDIR}/python ) # Not defined in GNUInstallDirs
  set(CMAKE_INSTALL_SCHEMADIR  ${CMAKE_INSTALL_DATADIR}/schema ) # Not defined in GNUInstallDirs

  set(DAQ_PROJECT_INSTALLS_TARGETS false)

  set(COMPILER_OPTS -g -pedantic -Wall -Wextra -fdiagnostics-color=always)
  if (${DBT_DEBUG})
    set(COMPILER_OPTS ${COMPILER_OPTS} -Og)
  else()
    set(COMPILER_OPTS ${COMPILER_OPTS} -O2)
  endif()
  add_compile_options(${COMPILER_OPTS})
  unset(COMPILER_OPTS)

  enable_testing()

  set(PRE_BUILD_STAGE_DONE_TRGT ${PROJECT_NAME}_pre_build_stage_done)
  add_custom_target(${PRE_BUILD_STAGE_DONE_TRGT})

  set(directories_to_copy)
  file(GLOB directories_to_copy CONFIGURE_DEPENDS 
    "scripts" 
    "python" 
    "schema" 
    "config"
    "test/scripts" 
    "test/schema" 
  )
        
  foreach(directory_to_copy ${directories_to_copy})
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}/" "" directory_to_copy_short "${directory_to_copy}")
    string(REPLACE "/" "_" directory_as_target ${directory_to_copy_short})
    set(source "${CMAKE_CURRENT_SOURCE_DIR}/${directory_to_copy_short}")
    set(dest "${CMAKE_CURRENT_BINARY_DIR}/${directory_to_copy_short}")
    add_custom_target(copy_files_${PROJECT_NAME}_${directory_as_target} ALL COMMAND ${CMAKE_COMMAND} -E copy_directory ${source} ${dest})
    add_dependencies(${PRE_BUILD_STAGE_DONE_TRGT} copy_files_${PROJECT_NAME}_${directory_as_target})
  endforeach()


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

# Public headers for users of the library should go in the project's
# include/<project name> directory. Private headers used in the
# library's implementation should be put in the src/ directory.

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

  if (libsrcs)
    add_library(${libname} SHARED ${libsrcs})
    target_link_libraries(${libname} PUBLIC ${LIBOPTS_LINK_LIBRARIES}) 
    target_include_directories(${libname} PUBLIC 
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> 
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}> 
    )
    target_include_directories(${libname}  
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CODEGEN_BASEDIR}/src>
    )
    add_dependencies( ${libname} ${PRE_BUILD_STAGE_DONE_TRGT})
    _daq_set_target_output_dirs( ${libname} ${LIB_PATH} )
  else()
    add_library(${libname} INTERFACE)
    target_link_libraries(${libname} INTERFACE ${LIBOPTS_LINK_LIBRARIES})
    target_include_directories(${libname} INTERFACE 
      $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include> 
      $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
  endif()

  _daq_define_exportname()
  install(TARGETS ${libname} EXPORT ${DAQ_PROJECT_EXPORTNAME} )
  set(DAQ_PROJECT_INSTALLS_TARGETS true PARENT_SCOPE)

endfunction()


####################################################################################################
# daq_codegen_schema:
# Usage:
# daq_codegen_schema( <schema filename> [TEST] [TEMPLATES <template filename1> ...] [MODEL <model filename>] )
#
# daq_codegen_schema will take the provided schema file name (minus
# its path), and generate code from it using moo given the names of
# the template files provided. If the code is meant for an entity in
# the package's test/ subdirectory, "TEST" should be passed as an
# argument, and the schema file's path will be assumed to be
# "test/schema/" rather than merely "schema/". The MODEL argument is
# optional; if no model file name is explicitly provided,
# omodel.jsonnet from the moo package itself is used.

# ---------------------------------------------------------------
function(daq_codegen_schema schemafile)

  cmake_parse_arguments(CODEGEN "TEST" "MODEL;TEMPLATES_PACKAGE" "TEMPLATES" ${ARGN})
  # insert test in schemadir if a TEST schema
  set(schemadir "${PROJECT_SOURCE_DIR}")

  if (${CODEGEN_TEST}) 
    set(schemadir "${schemadir}/test")
  endif()
  set(schemadir  "${schemadir}/schema")


  # Fall back on omodel.jsonnet if no model is defined
  if (NOT DEFINED CODEGEN_MODEL)
    set(CODEGEN_MODEL omodel.jsonnet)
  endif()

  if (DEFINED CODEGEN_TEMPLATES_PACKAGE)
    if (NOT DEFINED "${CODEGEN_TEMPLATES_PACKAGE}_CONFIG")
      message(FATAL_ERROR "Error: package ${CODEGEN_TEMPLATES_PACKAGE} not loaded")
    endif()

    get_filename_component(templates_package_dir ${${CODEGEN_TEMPLATES_PACKAGE}_CONFIG} DIRECTORY)
    set(templatedir "${templates_package_dir}/schema/templates")
  else()
    set(templatedir ${schemadir})
  endif()

  if (NOT DEFINED CODEGEN_TEMPLATES)
    message(FATAL_ERROR "Error: No template defined.")
  endif()

  set(schemapath "${schemadir}/${schemafile}")

  if (NOT EXISTS ${schemapath})
    message(FATAL_ERROR "Error: auto-generation of schema-based headers from \"${schemafile}\" failed because ${schemapath} wasn't found")
  endif()

  get_filename_component(schema ${schemafile} NAME_WE)

  foreach (WHAT ${CODEGEN_TEMPLATES})
    # string(TOLOWER ${WHAT} WHAT_LC)
    string(TOLOWER ${schema} schema_LC)

    # insert test in outdir if a TEST schema
    set(outdir "${CMAKE_CODEGEN_BASEDIR}")
    if (${CODEGEN_TEST}) 
        set(outdir "${outdir}/test")
    endif()
    set(outdir "${outdir}/src/${PROJECT_NAME}/${schema_LC}")

    if (NOT EXISTS ${outdir})
      message(NOTICE "Creating ${outdir} to hold moo-generated plugin headers for ${schemafile} since it doesn't yet exist")
      file(MAKE_DIRECTORY ${outdir})
    endif()

    set(outfile ${outdir}/${WHAT}.hpp)
    string(REPLACE "${CMAKE_CURRENT_BINARY_DIR}" "" moo_target ${outfile})
    string(REGEX REPLACE "[\./-]" "_" moo_target "moo${moo_target}")
    moo_associate(MPATH ${schemadir}
                  TPATH ${templatedir}
                  GRAFT /lang:ocpp.jsonnet
                  TLAS  path=dunedaq.${PROJECT_NAME}.${schema_LC}
                        ctxpath=dunedaq       
                        os=${schemafile}
                  MODEL ${CODEGEN_MODEL}
                  TEMPL ${WHAT}.hpp.j2
                  CODEGEN ${outfile}
                  CODEDEP ${schemadir}/${schemafile}
                  TARGET ${moo_target}
                  )
    add_dependencies( ${PRE_BUILD_STAGE_DONE_TRGT} ${moo_target})

  endforeach()
endfunction()

# ---------------------------------------------------------------


####################################################################################################
# daq_add_plugin:
# Usage:
# daq_add_plugin( <plugin name> <plugin type> [TEST] [LINK_LIBRARIES <lib1> ...] [SCHEMA] )
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

# If the "SCHEMA" option is used, daq_add_plugin will automatically generate
# C++ headers describing the configuration structure of the plugin as
# well as how to translate this structure between C++ and JSON, as long as 
# a schema file <package name>-<plugin name>-schema.jsonnet is available in
# the package's ./schema subdirectory

# Your plugin will look in include/ for your project's public headers
# and src/ for its private headers. Additionally, if it's a "TEST"
# plugin, it will look in test/src/.

function(daq_add_plugin pluginname plugintype)

  cmake_parse_arguments(PLUGOPTS "TEST;SCHEMA" "" "LINK_LIBRARIES" ${ARGN})

  set(pluginlibname "${PROJECT_NAME}_${pluginname}_${plugintype}")

  set(PLUGIN_PATH "plugins")
  if(${PLUGOPTS_TEST})
    set(PLUGIN_PATH "test/${PLUGIN_PATH}")
  endif()
  
  add_library( ${pluginlibname} MODULE ${PLUGIN_PATH}/${pluginname}.cpp)

  target_link_libraries(${pluginlibname} ${PLUGOPTS_LINK_LIBRARIES}) 
  target_include_directories(${pluginlibname}
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CODEGEN_BASEDIR}/src>
  )
  add_dependencies( ${pluginlibname} ${PRE_BUILD_STAGE_DONE_TRGT})

  _daq_set_target_output_dirs( ${pluginlibname} ${PLUGIN_PATH} )

  if ( ${PLUGOPTS_TEST} ) 
    target_include_directories(${pluginlibname} 
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/test/src>
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CODEGEN_BASEDIR}/test/src>
  )
  else()
    _daq_define_exportname()
    install(TARGETS ${pluginlibname} EXPORT ${DAQ_PROJECT_EXPORTNAME} DESTINATION ${CMAKE_INSTALL_LIBDIR})
    set(DAQ_PROJECT_INSTALLS_TARGETS true PARENT_SCOPE)
  endif()

  # Figure out if we need to generate code off of a schema and
  # rebuild the plugin whenever the schema is edited

  if (${PLUGOPTS_SCHEMA})
    if (${PLUGOPTS_TEST})
      set(options TEST)
    endif()
    # daq_codegen_schema(${PROJECT_NAME}/${pluginname}.jsonnet ${PLUGOPTS_TEST} TEMPLATES Structs Nljs)

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

# Your application will look in include/ for your project's public
# headers and src/ for its private headers. Additionally, if it's a
# "TEST" plugin, it will look in test/src/.

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
  # Add src to the include path for private headers
  target_include_directories( ${appname}  
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src> 
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CODEGEN_BASEDIR}/src>
  )
  add_dependencies( ${appname} ${PRE_BUILD_STAGE_DONE_TRGT})

  _daq_set_target_output_dirs( ${appname} ${APP_PATH} )

  if( ${APPOPTS_TEST} )
    target_include_directories( ${appname} 
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/test/src> 
      PRIVATE $<BUILD_INTERFACE:${CMAKE_CODEGEN_BASEDIR}/test/src>
  )
  else()
    _daq_define_exportname()
    install(TARGETS ${appname} EXPORT ${DAQ_PROJECT_EXPORTNAME} )
    set(DAQ_PROJECT_INSTALLS_TARGETS true PARENT_SCOPE)
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


  target_include_directories( ${testname} 
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/test/src>
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/plugins>

    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/codegen/src>
    PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/codegen/test/src>
  )

  add_dependencies( ${testname} ${PRE_BUILD_STAGE_DONE_TRGT})

  add_test(NAME ${testname} COMMAND ${testname})

  _daq_set_target_output_dirs( ${testname} ${UTEST_PATH} )

endfunction()

####################################################################################################

# _daq_gather_info:
# Will take info both about the build and the source, and save it in a *.txt file 
# referred to by the variable DAQ_PROJECT_SUMMARY_FILENAME

macro(_daq_gather_info)

  set(DAQ_PROJECT_SUMMARY_FILENAME ${CMAKE_BINARY_DIR}/${PROJECT_NAME}_build_info.txt)

  set(dgi_cmds 
    "echo \"user for build:         $USER\""
    "echo \"hostname for build:     $HOSTNAME\""
    "echo \"build time:             `date`\""
    "echo \"local repo dir:         `pwd`\""
    "echo \"git branch:             `git branch | sed -r -n 's/^\\*.//p'`\""
    "echo \"git commit hash:        `git log --pretty=\"%H\" -1`\"" 
    "echo \"git commit time:        `git log --pretty=\"%ad\" -1`\""
    "echo \"git commit description: `git log --pretty=\"%s\" -1`\""
    "echo \"git commit author:      `git log --pretty=\"%an\" -1`\""
         "echo \"uncommitted changes:    `git diff HEAD --name-status | awk  '{print $2}' | sort -n | tr '\n' ' '`\""
    )

  set (dgi_fullcmd "")
  foreach( dgi_cmd ${dgi_cmds} )
    set(dgi_fullcmd "${dgi_fullcmd}${dgi_cmd}; ")
  endforeach()

  execute_process(COMMAND "bash" "-c" "${dgi_fullcmd}"  
              OUTPUT_FILE ${DAQ_PROJECT_SUMMARY_FILENAME}
              ERROR_FILE  ${DAQ_PROJECT_SUMMARY_FILENAME}
              WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
              )

endmacro()

####################################################################################################

# daq_install:
# Usage:
# daq_install()
#
# This function should be called at the bottom of a project's
# CMakeLists.txt file in order to install the project's targets. It takes no
# arguments.

function(daq_install) 

  _daq_gather_info()                  
  install(FILES ${DAQ_PROJECT_SUMMARY_FILENAME} DESTINATION ${CMAKE_INSTALL_PREFIX}/${PROJECT_NAME})

  ## AT HACK ALERT
  file(GLOB cmks CONFIGURE_DEPENDS cmake/*.cmake)
  foreach (cmk ${cmks})
    # repkace with configure_file?
    file(COPY ${cmk} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
  endforeach()
  ## AT HACK ALERT
  
  if (${DAQ_PROJECT_INSTALLS_TARGETS})
    _daq_define_exportname()
    install(EXPORT ${DAQ_PROJECT_EXPORTNAME} FILE ${DAQ_PROJECT_EXPORTNAME}.cmake NAMESPACE ${PROJECT_NAME}:: DESTINATION ${CMAKE_INSTALL_CMAKEDIR} )
  endif()

  install(DIRECTORY include/${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR} FILES_MATCHING PATTERN "*.h??")
  install(DIRECTORY cmake/ DESTINATION ${CMAKE_INSTALL_CMAKEDIR} FILES_MATCHING PATTERN "*.cmake")

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/python/  DESTINATION ${CMAKE_INSTALL_PYTHONDIR} OPTIONAL FILES_MATCHING PATTERN "__pycache__" EXCLUDE PATTERN "*.py" )
  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scripts/ DESTINATION ${CMAKE_INSTALL_BINDIR} USE_SOURCE_PERMISSIONS OPTIONAL)
  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/schema/  DESTINATION ${CMAKE_INSTALL_SCHEMADIR} OPTIONAL FILES_MATCHING PATTERN "*.jsonnet")
  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/config/  DESTINATION ${CMAKE_INSTALL_SCHEMADIR} OPTIONAL FILES_MATCHING PATTERN "*.json")

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
