from scapy.all import *
import mmh3
import heapq
import numpy
import random
from statistics import mean


# Sketch memory configuration
col_size = 1024
row_size = 5
ingress_arrays = []
egress_arrays = []
clean = 0
loss_threshold = 100
heavy_lossers = {}
loss_rate = 0.2


def list_mean(list):
	total = 0;
	for item in list:
		total += item
	return (total/len(list))



class Flop:
	col_size = 1024
	row_size = 5
	ingress_arrays = []
	egress_arrays = []
	clean = 0
	loss_threshold = 100
	heavy_lossers = {}
	true_heavy_lossers = {}
	loss_rate = 0.2
	total_ingress = 0
	total_egress = 0

	def __init__(self, col, row, threshold, loss_rate):
		self.col_size = col
		self.row_size = row
		self.ingress_arrays = []
		self.egress_arrays = []
		self.clean = 0
		self.loss_threshold = threshold
		self.heavy_lossers = {}
		self.true_heavy_lossers = {}
		self.loss_rate = loss_rate
		self.total_ingress = 0
		self.total_egress = 0


	def pipeline_init(self):
		for i in range(self.row_size):
			ingress_array = []
			egress_array = []
			for j in range(self.col_size):
				ingress_array.append(0)
				egress_array.append(0)
				self.ingress_arrays.append(ingress_array)
				self.egress_arrays.append(egress_array)

	def sketch_cleanup(self, flowkey):
		for i in range(self.row_size):
			col = mmh3.hash(flowkey,i)%self.col_size
			self.ingress_arrays[i][col] = 0

	def get_flowkey(self, packet):
		if IP in packet:
			flowkey = str(packet[IP].src) + str(packet[IP].dst) + str(packet[IP].proto)
			if TCP in packet:
				flowkey += str(packet[TCP].sport)
				flowkey += str(packet[TCP].dport)
			elif UDP in packet:
				flowkey += str(packet[UDP].sport)
				flowkey += str(packet[UDP].sport)
			return flowkey
		else:
			return None

	## update ingress pipeline
	def update_ingress(self, packet):
		ingress_counters = []
		flowkey = self.get_flowkey(packet)
		if flowkey != None:
			if clean == 1:
				self.sketch_cleanup(flowkey)
			else:
				self.total_ingress = self.total_ingress + 1
				for i in range(self.row_size):
					col = mmh3.hash(flowkey,i)%self.col_size
					self.ingress_arrays[i][col] = self.ingress_arrays[i][col] + 1
					ingress_counters.append(self.ingress_arrays[i][col])
		return ingress_counters

	## update egress pipeline
	def update_egress(self, packet, ingress_counters):
		egress_counters = []
		flowkey = self.get_flowkey(packet)
		if flowkey != None:
			self.total_egress = self.total_egress + 1
			for i in range(self.row_size):
				col = mmh3.hash(flowkey,i)%self.col_size
				self.egress_arrays[i][col] = self.egress_arrays[i][col] + 1
				egress_counters.append(self.egress_arrays[i][col])

			diff_array = numpy.subtract(ingress_counters, egress_counters)
			min_diff = min(diff_array)
			if min_diff >= loss_threshold:
				self.heavy_lossers[flowkey] = min_diff

	def packet_processing(self, ingress_packets):
		self.pipeline_init()
		for packet in ingress_packets:
			ingress_message = self.update_ingress(packet)
			if numpy.random.random_sample() > self.loss_rate:
				if len(ingress_message) > 0:
					self.update_egress(packet, ingress_message)
			else:
				flowkey = self.get_flowkey(packet)
				if flowkey != None:
					if flowkey in self.true_heavy_lossers.keys():
						self.true_heavy_lossers[flowkey] = self.true_heavy_lossers[flowkey] + 1
					else:
						self.true_heavy_lossers[flowkey] = 1




def main():
	# Preloading pcap trace
	print("## Loading packet trace ... ")
	ingress_packets = rdpcap('../data/example.pcap')

	print("#### Figure 7 simulation on non-real-world-data ####")
	print("## Experiment 1 - 0.5% loss rate")
	exp = Flop(2048, 5, 1, 0.005)
	exp.packet_processing(ingress_packets)
	#evaluation function
	loss = exp.total_ingress - exp.total_egress
	print(loss)
	print(loss/len(ingress_packets))

	print("## Experiment 1 - 0.75% loss rate")
	exp = Flop(2048, 5, 1, 0.0075)
	exp.packet_processing(ingress_packets)
	#evaluation function
	loss = exp.total_ingress - exp.total_egress
	print(loss)
	print(loss/len(ingress_packets))

	print("## Experiment 1 - 1.0% loss rate")
	exp = Flop(2048, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	loss = exp.total_ingress - exp.total_egress
	print(loss)
	print(loss/len(ingress_packets))

	print("## Experiment 1 - 10.0% loss rate")
	exp = Flop(2048, 5, 1, 0.1)
	exp.packet_processing(ingress_packets)
	#evaluation function
	loss = exp.total_ingress - exp.total_egress
	print(loss)
	print(loss/len(ingress_packets))

	print("#### Figure 10 simulation on smaller data ####")
	print("## Experiment 2 - 1% loss - 10K: Mean Error")
	exp = Flop(1024, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 1% loss - 40K: Mean Error")
	exp = Flop(1024*4, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)

	print(ARE)

	print("## Experiment 2 - 1% loss - 80K: Mean Error")
	exp = Flop(1024*8, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 1% loss - 160K: Mean Error")
	exp = Flop(1024*16, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 1% loss - 320K: Mean Error")
	exp = Flop(1024*32, 5, 1, 0.01)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 2% loss - 10K: Mean Error")
	exp = Flop(2048, 5, 10, 0.02)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 2% loss - 40K: Mean Error")
	exp = Flop(2048*2, 5, 10, 0.02)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 2% loss - 80K: Mean Error")
	exp = Flop(2048*4, 5, 10, 0.02)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 2% loss - 160K: Mean Error")
	exp = Flop(2048*8, 5, 10, 0.02)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 2% loss - 320K: Mean Error")
	exp = Flop(2048*16, 5, 10, 0.02)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)


	print("## Experiment 2 - 5% loss - 10K: Mean Error")
	exp = Flop(3072, 5, 100, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 5% loss - 40K: Mean Error")
	exp = Flop(8192, 5, 20, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 5% loss - 80K: Mean Error")
	exp = Flop(8192*2, 5, 20, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 5% loss - 160K: Mean Error")
	exp = Flop(8192*4, 5, 20, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 2 - 5% loss - 160K: Mean Error")
	exp = Flop(8192*8, 5, 20, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Figure 11 raw data")
	print("## Experiment 3 - 0.5% loss: Mean Error")
	exp = Flop(8192, 5, 20, 0.005)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 3 - 5% loss: Mean Error")
	exp = Flop(8192, 5, 20, 0.05)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)

	print("## Experiment 3 - 10% loss: Mean Error")
	exp = Flop(8192, 5, 20, 0.1)
	exp.packet_processing(ingress_packets)
	#evaluation function
	errors = []
	for flow in exp.heavy_lossers.keys():
		estimate = exp.heavy_lossers[flow]
		if flow in exp.true_heavy_lossers.keys():
			true = exp.true_heavy_lossers[flow]
			error = abs(estimate-true)/true
			errors.append(error)
	ARE = mean(errors)
	print(ARE)





if __name__ == "__main__":
    main()

# update_sketch(packets)
# print ("192.168.202.79", query("192.168.202.79"))
# print ("192.168.229.254", query("192.168.229.254"))
