/**
 * @file RenameMe.cpp 
 *
 * Implementations of RenameMe's functions
 *
 * This is part of the DUNE DAQ Software Suite, copyright 2020.
 * Licensing/copyright details are in the COPYING file that you should have
 * received with this code.
 */

#include "RenameMe.hpp"

namespace dunedaq::package {

RenameMe::RenameMe(const std::string& name)
  : dunedaq::appfwk::DAQModule(name)
{
  register_command("conf", &RenameMe::do_conf);
  register_command("start", &RenameMe::do_start);
  register_command("stop", &RenameMe::do_stop);
  register_command("scrap", &RenameMe::do_scrap);
}

void
RenameMe::init(const data_t& /* structured args */)
{

}

void
RenameMe::do_conf(const data_t& /* structured args */ )
{

}

void
RenameMe::do_start(const data_t& /* structured args */ )
{

}

void
RenameMe::do_stop(const data_t& /* structured args */ )
{

}

void
RenameMe::do_scrap(const data_t& /* structured args */)
{

}

} // namespace dunedaq::package

DEFINE_DUNE_DAQ_MODULE(dunedaq::package::RenameMe)
