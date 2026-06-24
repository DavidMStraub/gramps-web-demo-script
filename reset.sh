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

# update cached queen example tree archive (fall back to existing cache on failure)
TREE_ARCHIVE=/opt/grampsweb/queen-tree.tar.gz
if curl -fsSL https://github.com/DavidMStraub/gramps-web-example-tree-queen/archive/refs/heads/main.tar.gz \
    -o "${TREE_ARCHIVE}.tmp"; then
  mv "${TREE_ARCHIVE}.tmp" "$TREE_ARCHIVE"
else
  echo "Warning: download failed, using cached archive"
  rm -f "${TREE_ARCHIVE}.tmp"
fi

# import queen example tree
docker-compose run --rm --entrypoint="" \
  -v "${TREE_ARCHIVE}:/tmp/queen-tree.tar.gz:ro" \
  grampsweb bash -c '
    tar xz -C /tmp -f /tmp/queen-tree.tar.gz &&
    cp -a /tmp/gramps-web-example-tree-queen-main/media/. /app/media/ &&
    rm -rf /root/.gramps/grampsdb/* &&
    gramps -C Gramps\ Web -i /tmp/gramps-web-example-tree-queen-main/queen.gramps \
      --config=database.backend:sqlite \
      --config=database.path:/root/.gramps/grampsdb
  '

# recreate search index
docker-compose run --rm grampsweb python3 -m gramps_webapi --config /app/config/config.cfg search index-full

# create user accounts
docker-compose run --rm grampsweb bash -c 'python3 -m gramps_webapi --config /app/config/config.cfg user add owner owner --fullname Owner --role 4 && python3 -m gramps_webapi  --config /app/config/config.cfg user add editor editor --fullname Editor --role 3 && python3 -m gramps_webapi  --config /app/config/config.cfg user add contributor contributor --fullname Contributor --role 2 && python3 -m gramps_webapi  --config /app/config/config.cfg user add member member --fullname Member --role 1'

docker-compose up -d