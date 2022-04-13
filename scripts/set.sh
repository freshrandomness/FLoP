sudo tc qdisc del dev eth0 root #reset

sudo tc qdisc add dev eth0 root handle 1: htb 
sudo tc class add dev eth0 parent 1: classid 1:1 htb rate 100gbit # this is for all other traffic.

for LATENCY in `seq 1 99`; do
	PORT=`expr 5200 + ${LATENCY}`;
	echo "Setting latency ${LATENCY}ms for TCP sport ${PORT}"
	sudo -E tc class add dev eth0 parent 1: classid 1:${PORT} htb rate 100gbit
	sudo -E tc filter add dev eth0 parent 1: protocol ip prio 1 u32 flowid 1:${PORT} match ip sport ${PORT} 0xffff 
	sudo -E tc qdisc add dev eth0 parent 1:${PORT} handle ${PORT}:1 netem delay ${LATENCY}ms
done


