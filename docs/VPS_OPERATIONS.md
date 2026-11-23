# Running ManhwaManiacs on the VPS

Live since 2026-09-03 on the OVH box in Vint Hill that also runs the Minecraft
bots. This is the operator's page: where things are, how to ship a change, and
what has to be done by hand.

| | |
|---|---|
| Web | https://manhwamaniacs.xyz (`www` 308s to the apex) |
| Install surface | https://app.manhwamaniacs.xyz — landing page, APK, `/app/source.json` for SideStore |
| Host | `ubuntu@135.148.43.147` — key auth, passwordless sudo, in the `docker` group |
| Code | `/srv/manhwamaniacs/app` — rsynced, **no `.git`** (this laptop has no GitHub push auth yet) |
| State | `/srv/manhwamaniacs/data` — the metadata SQLite DB + `settings.json`, on a dedicated 50 GB disk (`/dev/sdb1`, in fstab by UUID) |
| Artifacts | `/srv/manhwamaniacs/apk` and `/srv/manhwamaniacs/ipa`, mounted read-only into the backend |
| Containers | `manhwamaniacs-backend` (FastAPI :8000) · `manhwamaniacs-frontend` (Next standalone :3000) |
| Backups | OVH Automated Backup (Standard), daily |

## Shipping a change

From the laptop:

```bash
ops/vps/push.sh            # everything: verify the Next build locally, rsync, rebuild there
ops/vps/push.sh frontend   # or just one side
ops/vps/push.sh backend
ops/vps/push.sh apk        # publish mobile/build/.../app-release.apk to the app subdomain
```

`push.sh` builds the frontend locally first on purpose — the VPS has 2 vCores
behind a tunnel, and it is a slow place to discover a type error. The commit id
travels across in `.deploy-info` so a running container can still be traced to a
revision despite the missing `.git`.

On the VPS itself:

```bash
cd /srv/manhwamaniacs/app
bash ops/vps/deploy.sh deploy            # build + up + health gate
bash ops/vps/deploy.sh logs
bash ops/vps/deploy.sh edge              # re-apply the Caddy vhosts + tunnel ingress (idempotent)
bash ops/vps/deploy.sh create-owner      # needs a TTY: ssh -t
bash ops/vps/deploy.sh install-timers    # one-off: install + enable the iOS-build-fetch systemd timer
```

## How traffic reaches it

Nothing is published on a host port. The **Minecraft stack's** Caddy and
cloudflared do the edge work — this app joins their `mcbots_bots` network as a
co-tenant rather than standing up a second proxy or a second tunnel:

```
Cloudflare ──tunnel e40ede74-…(mcbots-vinthill)──▶ cloudflared ──▶ caddy:80 ──▶ manhwamaniacs-frontend:3000
                                                                          └──▶ manhwamaniacs-backend:8000   (app. subdomain)
```

Config lives with the Minecraft stack: `/opt/mcbots/edge/Caddyfile` and
`/opt/mcbots/edge/cloudflared/config.yml`. `deploy.sh edge` appends to both and
keeps timestamped `.bak-mm-*` copies. DNS is three proxied CNAMEs (`@`, `www`,
`app`) pointing at `e40ede74-c9c0-454d-9983-3a6ce2866a47.cfargotunnel.com`.

**Do not** add a second tunnel or a second Caddy. Touching the shared files means
the bots share the blast radius — check `minecraft.yashnas.xyz` still answers
after any edge change.

## Manual steps that are not automated

1. **Cloudflare Browser Cache TTL must be "Respect Existing Headers".** It is
   currently 4 hours, which overrides the origin on `/sw.js`: the origin
   correctly sends `no-cache, must-revalidate`, Cloudflare rewrites it to
   `max-age=14400`, and a browser then holds a stale **service worker** — the
   thing that controls the whole app shell and the offline store — for up to
   four hours, with no way for the reader to clear it themselves. Fix at
   *Caching → Configuration → Browser Cache TTL*, or with a Cache Rule that
   bypasses `/sw.js`, `/sw-policy.js`, `/offline-fallback.html`.
2. **GitHub push auth.** This laptop cannot push (`git@github.com: Permission
   denied (publickey)`), so the cloud-Mac iOS build never runs. Add the laptop
   key to the account, or use a PAT.
3. **Repo visibility.** The IPA sync downloads *release assets anonymously*,
   which needs a public repo. The repo currently reads Private — either make it
   public or put a token with `Actions:read` at `/root/.gh_token` on the VPS.
