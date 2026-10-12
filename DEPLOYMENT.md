> **cPanel / shared hosting?** Follow `CPANEL.md` (browser installer, no SSH needed). This file covers VPS and general production notes.

# Deployment & go-live checklist

## Server
- PHP 8.2+ with extensions: mbstring, openssl, pdo_mysql, tokenizer, xml, ctype, json, fileinfo, **gd (with WebP)** for image optimisation.
- MySQL 8 / MariaDB 10.6+ (the product search uses a FULLTEXT index; plain LIKE search works either way).
- HTTPS everywhere. Payment callbacks and webhooks must be reachable over HTTPS.

## Shared hosting (cPanel)
1. Upload the app **outside** `public_html`; point the domain's document root to the app's `public/` folder
   (or copy `public/` contents into `public_html` and edit the two paths in `index.php`).
2. Create the database/user in cPanel, fill `.env`, then `php artisan migrate --force` (SSH or a one-time route/cron if SSH is unavailable).
3. `php artisan storage:link` (if symlinks are blocked, set `FILESYSTEM_DISK=public` and copy `storage/app/public` to `public/storage` or ask the host).
4. Cron (every minute): `* * * * * php /home/USER/app/artisan schedule:run >> /dev/null 2>&1`
5. Queue: `* * * * * php /home/USER/app/artisan queue:work --stop-when-empty --max-time=55`
6. `composer install --no-dev --optimize-autoloader && npm run build` (build locally and upload `public/build` if the host has no Node).
7. `php artisan config:cache route:cache view:cache event:cache`

## .env must have
```
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain
SESSION_SECURE_COOKIE=true
QUEUE_CONNECTION=database
MAIL_*   (real SMTP)
PAYSTACK_SECRET_KEY / FLUTTERWAVE_SECRET_KEY / FLUTTERWAVE_WEBHOOK_HASH  (LIVE keys only after testing)
ADMIN_EMAIL / ADMIN_PASSWORD  (before seeding)
```

## Security
- Register the headers middleware in `bootstrap/app.php`: `$middleware->append(\App\Http\Middleware\SecurityHeaders::class);`
  (A strict Content-Security-Policy is not included because Alpine.js's standard build needs inline evaluation; add one if you adopt `@alpinejs/csp`.)
- Change the seeded admin password immediately; use a long unique password; give staff the `staff`/`manager` role, not `admin`.
- Never commit `.env`. Rotate any key that was ever pasted into chat, email or a ticket.
- Keep `storage/` and `.env` unreachable from the web (document root must be `public/`).
- Take daily database backups and keep copies off the server. Test a restore once.

## Before taking real money (do all of these)
1. Run `php artisan test` on the server's PHP version and fix any failures.
2. Complete test-mode payments with Paystack and Flutterwave **sandbox keys**: success, failure, abandoned, and a deliberately
   wrong amount. Confirm the order only becomes "paid" after verification, in both callback-only and webhook-only cases.
3. Register webhook URLs (`/webhooks/paystack`, `/webhooks/flutterwave`) in each dashboard; confirm a bad signature returns 401.
4. Settings → set the WhatsApp number, store email, phone, address, currency; place a WhatsApp order and confirm it stays *pending*.
5. Write real About, Contact, Delivery, Returns, Privacy and Terms pages. Only state guarantees, warranties and delivery
   times the business has confirmed.
6. Check logo/favicon, `/robots.txt`, `/sitemap.xml`, mobile layout, keyboard navigation, and colour contrast (red on white buttons pass; check any text on yellow).
7. Confirm legal basics for your market (e.g. NDPA/GDPR privacy notice, cookie notice if you add analytics, consumer-return rules).
