/**
 * @file RenameMe.hpp
 *
 * Developer(s) of this DAQModule have yet to replace this line with a brief description of the DAQModule.
 *
 * This is part of the DUNE DAQ Software Suite, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#ifndef PACKAGE_PLUGINS_RENAMEME_HPP_
#define PACKAGE_PLUGINS_RENAMEME_HPP_

#include "appfwk/DAQModule.hpp"

#include <string>

namespace dunedaq::package {

class RenameMe : public dunedaq::appfwk::DAQModule
{
public:
  explicit RenameMe(const std::string& name);

  void init(const data_t&) override;

  void get_info(opmonlib::InfoCollector&, int /*level*/) override;

  RenameMe(const RenameMe&) = delete;
  RenameMe& operator=(const RenameMe&) = delete;
  RenameMe(RenameMe&&) = delete;
  RenameMe& operator=(RenameMe&&) = delete;

  ~RenameMe() = default;

private:
  // Commands RenameMe can receive

  // TO package DEVELOPERS: PLEASE DELETE THIS FOLLOWING COMMENT AFTER READING IT
  // For any run control command it is possible for a DAQModule to
  // register an action that will be executed upon reception of the
  // command. do_conf is a very common example of this; in
  // RenameMe.cpp you would implement do_conf so that members of
  // RenameMe get assigned values from a configuration passed as 
  // an argument and originating from the CCM system.
  // To see an example of this value assignment, look at the implementation of 
  // do_conf in RenameMe.cpp

  void do_conf(const data_t&);

  int m_some_configured_value;
};

} // namespace dunedaq::package

#endif // PACKAGE_PLUGINS_RENAMEME_HPP_