4. **The iOS sync timer.** `ops/vps/deploy.sh install-timers` installs a
   15-minute systemd timer that runs `ops/fetch-ios-build.sh` (idempotent, run
   it again after any deploy). There is still nothing for it to fetch until 2
   and 3 above are resolved — a missing release just means each run exits 2
   ("nothing new to publish").

## Routing blocked sources through a second server

Some sources refuse this box's datacenter address while working fine from
elsewhere. Two are in the tree waiting for exactly this: **toonily** (blocks the
VPS outright) and **weebcentral** (two of its four image CDN zones answer the
VPS with a Cloudflare block page). Both stay unregistered -- absent from
`GET /sources`, never shown to a reader -- until you opt them in. The owner's
second VPS (Delhi) can carry their traffic.

### What it does

`MM_ALT_EGRESS_PROXY` names a forward proxy running on the second server, and
`MM_ALT_EGRESS_SOURCES` lists the source ids whose outbound requests go through
it. For a listed source **every** request leaves through the proxy: catalogue
and search scrapes, chapter lists, the health probe, and every page image and
cover the image proxy fetches. Nothing else changes -- other sources go out
directly, the SSRF allowlist and redirect checks still validate every
destination exactly as before, and the proxy's own address is operator
configuration, not something a source can point at.

`toonily` and `weebcentral` register **only when both settings are present** and
the id is in the list. Listing any other registered source id routes that
source's traffic too (useful for trying a source that is blocked from here); an
id that is not a registered source is ignored with one warning at boot.

### 1. Set up the proxy on the second server

An open proxy on the internet is found and abused within hours -- scraping,
spam, worse -- and the abuse report lands on the second server's owner. So the
proxy gets three locks, and all three are required: it listens on a non-default
port, it only answers the main VPS's IP, and it wants a password. Do the
firewall rule first.

On the second server (Debian/Ubuntu), as root. `MAIN_IP` is the main VPS's
public address (`135.148.43.147`).

```bash
MAIN_IP=135.148.43.147
PORT=38128                                   # anything but 3128/8080/8888

# 1. Firewall FIRST. Keep SSH reachable, then admit only the main VPS.
ufw allow OpenSSH
ufw allow from "$MAIN_IP" to any port "$PORT" proto tcp
ufw default deny incoming
ufw enable
# Add the same rule in the provider's own firewall/security group if it has one.

# 2. The proxy.
apt-get install -y tinyproxy
PASS="$(openssl rand -hex 24)"               # hex: nothing that needs URL-escaping
cat > /etc/tinyproxy/tinyproxy.conf <<CONF
User tinyproxy
Group tinyproxy
Port $PORT
Timeout 600
MaxClients 20
LogLevel Info
Allow $MAIN_IP
BasicAuth mm $PASS
# Tunnels to HTTPS sites only. Add "ConnectPort 80" only if a source needs it.
ConnectPort 443
DisableViaHeader Yes
CONF
chmod 640 /etc/tinyproxy/tinyproxy.conf      # the password is in this file
systemctl restart tinyproxy && systemctl enable tinyproxy
echo "$PASS"                                 # goes into the main VPS's .env below
```

Check it from the **main VPS**, not from the second server (the second server's
own address is not what the firewall is for):

```bash
curl -sS -o /dev/null -w '%{http_code}\n' -x "http://mm:PASS@SECOND_IP:38128" https://toonily.com/   # any HTTP status = the proxy works
curl -sS -o /dev/null -w '%{http_code}\n' -x "http://SECOND_IP:38128" https://toonily.com/           # no password: fails with 407
```

and from anywhere *else* the port should not answer at all.

Two things to know about this recipe. The proxy login is HTTP Basic over an
unencrypted hop to the proxy, so the allow-list and firewall rule are what
actually protect it; the page traffic itself is TLS end to end to the site. And
the proxy can reach whatever the second server can reach, including services on
its own `127.0.0.1` -- keep nothing sensitive listening there. The backend
validates every destination before it asks the proxy for it, and nothing else
can use the proxy.

### 2. Tell the main VPS

Put the settings in `ops/vps/.env` **on the main VPS**
(`/srv/manhwamaniacs/app/ops/vps/.env`), next to the compose file. It is
untracked (`.gitignore`), and `push.sh` excludes `.env` from its
`rsync --delete`, so a push never overwrites or removes it. It holds the proxy
password, so `chmod 600` it. It is the same file that holds `DEEPSEEK_API_KEY`
if you have set one.

