# Flask app `emojis_loopback` in Docker container
To try out my flask web app by starting a docker container with it, just run:
```sh
$ ./start.sh
```
To find out about all the possibilities of the script, enter:
```sh
$ ./start.sh --help
```
To manage Docker container manually, from root of this repository (directory with `app`, `src` and `docker` subdirectories) you can use the following commands:
```sh
# to build imange run:
$ docker build -t emojis_loopback:final -f docker/Dockerfile .
# after the image has finished building, you can check the resulting image size:
$ docker images
# and finally run it:
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
Using script
```sh
# automatically build an image and run it in a container
$ ./start.sh

# print all possibilities
$ ./start.sh --help
# or
$ ./start.sh -h
```
Manual mode
```sh
# build image
$ docker build -t emojis_loopback:final -f docker/Dockerfile .

# run image in container
$ docker run --name emojis_loopback -p 8080:80 -p 4430:443 -it -d emojis_loopback:final

# run a command in running container (for exemple, start sh interactively)
$ docker exec -it emojis_loopback sh

# stop container
$ docker stop emojis_loopback

# start the stopped container again
$ docker start emojis_loopback

# remove container
$ docker rm emojis_loopback

# remove image
$ docker rmi emojis_loopback:final
```
