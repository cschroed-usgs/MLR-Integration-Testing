MLR Integration Testing
---

This project is a working set of integration tests that may be run against
the MLR project. The tests are written using JMeter to go against a live, local MLR
stack running on the Docker engine.

#### Running the MLR stack When not on the USGS network

Feel free to skip this section if you are on the USGS network.

The MLR project is a set of Docker images that are served from an Artifactory instance within the Water Mission Area's data center. Through a reverse proxy setup, users on the USGS network are able to point their Docker engine at the Artifactory instance using the internal address to pull images (e.g. `cidasdpdasartip.cr.usgs.gov:8447/mlr/mlr-legacy-db:latest`). As such, no routing magic needs to happen on the user's machine in order to pull the images needed. However, when not on the USGS network, a developer must still be able to pull hosted images from Artifactory. In order to accomplish this, we use a running NGINX Docker container as a reverse proxy for localhost to point to `https://cida.usgs.gov/artifactory/api/docker/owi-docker/v2/` to pull the needed Docker images. This is required because the Docker engine only will pull images against a host at the root context or at a specific port. Therefore Docker cannot pull from `cida.usgs.gov/artifactory/api/docker/owi-docker/v2/` but can from `localhost` which NGINX proxies to Artifactory.

Ensure that the script to pull the images is executable:

`$ chmod +x pull-containers.sh`

Then execute the script:

`$ ./pull-containers.sh`

The script will first create the SSL certificates needed by NGINX to serve as an SSL enabled reverse proxy. It will then launch NGINX, sleep for 5 seconds to give NGINX time to come up and then will use NGINX to pull the images. The script will then shut down NGINX.

The SSL certificates created are stored in the `ssl/` subdirectory. These certificates are part of the `.gitignore` file so they are not checked in.

### Launching the services

If you are using Docker Machine and your Docker engine does not run on localhost, before launching the service stack, make sure that you create and export the `DOCKER_ENGINE_IP` variable in bash, setting it to the IP address of your Docker VM. This ensures that the launch script properly sets up the mock S3 bucket also running in a Docker container by ending curl commands to it. Using the following command properly exports the variable in bash. Don't forget to substitute the name of your Docker machine in the marked portion of the command:

```
$ export DOCKER_ENGINE_IP=`docker-machine ip <machine name>`
```

Also, if you will be running the JMeter tests using the JMeter GUI instead of running the tests via a master/slave configuration with a secondary stack of JMeter containers, you will want to edit one or two other files.

First, if you are using Docker Machine, edit `configuration/local/local.jmeter.properties` and replace `localhost` with the IP if your Docker VM. You can get that by running `docker-machine ip <machine name>` and subtituting the name of your VM that is running the Docker engine. If you are running native Docker, you can skip this.

Second, edit `configuration/local/config/common/config.env`. In this file you will want to substitute the `water.auth.server` domain with the IP of your Docker engine. This will either be localhost if not running on Docker Machine or the IP of your Docker VM. You can get that by running `docker-machine ip <machine name>` and subtituting the name of your VM that is running the Docker engine.

Also, before launching the services, you will want to generate SSL certificates that the services use. If you've already run the script to pull the containers from Artifactory, you won't need to do this here. Otherwise:

```
$ chmod +x ./create_certificates.sh && ./create_certificates.sh
```

In order to launch all of the required services, ensure that the "launch_services.sh" script is executable and run it:

```
$ chmod +x launch_services.sh`
$ ./launch_services.sh
```

This script uses the `docker-compose-services.yml` config file to launch the MLR stack as well as two helper containers. One is a mock SMTP server that is required for the mlr-notification service to run. The other is a mock S3 bucket that is also used by MLR services.

When run, the script will attempt to launch the entire MLR stack and will then test the stack health for four minutes. If within four minutes any of the containers running in the stack are still unhealthy, the script will bring down the stack. If you are experiencing issues with the stack not coming up properly, some of the things you may look into is whether or not you have allocated enough RAM to the stack. On my system, I allocate two CPUs and about 5GB of RAM to Docker. Once running, this is what the stack status looks like:

```
$ docker stats

