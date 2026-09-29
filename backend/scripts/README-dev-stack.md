# Dev stack

A throwaway backend on `127.0.0.1:8010` with its own SQLite file, seeded with a demo account.
It exists for redesign proof screenshots and API proof. It is never production and never
points at production data.

## Credentials

- Account `demo` / `maniacs-demo-2026` (the first account, so the owner/admin).
- Profile **Riya**: 18+ open, mood fantasy, 6 manga + 2 novel follows, a 6-day reading streak,
  3 bookmarks, the "Weekend binge" collection.
- Profile **Aarav**: 18+ closed, mood action, 3 follows, 2 chapters read 3 days ago (a broken
  streak).

## Subcommands

`backend/scripts/dev_stack.sh <subcommand>`

| Subcommand | What it does | Example |
|---|---|---|
| `start` | Starts uvicorn on 127.0.0.1:8010 (migrations run on boot), waits for `/health`. Idempotent. | `dev_stack.sh start` |
| `stop` | Kills the server (SIGKILL after 10 s). Idempotent. | `dev_stack.sh stop` |
| `restart` | `stop` + `start`. Needed after every backend code change: there is no auto-reload. | `dev_stack.sh restart` |
| `status` | Running or not, pid, port, db path and size, available RAM. | `dev_stack.sh status` |
| `seed` | Starts the stack if needed, then runs `seed_demo.py`. Refuses a seeded database. | `dev_stack.sh seed` |
| `reset` | Stops, deletes the db, settings and cookies, starts, seeds. | `dev_stack.sh reset` |
| `api METHOD PATH [JSON]` | Signs in as `demo`, sends the request as the profile `MM_DEV_PROFILE` (default `Riya`), pretty-prints the JSON. | `dev_stack.sh api GET /library/series` |

More `api` examples:

```bash
backend/scripts/dev_stack.sh api GET /profiles
MM_DEV_PROFILE=Aarav backend/scripts/dev_stack.sh api GET /library/continue-reading
backend/scripts/dev_stack.sh api PATCH /profiles/1 '{"skin":"glass"}'
```

## Safety guards

- Refuses to run when the data dir resolves under `/srv/manhwamaniacs/data` or
  `/srv/manhwamaniacs/app`, or when `MM_DB_PATH` resolves outside the data dir.
- Refuses to start with less than 1024 MB available, when another process already listens on
  the port, or when `backend/.venv` is missing (it prints the commands to create it).
- The server runs without `DEEPSEEK_API_KEY` and `MM_RENDER_WORKER_TOKEN`, so it never spends
  the AI allowance or books the render box. `MM_DEV_AI=1` passes `DEEPSEEK_API_KEY` through.
- `seed_demo.py` only talks to `127.0.0.1` or `localhost` on the dev port, over HTTP (it
  imports no app code), and turns the scheduled update sweep off.

## Data

`/srv/manhwamaniacs/dev/data/`: `dev.db`, `settings.json`, `cookies.txt`, `dev-backend.pid`,
`dev-backend.log`.

Parallel implementation lanes each own a port and a data dir: set `MM_DEV_PORT` and
`MM_DEV_DATA_DIR` (both scripts honour them), e.g.
`MM_DEV_PORT=8012 MM_DEV_DATA_DIR=/srv/manhwamaniacs/dev/data-backend dev_stack.sh reset`.

## RAM

This box shares 7.7 GB with production and five Minecraft bots. Check `free -m` first, never run
two `next build`s at once. The dev backend itself costs about 150 MB.

## With the web client

```bash
cd /srv/manhwamaniacs/dev/ManhwaManiacs/frontend
NEXT_PUBLIC_API_URL=/api BACKEND_INTERNAL_URL=http://127.0.0.1:8010 npx next dev -p 3010
# open http://localhost:3010 and sign in as demo
```

## With the Flutter app

The server address field takes `http://127.0.0.1:8010` only from a device that can reach this
box's loopback, through an SSH port-forward:
`ssh -L 8010:127.0.0.1:8010 ubuntu@135.148.43.147`.
