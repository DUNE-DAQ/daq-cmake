/**
 * @file ValueWrapper.hpp ValueWrapper Class Interface
 *
 * ValueWrapper is a class which contains an instance of a templatized
 * object accessible via a getter function
 *
 * The ValueWrapper interface is available to developers who link
 * toylibrary into their applications and libraries. It's not an
 * intrinsically useful class, but that's not the point: this is just
 * to show how developers can write a templatized class for use in
 * their library source code
 *
 * This is part of the DUNE DAQ Application Framework, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#ifndef TOYLIBRARY_INCLUDE_TOYLIBRARY_VALUEWRAPPER_HPP_
#define TOYLIBRARY_INCLUDE_TOYLIBRARY_VALUEWRAPPER_HPP_

namespace dunedaq::toylibrary {

template<typename ValueType>
class ValueWrapper
{

public:
  explicit ValueWrapper(const ValueType& value_to_wrap)
    : value_(value_to_wrap)
  {}

  ValueType GetValue() const;

  ValueWrapper(const ValueWrapper&) = default;
  ValueWrapper& operator=(const ValueWrapper&) = default;

  ValueWrapper(ValueWrapper&&) = default;
  ValueWrapper& operator=(ValueWrapper&&) = default;

private:
  const ValueType value_;
};

} // namespace dunedaq::toylibrary

#include "detail/ValueWrapper.hxx"

#endif // TOYLIBRARY_INCLUDE_TOYLIBRARY_VALUEWRAPPER_HPP_
