# dcos-ceph

This is a set of scripts and instructions to get the excellent Ceph-on-Mesos framework [ceph-on-mesos](https://github.com/vivint-smarthome/ceph-on-mesos) running on a DC/OS 1.8 cluster.

This has been tested initially on a cluster running Open DC/OS v1.8.7 composed of nodes running CentOS 7.2. This may work with other setups but your mileage may vary.

## Prerequisites

- A running DC/OS v1.8 cluster
- All nodes in the cluster that will be part of the Ceph installation MUST have a separate volume for Ceph OSDs to use
  * As an example, this can be achieved in AWS EC2 by just adding a second volume to each instance before installing.
- A node in the cluster with a working DC/OS CLI, and connected to Mesos-DNS for \*.mesos address resolution

The process has 4 parts

## 1 - Configure/format the DC/OS agents that will run the Ceph OSDs 

- Nodes where OSDs will run MUST have a separate volume
- This will be formatted as XFS, and mounted as /dcos/volumeX for Mesos - DC/OS to use
- Follow/execute the instructions in the file [ceph-nodes](./1-ceph-nodes.sh) on each node of the cluster

## 2 - Configure and launch the Ceph-on-mesos framework

- This can be executed from the DC/OS bootstrap node or from any node in the cluster
- As a prerequisite, the node MUST have a working DC/OS CLI, and be connected to Mesos-DNS for \*.mesos address resolution
