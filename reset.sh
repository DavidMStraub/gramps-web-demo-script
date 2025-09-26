#!/bin/bash

# switch to docker-compose folder
cd /opt/grampsweb

docker-compose down

# delete all data
docker-compose run --entrypoint="" grampsweb bash -c 'rm -rf /app/indexdir/* && rm -rf /app/thumbnail_cache/* && rm -rf /app/users/* && rm -rf /app/media/*'

# create new secret token (requires users to log in again)
docker-compose run --entrypoint="" grampsweb bash -c 'python3 -c "import secrets;print(secrets.token_urlsafe(32))"  | tr -d "\n" > /app/secret/secret'

# copy media files of example.gramps
docker-compose run --entrypoint="" grampsweb cp -a /usr/local/share/doc/gramps/example/gramps/. /app/media/

# import Gramps example database
docker-compose run --entrypoint="" grampsweb bash -c 'cp -r /usr/local/share/doc/gramps/example/gramps/example.gramps /app && rm -rf /root/.gramps/grampsdb/* && gramps -C Gramps\ Web -i example.gramps --config=database.backend:sqlite --config=database.path:/root/.gramps/grampsdb'

# recreate search index
docker-compose run grampsweb python3 -m gramps_webapi --config /app/config/config.cfg search index-full

# create user accounts
docker-compose run grampsweb bash -c 'python3 -m gramps_webapi --config /app/config/config.cfg user add owner owner --fullname Owner --role 4 && python3 -m gramps_webapi  --config /app/config/config.cfg user add editor editor --fullname Editor --role 3 && python3 -m gramps_webapi  --config /app/config/config.cfg user add contributor contributor --fullname Contributor --role 2 && python3 -m gramps_webapi  --config /app/config/config.cfg user add member member --fullname Member --role 1'

# update image
docker-compose pull grampsweb
docker-compose up -d