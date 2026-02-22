#/bin/bash

echo "Suppression de la stack MONITORING ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/05-monitoring
docker compose down -v

echo "Suppression de la stack TOOLS ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/04-tools
docker compose down -v

echo "Suppression de la stack DOWNLOADS ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/03-downloads
docker compose down -v

echo "Suppression de la stack MULTIMEDIA ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/02-multimedia
docker compose down -v

echo "Suppression de la stack CORE ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/01-core
docker compose down -v

echo "Suppression de toutes les images et les volumes"
docker system prune -a

echo "Suppression du dossier local"
rm -rf /Users/thomas/Documents/le-frigo-infra/apps
rm -rf /Users/thomas/Documents/le-frigo-infra/medias

echo "TERMINÉ ! Toutes les stacks ont été arrêtées et supprimées, ainsi que les images, les volumes et les données locales."