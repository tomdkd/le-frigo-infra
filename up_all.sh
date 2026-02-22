#/bin/bash
echo "Démarrage de la stack CORE ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/01-core
docker compose up -d

echo "Démarrage de la stack MULTIMEDIA ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/02-multimedia
docker compose up -d

echo "Démarrage de la stack DOWNLOADS ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/03-downloads
docker compose up -d

echo "Démarrage de la stack TOOLS ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/04-tools
docker compose up -d

echo "Démarrage de la stack MONITORING ..."
sleep 2

cd /Users/thomas/Documents/le-frigo-infra/05-monitoring
docker compose up -d

echo "TERMINÉ ! Toutes les stacks sont en cours d'exécution."