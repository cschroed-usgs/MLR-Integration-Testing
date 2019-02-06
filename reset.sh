#!/bin/bash
echo "Restarting MLR..."

bash destroy_jmeter_servers.sh
bash destroy_services.sh
bash launch_services.sh
bash launch_jmeter_servers.sh

echo "MLR successfully started"
