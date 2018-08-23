# docker-rabbitmq-cluster
Docker file and scripts to start a RabbitMQ cluster. There is also a docker-compose template to ease the deployment of multiple containers. This image allows to customize certain parts of the RabbitMQ deployment through variables.

Check out the [Wiki](https://github.com/Zerpet/docker-rabbitmq-cluster/wiki) page to get started with the image.

## Version information

<!--Add information on the Erlang version and RabbitMQ versions-->

This table shows the Rabbit and Erlang versions in each Docker image:

| Image version | Erlang version | RabbitMQ version |
|---------------|----------------|------------------|
| 3.6           | 19.2.1         | 3.6.15           |
| 3.7           | 20.2.4         | 3.7.7            |

## Environment variables reference

This section contains the environment variables that can be used to customize the deployment. 

- `NODENAME`: String ( default: _rabbit_ )
- `ENABLE_RAM` -> Boolean ( default: _false_ )
- `CLUSTER_WITH` -> String ( empty/no default )
- `RABBITMQ_ERLANG_COOKIE` -> String ( random generated )
- `RABBITMQ_DEFAULT_USER` -> String ( default: _guest_ )
- `RABBITMQ_DEFAULT_PASS` -> String ( default: _guest_ )
- `RABBITMQ_DEFAULT_VHOST` -> String ( default: _"/"_ )
- `RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` -> String ( empty/no default )


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
