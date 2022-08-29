/**
 * @file module.cpp
 *
 * This is part of the DUNE DAQ Software Suite, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>

namespace dunedaq::daqdataformats::python {

extern void
register_renameme(pybind11::module&);

PYBIND11_MODULE(_daq_package_py, m)
{

  m.doc() = "c++ implementation of the dunedaq package modules"; 

  register_renameme(m);
}

} // namespace dunedaq::daqdataformats::python
