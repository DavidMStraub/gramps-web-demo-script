#!/bin/bash

# switch to docker-compose folder
cd /opt/grampsweb

# delete all data
docker-compose run grampsweb bash -c 'rm -rf /app/indexdir/* && rm -rf /app/thumbnail_cache/* && rm -rf /app/users/* && rm -rf /app/media/*'

# create user accounts
docker-compose run grampsweb bash -c 'python3 -m gramps_webapi  --config /app/config/config.cfg user add owner owner --fullname Owner --role 4 && python3 -m gramps_webapi  --config /app/config/config.cfg user add editor editor --fullname Editor --role 3 && python3 -m gramps_webapi  --config /app/config/config.cfg user add contributor contributor --fullname Contributor --role 2 && python3 -m gramps_webapi  --config /app/config/config.cfg user add member member --fullname Member --role 1'

# import Gramps example database
docker-compose run grampsweb bash -c 'cp -r /usr/share/doc/gramps/example/gramps/example.gramps.gz /app && gunzip /app/example.gramps.gz && rm -rf /root/.gramps/grampsdb/* && gramps -C Gramps\ Web -i example.gramps --config=database.backend:sqlite --config=database.path:/root/.gramps/grampsdb'

# copy media files of example.gramps
docker-compose run grampsweb cp -a /usr/share/doc/gramps/example/gramps/. /app/media/

# create new secret token (requires users to log in again)
docker-compose run grampsweb bash -c 'python3 -c "import secrets;print(secrets.token_urlsafe(32))"  | tr -d "\n" > /app/secret/secret'

# recreate search index
docker-compose run grampsweb python3 -m gramps_webapi  --config /app/config/config.cfg search index-full