FROM debian:9

SHELL ["/bin/bash", "-exo", "pipefail", "-c"]

RUN apt-get update ;\
	DEBIAN_FRONTEND=noninteractive apt-get install --no-install-{recommends,suggests} -y \
	mariadb-server ;\
	apt-get clean ;\
	rm -vrf /var/lib/apt/lists/* ;\
	perl -pi -e 's/\b127\.0\.0\.1\b/0.0.0.0/ if /^bind-address\s*=/' /etc/mysql/mariadb.conf.d/50-server.cnf

RUN install -m 755 -o mysql -g root -d /var/run/mysqld

RUN mysqld -u mysql & \
	MYSQLD_PID="$!" ;\
	while ! mysql <<<''; do sleep 1; done ;\
	mysql <<<"CREATE DATABASE masif_upgrader; GRANT ALL ON masif_upgrader.* TO masif_upgrader_master@'%' IDENTIFIED BY '123456'; GRANT ALL ON masif_upgrader.* TO masif_upgrader_ui@'%' IDENTIFIED BY '123456';" ;\
	kill "$MYSQLD_PID" ;\
	while test -e "/proc/$MYSQLD_PID"; do sleep 1; done

COPY --from=ochinchina/supervisord:latest /usr/local/bin/supervisord /usr/local/bin/
COPY supervisord.conf /etc/

CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisord.conf"]
