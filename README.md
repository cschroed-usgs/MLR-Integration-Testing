MLR Integration Testing
---

This project is a working set of integration tests that may be run against
the MLR project. The tests are written using JMeter to go against a live, local MLR
stack running on the Docker engine.

#### Launching the services

Before launching the services, you will want to generate SSL certificates that the services use.

```bash
chmod +x ./create_certificates.sh && ./create_certificates.sh
```

Next, launch the services.

```bash
chmod +x launch_services.sh
./launch_services.sh
```

This script uses the `docker-compose-services.yml` config file. The script attempts to launch the entire MLR stack and will then test the stack health for several minutes. If containers are still unhealthy after the grace period, the script will bring down the stack.

#### Destroying the MLR stack

Once you're finished testing or you'd like to recreate the MLR stack running in Docker, you can destroy the stack by running the `destroy_services.sh` script after ensuring that it is executable:

```bash
chmod +x destroy_services.sh
./destroy_services.sh
```

#### Launching JMeter servers

If you will be running JMeter tests using the JMeter GUI, you can skip this section.

In order to perform the integration tests on MLR, JMeter is launched in a manager/worker configuration. First, we launch three JMeter worker containers that sit and wait for the JMeter manager to come online and provide instructions for testing. Once the testing has completed, the output files are provided back to the manager and written onto the file system. At this point, more testing may be run or the workers may be shut down.

In order to launch the JMeter worker containers, simply ensure the `launch_jmeter_servers.sh` script is executable and run it:

```bash
chmod +x launch_jmeter_servers.sh
./launch_jmeter_servers.sh
```

If this is your first time launching these containers, Docker will build the JMeter image based on the Dockerfile located @ `jmeter-docker/base/Dockerfile`.

You may see a warning about orphan containers if you're already running the MLR stack. You may disregard those warnings.

#### Destroying JMeter servers

Once your testing has completed or you'd like to bring down the JMeter worker servers, ensure that the `destroy_jmeter_servers.sh` script is executable and run it:

You may see a warning about orphan containers if you're already running the MLR stack. You may disregard those warnings.

#### Running JMeter tests via JMeter GUI

Once the MLR stack and the JMeter worker servers are up and running, you can run the JMeter tests via the JMeter GUI. Running via the GUI is the easiest way to visualize and edit the current set of tests.

Add the following entries to `/etc/hosts`.

```
127.0.0.1       mlr-int
127.0.0.1       mlr-keycloak
```

These mappings ensure that the JMeter GUI runs tests against your local services.

Ensure you have JMeter >= 5.0 installed on your system and from the root project directory, issue the following command:

`$ jmeter -p configuration/local/local.jmeter.properties`

This local properties overrides the default properties in the JMeter tests.

Note: Historically this properties file was necessary to parameterize the hostnames of the dockerized services. Now that we recommend hacking the host file, it's not clear if we need to continue to do this.

Once the JMeter GUI is loaded, you should be able to run any of the tests included in this project.

#### Running JMeter tests headless in manager/worker configuration

Once the service stack and the JMeter workers are running and healthy, you can run integration headlessly via a test plan script.

For example, to run the tests for the DDOT files...

```bash
chmod +x tests/integrations/ddot/test_plan.sh
./tests/integrations/ddot/test_plan.sh
```

Test Plan shell scripts...

* launch a manager JMeter container
* Attach the manager to the same docker network that the JMeter and MLR services stack use
* mount necessary volumes for configuration files, input files and output directories
* run the specified test by pushing the test out to the three JMeter worker nodes.
* wait for the tests to be completed
* gather the output
* put it into the `tests/output` directory on the docker host
* shut down and remove the JMeter manager container

For the ddot test output, you'd go to `tests/output/ddot/jmeter-output`

### Load Tests

In addition to the service integration tests, this project also includes a basic load test for the MLR system. The load test can be found in the `tests/integrations/load` directory. The load test is Jmeter project is setup to run a set of tests a single time, with a configurable number of users.

The load tests do include the addition of new sites into the database, and as such subsequent runs have the possibility of site collisions generating validation errors. To combat this issue the load tests work by generating a unique site number for every test that is run, starting from a configurable starting site number (because site numbers have length validation requirements the minimum starting site number is 100000000). At the time of writing the load test generates 1111 sites per user per run.

#### Running load tests headless in manager/worker configuration

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


#### Using JMeter GUI with Docker Machine

- Figure out the IP for your Docker Machine VM via `docker-machine ip <vm name>`

- Export the `DOCKER_ENGINE_IP` variable by running `export DOCKER_ENGINE_IP=<ip of Docker VM>`

- Launch MLR stack: `./launch_services.sh`

- Launch jmeter: `jmeter -p configuration/local/local.jmeter.properties`

#### Using JMeter GUI with native Docker

- Launch MLR stack: `./launch_services.sh`

- Launch jmeter: `jmeter -p configuration/local/local.jmeter.properties`

#### Using Docker manager/worker scripting

- Launch MLR stack: `./launch_services.sh`

- Launch JMeter worker stack: `./launch_jmeter_servers.sh`

- Run any JMeter test individually: `tests/integrations/<test name>/test_plan.sh`

#### Destroying JMeter worker stack

- `./destroy_jmeter_servers.sh`

#### Destroying MLR stack

- `./destroy_services.sh`
