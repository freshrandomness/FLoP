field_list ingress_mac_tstamp_fields {
    ig_intr_md_from_parser_aux.ingress_global_tstamp; //ingress tstamp
    // ig_intr_md.ingress_mac_tstamp;
}

field_list ingress_identify_fields {
    ethernet.dstAddr;
}


//calcuate the timestamp in 32 LSB (total 48-bit)
field_list_calculation ingress_mac_tstamp_hash_fields_calc {
    input { ingress_mac_tstamp_fields; }
    algorithm : identity_lsb;
    output_width : 32;
}
//calcuate the timestamp in 16 MSB (total 48-bit)
field_list_calculation ingress_mac_tstamp_hash_fields_calc_msb {
    input { ingress_mac_tstamp_fields; }
    algorithm : identity_msb;
    output_width : 16;
}

//check the "recirculation" bits
field_list_calculation identify_recirculate_packet_calc {
    input { ingress_identify_fields; }
    algorithm : identity_lsb;
    output_width : HH_TABLE_SIZE;
}
field_list_calculation identify_recirculate_packet_calc_msb {
    input { ingress_identify_fields; }
    algorithm : identity_msb;
    output_width : 8;
}


action get_ingress_tstamp(){
    modify_field_with_hash_based_offset(ingress_hh_md.timestamp, 0, ingress_mac_tstamp_hash_fields_calc, 4294967296);
}
table get_ingress_tstamp {
    actions {
        get_ingress_tstamp;
    }
    default_action: get_ingress_tstamp;
}


action identify_recirculate(){
    modify_field_with_hash_based_offset(ingress_hh_md.recirculation, 0, identify_recirculate_packet_calc, 65536);
    modify_field_with_hash_based_offset(ingress_hh_md.is_recirculate, 0, identify_recirculate_packet_calc_msb, 256);

}
table identify_recirculate {
    actions {
        identify_recirculate;
    }
    default_action: identify_recirculate;
}


header_type ingress_heavy_hitter_metadata_t {
    fields {
        load_1 : HH_CELL_WIDTH;
        load_2 : HH_CELL_WIDTH;
        load_3 : HH_CELL_WIDTH;
        load_4 : HH_CELL_WIDTH;
        load_5 : HH_CELL_WIDTH;
        timestamp : 32;
        is_congested: 8;
        recirculation: 1;
        clean: 8;
        total: 32;
        rng: 7;
        clean_index: 32;
    }
}
metadata ingress_heavy_hitter_metadata_t ingress_hh_md;



/* flow key: 5 tuple */
field_list hash_fields {
    ipv4.srcAddr;
    ipv4.dstAddr;
    tcp.srcPort;
    tcp.dstPort;
    ipv4.protocol;
}


