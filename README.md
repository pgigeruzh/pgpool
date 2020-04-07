# Docker Swarm Pgpool Raspberry Pi 4 ARM

# Overview

Deploy [Pgpool](https://www.pgpool.net/) on a [Raspberry Pi 4](https://www.raspberrypi.org/) using [Docker Swarm](https://docs.docker.com/engine/swarm/swarm-tutorial/create-swarm/).

This repo contains a Dockerfile and an entrypoint. The entrypoint.sh configures the pgpool on startup and should be adjusted for your own needs. A minimal configuration could be as follows:

1. Add username and password (pgpool requires a hash and provides a tool called pg_md5)

   ```bash
   pg_md5 -m -f /etc/pgpool2/pgpool.conf -u postgres password
   ```

2. Change pgpool.conf file

   ```bash
   # allow all connections (default: localhost)
   listen_addresses = "*"
   
   # add your postgres servers
   backend_hostname0 = 'postgresmaster'
   backend_port0 = 5432
   backend_weight0 = 1
   
   backend_hostname1 = 'postgresslave1'
   backend_port1 = 5432
   backend_weight1 = 1
   
   # enable load balancing
   load_balance_mode = true
   
   # use master-slave stream replication
   # (assumes an already working cluster)
   master_slave_mode = on
   master_slave_sub_mode = 'stream'
   
   # enable auto failback
   auto_failback = on
   ```

Since entrypoint.sh is a bash script, it can't easily map Docker environmental variables to pgpool.conf. For this reason, tools such as "sed" can be useful to find and replace lines in a config file. For example:

```bash
pgpool.conf (before)
--> listen_addresses='localhost'

# this replaces the line containing listen_addresses by listen_addresses='*'
sed -i "/listen_addresses/c listen_addresses='*'" /etc/pgpool2/pgpool.conf

pgpool.conf (after)
--> listen_addresses='*'
```

# Run with Docker

```bash
docker service create --name pgpool --network spark --publish 5432:5432 --env USER=postgres --env PASSWORD=password --env HOSTS=postgresmaster:5432:postgresslave1:5432:postgresslave2:5432:postgresslave3:5432 pgigeruzh/pgpool
```

"--network spark" attaches an existing network  
"--publish 5432:5432" opens port 5432  
"--env USER=postgres" environmental variable to define the Postgres user (used in entrypoint.sh)  
"--env PASSWORD=password" environmental variable to define the Postgres password (used in entrypoint.sh)  
"--env HOSTS" environmental variable to define all the Postgres servers by hostname:port (used in entrypoint.sh)  

# Build Docker Image

```bash
# build docker image
docker build -t pgigeruzh/pgpool .

# push to docker hub
docker login
docker push pgigeruzh/pgpool
```