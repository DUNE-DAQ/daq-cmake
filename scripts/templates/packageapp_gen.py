# This module facilitates the generation of package DAQModules within package apps


# Set moo schema search path                                                                              
from dunedaq.env import get_moo_model_path
import moo.io
moo.io.default_load_path = get_moo_model_path()

# Load configuration types                                                                                
import moo.otypes
moo.otypes.load_types("package/renameme.jsonnet")

import dunedaq.package.renameme as renameme

from daqconf.core.app import App, ModuleGraph
from daqconf.core.daqmodule import DAQModule
#from daqconf.core.conf_utils import Endpoint, Direction

def get_package_app(nickname, num_renamemes, some_configured_value, host="localhost"):
    """
    Here the configuration for an entire daq_application instance using DAQModules from package is generated.
    """

    modules = []

    for i in range(num_renamemes):
        modules += [DAQModule(name = f"nickname{i}", 
                              plugin = "RenameMe", 
                              conf = renameme.Conf(some_configured_value = some_configured_value
                                )
                    )]

    mgraph = ModuleGraph(modules)
    package_app = App(modulegraph = mgraph, host = host, name = nickname)

    return package_app
