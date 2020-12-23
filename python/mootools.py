'''
Construct  objects for DUNE DAQ apps based on moo oschema.
'''

import os
import moo

def default_schema_paths():
    '''
    Return list of default file system paths from which to locate schema files.
    '''
    maybe = [
        ".",
        # os.environ.get("MOO_MODULE_PATH"),
        # add more here if we default conventions.
    ]
    
    maybe += [ os.path.join(p, 'schema') for p in os.environ.get("DAQ_SHARE_PATH","").split(':')]
    
    return [one for one in maybe if one]

def load_oschema(filename, path=()):
    '''
    Load oschema file as data structure.
    '''
    return moo.io.load(filename, list(path) + default_schema_paths())

def make_otypes(schema):
    '''
    Make Python types from schema structure.
    '''
    ret = dict()
    for one in schema:
        typ = moo.otypes.make_type(**one)
        ret[typ.__module__ + '.' + typ.__name__] = typ
    return ret

def import_schema(filename, path=()):
    '''
    Convenience function to load schemas and make otypes in one go
    '''
    schema = load_oschema(filename, path=())
    return make_otypes(schema)
