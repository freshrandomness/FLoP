field_list egress_mac_tstamp_fields {
    eg_intr_md_from_parser_aux.egress_global_tstamp;//egress tstamp
    // eg_intr_md.egress_mac_tstamp;
}

field_list_calculation egress_mac_tstamp_hash_fields_calc {
    input { egress_mac_tstamp_fields; }
    algorithm : identity_lsb;
    output_width : 32;
}

field_list_calculation egress_mac_tstamp_hash_fields_calc_msb {
    input { egress_mac_tstamp_fields; }
    algorithm : identity_msb;
    output_width : 16;
}

action get_egress_tstamp() {
    modify_field_with_hash_based_offset(egress_hh_md.timestamp, 0, egress_mac_tstamp_hash_fields_calc, 4294967296);
    modify_field (egress_hh_md.timediff, egress_hh_md.timestamp - ingress_hh_md.timestamp);
}

table get_egress_tstamp {
    actions {
        get_egress_tstamp;
    }
    default_action: get_egress_tstamp;
}


header_type egress_heavy_hitter_metadata_t {
    fields {
        load_1 : HH_CELL_WIDTH;
        load_2 : HH_CELL_WIDTH;
        load_3 : HH_CELL_WIDTH;
        load_4 : HH_CELL_WIDTH;
        load_5 : HH_CELL_WIDTH;
        flowkey : 32;
        timestamp : 32;
        timediff: 32;
        // recirculation: 1;
        clean: 8;
        clean_index: HH_TABLE_SIZE;
        total: 32;
    }
}
metadata egress_heavy_hitter_metadata_t egress_hh_md;



/* flow key: 5 tuple */
field_list hash_fields_b {
    ipv4.srcAddr;
    ipv4.dstAddr;
    tcp.srcPort;
    tcp.dstPort;
    ipv4.protocol;
}


field_list_calculation hash_flow_key {
    input {
        hash_fields_b;
    }
    algorithm : crc32;
    output_width : 32;
}

field_list_calculation hash_flow_key_index {
    input {
        hash_fields_b;
    }
    algorithm : crc16;
    output_width : 16;
}


field_list_calculation hh_hash1b {
    input {
        hash_fields_b;
    }
    algorithm : crc32;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash2b {
    input {
        hash_fields_b;
    }
    algorithm : crc_32c;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash3b {
    input {
        hash_fields_b;
    }
    algorithm : crc_32d;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash4b {
    input {
        hash_fields_b;
    }
    algorithm : crc_32q;
    output_width : HH_HASH_BITS;
}

field_list_calculation hh_hash5b {
    input {
        hash_fields_b;
    }
    algorithm : random;
    output_width : HH_HASH_BITS;
}


register heavy_losser_reg {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}

register heavy_losser_count1 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}

register heavy_losser_count2 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}
register heavy_losser_count3 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}
register heavy_losser_count4 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}
register heavy_losser_count5 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}

register ground_truth_reg {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}

register ground_truth_count1 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}

register ground_truth_count2 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}
register ground_truth_count3 {
    width : HH_CELL_WIDTH;
    instance_count : 65536;
}


// Clean up sketch
//
register eg_clean_reg {
    width : 1;
    instance_count : 1;
}

action update_clean_reg() {
    clean_reg_alu.execute_stateful_alu(0);
}

table update_clean_reg {
    actions { update_clean_reg; }
    default_action: update_clean_reg;
}

blackbox stateful_alu clean_reg_alu {
    reg: eg_clean_reg;
    condition_lo: egress_hh_md.timediff > QUEUE_DELAY;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: set_bitc;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: 0;
    output_value: alu_lo;
    output_dst: egress_hh_md.clean;
}

// clean up process with index
register eg_clean_index {
    width : HH_TABLE_SIZE;
    instance_count : 1;
}

action update_clean_index() {
    clean_index_alu.execute_stateful_alu(0);
}

table update_clean_index {
    actions { update_clean_index; }
    default_action: update_clean_index;
}

blackbox stateful_alu clean_index_alu {
    reg: eg_clean_index;
    condition_lo: egress_hh_md.clean == 1;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: egress_hh_md.clean_index;
}


register eg_total {
    width : 32;
    instance_count : 2;
    attributes: saturating;
}

register heavy_hitter_reg_b1 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_b2 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_b3 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_b4 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_b5 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}


// register key_store_b1 {
//     width : 32;
//     instance_count : 1000;
//     attributes: saturating;
// }

// register key_store_b2 {
//     width : 32;
//     instance_count : 1000;
//     attributes: saturating;
// }

// blackbox stateful_alu key_store_b1_alu {
//     reg: key_store_b1;
//     update_lo_1_value:

// }

action update_to_true() {
    modify_field_with_hash_based_offset(egress_hh_md.flowkey, 0x0, hash_flow_key, 4294967296);
    true_key_reg_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}

table update_to_true {
    actions { update_to_true; }
    size: 1;
    default_action: update_to_true;
}

