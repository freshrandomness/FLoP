field_list ingress_mac_tstamp_fields {
    ig_intr_md_from_parser_aux.ingress_global_tstamp; //ingress tstamp
    // ig_intr_md.ingress_mac_tstamp;
}

field_list_calculation ingress_mac_tstamp_hash_fields_calc {
    input { ingress_mac_tstamp_fields; }
    algorithm : identity_lsb;
    output_width : 32;
}

field_list_calculation ingress_mac_tstamp_hash_fields_calc_msb {
    input { ingress_mac_tstamp_fields; }
    algorithm : identity_msb;
    output_width : 16;
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



header_type ingress_heavy_hitter_metadata_t {
    fields {
        load_1 : HH_CELL_WIDTH;
        load_2 : HH_CELL_WIDTH;
        load_3 : HH_CELL_WIDTH;
        load_4 : HH_CELL_WIDTH;
        load_5 : HH_CELL_WIDTH;
        bf_1 : 1;
        bf_2 : 1;
        bf_3 : 1;
        cleanup: 16;
        send_to_cpu : 1;
        timestamp : 32;
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

register special_flag {
    width : 16;
    instance_count : 1;
}

//CM counters
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





control ingress_heavy_hitter {

    apply(heavy_hitter_a1);
    apply(heavy_hitter_a2);
    apply(heavy_hitter_a3);
    apply(heavy_hitter_a4);
    apply(heavy_hitter_a5);

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
