# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")



####################################################################################################
# moo_update_deps:
#
# moo_update_deps is an utility function to handle moo dependencies behind the scenes.
# It creates a custom target to generate a moo dependency files and sets its modification date to 
# the most reacent file listed in the dependencies
function(moo_update_deps base_args deps_dir main_target source target_prefix)

  get_filename_component(basename ${source} NAME)
  string(REGEX REPLACE "[^a-zA-Z0-9]" "_" basename "${basename}")
  set(DEPS_TARGET "${main_target}__${basename}_deps")
  set(DEPS_FILE "${deps_dir}/${main_target}__${basename}.d")
  set(DEPS_PHONY "${deps_dir}/${main_target}__${basename}.d.phony")

  # moo_deps_name(${MC_DEPS_DIR} ${MC_TARGET} ${MC_CODEDEP} MC_CODEDEP)

  set(DEPS_ARGS ${base_args} imports -o ${DEPS_FILE} ${source})
  add_custom_command(
      COMMAND ${MOO_CMD} ARGS ${DEPS_ARGS}
      COMMAND bash ARGS -c "touch -r $(ls -t $(cat ${DEPS_FILE} ) | head -n1) ${DEPS_FILE}"
      VERBATIM
      COMMENT "Updating moo dependencies of ${source}"
      OUTPUT ${DEPS_FILE}
      OUTPUT ${DEPS_PHONY}
  )

  # # Custom target to force the update of jsonnet dependencies at build time
  # # Note the phony dependency to force it to be re-run every time
  add_custom_target(${DEPS_TARGET}
      ALL
      DEPENDS ${DEPS_FILE} ${DEPS_PHONY}
  )

  set(${target_prefix}_DEPS_TARGET ${DEPS_TARGET} PARENT_SCOPE)
endfunction()


####################################################################################################
# moo_update_deps:
# Usage:
# moo_render( TARGET <target name> MODEL <model name> TEMPL <template> CODEGEN <output file> 
#             DEPS_DIR <dependency file dir>  CODEDEP <extra dependency> [GRAFT <graft name>] 
#             [MPATH <module path 1> ...] [TPATH <template path 1> ...] [TLA <arg1>...]) 
#
# moo_update_deps is an utility function to handle moo dependencies behind the scenes.
# It creates a custom target to generate a moo dependency files and sets its modification date to 
# the most reacent file listed in the dependencies
# 
# Arguments:
#    TARGET: Custom target name for this code generation
#    MODEL: Model file
#    TEMPL: Template file
#    DEPS_DIR: destination directory of the dependency file
#    CODEDEP: schema file path ()
#    GRAFT: name of the graft
#    MPATH, TPATH: Module and template search paths
#    TLA: Top-level arguments
#
function(moo_render)
  # message(NOTICE "moo_render ${ARGN}")
  cmake_parse_arguments(MC "" "TARGET;MODEL;TEMPL;CODEGEN;GRAFT;CODEDEP;DEPS_DIR" "TPATH;MPATH;TLAS" ${ARGN})

  if (NOT DEFINED MC_MPATH)
    set(MC_MPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if (NOT DEFINED MC_TPATH)
    set(MC_TPATH ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  list(TRANSFORM MC_TPATH PREPEND "-T")
  list(TRANSFORM MC_MPATH PREPEND "-M")

  set(MC_BASE_ARGS ${MC_TPATH} ${MC_MPATH})

  if (DEFINED MC_GRAFT) 
    list(APPEND MC_BASE_ARGS -g ${MC_GRAFT})
  endif()
  
  if (DEFINED MC_TLAS)
    foreach(TLA ${MC_TLAS})
      list(APPEND MC_BASE_ARGS -A ${TLA})
    endforeach()
  endif()

  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})

  moo_update_deps("${MC_BASE_ARGS}" ${MC_DEPS_DIR} ${MC_TARGET} ${MC_CODEDEP} MC_CODEDEP)
  moo_update_deps("${MC_BASE_ARGS}" ${MC_DEPS_DIR} ${MC_TARGET} ${MC_TEMPL} MC_TEMPL)

  add_custom_command(OUTPUT ${MC_CODEGEN} COMMAND ${MOO_CMD} ${MC_CODEGEN_ARGS} DEPENDS ${MC_CODEDEP})
  add_custom_target(${MC_TARGET} DEPENDS ${MC_CODEGEN} ${MC_CODEDEP_DEPS_TARGET} ${MC_TEMPL_DEPS_TARGET})

endfunction()