$ docker stats --no-stream
CONTAINER ID        NAME                                    CPU %               MEM USAGE / LIMIT     MEM %               NET I/O             BLOCK I/O           PIDS
4d1098dfbfb8        mlr-gateway                             0.61%               341.1MiB / 5.825GiB   5.72%               19.5kB / 17.9kB     0B / 2.06MB         36
36308208da57        mlr-legacy                              0.10%               292.3MiB / 5.825GiB   4.90%               15kB / 12.9kB       0B / 557kB          32
b6aa2baa90ba        mlr-ddot-ingester                       0.78%               43.75MiB / 5.825GiB   0.73%               5.9kB / 2.86kB      0B / 283kB          4
e1d9ed51f803        mlr-legacy-transformer                  0.67%               44.02MiB / 5.825GiB   0.74%               5.87kB / 2.78kB     0B / 283kB          4
7cb59bef8d4f        mlr-validator                           0.64%               63.95MiB / 5.825GiB   1.07%               5.87kB / 2.78kB     0B / 283kB          4
9732ee65fd25        mlr-notification                        0.18%               297.1MiB / 5.825GiB   4.98%               8.95kB / 5.8kB      0B / 557kB          31
50aa6533bb83        mlr-wsc-file-exporter                   0.69%               48.02MiB / 5.825GiB   0.81%               5.94kB / 2.86kB     0B / 283kB          4
d5d05d848622        water-auth-server                       0.11%               486.1MiB / 5.825GiB   8.15%               23.7kB / 30.6kB     0B / 147kB          31
ce79713e1782        mlr-integration-testing_mock-s3_1       0.08%               116.3MiB / 5.825GiB   1.95%               2.79kB / 491B       0B / 0B             22
91ede6402494        mlr-integration-testing_smtp-server_1   0.07%               23.4MiB / 5.825GiB    0.39%               4.69kB / 2.82kB     0B / 0B             15
2b3049c69261        mlr-legacy-db                           2.52%               20.05MiB / 5.825GiB   0.34%               26.4kB / 22.9kB     0B / 136MB          17
```

Given these specs, the stack starts and shows as healthy on my system in about 80 seconds.

Once the script has verified that all of the containers are running successfully, it will also create a mock S3 bucket in the S3 container and exit.

An abbreviated example of the script running looks like:

```
$ ./launch_services.sh
Launching MLR services...
Creating network "mlr-it-net" with the default driver
Creating water-auth-server                     ... done
Creating mlr-integration-testing_smtp-server_1 ... done
Creating mlr-legacy-db                         ... done
Creating mlr-integration-testing_mock-s3_1     ... done
Creating mlr-validator                         ... done
Creating mlr-legacy-transformer                ... done
Creating mlr-ddot-ingester                     ... done
Creating mlr-notification                      ... done
Creating mlr-legacy                            ... done
Creating mlr-wsc-file-exporter                 ... done
Creating mlr-gateway                           ... done
Testing service health. Attempt 1 of 240
Services still not healthy: mlr-gateway mlr-legacy mlr-notification mlr-legacy-transformer mlr-ddot-ingester mlr-validator mlr-wsc-file-exporter mlr-legacy-db water-auth-server
Testing service health. Attempt 2 of 240
Services still not healthy: mlr-gateway mlr-legacy mlr-notification mlr-legacy-transformer mlr-ddot-ingester mlr-validator mlr-wsc-file-exporter mlr-legacy-db water-auth-server
Testing service health. Attempt 3 of 240

[...]

Testing service health. Attempt 49 of 240
Services still not healthy: mlr-gateway mlr-legacy mlr-notification
All services healthy: mlr-gateway mlr-notification mlr-validator mlr-legacy mlr-wsc-file-exporter mlr-ddot-ingester mlr-legacy-transformer mlr-legacy-db water-auth-server
Creating test s3 bucket...
Bucket created successfully
```

#### Destroying the MLR stack

Once you're finished testing or you'd like to recreate the MLR stack running in Docker, you can destroy the stack by running the `destroy_services.sh` script after ensuring that it is executable:

```
$ chmod +x destroy_services.sh
$ ./destroy_services.sh
$ ./destroy_services.sh
Bringing down MLR services...
Stopping mlr-gateway                           ... done
Stopping mlr-notification                      ... done
Stopping mlr-validator                         ... done
Stopping mlr-legacy                            ... done
Stopping mlr-wsc-file-exporter                 ... done
Stopping mlr-ddot-ingester                     ... done
Stopping mlr-legacy-transformer                ... done
Stopping mlr-legacy-db                         ... done
Stopping mlr-integration-testing_mock-s3_1     ... done
Stopping mlr-integration-testing_smtp-server_1 ... done
Stopping water-auth-server                     ... done
Removing mlr-gateway                           ... done
Removing mlr-notification                      ... done
Removing mlr-validator                         ... done
Removing mlr-legacy                            ... done
Removing mlr-wsc-file-exporter                 ... done
Removing mlr-ddot-ingester                     ... done
Removing mlr-legacy-transformer                ... done
Removing mlr-legacy-db                         ... done
Removing mlr-integration-testing_mock-s3_1     ... done
Removing mlr-integration-testing_smtp-server_1 ... done
Removing water-auth-server                     ... done
Removing network mlr-it-net
Done
```

#### Launching JMeter slave servers

If you will be running JMeter tests using the JMeter GUI, you can skip this section.

In order to perform the integration tests on MLR, JMeter is launched in a master/slave configuration. First, we launch three JMeter slave containers that sit and wait for the JMeter master to come online and provide instructions for testing. Once the testing has completed, the output files are provided back to master and written onto the file system. At this point, more testing may be run or the slaves may be shut down.

In order to launch the JMeter slave containers, simply ensure the `launch_jmeter_servers.sh` script is executable and run it:

```
$ chmod +x launch_jmeter_servers.sh
$ ./launch_jmeter_servers.sh
```

If this is your first time launching these containers, Docker will build the JMeter image based on the Dockerfile located @ `jmeter-docker/base/Dockerfile`. This Dockerfile builds a JMeter Docker image using version 5.0 of JMeter downloaded from Apache.

You may see a warning about orphan containers if you're already running the MLR stack. You may disregard those warnings.

#### Destroying JMeter slave servers

Once your testing has completed or you'd like to bring down the JMeter slave servers, ensure that the `destroy_jmeter_servers.sh` script is executable and run it:

```
$ chmod +x destroy_jmeter_servers.sh
$ ./destroy_jmeter_servers.sh
$ ./destroy_jmeter_servers.sh

