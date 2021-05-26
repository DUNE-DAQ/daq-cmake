# fixme: move into find_package(moo)!
# For now, use eg cmake -DMOO_CMD=$(which moo)
set(MOO_CMD "moo" CACHE STRING "The 'moo' command")

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

  set(DEPS_FILE "${MC_CODEGEN}.d")
  # ninja wants the target name in the deps file to be relative to ${CMAKE_BINARY_DIR}, so do that
  file(RELATIVE_PATH MC_CODEGEN_TARGET_NAME "${CMAKE_BINARY_DIR}" ${MC_CODEGEN})

  set(MC_CODEGEN_ARGS ${MC_BASE_ARGS} render -o ${MC_CODEGEN} ${MC_MODEL} ${MC_TEMPL})
  set(MC_RENDER_DEPS_ARGS ${MC_BASE_ARGS} render-deps -t ${MC_CODEGEN_TARGET_NAME} -o  ${DEPS_FILE} ${MC_MODEL} ${MC_TEMPL})

  add_custom_command(
    OUTPUT ${MC_CODEGEN}
    COMMAND ${MOO_CMD} ${MC_CODEGEN_ARGS}
    COMMAND ${MOO_CMD} ${MC_RENDER_DEPS_ARGS}
    DEPENDS ${MC_CODEDEP}
    DEPFILE ${DEPS_FILE}
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
  add_custom_target(${MC_TARGET} DEPENDS  ${MC_CODEGEN} )
endfunction()


