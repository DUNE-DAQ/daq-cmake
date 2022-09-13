// This is the configuration schema for package_gen

local moo = import "moo.jsonnet";
local s = moo.oschema.schema("dunedaq.package.confgen");

local cs = {

    int4 :    s.number(  "int4",    "i4",          doc="A signed integer of 4 bytes"),
    uint4 :   s.number(  "uint4",   "u4",          doc="An unsigned integer of 4 bytes"),
    int8 :    s.number(  "int8",    "i8",          doc="A signed integer of 8 bytes"),
    uint8 :   s.number(  "uint8",   "u8",          doc="An unsigned integer of 8 bytes"),
    float4 :  s.number(  "float4",  "f4",          doc="A float of 4 bytes"),
    double8 : s.number(  "double8", "f8",          doc="A double of 8 bytes"),
    boolean:  s.boolean( "Boolean",                doc="A boolean"),
    string:   s.string(  "String",   		   doc="A string"),   
    monitoring_dest: s.enum(     "MonitoringDest", ["local", "cern", "pocket"]),

    boot: s.record("boot", [
        s.field( "base_command_port", self.int4, default=3333, doc="Base port of application command endpoints"),
        s.field( "disable_trace", self.boolean, false, doc="Do not enable TRACE (default TRACE_FILE is /tmp/trace_buffer_${HOSTNAME}_${USER})"),
        s.field( "opmon_impl", self.monitoring_dest, default='local', doc="Info collector service implementation to use"),
        s.field( "ers_impl", self.monitoring_dest, default='local', doc="ERS destination (Kafka used for cern and pocket)"),
        s.field( "pocket_url", self.string, default='127.0.0.1', doc="URL for connecting to Pocket services"),
        s.field( "image", self.string, default="", doc="Which docker image to use"),
        s.field( "use_k8s", self.boolean, default=false, doc="Whether to use k8s"),
    ]),

    package: s.record("package", [
	s.field( "some_configured_value", self.int4, default=31415, doc="A value which configures the RenameMe DAQModule instance"),
    ]),

    package_gen: s.record("package_gen", [
        s.field("boot", self.boot, default=self.boot, doc="Boot parameters"),
        s.field("package", self.package, default=self.package, doc="package parameters"),
    ]),
};

// Output a topologically sorted array.
moo.oschema.sort_select(cs)
