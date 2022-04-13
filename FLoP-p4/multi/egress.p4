field_list egress_mac_tstamp_fields {
    eg_intr_md_from_parser_aux.egress_global_tstamp;//egress tstamp
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
        out_load_1 : HH_CELL_WIDTH;
        out_load_2 : HH_CELL_WIDTH;
        out_load_3 : HH_CELL_WIDTH;
        out_load_4 : HH_CELL_WIDTH;
        out_load_5 : HH_CELL_WIDTH;
        flowkey : 32;
        timestamp : 32;
        timediff: 32;
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
    output_width : 4;
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
    instance_count : 16;
}

register heavy_losser_count1 {
    width : HH_CELL_WIDTH;
    instance_count : 16;
}

register heavy_losser_count2 {
    width : HH_CELL_WIDTH;
    instance_count : 16;
}
register heavy_losser_count3 {
    width : HH_CELL_WIDTH;
    instance_count : 16;
}
register heavy_losser_count4 {
    width : HH_CELL_WIDTH;
    instance_count : 16;
}
register heavy_losser_count5 {
    width : HH_CELL_WIDTH;
    instance_count : 16;
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



register heavy_hitter_reg_c1 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_c2 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_c3 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_c4 {
    width : HH_CELL_WIDTH;
    instance_count : HH_TABLE_SIZE;
    attributes: saturating;
}

register heavy_hitter_reg_c5 {
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
}

action update_to_count2() {
    heavy_losser_count2_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count2 {
    actions { update_to_count2; }
    default_action: update_to_count2;
}

action update_to_count3() {
    heavy_losser_count3_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count3 {
    actions { update_to_count3; }
    default_action: update_to_count3;
}

action update_to_count4() {
    heavy_losser_count4_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count4 {
    actions { update_to_count4; }
    default_action: update_to_count4;
}

action update_to_count5() {
    heavy_losser_count5_alu.execute_stateful_alu_from_hash(hash_flow_key_index);

}
table update_to_count5 {
    actions { update_to_count5; }
    default_action: update_to_count5;
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
    update_lo_1_value: egress_hh_md.out_load_1;
}

blackbox stateful_alu heavy_losser_count2_alu {
    reg: heavy_losser_count2;
    update_lo_1_value: egress_hh_md.out_load_2;
}

blackbox stateful_alu heavy_losser_count3_alu {
    reg: heavy_losser_count3;
    update_lo_1_value: egress_hh_md.out_load_3;
}

blackbox stateful_alu heavy_losser_count4_alu {
    reg: heavy_losser_count4;
    update_lo_1_value: egress_hh_md.out_load_4;
}

blackbox stateful_alu heavy_losser_count5_alu {
    reg: heavy_losser_count5;
    update_lo_1_value: egress_hh_md.out_load_5;
}



blackbox stateful_alu heavy_hitter_b1_alu {
    reg: heavy_hitter_reg_b1;

    update_lo_1_value: register_lo + 1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
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



blackbox stateful_alu heavy_hitter_c1_alu {
    reg: heavy_hitter_reg_b1;

    update_lo_1_value: register_lo + ingress_hh_md.load_1;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.out_load_1;
}

blackbox stateful_alu heavy_hitter_c2_alu {
    reg: heavy_hitter_reg_b2;

    update_lo_1_value: register_lo + ingress_hh_md.load_2;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.out_load_2;
}

blackbox stateful_alu heavy_hitter_c3_alu {
    reg: heavy_hitter_reg_b3;

    update_lo_1_value: register_lo + ingress_hh_md.load_3;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.out_load_3;
}

blackbox stateful_alu heavy_hitter_c4_alu {
    reg: heavy_hitter_reg_b4;

    update_lo_1_value: register_lo + ingress_hh_md.load_4;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.out_load_4;
}

blackbox stateful_alu heavy_hitter_c5_alu {
    reg: heavy_hitter_reg_b5;

    update_lo_1_value: register_lo + ingress_hh_md.load_5;
    condition_lo: register_lo > 0;
    output_predicate : condition_lo;
    output_value: alu_lo;
    output_dst: egress_hh_md.out_load_5;
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


action run_heavy_hitter_c1() {
    heavy_hitter_c1_alu.execute_stateful_alu_from_hash(hh_hash1b);
}

action run_heavy_hitter_c2() {
    heavy_hitter_c2_alu.execute_stateful_alu_from_hash(hh_hash2b);
}

action run_heavy_hitter_c3() {
    heavy_hitter_c3_alu.execute_stateful_alu_from_hash(hh_hash3b);
}

action run_heavy_hitter_c4() {
    heavy_hitter_c4_alu.execute_stateful_alu_from_hash(hh_hash4b);
}

action run_heavy_hitter_c5() {
    heavy_hitter_c5_alu.execute_stateful_alu_from_hash(hh_hash5b);
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


table heavy_hitter_c1 {
    actions { run_heavy_hitter_c1; }
    default_action: run_heavy_hitter_c1;
}
table heavy_hitter_c2 {
    actions { run_heavy_hitter_c2; }
    default_action: run_heavy_hitter_c2;
}
table heavy_hitter_c3 {
    actions { run_heavy_hitter_c3; }
    default_action: run_heavy_hitter_c3;
}
table heavy_hitter_c4 {
    actions { run_heavy_hitter_c4; }
    default_action: run_heavy_hitter_c4;
}
table heavy_hitter_c5 {
    actions { run_heavy_hitter_c5; }
    default_action: run_heavy_hitter_c5;
}


action calculate_diff() {
    modify_field(egress_hh_md.out_load_1, egress_hh_md.load_1 - egress_hh_md.out_load_1);
    modify_field(egress_hh_md.out_load_2, egress_hh_md.load_2 - egress_hh_md.out_load_2);
    modify_field(egress_hh_md.out_load_3, egress_hh_md.load_3 - egress_hh_md.out_load_3);
    modify_field(egress_hh_md.out_load_4, egress_hh_md.load_4 - egress_hh_md.out_load_4);
    modify_field(egress_hh_md.out_load_5, egress_hh_md.load_5 - egress_hh_md.out_load_5);

}


table calculate_diff {
    actions { calculate_diff; }
    default_action: calculate_diff;
}



/*
bloom filter for HHs
*/
// field_list_calculation bf_hash_1 {
//     input { hash_fields; }
//     algorithm: crc_32c;
//     output_width: BF_HASH_WIDTH;
// }
// field_list_calculation bf_hash_2 {
//     input { hash_fields; }
//     algorithm: crc_32d;
//     output_width: BF_HASH_WIDTH;
// }
// field_list_calculation bf_hash_3 {
//     input { hash_fields; }
//     algorithm: crc_32q;
//     output_width: BF_HASH_WIDTH;
// }



// register bloom_filter_1 {
//     width : 1;
//     instance_count : HH_BF_TABLE_SIZE;
// }
// register bloom_filter_2 {
//     width : 1;
//     instance_count : HH_BF_TABLE_SIZE;
// }
// register bloom_filter_3 {
//     width : 1;
//     instance_count : HH_BF_TABLE_SIZE;
// }



// blackbox stateful_alu bloom_filter_alu_1 {
//     reg: bloom_filter_1;
//     update_lo_1_value: set_bitc;
//     output_value: alu_lo;
//     output_dst: hh_md.bf_1;
// }
// blackbox stateful_alu bloom_filter_alu_2 {
//     reg: bloom_filter_2;
//     update_lo_1_value: set_bitc;
//     output_value: alu_lo;
//     output_dst: hh_md.bf_2;
// }
// blackbox stateful_alu bloom_filter_alu_3 {
//     reg: bloom_filter_3;
//     update_lo_1_value: set_bitc;
//     output_value: alu_lo;
//     output_dst: hh_md.bf_3;
// }

// action check_bloom_filter_1() {
//     bloom_filter_alu_1.execute_stateful_alu_from_hash(bf_hash_1);
// }
// action check_bloom_filter_2() {
//     bloom_filter_alu_2.execute_stateful_alu_from_hash(bf_hash_2);
// }
// action check_bloom_filter_3() {
//     bloom_filter_alu_3.execute_stateful_alu_from_hash(bf_hash_3);
// }

// table bloom_filter_table_1 {
//     actions { check_bloom_filter_1; }
//     default_action: check_bloom_filter_1;
// }
// table bloom_filter_table_2 {
//     actions { check_bloom_filter_2; }
//     default_action: check_bloom_filter_2;
// }
// table bloom_filter_table_3 {
//     actions { check_bloom_filter_3; }
//     default_action: check_bloom_filter_3;
// }



// action mark_as_hot_report_act () {
//     modify_field (hh_md.send_to_cpu, 1);
// }

//@pragma stage 10
// table mark_as_hot_report {
//     actions {
//         mark_as_hot_report_act;
//     }
//     default_action: mark_as_hot_report_act;
//     size: 1;
// }


control onoff {
    apply(get_egress_tstamp);

}

control egress_sketch {

    apply(heavy_hitter_b1);
    apply(heavy_hitter_b2);
    apply(heavy_hitter_b3);
    apply(heavy_hitter_b4);
    apply(heavy_hitter_b5);

    apply(heavy_hitter_c1);
    apply(heavy_hitter_c2);
    apply(heavy_hitter_c3);
    apply(heavy_hitter_c4);
    apply(heavy_hitter_c5);

    apply(calculate_diff);


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


// control check_hot {

//     if (hh_md.load_1 != 0){
//         if(hh_md.load_2 != 0) {
//             if (hh_md.load_3 != 0){
//                 if (hh_md.load_4 != 0){
//                     apply(bloom_filter_table_1);
//                     apply(bloom_filter_table_2);
//                     apply(bloom_filter_table_3);
//                     if (hh_md.bf_1 == 0 or hh_md.bf_2 == 0 or hh_md.bf_3 == 0)
//                     {
//                         apply(mark_as_hot_report);
//                     }
//                 }
//             }
//         }
//     }
// }
