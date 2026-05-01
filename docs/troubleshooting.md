# Troubleshooting: Rare & Silent Issues

A collection of non-obvious issues that look like something else and waste hours.

---

## 1. Session Loss — Login Loop / DB Selector Appears After Few Clicks

**Symptom:**
- User logs in successfully
- After a few clicks, Odoo asks to select a database and login again
- Browser console may show 404s on `/web/dataset/call_kw/*` or `/websocket`
- Odoo log shows requests with `?` instead of the database name

**Looks like:** DB config issue, dbfilter problem, multi-DB conflict, cookie issue.

**Actually:** Stale/corrupt session files in the session store.

**Root cause:**
Odoo stores sessions as files under `data_dir/sessions/` (default: `/var/lib/odoo/.local/share/Odoo/sessions/`).
Over time (especially with multiple databases and restarts), session files accumulate and can become stale or internally inconsistent.

In **Odoo 18 specifically**, session keys changed from hex (40 chars) to base64 (84 chars, case-sensitive), and sessions now include a `session_token` validated against the database via `res.device` tracking. A mismatch between an old session file and the current database state causes silent session invalidation — Odoo drops the session and redirects to the DB selector.

**Fix:**
```bash
sudo systemctl stop odoo
sudo find /var/lib/odoo/.local/share/Odoo/sessions/ -type f -delete
sudo systemctl start odoo
```
Then hard-refresh the browser (Ctrl+Shift+R) and log in fresh.

**Why this doesn't affect Odoo 15/16/17 the same way:**
- Older versions used hex session keys with simpler token validation
- No `res.device` DB-side session tracking
- Less aggressive session rotation logic

**Prevention:**
There is no built-in periodic cleanup in development setups. The `vacuum()` method in `odoo/http.py` only runs as part of request processing — in low-traffic dev instances it rarely triggers. You can run the cleanup manually anytime sessions feel off, it is safe and instant.

---

## 2. 404 on RPC Calls When Running Multiple Odoo Versions on Same Machine

**Symptom:**
- Session works initially, then breaks after a few clicks or navigating between pages
- Browser DevTools shows `POST /web/dataset/call_kw/*/search_panel_select_range` → **404**
- The `session_id` cookie in the failing request is a **40-character hex string**
- Only happens when switching between browser tabs/windows for different Odoo versions

**Looks like:** Server misconfiguration, dbfilter issue, multi-DB conflict, session file corruption.

**Actually:** Browser cookie namespace collision between Odoo versions.

**Root cause:**
Browsers scope cookies by **domain only, not port**. All Odoo instances on `localhost` (`:8015`, `:8016`, `:8017`, `:8018`) share the same cookie jar. When you switch from an Odoo 15/16/17 tab back to Odoo 18, the browser may send the old `session_id` (40-char hex, set by the older instance) to Odoo 18.

Odoo 18 changed the session key format from **hex (40 chars)** to **base64 (84 chars)** and added strict format validation via `is_valid_key()`. When it receives the old hex key, it immediately rejects it without looking up the session file, creates a new anonymous session with no database context, and the next RPC call has no DB → **404**.

Odoo 15/16/17 all shared the same hex format, so cross-port cookie bleeding was invisible — those versions would just create a new session and redirect to login gracefully.

**Fix:**
Access Odoo 18 via `http://127.0.0.1:8018` instead of `http://localhost:8018`.
Browsers treat `127.0.0.1` and `localhost` as separate cookie domains. Zero configuration needed.

**Alternative (permanent):**
Add a dedicated hostname in your Windows hosts file (`C:\Windows\System32\drivers\etc\hosts`):
```
127.0.0.1   odoo18.local
```
Then always access Odoo 18 via `http://odoo18.local:8018` — fully isolated cookie domain.

---

## 3. Odoo ABRT Crash on Restart (Python 3.12)

**Symptom:**
- `sudo systemctl restart odoo` causes an `ABRT` signal
- Journal shows `Aborted` during shutdown
- Odoo crashes instead of gracefully restarting

**Looks like:** Memory corruption, kernel bug, OOM killer.

**Actually:** Python 3.12 changed daemon thread locking behavior during interpreter shutdown. Odoo's cron thread holds a lock that Python 3.12's shutdown sequence tries to acquire — deadlock → ABRT.

**Fix (development only):**
```ini
# /etc/odoo/odoo.conf
max_cron_threads = 0
```

**Note:** Do not use `max_cron_threads = 0` in production. In production, proper gevent workers and a process manager handle this correctly. This is a dev environment workaround only.
