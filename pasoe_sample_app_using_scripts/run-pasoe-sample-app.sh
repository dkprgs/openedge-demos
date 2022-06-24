#!/bin/bash

export DLC=/psc/dlc
export PATH=$PATH:$DLC/bin

if [ -f /usr/bin/podman ]
then
  export DOCKER_HOST="unix:$XDG_RUNTIME_DIR/podman/podman.sock"
fi

export PUBLIC_IP_ADDRESS=13.58.191.210
export PRIVATE_IP_ADDRESS=172.31.38.81

export TERM=vt100

if [ ! -f /psc/wrk/sports.db ]
then
  cd /psc/wrk/
  prodb sports sports2000
fi

if [ ! -f /psc/wrk/sports.lk ]
then
  cd /psc/wrk/
  proserve sports -S 20000
fi

if [ ! -s ~/pasoe-sample-app/Sports/conf/startup.pf ]
then
  echo -db sports -H $PRIVATE_IP_ADDRESS -S 20000 > ~/pasoe-sample-app/Sports/conf/startup.pf
fi

if [ ! -f ~/pasoe-sample-app/Sports/output/package-output/Sports.zip ]
then
  cd ~/pasoe-sample-app/Sports/
  proant package
fi  

if fgrep '<Place_IP_Address_of_Docker_Host>' ~/pasoe-sample-app/webui/grid.js > /dev/null
then
  sed -i "/<Place_IP_Address_of_Docker_Host>/s//${PUBLIC_IP_ADDRESS}/" ~/pasoe-sample-app/webui/grid.js
fi

if [ ! -f ~/pasoe-sample-app/deploy/ablapps/Sports.zip ]
then
  cd ~/pasoe-sample-app/
  cp ./Sports/output/package-output/Sports.zip ./deploy/ablapps/
fi

cd ~/pasoe-sample-app/
cp ./config.properties ./deploy/config.properties
sed -i '/12.2.3/s//12.2.9/' ~/pasoe-sample-app/deploy/config.properties
sed -i '/JDK.DOCKER.IMAGE.NAME=adoptopenjdk/s//JDK.DOCKER.IMAGE.NAME=docker.io\/adoptopenjdk/' ~/pasoe-sample-app/deploy/config.properties

cd ~/pasoe-sample-app/
cp ./fluentbit/conf/fluent-bit-output.conf ./deploy/conf/logging/
sed -i "/<Place_IP_Address_of_Elastic_Host>/s//${PRIVATE_IP_ADDRESS}/" ~/pasoe-sample-app/deploy/conf/logging/fluent-bit-output.conf

cp /psc/dlc/progress.cfg ~/pasoe-sample-app/deploy/license/

if docker ps | fgrep oepas1_pasoeinstance_dc
then
  echo PASOE instance is already running
else
  cd ~/pasoe-sample-app/deploy/
  proant deploy
fi

sudo sysctl -w vm.max_map_count=262144

cd ~/pasoe-sample-app/
sed -i '/^    image: nginx/s//    image: docker.io\/nginx/' ~/pasoe-sample-app/docker-compose.yaml
sed -i '/^    links:/s//#    links:/' ~/pasoe-sample-app/docker-compose.yaml
sed -i '/^    - "elasticsearch"/s//#    - "elasticsearch"/' ~/pasoe-sample-app/docker-compose.yaml
docker-compose up -d

