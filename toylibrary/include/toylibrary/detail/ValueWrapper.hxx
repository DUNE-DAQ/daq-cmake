
// Normally we'd define a function as short as GetValue() inline
// within the class declaration; however, it's put in an *.hxx file to
// demonstrate how on DUNE DAQ we can separate a template class
// declaration from its member function definitions

namespace dunedaq::toylibrary {

template<typename T>
T
ValueWrapper<T>::GetValue() const
{
  return value_;
}

} // namespace dunedaq::toylibrary
