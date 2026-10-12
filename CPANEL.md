# Installing on cPanel (shared hosting) — step by step

You do **not** need SSH, Composer or Node on the server. You get a ready-made zip, upload it, and finish in the browser.

## A. Get the zip
You need `brightstar-cpanel.zip`. Pick one:
1. **GitHub (no tools on your computer):** create a free GitHub repository, upload this whole project to it, open the
   **Actions** tab → "Test and build cPanel package" → **Run workflow**. When it finishes, download the **brightstar-cpanel**
   artifact (it contains the zip). The same run also runs all the automated tests: open the **test-output** artifact
   to see the results.
2. **Your own computer** with PHP 8.2+, Composer, Node 18+ and `zip`: run `bash scripts/build-cpanel-package.sh`
   → `dist/brightstar-cpanel.zip`.

## B. Prepare cPanel (5 minutes)
1. **PHP version:** cPanel → *MultiPHP Manager* → select your domain → choose **PHP 8.2 or 8.3** → Apply.
2. **PHP extensions:** cPanel → *Select PHP Version* → *Extensions*: make sure `pdo_mysql`, `mbstring`, `openssl`, `xml`,
   `curl`, `fileinfo`, `tokenizer`, `ctype`, `gd` are ticked. (The installer shows exactly what is missing.)
3. **Database:** cPanel → *MySQL® Database Wizard* → create a database and a user (write down the full names, they have your
   account prefix, e.g. `cpuser_store`) → give the user **ALL PRIVILEGES**.
4. **HTTPS:** cPanel → *SSL/TLS Status* → run AutoSSL so your site has https.

## C. Upload
1. cPanel → *File Manager* → go to your **home folder** (the one that contains `public_html`, **not** inside it).
2. *Upload* `brightstar-cpanel.zip`, then right-click it → **Extract** into the home folder.
   You now have a `brightstar` folder (private app) and the web files inside `public_html`.
   *(Hosting an addon domain or subdomain? Move the contents of the extracted `public_html` into that domain's document
   root, and edit its `index.php`: the three `../brightstar/` paths must point at the `brightstar` folder, e.g. `../../brightstar/`.)*
3. Open `brightstar/storage/app/INSTALL-CODE.txt` in File Manager (right-click → View) and copy the code.

## D. Run the installer
1. Visit **https://your-domain/install**.
2. The page checks your server. Fix any red item (hint included), refresh.
3. Enter the database details, your store name, your admin email + password, and the install code → **Install now**.
4. Done. Log in at `/login`, then use **Admin → Settings** for your logo, WhatsApp number, payment keys, email settings.
   The installer locks itself afterwards.

## E. After installing (important)
1. **Cron job** (cPanel → *Cron Jobs*, "once per minute"). Use your own username and PHP path (the PHP path is shown in
   the cron page help, commonly `/usr/local/bin/ea-php82`):
   `/usr/local/bin/ea-php82 /home/YOURUSER/brightstar/artisan schedule:run >/dev/null 2>&1`
   This cancels abandoned unpaid orders and returns their stock.
2. **Emails** are sent immediately (queue = `sync`). For many customers, switch to background sending: in
   `brightstar/.env` set `QUEUE_CONNECTION=database` and add a second cron:
   `/usr/local/bin/ea-php82 /home/YOURUSER/brightstar/artisan queue:work --stop-when-empty --max-time=55 >/dev/null 2>&1`
3. **Payment webhooks:** register `https://your-domain/webhooks/paystack`, `/webhooks/flutterwave` and `/webhooks/stripe`
   in each provider's dashboard. Use **test keys** first (see `QA-CHECKLIST.md`).
4. **Backups:** cPanel → *Backup Wizard* (or JetBackup). Back up the database and `brightstar/storage` + `public_html/uploads`.
5. Change nothing in `brightstar/.env` unless you know why; most things are in **Admin → Settings**.

## Troubleshooting
| Symptom | Fix |
|---|---|
| "500 Internal Server Error" | Check PHP version (8.2+). View `brightstar/storage/logs/laravel.log`. Make sure `storage` and `bootstrap/cache` are writable (permissions 755/775). |
| Installer says a folder is not writable | File Manager → right-click `storage` → *Change Permissions* → 755 (or 775), tick "recurse". |
| Images don't show | Your host blocked symbolic links; the installer then saves images to `public_html/uploads` automatically. If you moved folders later, re-run nothing: just keep `public_html/uploads` writable. |
| "No application encryption key" | `.env` lost its `APP_KEY`; restore from your backup, do not generate a new one on a live store (saved API keys would become unreadable). |
| Blank page after upload | Domain's document root must be `public_html` (or the folder containing `index.php`). |
| Want to reinstall | Delete `brightstar/storage/app/installed.lock` (this re-opens the installer; it will **not** erase existing data unless you drop the tables yourself). |

## Updating later
Build a new zip, upload and extract **over** the old files **except** keep your `brightstar/.env`, `brightstar/storage`
and `public_html/uploads`. Then visit `/install`? **No** — instead run migrations by opening cPanel → *Terminal*
(`php artisan migrate --force`) or ask your developer. Never delete `installed.lock`.
