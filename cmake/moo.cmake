# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")


# https://cmake.org/pipermail/cmake/2009-December/034253.html

# Given a source file name set <prefix>_DEPS_FILE to a file name and
# <prefix>_DEPS_NAME to a variable name.  The file name is suitable
# for use in "moo imports -o ${<prefix>_DEPS_FILE} ..." such that when
# this file is included into cmake the ${${<prefix>_DEPS_NAME}} will
# contain the list of import dependencies that moo calculated.
function(moo_deps_name source prefix)
  get_filename_component(basename ${source} NAME)
  get_filename_component(fullpath ${source} REALPATH)
  string(CONCAT DEPS_NAME "${basename}" "_deps") #make unique
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" DEPS_NAME "${DEPS_NAME}")
  set("${prefix}_DEPS_FILE" "${CMAKE_CURRENT_BINARY_DIR}/${DEPS_NAME}.cmake" PARENT_SCOPE)
  string(TOUPPER "${DEPS_NAME}" DEPS_NAME)
  set("${prefix}_DEPS_NAME" "${DEPS_NAME}" PARENT_SCOPE)
endfunction()

##
macro(moo_codegen)
  cmake_parse_arguments(MC "" "MODEL;TEMPL;CODEGEN;MPATH;TPATH;GRAFT" "TLAS" ${ARGN})

  if (NOT DEFINED MC_MPATH)
    set(MC_MPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()
  if (NOT DEFINED MC_TPATH)
    set(MC_TPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  set(MC_BASE_ARGS -T ${MC_TPATH} -M ${MC_MPATH})

  if (DEFINED MC_GRAFT) 
    list(APPEND MC_BASE_ARGS -g ${MC_GRAFT})
  endif()
  
  if (DEFINED MC_TLAS)
    foreach(TLA ${MC_TLAS})
      list(APPEND MC_BASE_ARGS -A ${TLA})
    endforeach()
  endif()

  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})

  string(REPLACE ";" " " formatted_codegen_call "${MC_CODEGEN_ARGS}")
  #message(STATUS "Build system generating header via ${MOO_CMD} ${formatted_codegen_call}")

  execute_process(
    COMMAND ${MOO_CMD} ${MC_CODEGEN_ARGS}
    RESULT_VARIABLE returnval 
    OUTPUT_VARIABLE outvar 
    ERROR_VARIABLE errvar 
  )
  if (NOT returnval EQUAL 0)
    message(WARNING "WARNING: ${errvar}")
    message(STATUS "Called ${MOO_CMD} ${MC_CODEGEN_ARGS}")
    message(STATUS "Non-stderr output was ${outvar}")
    message(FATAL_ERROR "Problem trying to generate ${MC_CODEGEN}")
  endif()

endmacro()

