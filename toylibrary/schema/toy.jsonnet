// The toy schema.
//

local moo = import "moo.jsonnet";

// A schema builder in the given path (namespace)
local ns = "dunedaq.toy";
local s = moo.oschema.schema(ns);

// Object structure used by the test/fake producer module
local toy = {

    size: s.number("Size", "u8",
                   doc="A count of very many things"),

    count : s.number("Count", "i4",
                     doc="A count of not too many things"),

};

moo.oschema.sort_select(toy, ns)

