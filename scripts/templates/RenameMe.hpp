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
  void do_conf(const data_t&);
  void do_start(const data_t&);
  void do_stop(const data_t&);
  void do_scrap(const data_t&);
};

} // namespace dunedaq::package

#endif // PACKAGE_PLUGINS_RENAMEME_HPP_
