local moo = import "moo.jsonnet";
local s = moo.oschema.schema(dunedaq.package.renameme");

local info = {

    int8 :   s.number(  "int8",    "i8",          doc="A signed integer of 8 bytes"),
    uint8 :  s.number(  "uint8",   "u8",          doc="An unsigned integer of 8 bytes"),
    float8 : s.number(  "float8",  "f8",          doc="A float of 8 bytes"),
    boolean: s.boolean( "Boolean",                doc="A boolean"),
    string:  s.string(  "String",   moo.re.ident, doc="A string")   

    // ...Replace this comment with the info record...

};

moo.oschema.sort_select(info)
