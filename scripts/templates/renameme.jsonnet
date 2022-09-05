local moo = import "moo.jsonnet";
local ns = "dunedaq.package.renameme";
local s = moo.oschema.schema(ns);

local types = {

    int8 :   s.number(  "int8",    "i8",          doc="A signed integer of 8 bytes"),
    uint8 :  s.number(  "uint8",   "u8",          doc="An unsigned integer of 8 bytes"),
    float8 : s.number(  "float8",  "f8",          doc="A float of 8 bytes"),
    boolean: s.boolean( "Boolean",                doc="A boolean"),
    string:  s.string(  "String",   moo.re.ident, doc="A string"),   

    // TO package DEVELOPERS: PLEASE DELETE THIS FOLLOWING COMMENT AFTER READING IT
    // The following code is an example of a configuration record
    // written in jsonnet. In the real world it would be written so as
    // to allow the relevant members of RenameMe to be configured by
    // Run Control
  
    conf: s.record("ConfParams", [
                                   s.field("some_configured_value", self.int8, 999999,
                                           doc="This line is where you'd document the value"),
                                  ],
                   doc="This configuration is for developer education only"),

};

moo.oschema.sort_select(types, ns)
