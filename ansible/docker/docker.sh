#! /bin/bash

help_message=$'usage: ./docker.sh [COMMAND]
This script was created to make it easier to manage Docker when you want to build,
run, start/stop, or remove a container/image
that is running the \'emojis_loopback\' web app.
Examples:
./docker.sh
./docker.sh stop
./docker.sh start
./docker.sh rm
./docker.sh rmi

By default, if the script is run without any command,
it initializes the build of the image and then
automatically runs it in the container.

COMMANDs:
  build         build image
  run           run image in container
  exec          start sh in container interactively
  stop          stop container
  start         start the stopped container again
  rm            remove container
  rmi           remove image

  -h, --help    print this help message'

error_message="Invalid argument. Type './docker.sh --help' to see more info"

# build image
docker_build="docker build -t emojis_loopback:final -f docker/Dockerfile ."
# run image in container
docker_run="docker run --name emojis_loopback -p 8080:80 -p 4430:443 -it -d emojis_loopback:final"
# run a command in running container (for exemple, start sh interactively)
docker_exec="docker exec -it emojis_loopback sh"
# stop container
docker_stop="docker stop emojis_loopback"
# start the stopped container again
docker_start="docker start emojis_loopback"
# remove container
docker_rm="docker rm emojis_loopback"
# remove image
docker_rmi="docker rmi emojis_loopback:final"

if [[ -z $(groups | awk "/docker/ {print}") ]]; then
  sudo="sudo"
fi

if [ $# -eq 0 ]; then
  cd ..
  eval $sudo $docker_build
  eval $sudo $docker_run
else
  case $1 in
    -h|--help)
      echo "$help_message";;
    build)
      cd ..
      eval $sudo $docker_build;;
    run)
      cd ..
      eval $sudo $docker_run;;
    exec)
      cd ..
      eval $sudo $docker_exec;;
    stop)
      cd ..
      eval $sudo $docker_stop;;
    start)
      cd ..
      eval $sudo $docker_start;;
    rm)
      cd ..
      eval $sudo $docker_rm;;
    rmi)
      cd ..
      eval $sudo $docker_rmi;;
    *)
      echo $error_message;;
  esac
fi
