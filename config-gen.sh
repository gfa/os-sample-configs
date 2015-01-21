#!/bin/sh
set -e

DISTRIB=debian
openstack_release=icehouse
RELEASE=wheezy

APT_MIRROR="192.168.255.1:9999"

if [ $DISTRIB = ubuntu ]; then
cat <<- EOF > /etc/apt/sources.list
deb http://$APT_MIRROR/$DISTRIB $RELEASE main restricted universe multiverse
deb http://$APT_MIRROR/$DISTRIB $RELEASE-security main restricted universe multiverse
deb http://$APT_MIRROR/$DISTRIB $RELEASE-updates main restricted universe multiverse
deb http://$APT_MIRROR/$DISTRIB $RELEASE-backports main restricted universe multiverse
EOF
    else
cat <<- EOF > /etc/apt/sources.list
deb http://$APT_MIRROR/$DISTRIB $RELEASE main contrib non-free
deb http://$APT_MIRROR/$DISTRIB $RELEASE-updates main contrib non-free
deb http://$APT_MIRROR/$DISTRIB-security $RELEASE/updates main contrib non-free
deb http://$APT_MIRROR/$DISTRIB $RELEASE-backports main contrib non-free
EOF
fi

TEMP=`mktemp -d`
cd $TEMP

if [ "$openstack_release" = "havana" ]; then
    DAEMONS=nova
    if [ $DISTRIB = ubuntu ]; then
        cat <<- EOF >> /etc/apt/sources.list
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $RELEASE-updates/$openstack_release main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $RELEASE-updates/$openstack_release main
EOF
    else
        cat <<- EOF >> /etc/apt/sources.list
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
EOF
    fi
fi

if [ "$openstack_release" = "icehouse" ]; then
    DAEMONS="nova keystone cinder ceilometer heat"
    if [ $DISTRIB = ubuntu ]; then
        cat <<- EOF >> /etc/apt/sources.list
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $RELEASE-updates/$openstack_release main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $RELEASE-updates/$openstack_release main
EOF
    else
        cat <<- EOF >> /etc/apt/sources.list
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
EOF
    fi
fi

if [ "$openstack_release" = "juno" ]; then
    DAEMONS="nova keystone cinder ceilometer heat"
    if [ $DISTRIB = ubuntu ]; then
        cat <<- EOF >> /etc/apt/sources.list
        deb-src http://$APT_MIRROR/$DISTRIB $RELEASE main restricted universe multiverse
        deb-src http://$APT_MIRROR/$DISTRIB $RELEASE-security main restricted universe multiverse
        deb-src http://$APT_MIRROR/$DISTRIB $RELEASE-updates main restricted universe multiverse
        deb-src http://$APT_MIRROR/$DISTRIB $RELEASE-backports main restricted universe multiverse
EOF
    else
        cat <<- EOF >> /etc/apt/sources.list
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release main
        deb-src [arch=amd64] http://$APT_MIRROR/$DISTRIB-cloud-archive/ $openstack_release-backports main
EOF
    fi
fi

# having, or not, installed libvirt, qpid or zmq won't change the result, but better be safe than sorry
apt-get update
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install eatmydata
DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true eatmydata apt-get -y install websockify python-libvirt python-zmq python-qpid dpkg-dev eatmydata

for daemon in ${DAEMONS}
    do
        eatmydata apt-get -y source $daemon
        DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true eatmydata apt-get -y build-dep $daemon
        cd $daemon*
        DEBVERS=`dpkg-parsechangelog | sed -n -e 's/^Version: //p' | awk -F - '{print $2}' `
        VERSION=`dpkg-parsechangelog | sed -n -e 's/^Version: //p' | awk -F - '{print $1}' `
        mkdir -p /storage/tmp/$daemon/$DISTRIB-$daemon-$VERSION-$DEBVERS
        bash tools/config/generate_sample.sh -b . -p $daemon -o /storage/tmp/$daemon/$DISTRIB-$daemon-$VERSION-$DEBVERS
        dpkg -l | sort | grep -e $daemon -e oslo -e python-libvirt -e python-qpid -e python-zmq -e python-librabbitmq > /storage/tmp/$daemon/$DISTRIB-$daemon-$VERSION-$DEBVERS/dpkg
        dpkg -l | sort > /storage/tmp/$daemon/$DISTRIB-$daemon-$VERSION-$DEBVERS/dpkg-full
        cd $TEMP
done

echo FINISH!!!
exit 0
