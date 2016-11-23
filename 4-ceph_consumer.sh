#!/bin/bash
#######################################################################
### CEPH FRAMEWORK (stage 4) - Ceph Consumer configuration
#######################################################################
# Instructions for configuring a CentOS node as consumer of the DC/OS
# Ceph framework. This allows to mount volumes created and handled by
# the Ceph framework running on DC/OS.
# This node can be any node from the cluster or not part of the cluster but
# part of the same subnet and authorized.
# RBD is used as a client.
########################################################################

# 0
# Prerequisites on the node - CentOS
###############

# 0.0 Root access --  all these are root operations
sudo su

# 0.1 jq
wget http://stedolan.github.io/jq/download/linux64/jq
chmod +x ./jq
cp jq /usr/bin

# 0.2 find out the HOST network.
# This is the same HOST network used in the bootstrap node to install and launch the Ceph framework
# can be copied from it. Alternatively, the steps used to calculate it in the bootstrap should also work.
# On bootstrap:
echo $HOST_NETWORK
# example OUTPUT:
#  172.31.0.0/20
# on this node
export $HOST_NETWORK=172.31.0.0/20  #change to your specific output

# 1
# Create CEPH.conf
##############################

# 1.1 Parameter 1: Find out the ceph SECRET created by Ceph and stored in Zookeeper
# go into Zookeeper at http://$DCOS_IP:8181

# Open the "Explorer". Open up the root ZK folder by expanding with the button on the left of the folder icon.
# go to "ceph-on-mesos", click on "secrets.json" -- copy the entire "Data as String" available at the bottom. Example:
# {"fsid":"d8e57f50-c26f-43d6-b678-95640beb27f4","adminRing":"AQC6/TRYdsbZhhAAzzQfp8a1HVS5N+PDRzQXMg==","monRing":"AQC6/TRY/vZ+hxAA6GClC+goMWh/zFunwhd8WA==","mdsRing":"AQC6/TRYm4x/hxAA5snbgMzzu8pjgtS0cADxiQ==","osdRing":"AQC6/TRYWkuAhxAAlqc4OYu4T9hL9TT83F+yng==","rgwRing":"AQC6/TRYSAGBhxAAEo5N3oey9ekU99tWEQOjAw=="}
# export it in the node where you want ceph installed
# export SECRETS='{<paste JSON blob here>}'
export SECRETS='{"fsid":"d7170dac-ea14-4668-8a72-017172c13075","adminRing":"AQCtvjVYcOTitRAAGSArjCyokh+n+WiR18z98g==","monRing":"AQCtvjVYP6UbtxAASVpcU10wz/qmuf+dkQE5wA==","mdsRing":"AQCtvjVYyJYctxAAC38oVQspyO0Z1lRxWHJW1g==","osdRing":"AQCtvjVYSJ8dtxAA6ymsbHSgcmaLQvv7cVgp+g==","rgwRing":"AQCtvjVY9ZoetxAAeLy2U1S9COB5PfJ78tUW6g=="}'
#check that the FSID was correctly parsed
echo "$SECRETS" |jq .fsid
# EXAMPLE OUTPUT:
# "d8e57f50-c26f-43d6-b678-95640beb27f4"

# 1.2
# Use the $SECRETS variable exported above to create the Ceph configuration for this node which will be the Ceph client

mkdir -p /etc/ceph
cat <<-EOF > /etc/ceph/ceph.conf
[global]
fsid = $(echo "$SECRETS" | jq .fsid)
mon host = $(curl leader.mesos:8123/v1/services/_mon._tcp.ceph.mesos | jq '. | map(.ip + ":" + .port) | sort | join(",")')

auth cluster required = cephx
auth service required = cephx
auth client required = cephx
public network = $HOST_NETWORK
cluster network = $HOST_NETWORK
max_open_files = 131072
mon_osd_full_ratio = ".95"
mon_osd_nearfull_ratio = ".85"
osd_pool_default_min_size = 1
osd_pool_default_pg_num = 128
osd_pool_default_pgp_num = 128
osd_pool_default_size = 3
rbd_default_features = 1
EOF

# 2
# Create the CEPH monitor keyring file
#############################################

cat <<-EOF > /etc/ceph/ceph.mon.keyring
[mon.]
 key = $(echo "$SECRETS" | jq .monRing -r)
 caps mon = "allow *"
EOF

# 3
# Create the CEPH client Admin Keyring file
#############################################

cat <<-EOF > /etc/ceph/ceph.client.admin.keyring
[client.admin]
  key = $(echo "$SECRETS" | jq .monRing -r)
  auid = 0
  caps mds = "allow"
  caps mon = "allow *"
  caps osd = "allow *"
EOF

# 4
# INSTALL CEPH FROM REPOS
##############################

rpm --rebuilddb  #sometimes the dB needs this after install
yum install -y centos-release-ceph-jewel
yum install -y ceph

# 6
# check ceph is working. need to use the system python packages
###############################################################

/bin/python /bin/ceph mon getmap -o /etc/ceph/monmap-ceph
/bin/python /bin/ceph -s

# 7
# USE IT!: use RBD to map and mount the remote volume
############################################################

rbd create --size=1G test
rbd map test
#/dev/rbd0
mkdir -p /mnt/ceph
mount /dev/rbd0 /mnt/ceph

cd /mnt/ceph/
touch "RIGHT_ON"
ls
