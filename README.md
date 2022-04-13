## FLoP Artifact

This branch contains artifacts for the FLoP paper.

### Directory Structure
Subdirectory      | Description
------------------| ---------------
`FLoP-p4`       | FLoP hardware prototype in P4
`simulator`     | Packet-level simulator to mimic e2e setup and reproduce figures
`data`          | Data traces collected or simulated from real-world experiments
`scripts`       | Scripts for setup the testbed.
`README`       | This document describing the artifact

### System Requirements and Dependencies
We tested the current prototype in the following environmentss:
- **FLoP-P4:** Edgecore Wedge100BF-32X Tofino switch with P4 studio 9.4.0, three commodity servers with Mellanox ConnectX-5 100G NICs. TCP stack is the default Ubuntu 18.04.4 LTS (GNU/Linux 4.15.0-142-generic x86_64).

- **VM:** We provide a VM image to compile/run P4 code and run the simulator with all dependencies installed.


### Longer Instructions

This is for real-world testbed setup building from scratch.

0. Download [P4 Studio Compiler] (v9.4.0) via [Intel Connectivity Research Program](https://www.intel.com/content/www/us/en/products/network-io/programmable-ethernet-switch/connectivity-education-hub/research-program.html). Install the compiler and the BF-reference library on the control CPU of a Tofino switch. (Estimated 45min)

1. Compile the code using the supplied script ``./p4_build.sh ../FLoP-p4/multi/flop.p4 --with-p4c=bf-p4c``. (Estimated 10min)

2. Run the P4 program on the switch ``./run_switchd.sh -p flop`` and configure the switch ports via ``./run_switchd.sh -p flop``

3. Create 100 concurrent TCP connections via iperf3 between sender and receiver.

4. (Optional) Configure the sender via ``set.sh`` to launch TCP connections with different RTTs (e.g., 1ms to 100ms).

5. (Optional) Install [MoonGen](https://github.com/emmericp/MoonGen) on the third server for DPDK-based packet generation. Run ``./build/MoonGen ./udp_sender.lua``
