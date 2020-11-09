if(EXISTS $ENV{CETLIB_LIB})
 # UPS
  include_directories($ENV{CETLIB_INC})
  include_directories($ENV{CETLIB_EXCEPT_INC})
  find_library(CETLIB NAMES libcetlib.so)
  find_library(CETLIB_EXCEPT NAMES libcetlib_except.so)
  set(cetlib_FOUND TRUE)
else()
	# Spack
	find_package(cetlib REQUIRED CONFIG)
	set(CETLIB cetlib)
	set(CETLIB_EXCEPT cetlib_except)
endif()
