#include <tofino/constants.p4>
#include <tofino/intrinsic_metadata.p4>
#include <tofino/primitives.p4>
#include <tofino/stateful_alu_blackbox.p4>

/* Definition of Dataplane */
#define HH_HASH_BITS   4
#define HH_CELL_WIDTH  32
#define HH_TABLE_SIZE  16
#define THRESHOLD 1024
#define QUEUE_LENGTH 1000
#define SAMPLING_RANGE 127

#define CPU_PORT 32

#include "headers.p4"
#include "parsers.p4"
#include "ingress.p4"
#include "egress.p4"

control ingress {

	ingress_heavy_hitter();

	apply(forward);

	apply(set_negative_mirror);

	apply(random_number_table);
	if(ingress_hh_md.rng == 1){
		apply(do_recirculate)
	}

}

control egress {

	// apply(get_egress_tstamp);
	if(eg_intr_md.deq_qdepth > QUEUE_LENGTH
		and ingress_hh_md.recirculation == 1)
	{
		apply(notify_start_packet);
	}else{
		apply(notify_stop_packet);
	}
	
	if(eg_intr_md.deflection_flag == 1)
	{
		true_sketch();

	}else{
		eg_clean_up();
		egress_sketch();
	}

}
