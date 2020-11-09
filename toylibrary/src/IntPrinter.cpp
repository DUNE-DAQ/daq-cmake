/**
 * @file IntPrinter.hpp IntPrinter Class Implementation
 *
 * See header for more on this class
 *
 * This is part of the DUNE DAQ Application Framework, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */


#include "toylibrary/IntPrinter.hpp"

#include <ers/ers.h>

namespace dunedaq::toylibrary {

void
IntPrinter::Show() const
{

  //  ERS_INFO("The integer is " << int_to_print_);
  ERS_INFO(int_to_print_);
}

} // namespace dunedaq::toylibrary