```bash
# /srv/manhwamaniacs/app/ops/vps/.env   (one setting per line, no quotes)
MM_ALT_EGRESS_PROXY=http://mm:PASS@SECOND_IP:38128
MM_ALT_EGRESS_SOURCES=toonily,weebcentral
```

* The URL is `http://` or `https://` (what your proxy speaks to the main VPS),
  **with an explicit port**. SOCKS (`socks5://`) is rejected at boot: the
  installed httpx cannot do SOCKS without an extra package.
* A password containing `@ : / # % $` must be percent-encoded, and `$` is best
  avoided altogether (compose reads it as a variable). The hex password from
  the recipe needs none of that.
* A malformed value **stops the backend from booting**, with a message that says
  what is wrong and never prints the value. That is deliberate: it will not
  quietly fall back to direct egress.

### 3. Restart

Settings are read once, at boot, so after any change to `.env`:

```bash
cd /srv/manhwamaniacs/app
docker compose -f ops/vps/docker-compose.yml up -d backend
```

(`bash ops/vps/deploy.sh deploy` does the same as part of a full deploy.)

### 4. Verify

```bash
docker logs manhwamaniacs-backend 2>&1 | grep -i 'alternate egress'
# Alternate egress on via SECOND_IP:38128 for sources: toonily, weebcentral
```

That line names the proxy's host and port, never its password. A WARNING after
it ("... names sources that are not registered and were ignored: ...") means a
typo in the list. Then run the live check for the routed sources. From the
laptop it executes inside the production container, so it uses the same
settings and the same egress:

```bash
backend/.venv/bin/python backend/scripts/e2e_connector_check.py --remote --mature --only toonily,weebcentral
```

`--mature` is needed because toonily is 18+. The run first prints
`Alternate egress via SECOND_IP:38128 for: toonily, weebcentral`, then a
PASS/FAIL per stage: browse, search, detail, chapters, pages and **images** (the
stage that fetches real page bytes through the same code the reader uses).
weebcentral passing `images` is the proof its blocked CDN zones accept the
second server. The source health shown on the admin status page is refreshed by
the normal re-probe, which goes through the proxy as well.

If the proxy itself is down or refuses the login, the routed source answers
`502 source_unreachable` like any unreachable source, and the backend log has
`alternate egress proxy SECOND_IP:38128 failed for source toonily (...)`. That
line, not a site error, is how you tell the second server from the site.

### 5. Turn it off

Remove (or blank) both lines in `ops/vps/.env` and run the `up -d backend`
above. toonily and weebcentral leave the registry at that boot and the cache
sweep deletes their cached rows (series, browse pages, covers) at that boot like
any deregistered source; any other listed source goes back to direct egress.
Turn it on again later and they simply refetch. Follows, progress and bookmarks
on those sources are not deleted, and toonily stays 18+ for as long as rows
name it.

### Limits

* **All of a routed source's traffic crosses the second server**, page images
  included. A chapter is tens of megabytes: that is bandwidth on the second
  server's plan and an extra network hop of latency on every image. A reader's
  request now goes main VPS -> second server -> site -> back.
* **A second datacenter IP is not guaranteed to be accepted either.** Delhi is a
  different address, not a residential one. weebcentral's CDN zones in
  particular may block it the same way; run the `images` stage above before
  telling anyone it works, and take the id out of `MM_ALT_EGRESS_SOURCES` if it
  does not.
* **The proxy is a single point of failure for the listed sources only.**
  Everything else is untouched when it is down; the listed sources return 502
  until it is back. There is no automatic fallback to direct egress -- that
  would only be the blocked address again.
* One proxy for all listed sources: no per-source proxy, no pool, no automatic
  detection of which sources are blocked.

## Accounts

One account exists: `Yash`, admin, created through the web bootstrap form.
`MM_REGISTRATION_ENABLED=false`, so `needs_bootstrap` is false and nobody else
can register. **An empty users table on a public host is an open admin
takeover** — if the DB is ever wiped, create the owner before DNS points at it.

## Disk

The system disk (`/dev/sda`, 40 GB) holds the OS, Docker, and the Minecraft
stack; ~27 GB free after a prune of 16.5 GB of stale Rust build cache. The
manhwamaniacs disk (`/dev/sdb1`, 50 GB at `/srv/manhwamaniacs`) is essentially
empty and stays that way by design: **chapter images never touch the server.**
If disk use there starts climbing, something has regressed.
