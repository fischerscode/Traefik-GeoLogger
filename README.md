# Traefik-GeoLogger

Include geo locations in your traefik logs.

# Testing:
```bash
docker build . -t geologger
docker run --rm -d --name geologger -p 8080:8080\
    --mount type=bind,source="$(pwd)"/GeoLite2-City.mmdb,target=/app/GeoLite2-City.mmdb \
    --mount type=bind,source="$(pwd)"/access.log,target=/var/log/access.log \
    geologger:latest
docker logs geologger -f
echo "Stopping container..."
docker stop geologger


docker build . -t geologger -f Dockerfile.database
docker run --rm -d --name geologger -p 8080:8080\
    --mount type=bind,source="$(pwd)"/access.log,target=/var/log/access.log \
    geologger:latest
docker logs geologger -f
echo "Stopping container..."
docker stop geologger
```