FROM alpine:3.7

# specifying ports for listening
EXPOSE 80 443

# copy in container src files
COPY src/nginx.conf \
	app/flask_emoji.py \
	app/templates/index.html \
	app/templates/preview.html /

# install requiered components
RUN apk add --update --no-cache \
	nginx \
	openssl \
	python3 \
	py3-flask \
&&	wget -c https://files.pythonhosted.org/packages/d6/56/\
484163d2f941f8c96de24fecf4885e3101913a2f4b31a1d50b4eb8eb244a/\
emoji-1.2.0.tar.gz \
&&	tar -xvf emoji-1.2.0.tar.gz \
&&	cd emoji-1.2.0 \
&&	find . -mtime +10950 -print -exec touch {} \; \
&&	python3 setup.py install \
&&	rm -rf /emoji-1.2.0

# generate ssl certificate and key
RUN	mkdir -p	/etc/ssl/certificates \
				/etc/supervisor.d \
				/run/nginx \
&&	openssl req -newkey rsa:2048 -x509 -sha256 -days 30 -nodes \
	-out /etc/ssl/certificates/dockerhost_cert.pem \
	-keyout /etc/ssl/certificates/dockerhost_privkey.pem \
	-subj "/C=RU/ST=Tatarstan/L=Kazan/O=DevOps courses/OU=a.bulgakov.86@gmail.com/CN=Flask emoji"

# replace Ansible variable in src files with a specific value
RUN	sed -i 's/{{\ server_hostname\ }}/dockerhost/' flask_emoji.py \
&&	sed -i 's/{{\ server_hostname\ }}/dockerhost/' nginx.conf

# move src files to correct locations
RUN	rm /etc/nginx/conf.d/default.conf \
&&	mv /nginx.conf /etc/nginx/conf.d/ \
&&	mkdir -p /emojis_loopback/templates \
&&	mv /index.html /preview.html /emojis_loopback/templates/ \
&&	mv flask_emoji.py /emojis_loopback/

# launch server
CMD	python3 /emojis_loopback/flask_emoji.py & \
	nginx -g 'daemon off;'