action update_to_true_count1() {
    true_losser_count1_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_true_count1 {
    actions { update_to_true_count1; }
    default_action: update_to_true_count1;
    size: 1;
}

action update_to_true_count2() {
    true_losser_count2_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_true_count2 {
    actions { update_to_true_count2; }
    default_action: update_to_true_count2;
    size: 1;
}

action update_to_true_count3() {
    true_losser_count3_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_true_count3 {
    actions { update_to_true_count3; }
    default_action: update_to_true_count3;
    size: 1;
}



action update_to_cache() {
    modify_field_with_hash_based_offset(egress_hh_md.flowkey, 0x0, hash_flow_key, 4294967296);
    heavy_losser_reg_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}

table update_to_cache {
    actions { update_to_cache; }
    default_action: update_to_cache;
}

action update_to_count1() {
    heavy_losser_count1_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count1 {
    actions { update_to_count1; }
    default_action: update_to_count1;
    size: 1;
}

action update_to_count2() {
    heavy_losser_count2_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count2 {
    actions { update_to_count2; }
    default_action: update_to_count2;
    size: 1;
}

action update_to_count3() {
    heavy_losser_count3_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count3 {
    actions { update_to_count3; }
    default_action: update_to_count3;
    size: 1;
}

action update_to_count4() {
    heavy_losser_count4_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count4 {
    actions { update_to_count4; }
    default_action: update_to_count4;
    size: 1;
}

action update_to_count5() {
    heavy_losser_count5_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count5 {
    actions { update_to_count5; }
    default_action: update_to_count5;
    size: 1;
}

blackbox stateful_alu true_key_reg_alu {
    reg: ground_truth_reg;
    update_lo_1_value: egress_hh_md.flowkey;
}


blackbox stateful_alu heavy_losser_reg_alu {
    reg: heavy_losser_reg;
    update_lo_1_value: egress_hh_md.flowkey;
    // condition_lo: register_lo > 0;
    // output_predicate : condition_lo;
    // output_value: alu_lo;
    // output_dst: egress_hh_md.load_1;
}

blackbox stateful_alu heavy_losser_count1_alu {
    reg: heavy_losser_count1;
    update_lo_1_value: egress_hh_md.load_1;
}

blackbox stateful_alu heavy_losser_count2_alu {
    reg: heavy_losser_count2;
    update_lo_1_value: egress_hh_md.load_2;
}

blackbox stateful_alu heavy_losser_count3_alu {
    reg: heavy_losser_count3;
    update_lo_1_value: egress_hh_md.load_3;
}

blackbox stateful_alu heavy_losser_count4_alu {
    reg: heavy_losser_count4;
    update_lo_1_value: egress_hh_md.load_4;
}

blackbox stateful_alu heavy_losser_count5_alu {
    reg: heavy_losser_count5;
    update_lo_1_value: egress_hh_md.load_5;
}


blackbox stateful_alu true_losser_count1_alu {
    reg: ground_truth_count1;
    update_lo_1_value: register_lo + 1;
}

blackbox stateful_alu true_losser_count2_alu {
    reg: ground_truth_count2;
    update_lo_1_value: register_lo + 1;
}

blackbox stateful_alu true_losser_count3_alu {
    reg: ground_truth_count3;
    update_lo_1_value: register_lo + 1;
}


blackbox stateful_alu eg_total_alu {
    reg: eg_total;
    // initial_register_lo_value : 0;

    update_lo_1_value: register_lo + 1;
    output_value: alu_lo;
    output_dst: egress_hh_md.total;
}



blackbox stateful_alu heavy_hitter_b1_alu {
    reg: heavy_hitter_reg_b1;
    condition_lo: egress_hh_md.clean == 1;
    update_lo_1_predicate: condition_lo;
    update_lo_1_value: 0;
    update_lo_2_predicate: not condition_lo;
    update_lo_2_value: register_lo + 1;

    condition_hi: register_lo > 0;
    output_predicate : condition_hi;
    output_value: alu_lo;
    output_dst: egress_hh_md.load_1;
}

blackbox stateful_alu heavy_hitter_b2_alu {
    reg: heavy_hitter_reg_b2;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.load_2;
}

blackbox stateful_alu heavy_hitter_b3_alu {
    reg: heavy_hitter_reg_b3;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.load_3;
}

blackbox stateful_alu heavy_hitter_b4_alu {
    reg: heavy_hitter_reg_b4;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.load_4;
}

blackbox stateful_alu heavy_hitter_b5_alu {
    reg: heavy_hitter_reg_b5;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.load_5;
}


action run_heavy_hitter_b1() {
    heavy_hitter_b1_alu.execute_stateful_alu_from_hash(hh_hash1b);
}

action run_heavy_hitter_b2() {
    heavy_hitter_b2_alu.execute_stateful_alu_from_hash(hh_hash2b);
}

action run_heavy_hitter_b3() {
    heavy_hitter_b3_alu.execute_stateful_alu_from_hash(hh_hash3b);
}

action run_heavy_hitter_b4() {
    heavy_hitter_b4_alu.execute_stateful_alu_from_hash(hh_hash4b);
}

action run_heavy_hitter_b5() {
    heavy_hitter_b5_alu.execute_stateful_alu_from_hash(hh_hash5b);
}


action eg_total_count() {
    eg_total_alu.execute_stateful_alu(0);
}

table eg_total_count {
    actions { eg_total_count; }
    default_action: eg_total_count;
}

action eg_negative_count() {
    eg_total_alu.execute_stateful_alu(1);
}

table eg_negative_count {
    actions { eg_negative_count; }
    default_action: eg_negative_count;
}


action notify_start_packet() {
    modify_field(ethernet.etherType, 0);
}

table notify_start_packet {
    actions { notify_start_packet; }
    size: 1;
    default_action: notify_start_packet;
}

action notify_stop_packet() {
    modify_field(ethernet.etherType, 65535);
}

table notify_stop_packet {
    actions { notify_stop_packet; }
    size: 1;
    default_action: notify_stop_packet;
}


table heavy_hitter_b1 {
    actions { run_heavy_hitter_b1; }
    default_action: run_heavy_hitter_b1;
}
table heavy_hitter_b2 {
    actions { run_heavy_hitter_b2; }
    default_action: run_heavy_hitter_b2;
}
table heavy_hitter_b3 {
    actions { run_heavy_hitter_b3; }
    default_action: run_heavy_hitter_b3;
}
table heavy_hitter_b4 {
    actions { run_heavy_hitter_b4; }
    default_action: run_heavy_hitter_b4;
}
table heavy_hitter_b5 {
    actions { run_heavy_hitter_b5; }
    default_action: run_heavy_hitter_b5;
}


action run_heavy_hitter_b1_clean() {
    heavy_hitter_b1_alu.execute_stateful_alu(egress_hh_md.clean_index);
}
table heavy_hitter_b1_clean {
    actions { run_heavy_hitter_b1_clean; }
    default_action: run_heavy_hitter_b1_clean;
}

action run_heavy_hitter_b2_clean() {
    heavy_hitter_b2_alu.execute_stateful_alu(egress_hh_md.clean_index);
}
table heavy_hitter_b2_clean {
    actions { run_heavy_hitter_b2_clean; }
    default_action: run_heavy_hitter_b2_clean;
}

action run_heavy_hitter_b3_clean() {
    heavy_hitter_b3_alu.execute_stateful_alu(egress_hh_md.clean_index);
}
table heavy_hitter_b3_clean {
    actions { run_heavy_hitter_b3_clean; }
    default_action: run_heavy_hitter_b3_clean;
}

action run_heavy_hitter_b4_clean() {
    heavy_hitter_b4_alu.execute_stateful_alu(egress_hh_md.clean_index);
}
table heavy_hitter_b4_clean {
    actions { run_heavy_hitter_b4_clean; }
    default_action: run_heavy_hitter_b4_clean;
}

action run_heavy_hitter_b5_clean() {
    heavy_hitter_b5_alu.execute_stateful_alu(egress_hh_md.clean_index);
}
table heavy_hitter_b5_clean {
    actions { run_heavy_hitter_b5_clean; }
    default_action: run_heavy_hitter_b5_clean;
}


action calculate_diff() {
    modify_field(egress_hh_md.load_1, ingress_hh_md.load_1 - egress_hh_md.load_1);
    modify_field(egress_hh_md.load_2, ingress_hh_md.load_2 - egress_hh_md.load_2);
    modify_field(egress_hh_md.load_3, ingress_hh_md.load_3 - egress_hh_md.load_3);
    modify_field(egress_hh_md.load_4, ingress_hh_md.load_4 - egress_hh_md.load_4);
    modify_field(egress_hh_md.load_5, ingress_hh_md.load_5 - egress_hh_md.load_5);

}

table calculate_diff {
    actions { calculate_diff; }
    default_action: calculate_diff;
}

control eg_clean_up {
/*
Check if needs to clean up
*/

    apply(eg_total_count);

    if(ingress_hh_md.clean == 1)
    {
        apply(heavy_hitter_b1_clean);
        apply(heavy_hitter_b2_clean);
        apply(heavy_hitter_b3_clean);
        apply(heavy_hitter_b4_clean);
        apply(heavy_hitter_b5_clean);

    }else{
        apply(heavy_hitter_b1);
        apply(heavy_hitter_b2);
        apply(heavy_hitter_b3);
        apply(heavy_hitter_b4);
        apply(heavy_hitter_b5);
        apply(calculate_diff);
    }
}


control egress_sketch {

    if(egress_hh_md.load_1 > 0
        and egress_hh_md.load_2 > 0
        and egress_hh_md.load_3 > 0){

            apply(update_to_cache);
            apply(update_to_count1);
            apply(update_to_count2);
            apply(update_to_count3);
            apply(update_to_count4);
            apply(update_to_count5);
    }

}

control true_sketch {

    apply(eg_negative_count);

    apply(update_to_true);
    apply(update_to_true_count1);
    apply(update_to_true_count2);
    apply(update_to_true_count3);
}
