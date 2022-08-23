local moo = import "moo.jsonnet";
local ns = "dunedaq.package.renameme";
local s = moo.oschema.schema(ns);

local types = {

};

moo.oschema.sort_select(types, ns)
