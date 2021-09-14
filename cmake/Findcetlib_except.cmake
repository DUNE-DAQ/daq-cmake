if(EXISTS $ENV{CETLIB_LIB})

  message(FATAL_ERROR "Tell John Freeman to fix this")	
  include_directories($ENV{CETLIB_EXCEPT_INC})
  find_library(CETLIB_EXCEPT NAMES libcetlib_except.so)
  set(cetlib_except_FOUND TRUE)
else()
  # Spack

  find_package(cetlib_except REQUIRED CONFIG)

  foreach (dir ${cetlib_except_INCLUDE_DIRS})
    include_directories(${dir})
  endforeach()

  find_library(CETLIB_EXCEPT NAMES libcetlib_except.so PATHS ${cetlib_except_LIBRARY_DIR})

endif()
