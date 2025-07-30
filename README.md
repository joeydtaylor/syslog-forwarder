# Syslog Forwarder (UDP/TCP → TLS) 🔒📡⚙️

Containerised rsyslog relay that upgrades plaintext syslog to TLS. 🚀🛡️🧰

**Key features** 🎯📦✅

* Drop‑in deployment via Docker Compose
* Public CAs (Let’s Encrypt, DigiCert, etc.) trusted by default
* Optional private CA: drop a bundle at `dist/ca.crt`
* One config file: `.env` for host/port

---

## Directory layout 🗂️📁🧾

```
syslog-forwarder/
├─ dist/                     # optional: drop ca.crt or generated certs here
│  ├─ ca.crt
│  ├─ server.crt
│  └─ server.key
├─ scripts/
│  └─ gen-selfsigned.sh      # helper script
├─ Dockerfile
├─ docker-compose.yml
├─ docker-entrypoint.sh
├─ rsyslog.conf.tmpl
└─ .env                      # user‑editable runtime settings
```

---

## Quick Start (Let’s Encrypt or any public CA) ⚡🧪📘

```bash
# 1. clone project and enter
git clone https://github.com/joeydtaylor/syslog-forwarder.git
cd syslog-forwarder

# 2. configure destination
echo "REMOTE_HOST=logs.example.com" > .env
# echo "REMOTE_PORT=50001" >> .env   # optional

# 3. launch
docker compose up -d --build

# 4. view runtime logs
docker compose logs -f
```

---

## Custom or Self‑Signed CA 🛠️🔐🏗️

You can pin trust to a private CA by providing a `dist/ca.crt` bundle. 🧾📩📍

```bash
# generate a self‑signed CA + server certs
scripts/gen-selfsigned.sh syslog.acme.local

# (optional) include SANs
# scripts/gen-selfsigned.sh syslog.acme.local alt1.acme.local 10.0.0.12

# install dist/server.crt and dist/server.key on the TLS‑listening syslog server

# restart forwarder to pick up dist/ca.crt
docker compose up -d
docker compose logs -f
```

---

## Environment variables ⚙️🧾🔧

| Variable      | Required | Default | Description                                 |
| ------------- | -------- | ------- | ------------------------------------------- |
| `REMOTE_HOST` | ✅        | –       | FQDN or IP of TLS syslog server             |
| `REMOTE_PORT` |          | `50001` | Destination port                            |
| `CA_FILE`     |          | auto    | Optional override for CA path (rarely used) |

---

## Performance & scaling 📈💨🧠

* **Typical sustained rates**

  * UDP 514 → TLS: 20–40 k EPS on M‑series, 50–100 k EPS on x86
  * TCP 514 → TLS: 15–30 k EPS (ACK‑gated)
* **Scale‑out**

  * Run multiple containers for >100k EPS, or shard by source IP
* **Queue handling**

  * Raise queue size for burst tolerance:

```conf
action(
  ...
  queue.type="FixedArray"
  queue.size="200000"
)
```

---

## Health & Observability ❤️📊🩺

* Docker healthcheck confirms rsyslog is alive
* Enable `impstats` in `rsyslog.conf.tmpl`:

```conf
module(load="impstats"
       interval="10"
       format="json")
```

---

## Troubleshooting 🧯🔍🛠️

| Symptom                      | Cause / Resolution                                  |
| ---------------------------- | --------------------------------------------------- |
| `connection refused`         | Use `host.docker.internal` not `127.0.0.1` on macOS |
| TLS handshake fails          | Ensure `dist/ca.crt` matches the server's chain     |
| Nothing received             | Remap ports if 514 is already bound locally         |
| High CPU or queue saturation | TLS-bound. Add CPU, raise queue, or replicate       |

---

## Diagnostics 🧪🧭📟

```bash
# View container logs
docker compose logs -f

# Shell into container
docker exec -it syslog-forwarder bash

# TLS probe from inside
openssl s_client -connect $REMOTE_HOST:$REMOTE_PORT -CAfile /etc/ssl/certs/ca-certificates.crt

# Host-level UDP stats
sudo netstat -anu | grep ':514 '

# Raise UDP buffer
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.netdev_max_backlog=250000
```
