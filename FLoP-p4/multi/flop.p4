#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>

/* Definition of Dataplane */
#define HH_HASH_BITS   4
#define HH_CELL_WIDTH  32
#define HH_TABLE_SIZE  16
#define THRESHOLD 1024
#define QUEUE_THRESHOLD 100

#define CPU_PORT 32

#include "headers.p4"
#include "parsers.p4"
#include "ingress.p4"
#include "egress.p4"

control ingress {

	ingress_heavy_hitter();

	apply(forward);
	// apply(hh_mirror);

	apply(get_ingress_tstamp);

}

control egress {

	apply(get_egress_tstamp);
	egress_sketch();

}
