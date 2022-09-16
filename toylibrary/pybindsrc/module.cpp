/**
 * @file module.cpp
 *
 * Example Pybind11 source file for wrapping a dunedaq library
 *
 * This is part of the DUNE DAQ Software Suite, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#include "toylibrary/IntPrinter.hpp"
#include "toylibrary/ValueWrapper.hpp"

#include "logging/Logging.hpp"

#include "pybind11/pybind11.h"
#include "pybind11/stl.h"

#include <sstream>
#include <string>
#include <vector>

namespace py = pybind11;

namespace dunedaq::toylibrary::python {

// Toy functions for pybind11 demo
int
WindUp(int number)
{
  return ++number; // NOLINT(runtime/increment_decrement)
}

int
WindDown(int number)
{
  return --number; // NOLINT(runtime/increment_decrement)
}

void
PlayInts(const std::vector<int>& numbers, bool new_line = false)
{
  std::string separator = new_line ? "\n" : ",";
  std::stringstream numbers_stream;
  for (decltype(numbers.size()) i = 0; i < numbers.size(); ++i) {
    if (i > 0) {
      numbers_stream << separator;
    }
    numbers_stream << numbers.at(i);
  }
  TLOG() << numbers_stream.str() << std::endl;
}

PYBIND11_MODULE(_daq_toylibrary_py, m)
{

  m.doc() = "Python module wrapper for C++ library, toylibrary";

  // expose toylibrary classes in the top level python module

  py::class_<toylibrary::ValueWrapper<int>>(m, "ValueWrapperInt")

    // Expose ValueWrapper<int> constructor
    .def(py::init<const int&>())

    // expose the ValueWrapper<int> method GetValue
    .def("GetValue", &toylibrary::ValueWrapper<int>::GetValue);

  py::class_<toylibrary::IntPrinter>(m, "IntPrinter")

    // Expose IntPrinter constructor
    .def(py::init<const ValueWrapper<int>&>())

    // expose the IntPrinter method Show
    .def("Show", &toylibrary::IntPrinter::Show);

  // Sub-module of the top module
  py::module_ wind_module = m.def_submodule("wind");

  // Expose "winding" functions via wind sub-module
  wind_module.def("WindUp", &WindUp);
  wind_module.def("WindDown", &WindDown);

  // Another sub-module of top module above
  py::module_ play_module = m.def_submodule("play");

  // Expose "playing" functions via the play sub-module
  // Here we are adding argument names, as well as defining a default value for one of the function arguments. The
  // function can be called from python with or without that argument.
  play_module.def("PlayInts", &PlayInts, py::arg("numbers"), py::arg("new_line") = false);
}

} // namespace dunedaq::toylibrary::python
