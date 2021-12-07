if(EXISTS $ENV{CETLIB_EXCEPT_LIB})

  message(FATAL_ERROR "find_package(cetlib_except) is unnecessary as this is brought in by find_package(cetlib). Please contact John Freeman at jcfree@fnal.gov if you have any questions")	

else()
  # Spack

  find_package(cetlib_except REQUIRED CONFIG)

  foreach (dir ${cetlib_except_INCLUDE_DIRS})
    include_directories(${dir})
  endforeach()

  find_library(CETLIB_EXCEPT NAMES libcetlib_except.so PATHS ${cetlib_except_LIBRARY_DIR})

endif()
