import os.path


def get_moo_model_path():
    """
    Gets the moo model path.
    """
    return [os.path.join(p, 'schema') for p in os.environ.get("DUNEDAQ_SHARE_PATH", "").split(':')]