field_list_calculation hh_hash1 {
    input {
        hash_fields;
    }
    algorithm : crc32;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash2 {
    input {
        hash_fields;
    }
    algorithm : crc_32c;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash3 {
    input {
        hash_fields;
    }
    algorithm : crc_32d;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash4 {
    input {
        hash_fields;
    }
    algorithm : crc_32q;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash5 {
    input {
        hash_fields;
    }
    algorithm : random
    ;
    output_width : HH_HASH_BITS;
}

/*
update clean index
*/
register ig_clean_reg {
    width : 8;
    instance_count : 1;
}

action update_ig_clean_reg() {
    ig_clean_reg_alu.execute_stateful_alu(0);
}

table update_ig_clean_reg {
    actions { update_ig_clean_reg; }
    default_action: update_ig_clean_reg;
}

blackbox stateful_alu ig_clean_reg_alu {
    reg: ig_clean_reg;
    condition_lo: ingress_hh_md.is_recirculate == 0xff;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 1;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: 0;
    output_value: alu_lo;
    output_dst: ingress_hh_md.;
}



register ig_total {
    width : 32;
    instance_count : 1;
    attributes: saturating;
}

// register ig_negative_total {
//     width : 32;
//     instance_count : 1;
//     attributes: saturating;
// }

register heavy_hitter_reg_a1 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_a2 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_a3 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_a4 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_a5 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}


blackbox stateful_alu ig_total_alu {
    reg: ig_total;
    // initial_register_lo_value : 0;

    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: ingress_hh_md.total;
}

// blackbox stateful_alu ig_negative_total_alu {
//     reg: ig_negative_total;
//     initial_register_lo_value : 0;
//
//     update_lo_1_value: register_lo + 1;
//     output_value: alu_lo;
//     output_dst: ingress_hh_md.total;
// }

blackbox stateful_alu heavy_hitter_a1_alu {
    reg: heavy_hitter_reg_a1;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: ingress_hh_md.load_1;
}

blackbox stateful_alu heavy_hitter_a2_alu {
    reg: heavy_hitter_reg_a2;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: ingress_hh_md.load_2;
}

blackbox stateful_alu heavy_hitter_a3_alu {
    reg: heavy_hitter_reg_a3;
    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: ingress_hh_md.load_3;
}

blackbox stateful_alu heavy_hitter_a4_alu {
    reg: heavy_hitter_reg_a4;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: ingress_hh_md.load_4;
}

blackbox stateful_alu heavy_hitter_a5_alu {
    reg: heavy_hitter_reg_a5;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: ingress_hh_md.load_5;
}


action run_heavy_hitter_a1() {
    heavy_hitter_a1_alu.execute_stateful_alu_from_hash(hh_hash1);
}

action run_heavy_hitter_a2() {
    heavy_hitter_a2_alu.execute_stateful_alu_from_hash(hh_hash2);
}

action run_heavy_hitter_a3() {
    heavy_hitter_a3_alu.execute_stateful_alu_from_hash(hh_hash3);
}

action run_heavy_hitter_a4() {
    heavy_hitter_a4_alu.execute_stateful_alu_from_hash(hh_hash4);
}

action run_heavy_hitter_a5() {
    heavy_hitter_a5_alu.execute_stateful_alu_from_hash(hh_hash5);
}

action ig_total_count() {
    ig_total_alu.execute_stateful_alu(0);
}

table ig_total_count {
    actions { ig_total_count; }
    default_action: ig_total_count;
}

// action ig_negative_count() {
//     ig_negative_total_alu.execute_stateful_alu(0);
// }
//
// table ig_negative_count {
//     actions { ig_negative_count; }
//     default_action: ig_negative_count;
// }

table heavy_hitter_a1 {
    actions { run_heavy_hitter_a1; }
    default_action: run_heavy_hitter_a1;
}
table heavy_hitter_a2 {
    actions { run_heavy_hitter_a2; }
    default_action: run_heavy_hitter_a2;
}
table heavy_hitter_a3 {
    actions { run_heavy_hitter_a3; }
    default_action: run_heavy_hitter_a3;
}
table heavy_hitter_a4 {
    actions { run_heavy_hitter_a4; }
    default_action: run_heavy_hitter_a4;
}
table heavy_hitter_a5 {
    actions { run_heavy_hitter_a5; }
    default_action: run_heavy_hitter_a5;
}

/*
 up sketch counters
*/
action run_heavy_hitter_a1_clean() {
    heavy_hitter_a1_alu.execute_stateful_alu(ingress_hh_md.clean_index);
}
table heavy_hitter_a1_clean {
    actions { run_heavy_hitter_a1_clean; }
    default_action: run_heavy_hitter_a1_clean;
}

action run_heavy_hitter_a2_clean() {
    heavy_hitter_a2_alu.execute_stateful_alu(ingress_hh_md.clean_index);
}
table run_heavy_hitter_a1_clean {
    actions { run_heavy_hitter_a2_clean; }
    default_action: run_heavy_hitter_a2_clean;
}

action run_heavy_hitter_a3_clean() {
    heavy_hitter_a3_alu.execute_stateful_alu(ingress_hh_md.clean_index);
}
table run_heavy_hitter_a3_clean {
    actions { run_heavy_hitter_a3_clean; }
    default_action: run_heavy_hitter_a3_clean;
}

action run_heavy_hitter_a4_clean() {
    heavy_hitter_a4_alu.execute_stateful_alu(ingress_hh_md.clean_index);
}
table run_heavy_hitter_a4_clean {
    actions { run_heavy_hitter_a4_clean; }
    default_action: run_heavy_hitter_a4_clean;
}

action run_heavy_hitter_a5_clean() {
    heavy_hitter_a5_alu.execute_stateful_alu(ingress_hh_md.clean_index);
}
table run_heavy_hitter_a5_clean {
    actions { run_heavy_hitter_a5_clean; }
    default_action: run_heavy_hitter_a5_clean;
}


action set_egr(egress_spec) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, egress_spec);
}


table forward {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        set_egr;
    }
    size : 1000;
}

action send(port) {
    modify_field(ig_intr_md_for_tm.ucast_egress_port, port);
}

action discard() {
    modify_field(ig_intr_md_for_tm.drop_ctl, 1);
}

table ipv4_host {
    reads {
        ipv4.dstAddr : exact;
    }
    actions {
        send;
        discard;
    }
    size : 1000;
}

/*
generate a random number
*/

action generate_random_number() {
    modify_field_rng_uniform(ingress_hh_md.rng, 0, SAMPLING_RANGE);
}

table random_number_table {
    actions { generate_random_number; }
    size : 1;
    default_action : generate_random_number();
}

/*
Enable deflection on drop
*/

table set_negative_mirror {
    actions { set_negative_mirror; }
    size : 1;
    default_action: set_negative_mirror;
}

action set_negative_mirror() {
    modify_field(ig_intr_md_for_tm.deflect_on_drop, 1);
}


/*
set packet recirculation
*/
action do_recirculate() {
    recirculate(68);
    modify_field(ingress_hh_md.recirculation, 1);
    // modify_field(ig_intr_md_for_tm.ucast_egress_port, 68);
}
table do_recirculate {
    actions { do_recirculate; }
    size: 1;
    default_action: do_recirculate;
}

action mark_to_clean() {
    modify_field(ingress_hh_md., 1);
    // modify_field(ig_intr_md_for_tm.ucast_egress_port, 68);
}
table mark_to_clean {
    actions { mark_to_clean; }
    size: 1;
    default_action: mark_to_clean;
}





control ingress_heavy_hitter {

    if(ethernet.etherType == 0)
    {
        apply(mark_to_clean);
        
    }else if(ethernet.etherType == 65535)
    {

    }

    apply(ig_total_count);

    if(ingress_hh_md. == 1)
    {
        apply(heavy_hitter_a1_clean);
        apply(heavy_hitter_a2_clean);
        apply(heavy_hitter_a3_clean);
        apply(heavy_hitter_a4_clean);
        apply(heavy_hitter_a5_clean);
    }else{
        apply(heavy_hitter_a1);
        apply(heavy_hitter_a2);
        apply(heavy_hitter_a3);
        apply(heavy_hitter_a4);
        apply(heavy_hitter_a5);
    }
    // apply(get_ingress_tstamp);

}
