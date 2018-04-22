# About Latte

Latte is a GPU server, donated in part by NVIDIA Corp. for use by the CS community. It features 8 datacenter-class [NVIDIA Tesla P100 GPUs][2], which offer a large speedup for machine learning and related GPU computing tasks. The Tensorflow and PyTorch libraries are available for use as well.

## User Guide

### Getting Started

To begin using `latte`, you need to first have a CSUA account and be a member of the `ml2018` group. You can check if you are a member by logging into `soda.csua.berkeley.edu` and using the `id` command.

To get a CSUA account, please visit our office in 311 Soda and an officer will create an account for you.

To get into the `ml2018` group, send an email to [latte@csua.berkeley.edu][3] with the following:

- Name
- CSUA Username
- Intended use

Once we receive your email, we will give you access to the group.

Once you have an account, you can log into `latte.csua.berkeley.edu` over SSH. This will bring you into the `slurmctld` machine. From here, you can begin setting up your jobs.

### Testing Your Jobs

`slurmctld` is meant for testing only. There are limits to the amount of compute you can use while in this machine.

The `/datasets/` directory has some publicly-available datasets to use in `/datasets/share/`. If you are using your own dataset, please place them in `/datasets/` because the contents of `/home/` are mounted over a network filesystem and __will__ be slower.

Once you run your program and it works, you can submit a job.

### Running Your Jobs

Slurm is used to manage the job scheduling on `latte`.

To run a job, you need to submit it using the `srun` command. [You can read about how to use Slurm here][1].

This will send the job to one of the GPU nodes and run the job.

### Contact

If you have any questions, please email [latte@csua.berkeley.edu][3].

[1]: https://slurm.schedmd.com/quickstart.html
[2]: http://www.nvidia.com/object/tesla-p100.html
[3]: mailto:latte@csua.berkeley.edu

## Developer Guide

This repo contains the configurations used to test and deploy the slurm docker cluster known as `latte`. The important commands can be found in the contents of `Makefile`.

The cluster is created using `docker-compose`, specifically using `nvidia-docker-compose`. There are a number of other pieces of software involved, however.

### How docker-compose works

(Copied from <https://docs.docker.com/compose/overview/> )

Compose is a tool for defining and running multi-container Docker applications. With Compose, you use a YAML file to configure your application’s services. Then, with a single command, you create and start all the services from your configuration.

Using Compose is basically a three-step process:

1. Define your app’s environment with a `Dockerfile` so it can be reproduced anywhere.

2. Define the services that make up your app in `docker-compose.yml` so they can be run together in an isolated environment.

3. Run `docker-compose up` and Compose starts and runs your entire app.

### About the Makefile

The `Makefile` describes all the necessary commands for building and testing the cluster.

## Slurm Docker Cluster (Documentation from original Repo)

This is a multi-container Slurm cluster using docker-compose.  The compose file
creates named volumes for persistent storage of MySQL data files as well as
Slurm state and log directories.

### Containers and Volumes

The compose file will run the following containers:

* `mysql`
* `slurmdbd`
* `slurmctld`
* `c1 (slurmd)`
* `c2 (slurmd)`

The compose file will create the following named volumes:

* etc_munge         ( -> /etc/munge     )
* etc_slurm         ( -> /etc/slurm     )
* slurm_jobdir      ( -> /data          )
* var_lib_mysql     ( -> /var/lib/mysql )
* var_log_slurm     ( -> /var/log/slurm )

### Building the Docker Image

Build the image locally:

```console
$ docker build -t slurm-docker-cluster:17.02.9 .
```

### Starting the Cluster

Run `docker-compose` to instantiate the cluster:

```console
$ docker-compose up -d
```

### Register the Cluster with SlurmDBD

To register the cluster to the slurmdbd daemon, run the `register_cluster.sh`
script:

```console
$ ./register_cluster.sh
```

> Note: You may have to wait a few seconds for the cluster daemons to become
> ready before registering the cluster.  Otherwise, you may get an error such
> as **sacctmgr: error: Problem talking to the database: Connection refused**.
>
> You can check the status of the cluster by viewing the logs: `docker-compose
> logs -f`

### Accessing the Cluster

Use `docker exec` to run a bash shell on the controller container:

```console
$ docker exec -it slurmctld bash
```

From the shell, execute slurm commands, for example:

```console
[root@slurmctld /]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
normal*      up 5-00:00:00      2   idle c[1-2]
```

### Submitting Jobs

The `slurm_jobdir` named volume is mounted on each Slurm container as `/data`.
Therefore, in order to see job output files while on the controller, change to
the `/data` directory when on the **slurmctld** container and then submit a job:

```console
[root@slurmctld /]# cd /data/
[root@slurmctld data]# sbatch --wrap="uptime"
Submitted batch job 2
[root@slurmctld data]# ls
slurm-2.out
```

### Stopping and Restarting the Cluster

```console
$ docker-compose stop
```

```console
$ docker-compose start
```

### Deleting the Cluster

To remove all containers and volumes, run:

```console
$ docker-compose rm -sf
$ docker volume rm slurmdockercluster_etc_munge slurmdockercluster_etc_slurm slurmdockercluster_slurm_jobdir slurmdockercluster_var_lib_mysql slurmdockercluster_var_log_slurm
```
