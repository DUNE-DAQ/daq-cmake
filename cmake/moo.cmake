# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")


# https://cmake.org/pipermail/cmake/2009-December/034253.html

# Given a source file name set <prefix>_DEPS_FILE to a file name and
# <prefix>_DEPS_NAME to a variable name.  The file name is suitable
# for use in "moo imports -o ${<prefix>_DEPS_FILE} ..." such that when
# this file is included into cmake the ${${<prefix>_DEPS_NAME}} will
# contain the list of import dependencies that moo calculated.
# function(moo_deps_name source prefix)
#   get_filename_component(basename ${source} NAME)
#   get_filename_component(fullpath ${source} REALPATH)
#   string(CONCAT DEPS_NAME "${basename}" "_deps") #make unique
#   string(REGEX REPLACE "[^a-zA-Z0-9]" "_" DEPS_NAME "${DEPS_NAME}")
#   set("${prefix}_DEPS_FILE" "${CMAKE_CURRENT_BINARY_DIR}/${DEPS_NAME}.cmake" PARENT_SCOPE)
#   string(TOUPPER "${DEPS_NAME}" DEPS_NAME)
#   set("${prefix}_DEPS_NAME" "${DEPS_NAME}" PARENT_SCOPE)
# endfunction()


function(moo_deps_name deps_dir target source prefix)
  get_filename_component(basename ${source} NAME)
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" basename "${basename}")
  set("${prefix}_DEPS_TARGET" "${target}__${basename}_deps" PARENT_SCOPE)
  set("${prefix}_DEPS_FILE" "${deps_dir}/${target}__${basename}.d" PARENT_SCOPE)
  set("${prefix}_DEPS_PHONY" "${deps_dir}/${target}__${basename}.d.phony" PARENT_SCOPE)
  # set("${prefix}_DEPS_PHONY" "${${prefix}_DEPS_NAME}.phony" PARENT_SCOPE)
endfunction()

function(moo_render)
  cmake_parse_arguments(MC "" "TARGET;MODEL;TEMPL;CODEGEN;MPATH;TPATH;GRAFT;CODEDEP;DEPS_DIR" "TLAS" ${ARGN})

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

  
  moo_deps_name(${MC_DEPS_DIR} ${MC_TARGET} ${MC_CODEDEP} MC_CODEDEP)

  set(MC_CODEDEP_DEPS_ARGS ${MC_BASE_ARGS} imports -o ${MC_CODEDEP_DEPS_FILE} ${MC_CODEDEP})
  add_custom_command(
      COMMAND ${MOO_CMD} ARGS ${MC_CODEDEP_DEPS_ARGS}
      COMMAND bash ARGS -c "touch -r $(ls -t $(cat ${MC_CODEDEP_DEPS_FILE} ) | head -n1) ${MC_CODEDEP_DEPS_FILE}"
      VERBATIM
      COMMENT "Updating moo dependencies of ${MC_CODEDEP}"
      OUTPUT ${MC_CODEDEP_DEPS_FILE}
      OUTPUT ${MC_CODEDEP_DEPS_PHONY}
  )

  # # Custom target to force the update of jsonnet dependencies at build time
  # # Note the phony dependency to force it to be re-run every time
  add_custom_target(${MC_CODEDEP_DEPS_TARGET}
      ALL
      DEPENDS ${MC_CODEDEP_DEPS_FILE} ${MC_CODEDEP_DEPS_PHONY}
  )
  #--------------------

  # message(NOTICE "${MC_TARGET} ${MC_BASE_ARGS} ${MC_CODEGEN_ARGS}")
  add_custom_command(OUTPUT ${MC_CODEGEN} COMMAND ${MOO_CMD} ${MC_CODEGEN_ARGS} DEPENDS ${MC_CODEDEP})
  add_custom_target(${MC_TARGET} DEPENDS ${MC_CODEGEN} ${MC_CODEDEP_DEPS_TARGET})

endfunction()


