# VPS subdomain & reverse-proxy setup (kestra.gratiosoft.com)

This page explains how to expose Kestra on `kestra.gratiosoft.com` from a VPS that already runs `n8n`.

Summary
- Create an `A` record for `kestra.gratiosoft.com` in Route 53 pointing to your VPS public IP.
- Use a reverse proxy (system `nginx` or `caddy`) on the VPS to route `kestra.gratiosoft.com` -> `http://127.0.0.1:8080`.
- Obtain TLS certificates (Let's Encrypt via Certbot for `nginx`, or automatic with `caddy`).
- Keep `n8n` configuration unchanged; use a separate server block for its hostname.

1) Get your VPS public IP

On the VPS run:

```bash
curl -s https://ifconfig.me || curl -s https://ipinfo.io/ip
```

2) Route 53 DNS record

- In the Route 53 console, open your hosted zone for `gratiosoft.com` and add a record:

  - Record name: `kestra` (this becomes `kestra.letterscode.com`)
  - Record type: `A`
  - Value: your VPS public IPv4 address
  - TTL: 300

Or with the AWS CLI (replace `ZXXXXXXXX` and `1.2.3.4`):

```bash
aws route53 change-resource-record-sets --hosted-zone-id ZXXXXXXXX \
  --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"kestra.gratiosoft.com.","Type":"A","TTL":300,"ResourceRecords":[{"Value":"1.2.3.4"}]}}]}'
```

3) Firewall / ports

Ensure ports 80 and 443 are open to the public and port 8080 is reachable from localhost only. Example (Ubuntu + UFW):

```bash
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

4) Reverse proxy options (choose one)

a) nginx (system package)

- Install and create a site file `/etc/nginx/sites-available/kestra` and symlink to `sites-enabled` (example in `docs/nginx_kestra.conf.example`).
- Obtain cert with Certbot (recommended):

```bash
sudo apt install -y certbot python3-certbot-nginx
  sudo certbot --nginx -d kestra.letterscode.com
```

b) Caddy (easy, automatic TLS)

- Install Caddy and use the `Caddyfile` example in `docs/Caddyfile.kestra.example`.
- Caddy will obtain and renew Let's Encrypt certs automatically.

5) Example: verify working

From your laptop:

```bash
curl -v https://kestra.letterscode.com/    # should 307 -> /ui/
```

6) Notes about `n8n`

- Because `n8n` already runs on the VPS, ensure `n8n` has its own server block and hostname (for example `n8n.gratiosoft.com`).
- Do not bind `n8n` to port 80/443 directly; let the reverse proxy route based on `Host`.

If you want, I can:
- (A) create the `nginx` site file and `Caddyfile` in the repo (done), or
- (B) SSH into your VPS and apply the `nginx` config + Certbot (I will need sudo access and the VPS IP/hostname). 
