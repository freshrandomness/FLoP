#
# Simple table setup script for buffer_extension.p4
#
import traceback
from struct import *

clear_all(verbose=True)

# forward
p4_pd.forward_table_add_with_set_egr( # roce27
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.27")),
        p4_pd.set_egr_action_spec_t(148))

p4_pd.forward_table_add_with_set_egr( # roce28
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.28")),
        p4_pd.set_egr_action_spec_t(156))

p4_pd.forward_table_add_with_set_egr( # roce29
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.29")),
        p4_pd.set_egr_action_spec_t(140))

p4_pd.forward_table_add_with_set_egr( # roce30
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.30")),
        p4_pd.set_egr_action_spec_t(132))

p4_pd.forward_table_add_with_set_egr( # roce33
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.33")),
        p4_pd.set_egr_action_spec_t(184))

p4_pd.forward_table_add_with_set_egr( # roce34
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.34")),
        p4_pd.set_egr_action_spec_t(168))

p4_pd.forward_table_add_with_set_egr( # roce36
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.36")),
        p4_pd.set_egr_action_spec_t(52))

p4_pd.forward_table_add_with_set_egr( # roce37
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.37")),
        p4_pd.set_egr_action_spec_t(172))

p4_pd.forward_table_add_with_set_egr( # roce38
        p4_pd.forward_match_spec_t(ipv4Addr_to_i32("10.10.10.38")),
        p4_pd.set_egr_action_spec_t(164))

#RDMA multicase group
p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("24:be:05:ca:5e:a1"))) #from the DRAM server (roce28)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("e0:07:1b:70:0c:51"))) #from the DRAM server (roce29)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("f4:52:14:61:a9:22"))) #from the DRAM server (roce30)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("ec:0d:9a:b9:e0:70"))) #from the DRAM server (roce33)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("ec:0d:9a:b9:e0:20"))) #from the DRAM server (roce34)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("ec:0d:9a:b9:e1:b0"))) #from the DRAM server (roce33)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("ec:0d:9a:b9:df:40"))) #from the DRAM server (roce33)

p4_pd.rdma_read_response_table_add_with_rdma_read_decap(
        p4_pd.rdma_read_response_match_spec_t(macAddr_to_string("ec:0d:9a:b9:df:50"))) #from the DRAM server (roce33)



try:
    for x in xrange(1,9):
        p4_pd.update_read_seqnum_step1_table_add_with_update_read_seqnum_step1(
        p4_pd.update_read_seqnum_step1_match_spec_t(x),
        p4_pd.update_read_seqnum_step1_action_spec_t(x-1))

except:
    print """
[ERROR] Failed on init update_read_seqnum_step1_table
"""
    traceback.print_exc()
    quit()
#set default actions
p4_pd.update_read_seqnum_step2_set_default_action_update_read_seqnum_step2()
#p4_pd.generate_rdma_read_set_default_action_generate_rdma_read()


try:
    for x in xrange(1,9):
        p4_pd.update_qp_num_step1_table_add_with_update_qp_num_step1(
        p4_pd.update_qp_num_step1_match_spec_t(x),
        p4_pd.update_qp_num_step1_action_spec_t(x-1))

except:
    print """
[ERROR] Failed on init update_read_seqnum_step1_table
"""
    traceback.print_exc()
    quit()
    
# p4_pd.hash_kv_table_1_set_default_action_hash_kv_act_1()
# p4_pd.hash_kv_table_2_set_default_action_hash_kv_act_2()
# p4_pd.hash_kv_table_3_set_default_action_hash_kv_act_3()
# p4_pd.hash_kv_table_4_set_default_action_hash_kv_act_4()
# p4_pd.hash_kv_table_5_set_default_action_hash_kv_act_5()

# p4_pd.find_rdma_match_1_set_default_action_match_rdma_act_1()
# p4_pd.find_rdma_match_2_set_default_action_match_rdma_act_2()
# p4_pd.find_rdma_match_3_set_default_action_match_rdma_act_3()
# p4_pd.find_rdma_match_4_set_default_action_match_rdma_act_4()



p4_pd.add_roce_pad_table_add_with_add_roce_pad_0 (
       p4_pd.add_roce_pad_match_spec_t(3))
p4_pd.add_roce_pad_table_add_with_add_roce_pad_1 (
       p4_pd.add_roce_pad_match_spec_t(2))
p4_pd.add_roce_pad_table_add_with_add_roce_pad_2 (
       p4_pd.add_roce_pad_match_spec_t(1))
p4_pd.add_roce_pad_table_add_with_add_roce_pad_3 (
        p4_pd.add_roce_pad_match_spec_t(0))


