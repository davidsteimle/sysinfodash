# Build and Run API

Note that you _typically_ need to run elevated. 

## The Build Process

```sh
# cd to your content location
docker build -t sysinfodash:latest .
# create your volume, which the api will use
docker volume create sysinfo
```

## The Run Process

```sh
docker run -d -p 5000:8082 --name sysinfodash -v sysinfo:/data sysinfodash:latest
```

## Stop the API

```sh
# this will stop the image
docker stop sysinfodash
# remove the container before you may re-use
docker rm [CONTAINER ID]
```
