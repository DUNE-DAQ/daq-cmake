/**
 * @file ValueWrapper_test.cxx ValueWrapper class Unit Tests
 *
 * This file is meant to serve as an example for developers for how to use Boost
 * to write unit tests for their package's components. It's good practice to write
 * unit tests and make sure they pass before passing code on to others.
 *
 * This is part of the DUNE DAQ Application Framework, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#include "toylibrary/ValueWrapper.hpp"

#define BOOST_TEST_MODULE ValueWrapper_test // NOLINT

#include <boost/test/unit_test.hpp>
#include <string>

using namespace dunedaq::toylibrary;

BOOST_AUTO_TEST_SUITE(ValueWrapper_test)

namespace {
const int integer_to_wrap = 2010;
const std::string string_to_wrap = "Haskell";
} // namespace ""

BOOST_AUTO_TEST_CASE(Construct)
{
  BOOST_REQUIRE_NO_THROW(ValueWrapper<int> should_construct_fine(integer_to_wrap));
}

BOOST_AUTO_TEST_CASE(Commands)
{
  ValueWrapper<std::string> wrapped_characters(string_to_wrap);
  BOOST_REQUIRE(wrapped_characters.GetValue() == string_to_wrap);
}

BOOST_AUTO_TEST_SUITE_END()
