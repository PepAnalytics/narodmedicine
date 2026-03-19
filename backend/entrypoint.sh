#!/bin/sh
set -e

python manage.py migrate --noinput

case "${COLLECTSTATIC:-0}" in
  1|true|TRUE|True|yes|YES)
    python manage.py collectstatic --noinput
    ;;
esac

exec "$@"
