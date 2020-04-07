#!/bin/bash

echo "---------------------------------------------------"
echo "Please check your environmental variables:"
echo "User: $USER"
echo "Password: $PASSWORD"
AR=$(echo $HOSTS | tr ":" "\n")
ITER=0
for I in ${AR[@]}
do  
  let HOSTNR=$ITER/2
  
  if ((ITER % 2 == 0)); then
    echo "Hostname$HOSTNR: $I"
  fi

  if ((ITER % 2 == 1)); then
    echo "Port$HOSTNR: $I"
  fi

  ITER=$(expr $ITER + 1)
done
echo "---------------------------------------------------"

# hash user and password (required by pgpool)
pg_md5 -m -f /etc/pgpool2/pgpool.conf -u $USER $PASSWORD

# accept all connections
sed -i "/listen_addresses/c listen_addresses='*'" /etc/pgpool2/pgpool.conf

# enable load balancing
sed -i "/load_balance_mode/c load_balance_mode=on" /etc/pgpool2/pgpool.conf

# use master-slave replication
sed -i "/master_slave_mode/c master_slave_mode=on" /etc/pgpool2/pgpool.conf
sed -i "/master_slave_sub_mode/c master_slave_sub_mode='stream'" /etc/pgpool2/pgpool.conf
sed -i "/sr_check_user/c sr_check_user='$USER'" /etc/pgpool2/pgpool.conf
sed -i "/sr_check_password/c sr_check_password='$PASSWORD'" /etc/pgpool2/pgpool.conf

# enable auto failback
sed -i "/auto_failback/c auto_failback=on" /etc/pgpool2/pgpool.conf

# delete  backends
sed -i "/backend_hostname0/c #" /etc/pgpool2/pgpool.conf
sed -i "/backend_port0/c #" /etc/pgpool2/pgpool.conf
sed -i "/backend_weight0/c #" /etc/pgpool2/pgpool.conf
sed -i "/backend_data_directory0/c #" /etc/pgpool2/pgpool.conf
sed -i "/backend_flag0/c #" /etc/pgpool2/pgpool.conf
sed -i "/backend_application_name0/c #" /etc/pgpool2/pgpool.conf

# add new backends
ITER=0
for I in ${AR[@]}
do  
  let HOSTNR=$ITER/2
  
  if ((ITER % 2 == 0)); then
    echo "backend_hostname$HOSTNR=$I" >> /etc/pgpool2/pgpool.conf
  fi

  if ((ITER % 2 == 1)); then
    echo "backend_port$HOSTNR=$I" >> /etc/pgpool2/pgpool.conf
    echo "backend_weight$HOSTNR=1" >> /etc/pgpool2/pgpool.conf
  fi

  ITER=$(expr $ITER + 1)
done

exec "$@"
