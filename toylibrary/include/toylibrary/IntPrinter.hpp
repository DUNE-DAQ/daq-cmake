/**
 * @file IntPrinter.hpp IntPrinter Class Interface
 *
 * IntPrinter is a class which prints an integer represented by a
 * ValueWrapper class instance on demand
 *
 * The IntPrinter interface is available to developers who link
 * toylibrary into their applications and libraries. It's not an
 * intrinsically useful class, but that's not the point: this is just
 * to show how developers can incorporate a class into a library for
 * others to use in the DUNE DAQ framework.
 *
 * This is part of the DUNE DAQ Application Framework, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#ifndef TOYLIBRARY_INCLUDE_TOYLIBRARY_INTPRINTER_HPP_
#define TOYLIBRARY_INCLUDE_TOYLIBRARY_INTPRINTER_HPP_

#include "toylibrary/ValueWrapper.hpp"

namespace dunedaq::toylibrary {

class IntPrinter
{

public:
  explicit IntPrinter(const ValueWrapper<int>& vw)
    : int_to_print_(vw.GetValue())
  {}

  void Show() const;

  IntPrinter(const IntPrinter&) = delete;
  IntPrinter& operator=(const IntPrinter&) = delete;

  IntPrinter(IntPrinter&&) = delete;
  IntPrinter& operator=(IntPrinter&&) = delete;

private:
  const int int_to_print_;
};

} // namespace dunedaq::toylibrary


#endif // TOYLIBRARY_INCLUDE_TOYLIBRARY_INTPRINTER_HPP_
