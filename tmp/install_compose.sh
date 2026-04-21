#!/bin/bash
set -euo pipefail

echo "== OS =="
cat /etc/os-release || true

echo "== docker version =="
sudo docker --version || true

echo "== resolving latest docker-compose tag via GitHub API =="
LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\\K.*?(?=")')
echo "Resolved tag: ${LATEST}"

sudo mkdir -p /usr/lib/docker/cli-plugins
sudo rm -f /usr/lib/docker/cli-plugins/docker-compose || true
sudo curl -sfL "https://github.com/docker/compose/releases/download/${LATEST}/docker-compose-linux-x86_64" -o /usr/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/lib/docker/cli-plugins/docker-compose

echo "== verify =="
sudo docker compose version || true

echo "INSTALL_DONE"
#!/bin/bash
set -euo pipefail
echo "== OS =="
cat /etc/os-release || true
echo "== docker version =="
sudo docker --version || true
echo "== resolving latest docker-compose tag via redirect =="
LATEST_URL=$(curl -s -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest)
LATEST=${LATEST_URL##*/}
echo "Resolved tag: ${LATEST}"
sudo mkdir -p /usr/lib/docker/cli-plugins
sudo curl -sfL "https://github.com/docker/compose/releases/download/${LATEST}/docker-compose-linux-x86_64" -o /usr/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/lib/docker/cli-plugins/docker-compose
echo "== verify =="
sudo docker compose version || true

echo "INSTALL_DONE"
