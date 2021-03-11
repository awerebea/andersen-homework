FROM debian:buster

# specifying ports for listening
EXPOSE 80 443

# copy in container src files
COPY src/nginx.conf \
	app/flask_emoji.py \
	app/templates/index.html \
	app/templates/preview.html /

# install requiered components
RUN apt-get update \
&&	apt-get install -y \
	git \
	nginx \
	openssl \
	python3 \
	python3-flask \
	python3-setuptools

# generate ssl certificate and key
RUN	mkdir -p /etc/ssl/certificates \
&&	openssl req -newkey rsa:2048 -x509 -sha256 -days 30 -nodes \
	-out /etc/ssl/certificates/dockerhost_cert.pem \
	-keyout /etc/ssl/certificates/dockerhost_privkey.pem \
	-subj "/C=RU/ST=Tatarstan/L=Kazan/O=DevOps courses/OU=a.bulgakov.86@gmail.com/CN=Flask emoji"

# replace Ansible variable in src files with a specific value
RUN	sed -i 's/{{\ server_hostname\ }}/dockerhost/' flask_emoji.py \
&&	sed -i 's/{{\ server_hostname\ }}/dockerhost/' nginx.conf

# move src files to correct locations
RUN	mv /nginx.conf /etc/nginx/sites-available/my_webserv \
&&	mkdir -p /emojis_loopback/templates \
&&	mv /index.html /preview.html /emojis_loopback/templates/ \
&&	mv flask_emoji.py /emojis_loopback/ \
&&	ln -s /etc/nginx/sites-available/my_webserv /etc/nginx/sites-enabled/ \
&&	rm -f /etc/nginx/sites-enabled/default

# clone the sources of the 'emoji' module and install it
RUN	git clone https://github.com/carpedm20/emoji.git \
&&	cd emoji \
&&	python3 setup.py install

# launch server
CMD	service nginx start \
&&	python3 /emojis_loopback/flask_emoji.py
