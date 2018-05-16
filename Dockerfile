FROM rabbitmq:3.7

RUN rabbitmq-plugins enable --offline rabbitmq_management

ADD rabbitmq.conf /etc/rabbitmq/

RUN chmod u+rw /etc/rabbitmq/rabbitmq.conf \
	&& chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq.conf

ADD rabbitmq-cluster-entrypoint.sh /
RUN chmod +x /rabbitmq-cluster-entrypoint.sh
ENTRYPOINT ["/rabbitmq-cluster-entrypoint.sh"]
CMD []
