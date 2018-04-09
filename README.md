# docker-rabbitmq-cluster
Docker file and scripts to start a RabbitMQ cluster. There is also a docker-compose template to ease the deployment of multiple containers. This image allows to customize certain parts of the RabbitMQ deployment through variables.

## Deploying your RabbitMQ Cluster

This section describes how to deploy a RabbitMQ cluster **without using Compose**. The recommended way is using [docker-compose](#using-docker-compose) tool and customizing the templates. It is advised to continue reading this section to understand the variables and requirements of this image.

Starting a container with a RabbitMQ with docker requires, at the very least, the following parameters:

- `RABBITMQ_ERLANG_COOKIE` -- This can be any string (e.g. 'secret'). Make sure it is the same for **all the nodes**
- Hostname for the container. This is necessary because RabbitMQ uses the hostname to set the RabbitMQ Node

An example to start a RabbitMQ disc node would be:

```
 docker run --hostname server1 -e RABBITMQ_ERLANG_COOKIE="secret" --name rabbitmq-server1 -p 15672:15672 zerpetfakename/rabbitmq-cluster:3.6
```

This command launches a single instance of a RabbitMQ node and forwards the port in `15672` in the localhost to the container. This port can be used to access the management UI in a browser using `127.0.0.1:15672`.

Once the first node is up and running, the second node has to be *linked* to the first node and it must include the variable `RABBITMQ_ERLANG_COOKIE` with the **same value** as the first node. An example would be:

```
docker run --hostname server2 --name rabbitmq-server2 -e CLUSTER_WITH=server1 -e RABBITMQ_ERLANG_COOKIE="secret" -p 15673:15672 --link rabbitmq-server1:server1 zerpetfakename/rabbitmq-cluster:3.6
```

The second node should start up normally; once the RabbitMQ node is started, the script to join the cluster will wait for 20 seconds to allow initialization of the node; then it will add the node to the cluster if it's not already part of it.

Adding a third node is possible specifying the same Erlang cookie and links to the previous two nodes. It is also possible to specify a RAM node using the variable `ENABLE_RAM=true`. An example of a command to spawn a third node would be:

```
docker run -e ENABLE_RAM=true --hostname server3 --name rabbitmq-server3 -e CLUSTER_WITH=server1 -e RABBITMQ_ERLANG_COOKIE="secret" -p 15674:15672 --link rabbitmq-server1:server1 --link rabbitmq-server2:server2 zerpetfakename/rabbitmq-cluster:3.6
```

Once the node is started, it will check if it's part of a cluster and it will join if it's not a member already. Please review the [limitations](#limitations) section to learn about a known limitation with RAM nodes.

The command to spawn nodes individually will be getting more complex as more nodes are added since the new container has to be linked to the existing ones. [Compose](#using-docker-compose) solves this complexity.


## Using docker-compose

In the folder `compose-templates` there are a few YAML templates to help using `docker-compose` to spawn the cluster. The aim of Compose is to ease the deployment and reduce the complexity of the commands required to launch the cluster.

The templates for 3-disc nodes and 2-disc 1-ram nodes are ready to use. If you want to use any of these templates, this command will get the cluster up and running within 30 seconds:

```
docker-compose -p my-cluster -f compose-templates/3-disc-nodes.yml up -d
```

The logs of nodes 2 and 3 will show the progress of the initialization process:

```
docker logs --follow mycluster_rabbitmq-server2_1
```

The shell variable `rabbitmq_version` is mandatory, otherwise compose will exit with an error. The template can be modified to change the variable into a specific version to avoid setting the shell variable.

The subcommand `ps` for Compose will show the status of the containers and the forwards of the ports:

```
docker-compose -p my-cluster -f compose-templates/3-disc-nodes.yml ps
```

The management UI is available in all the nodes and it is forwarded to the local port 15672-15674.

### Clean up

Compose offers the command `down` to stop and remove the containers and network/s created in the project. A command as the following will do a "clean up":

```
docker-compose -p my-cluster -f compose-templates/3-disc-nodes.yml down
```

The version variable is not mandatory here. If avoided, Compose will print a warning and proceed.

## Using a sample producer and consumer

There is a template named "consumer-producer.yml" that includes a RabbitMQ cluster with 2 disc nodes and 1 RAM nodes, a producer and a consumer. The producer and consumer are basic examples in Python from [this repo](https://github.com/damianogiorgi/pythonrabbitmqexample).

The piece of YAML to add a new producer node is similar to this one:

```
services:
  [...]
  rabbitmq-producer:
	  image: "damiano7pixel/pyrabbitmqproducer"
	  environment:
	    - RABBITMQ_HOST=rabbitmq-master-server
	    - RABBITMQ_QUEUE=messages
	    - PRODUCER_SLEEP_TIME=0.1
	  depends_on:
	    - rabbitmq-master-server
	  tty: 'true'
```

The consumer is configured in the same way, just changing the image to `image: "damiano7pixel/pyrabbitmqconsumer"`.

The variable `CONSUMER_SLEEP_TIME` allows to set the ratio between consumer/producer. For example, a producer with a sleep time of `0.1` and a consumer with a sleep time of `0.2` will produce more messages than messages consumed (because the producer publishes every 0.1 seconds and the consumer consumes every 0.2 seconds). Setting these variables at the same value in both consumer and producer will create an "even" production/consumption rate.

## Altering the template

### How to add an additional node?
In the template, you have to add an additional section under the `services` section. It is **important** to set the **same Erlang cookie** as the other nodes in the cluster, otherwise the node will fail to join the cluster. The following is an example of the additional node; it is recommended to adjust this to your environment.

```
services:
  [...]
  my-additional-rabbitmq-node:
    environment:
      CLUSTER_WITH: rabbit@rabbitmq-master-server
      RABBITMQ_ERLANG_COOKIE: secret
    hostname: my-additional-rabbitmq-node
    image: zerpetfakename/rabbitmq-cluster:${rabbitmq_version}
    ports:
    - 12345:5672
    - 43210:15672
```

### How to make a node a RAM node?
Simply add the environment variable `ENABLE_RAM` and set it to `'true'`. Please note that it's advised to escape the boolean value `'true'` to avoid misinterpretation by the YAML engine in Docker. It should look similar to this snippet:

```
services:
  [...]
  my-node:
    environment:
      [...]
      ENABLE_RAM: 'true'
    [...]
```


## Version information

<!--Add information on the Erlang version and RabbitMQ versions-->

This table shows the Rabbit and Erlang versions in each Docker image:

| Image version | Erlang version | RabbitMQ version |
|---------------|----------------|------------------|
| 3.6           | 19.2.1         | 3.6.15           |
| 3.7           | 20.2.4         | 3.7.4            |

## Dockerfile reference

This section contains the environment variables that can be used to customize the deployment. 

- `NODENAME`: String ( default: _rabbit_ )
- `ENABLE_RAM` -> Boolean ( default: _false_ )
- `CLUSTER_WITH` -> String ( empty/no default )
- `RABBITMQ_ERLANG_COOKIE` -> String ( random generated )
- `RABBITMQ_DEFAULT_USER` -> String ( default: _guest_ )
- `RABBITMQ_DEFAULT_PASS` -> String ( default: _guest_ )
- `RABBITMQ_DEFAULT_VHOST` -> String ( default: _"/"_ )
- `RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` -> String ( empty/no default )

Explain the importance of `RABBITMQ_ERLANG_COOKIE`.

## Limitations

### There must be at least 2 disc nodes
This is a limitation in the entry point script. The entry point checks if the number of running disc nodes in the cluster is exactly 1. This is the case when you start a bran new broker: there is 1 disc node and 0 ram nodes in the cluster. Once you join a cluster as a disc node, the `rabbitmqctl cluster_status` will report 2 disc nodes as part of the cluster. In such condition, the entry point script will skip the cluster joining step (because we are already part of the cluster).

This limitation affects the ability to restart the RabbitMQ cluster. If there is only 1 disc node, upon cluster restart, RAM nodes will fail to join the cluster and require manual intervention (`stop_app` + `start_app`) to come up and join the cluster.

### Docker node name and hostname must be the same
This is more a limitation on how RabbitMQ clustering works. The broker is expecting a node name as `node_name@hostname`. The way `docker-compose` works, the containers are accessible to each other by node name. If the hostname is not explicitly set to the node name, the node might end up in a situation where `Broker_1` connects to `rabbit@broker2`, however `my_other_broker` hostname is not `broker2`, so it causes `Broker_1` to reject the node joining the cluster.

#### Workaround to this limitation ☝️
You can use Docker links to workaround this limitation. However, Docker links have been deprecated and are not recommended to use. With this workaround, every new created container must have links to the previous existing containers and use a link alias equal to the hostname specified. *This workaround is not recommended.*

### MQTT and STOMP ports are not exposed
By default, RabbitMQ base image does not enable MQTT and STOMP plugins, therefore there was no need to expose those ports. If there is a requirement to use this ports, the image has to be recompiled to expose these ports and the plugins have to be enabled.

----

Inspired in [webratio/rabbitmq-cluster](https://github.com/webratio/docker) and [harbur/docker-rabbitmq-cluster](https://github.com/harbur/docker-rabbitmq-cluster).

Thanks to user "damianogiorgi" for sharing the consumer and producer Python [example](https://github.com/damianogiorgi/pythonrabbitmqexample).