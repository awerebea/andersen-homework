# Flask app `emojis_loopback` in Docker container
To try my flask web app by starting a docker container with it, from root of this repository (directory with `app`, `src` and `docker` subdirectories) run:
```sh
$ docker build -t emojis_loopback:final -f docker/Dockerfile .
```
After the image has finished building, you can check the resulting image size:
```sh
$ docker images
```
and finally run it:
```sh
$ docker run --name emojis_loopback -p 8080:80 -p 4430:443 -it -d emojis_loopback:final
```
**NOTE:** If your current user is not a member of the `Docker` group you should probably run the commands above with `sudo`.

<br/>When the container is running, you can try running something like this:
```sh
$ curl -XPOST --insecure -d'{"word":"test", "count": 8}' https://localhost:4430
```
or this:
```sh
$ curl -XPOST -d'{"word":"example", "count": 3}' http://127.0.0.1:8080
```
![docker_output_sample](https://user-images.githubusercontent.com/63558838/110846836-4a2fab80-82bd-11eb-9aed-f88b57f38041.png)<br/>
**NOTE:** The `--insecure` flag added to allow `curl` connect to the server using an *untrusted* selfsigned certificate when connected via https.
<br/>More details here: [https://curl.se/docs/sslcerts.html](https://curl.se/docs/sslcerts.html)
## GET method
To test http `GET` request method, you can enter `http://localhost:8080` or `https://127.0.0.1:4430` in the address bar of your preferred browser.

## Usage
```sh
# build image
$ docker build -t emojis_loopback:final -f docker/Dockerfile .

# run image in container
$ docker run --name emojis_loopback -p 8080:80 -p 4430:443 -it -d emojis_loopback:final

# run a command in running container (for exemple, start bash interactively):
$ docker exec -it emojis_loopback bash

# stop container:
$ docker stop emojis_loopback

# start the stopped container again:
$ docker start emojis_loopback

# remove container:
$ docker rm emojis_loopback

# remove image
$ docker rmi emojis_loopback:final
```