p4_pd.register_reset_all_qp_idx ()
p4_pd.register_reset_all_read_seqnum ()
p4_pd.register_reset_all_cache_pip_reg ()
p4_pd.register_reset_all_cache_port_reg ()

#p4_pd.register_reset_all_write_offset ()
#p4_pd.register_reset_all_write_counter ()


# #init cache
# srcs = []
# dsts = []
# srcports = []
# dstports = []
# protos = []

# pips = []
# ports = []
# cache_size = 0
# try:
#     cache = open("/home/gem/GEM/src/misc/zipf_gen/output/zipf_99_top1024.txt", "r")
#     lines = cache.readlines()
#     cache_size = len(lines)
#     for i in xrange(0, cache_size):
#         line = lines[i]
#         numbers = line.split()
#         srcs.append(int(numbers[0]))
#         dsts.append(int(numbers[1]))
#         srcports.append(int(numbers[2]))
#         dstports.append(int(numbers[3]))
#         protos.append(int(numbers[4]))
#     print "cache size: %d " % cache_size
# except:
#     print """
# Failed to read from cache text file
# """
#     traceback.print_exc()
#     quit()

# print srcs
# print dsts
# print srcports
# print dstports
# print protos

# try:
#     for x in xrange(0,cache_size):
#         p4_pd.cache_check_exist_table_add_with_cache_check_exist_act(
#         p4_pd.cache_check_exist_match_spec_t(srcs[x],dsts[x],srcports[x],dstports[x],protos[x]),
#         p4_pd.cache_check_exist_act_action_spec_t(x))

#         for y in xrange(0,cache_size):
#             p4_pd.register_write_cache_pip_reg(y,ipv4Addr_to_i32("10.10.10.28"))
#             p4_pd.register_write_cache_port_reg(y,80)
#         print "Inserted cache %d" % x
# except:
#     print """
# Failed to init cache table
# """
#     traceback.print_exc()
#     quit()


# try:
#     for x in xrange(0,8):
#         p4_pd.forward_to_DRAM_table_add_with_set_egr_DRAM(
#         p4_pd.forward_to_DRAM_match_spec_t(x),
#         p4_pd.set_egr_DRAM_action_spec_t(x+1,"0x007fd323e00001"))
# except:
#     print """
# Failed to init forward_to_DRAM table
# """
#     traceback.print_exc()
#     quit()

try:
    for x in xrange(0,8):
        p4_pd.load_table_add_with_increment_load(
        p4_pd.load_match_spec_t(x),
        p4_pd.increment_load_action_spec_t(x))
except:
    print """
Failed to init load table
"""
    traceback.print_exc()
    quit()


# try:
#     for x in xrange(0,128):
#         p4_pd.mem_bucket_offset_1_table_add_with_mem_bucket_1(
#         p4_pd.mem_bucket_offset_1_match_spec_t(x),
#         p4_pd.mem_bucket_1_action_spec_t(pack('i',1594*x)))
#         #print "Inserted multilication table %d" % x
# except:
#     print """
# Failed to init mem_bucket_offset_1 table
# """
#     traceback.print_exc()
#     quit()




try:
    mcg1  = mc.mgrp_create(1)
    mcg2  = mc.mgrp_create(2)
    mcg3  = mc.mgrp_create(3)
    mcg4  = mc.mgrp_create(4)
    mcg5  = mc.mgrp_create(5)
    mcg6  = mc.mgrp_create(6)
    mcg7  = mc.mgrp_create(7)
    mcg8  = mc.mgrp_create(8)

except:
    print """
clean_all() does not yet support cleaning the PRE programming.
You need to restart the driver before running this script for the second time
"""
    quit()

(sess, dev) = mc_common_args(None, None)

EG_PORTS = [156,184,168,52,132,140,172,164]
for idx in xrange(0, len(EG_PORTS)):
    lag_idx1 = 2 * idx
    lag_idx2 = 2 * idx + 1

    mc.set_lag_membership(i8(lag_idx1), devports_to_mcbitmap([EG_PORTS[idx]]), sess_hdl=sess, dev_id=dev)
    mc.set_lag_membership(i8(lag_idx2), devports_to_mcbitmap([EG_PORTS[idx]]), sess_hdl=sess, dev_id=dev)

    exec "node%d = mc.node_create(rid=idx+1, port_map=devports_to_mcbitmap([]), lag_map=lags_to_mcbitmap([lag_idx1, lag_idx2]))" % (idx+1)
    exec "mc.associate_node(mcg%d, node%d, xid=0, xid_valid=False)" % (idx+1, idx+1)

mc.complete_operations()


conn_mgr.complete_operations()