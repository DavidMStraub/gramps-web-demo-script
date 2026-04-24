#!/bin/bash
set -e

# switch to docker-compose folder
cd /opt/grampsweb

docker-compose down --rmi all

# free up disk space before pulling, then pull updated images
journalctl --vacuum-size=50M
docker system prune -f
docker-compose pull

# delete all data
docker-compose run --rm --entrypoint="" grampsweb bash -c 'rm -rf /app/indexdir/* && rm -rf /app/thumbnail_cache/* && rm -rf /app/users/* && rm -rf /app/media/*'

# create new secret token (requires users to log in again)
docker-compose run --rm --entrypoint="" grampsweb bash -c 'python3 -c "import secrets;print(secrets.token_urlsafe(32))"  | tr -d "\n" > /app/secret/secret'

# copy media files of example.gramps
docker-compose run --rm --entrypoint="" grampsweb cp -a /venv/share/doc/gramps/example/gramps/. /app/media/

# import Gramps example database
docker-compose run --rm --entrypoint="" grampsweb bash -c 'cp -r /venv/share/doc/gramps/example/gramps/example.gramps /app && rm -rf /root/.gramps/grampsdb/* && gramps -C Gramps\ Web -i example.gramps --config=database.backend:sqlite --config=database.path:/root/.gramps/grampsdb'

# recreate search index
docker-compose run --rm grampsweb python3 -m gramps_webapi --config /app/config/config.cfg search index-full

# create user accounts
docker-compose run --rm grampsweb bash -c 'python3 -m gramps_webapi --config /app/config/config.cfg user add owner owner --fullname Owner --role 4 && python3 -m gramps_webapi  --config /app/config/config.cfg user add editor editor --fullname Editor --role 3 && python3 -m gramps_webapi  --config /app/config/config.cfg user add contributor contributor --fullname Contributor --role 2 && python3 -m gramps_webapi  --config /app/config/config.cfg user add member member --fullname Member --role 1'

docker-compose up -d