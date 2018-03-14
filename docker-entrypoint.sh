#!/bin/bash
export PATH="/usr/local/nvidia/bin:$PATH"
export PATH="/usr/local/cuda:$PATH"
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/extras/CUPTI/lib64
set -e

if [ "$1" = "slurmdbd" ]
then
    echo "---> Starting nslcd ldap client daemon ..."
    /usr/sbin/nslcd

    echo "---> Starting the MUNGE Authentication service (munged) ..."
    gosu munge /usr/sbin/munged

    echo "---> Starting the Slurm Database Daemon (slurmdbd) ..."

    until echo "SELECT 1" | mysql -h mysql -uslurm -ppassword 2>&1 > /dev/null
    do
        echo "-- Waiting for database to become active ..."
        sleep 2
    done
    echo "-- Database is now active ..."

    exec gosu slurm /usr/sbin/slurmdbd -Dvvv
fi

if [ "$1" = "slurmctld" ]
then
    echo "---> Starting nslcd ldap client daemon ..."
    /usr/sbin/nslcd

    echo "---> Starting the sshd daemon ..."
    /usr/sbin/sshd -p22

    echo "---> Starting the MUNGE Authentication service (munged) ..."
    gosu munge /usr/sbin/munged

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819
    do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."
    exec gosu slurm /usr/sbin/slurmctld -Dvvv
fi

if [ "$1" = "slurmd" ]
then
    echo "---> Starting nslcd ldap client daemon ..."
    /usr/sbin/nslcd

    echo "---> Starting the MUNGE Authentication service (munged) ..."
    gosu munge /usr/sbin/munged

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817
    do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    echo "---> Setting up Gres ..."
    printf "NAME=gpu Type=P100 File=`find /dev/ -name "nvidia?"` CPUs=0-3\n" > /etc/slurm/gres.conf

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec /usr/sbin/slurmd -Dvvv
fi

exec "$@"