Bringing down JMeter server services...
Stopping mlr-integration-testing_jmeter-server-2_1 ... done
Stopping mlr-integration-testing_jmeter-server-3_1 ... done
Stopping mlr-integration-testing_jmeter-server-1_1 ... done
WARNING: Found orphan containers (mlr-gateway, mlr-legacy, mlr-ddot-ingester, mlr-legacy-transformer, mlr-validator, mlr-notification, mlr-wsc-file-exporter, water-auth-server, mlr-integration-testing_mock-s3_1, mlr-integration-testing_smtp-server_1, mlr-legacy-db) for this project. If you removed or renamed this service in your compose file, you can run this command with the --remove-orphans flag to clean it up.
Removing mlr-integration-testing_jmeter-server-2_1 ... done
Removing mlr-integration-testing_jmeter-server-3_1 ... done
Removing mlr-integration-testing_jmeter-server-1_1 ... done
Network mlr-it-net is external, skipping
Done
```

You may see a warning about orphan containers if you're already running the MLR stack. You may disregard those warnings.

#### Running JMeter tests via JMeter GUI

Once the MLR stack and the JMeter slave servers are up and running, you can run the JMeter tests via the JMeter GUI. Running via the GUI is the easiest way to visualize and edit the current set of tests.

Ensure you have JMeter >= 5.0 installed on your system and from the root project directory, issue the following command:

`$ jmeter -p configuration/local/local.jmeter.properties`

We use this local properties file as a source for key value pairs to override the default properties in the JMeter tests. The reason is that the JMeter tests include hostnames that only make sense if running the JMeter tests from within the Docker stack network that's created when the services stack is launched. That's what we do when we run the master/slave configuration for JMeter but when running with the JMeter GUI, we end up using the IP address of the Docker engine itself (localhost or the IP address of the docker machine VM)

Once the JMeter GUI is loaded, you should be able to run any of the tests included in this project.

#### Running JMeter tests headless in master/slave configuration

Each integration test also comes with a shell script that launches. Once you have the service stack running and healthy and you've launched the JMeter slaves, you can run the testing script for any of the included tests.

For example, to run the test for the DDOT files, ensure that the script to do so is executable and then run it:

```
$ chmod +x tests/integrations/ddot/test_plan.sh
$ tests/integrations/ddot/test_plan.sh
Dec 12, 2018 10:15:09 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
Creating summariser <summary>
Created the tree successfully using /tests/integrations/ddot/ddot.jmx
Configuring remote engine: jmeter.server.1
Using local port: 60000
Configuring remote engine: jmeter.server.2
Configuring remote engine: jmeter.server.3
Starting remote engines
Starting the test @ Wed Dec 12 22:15:12 UTC 2018 (1544652912143)
Remote engines have been started
Waiting for possible Shutdown/StopTestNow/Heapdump message on port 4445
summary =    300 in 00:00:11 =   27.3/s Avg:    23 Min:     3 Max:   354 Err:     0 (0.00%)
Tidying up remote @ Wed Dec 12 22:15:26 UTC 2018 (1544652926912)
... end of run
```

What happens during the run is the shell script launches a master JMeter container, attaches it to the network that the jmeter and MLR services stack runs on, mounts necessary volumes for configuration files, input files and output directories, and runs the specified test by pushing the test out to the three JMeter slave nodes.

It then waits for the tests to be completed, gathers the output, puts it into the `tests/output` directory in the project and shuts down and removes the master JMeter container.

For the ddot test output, you'd go to `tests/output/ddot/jmeter-output`

### Load Tests

In addition to the service integration tests, this project also includes a basic load test for the MLR system. The load test can be found in the `tests/integrations/load` directory. The load test is Jmeter project is setup to run a set of tests a single time, with a configurable number of users. 

The load tests do include the addition of new sites into the database, and as such subsequent runs have the possibility of site collisions generating validation errors. To combat this issue the load tests work by generating a unique site number for every test that is run, starting from a configurable starting site number (because site numbers have length validation requirements the minimum starting site number is 100000000). At the time of writing the load test generates 1111 sites per user per run.

#### Running load tests headless in master/slave configuration

The load tests include a headless test plan script similar to the service integration tests described above. This script is configured to run the load test 5 times with `1`, `4`, `8`, `16`, and `32` users, and because this projec is setup to run headless tests on 3 separate testing servers this results in the tests actually consisting of `3`, `12`, `24`, `48`, and `96` users. The headless load tests will output their results into the `tests/output/load/` directory and into total-user-specific sub-directories (i.e: `tests/output/load/3/`). |

In order to prevent site collisions during headless runs the jmeter test also uses specific configuration to create a site number offset for each of the servers. The headless servers are named as `jmeter.server.1`, `jmeter.server.2`, and `jmeter.server.3` when created so the load test project takes the last character of the server name (`1`, `2`, and `3`) and uses that to offset the sites generated by the test accordingly. In the load test Jmeter project this is referred to as the `LOAD_SITE_PREFIX`. During the course of the `test_plan` script the starting site number is incremented with each test by the formula `STARTING_SITE_NUMBER = STARTING_SITE_NUMBER + (LOAD_TEST_SERVER_COUNT * LOAD_TEST_USER_COUNT * SITES_ADDED_PER_USER)`.

Subsequent runs of the load `test_plan` script should either modify the starting site number to a value large enough to prevent site collisions with previous runs or should bring the stack down and back up to clear out the database.

#### Running load tests in the Jmeter GUI

Jmeter discourages running load tests through the GUI because the GUI processes slow down the rate at which Jmeter runs its requests, which results in inaccurate load testing results. However, during load test development it is fine to run tests through the GUI. In order to run the load tests through the Jmeter GUI you should start Jmeter in the manner described above for running integration tests in the GUI (`$ jmeter -p configuration/local/local.jmeter.properties`). When started this way the `LOAD_SITE_PREFIX` value described in the previous section is set to `1`. To prevent site collisions on subsequent runs through the Jmeter GUI you should modify the global configuration value of the `STARTING_SITE_NUMBER` so that it is large enough to prevent site collisions with the previous run. The number of users to run the test plan with can also be changed in the global configuration settings at the top of the test plan.

Note that because tests are only being run through the GUI the number of users per run is not multipled by 3 as it is in headless mode.

### TL;DR

Before running any script, ensure it's executable by issuing the chmod command against it: `chmod +x <script path>`

#### Create necessary SSL certificates used in this project

- `chmod +x create_certificates.sh && ./create_certificates.sh`

#### Working off of the USGS network

- `./pull-containers.sh`

#### Using JMeter GUI with Docker Machine

- Figure out the IP for your Docker Machine VM via `docker-machine ip <vm name>`

- Edit `configuration/local/config/common/config.env` and replace `water.auth.server` with IP of Docker VM

- Edit `configuration/local/local.jmeter.properties` and replace `localhost` with IP of Docker VM

- Export the `DOCKER_ENGINE_IP` variable by running `export DOCKER_ENGINE_IP=<ip of Docker VM>`

- Launch MLR stack: `./launch_services.sh`

- Launch jmeter: `jmeter -p configuration/local/local.jmeter.properties`

#### Using JMeter GUI with native Docker

- Edit `configuration/local/config/common/config.env` and replace `water.auth.server` with `localhost`

- Launch MLR stack: `./launch_services.sh`

- Launch jmeter: `jmeter -p configuration/local/local.jmeter.properties`

#### Using Docker Master/Slave scripting

- Launch MLR stack: `./launch_services.sh`

- Launch JMeter Slave stack: `./launch_jmeter_servers.sh`

- Run any JMeter test individually: `tests/integrations/<test name>/test_plan.sh`

#### Destroying JMeter slave stack

- `./destroy_jmeter_servers.sh`

#### Destroying MLR stack

- `./destroy_services.sh`
