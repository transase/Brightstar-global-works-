# Brightstar Global Furniture – Phases 1–10

This folder is an **overlay** for a fresh Laravel install (PHP 8.2+, MySQL/MariaDB). It contains the shop, cart,
checkout, WhatsApp ordering, Paystack/Flutterwave payments, and the database schema for the whole project.
Phase 2 adds the admin panel at `/admin`: dashboard, orders (status, notes, printable invoice, stock restore on
cancel), products (variants, images, duplicate, bulk actions, CSV import/export with error report), categories
(nested), coupons, review moderation, payment reconciliation, and settings (store, WhatsApp, gateway toggles).
Phase 3 adds: queued order emails (customer + store), automatic release of stock held by abandoned online-payment
orders, wishlist, `sitemap.xml` / `robots.txt` / product structured data, and editable hero slides and promo banners
(with scheduling) under Admin → Slides & banners.
Phase 4 adds: customer order history with one-click reorder (current prices/stock), a navigation + mega-menu editor,
editable pages (About, Contact, delivery, returns, privacy, terms), automatic image resizing + WebP + thumbnails (GD),
security headers, and `DEPLOYMENT.md` (shared-hosting steps and a go-live checklist).
Phase 5 adds: "Ideas for Your Space" articles with a "Shop this look" product grid (admin-curated, scheduled
publishing, shown on the homepage and sitemap) and admin-only automated refunds (partial or full) through Paystack and
Flutterwave. A refund is recorded only after the provider accepts the request; providers may settle it asynchronously.
Phase 6 adds: newsletter campaigns (queued, test-send, per-subscriber unsubscribe link and header, re-subscribe), a
skip-to-content link, and bug fixes found in a review pass (SQLite-safe migration, admin nav highlighting, Tailwind v4 note).
Phase 7 adds clickable product pins on an article's cover photo (place them by clicking the image in Admin → Ideas;
customers tap a pin to see the product card).
Phase 8 adds Stripe Checkout as an optional third gateway (same server-side verification, signed + replay-protected
webhooks, refunds). Set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`; webhook URL `/webhooks/stripe`, event
`checkout.session.completed`. Stripe only appears at checkout if keys are set and it is switched on in Settings.
Phase 9 moves (almost) everything into Admin → Settings: logo, favicon, hero photo and brand colours; Paystack, Flutterwave
and Stripe keys; SMTP email (with a test button); tax rate and label; free-delivery threshold; delivery areas and fees;
default country; order-number prefix; low-stock threshold. Secret values are stored **encrypted with APP_KEY**, never shown
again, and fall back to `.env` if not set in admin. New: Admin → Users (staff roles, passwords, customers) and Delivery areas.
Register `App\Providers\StoreSettingsServiceProvider::class` in `bootstrap/providers.php` (install.sh does this).
Still in `.env` by necessity: DB credentials, APP_KEY, APP_URL, queue/cache drivers.
Phase 10 closes the gaps found in an audit against the written brief: full default navigation + header icons + WhatsApp
shortcut; **Collections**; homepage "Shop by room", configurable "Why shop with us", customer reviews, featured category
cards, footer socials/categories/payment badges; product cards with add-to-cart, WhatsApp and **quick view**; list view,
colour/size filters and active-filter chips; product page lightbox, variant images, share, wishlist, ratings, delivery
info and category-specific specifications; brand, social-image, variant-image and image-order controls in the admin;
cart option switching; **billing address**; live delivery total; bank-transfer details and **pay online / retry / pay-later
(signed link)** on the order page; WhatsApp cart template + greeting settings that are actually used; S3-compatible media
disk (`MEDIA_DISK=s3`); search layer isolated in `ProductSearch`; brand logo on the login screens; browser installer.
**Still not built (optional in the brief):** WhatsApp Business **Cloud API** automation (needs Meta business verification and
approved message templates, so it is left for when you have those credentials), multi-currency, and anything in the
brief after Section 13 (the document you sent stops mid-sentence at "Fulf…").
**Not yet built:** WhatsApp Cloud API, review photos,
multi-currency, refund status webhooks.

## Install
**cPanel / shared hosting (no SSH): see `CPANEL.md`.** Build `brightstar-cpanel.zip` for free with the included GitHub Actions
workflow (or `bash scripts/build-cpanel-package.sh`), upload it, then finish in the browser at `/install` (requirements
check, database, admin account, install code). The same workflow also runs the whole test-suite and saves the results.

**Fastest (developer/VPS):** `bash install.sh ../brightstar-app` automates every step below (untested across all Laravel versions; it prints each step). Then follow `QA-CHECKLIST.md`.

Manual steps:
```bash
composer create-project laravel/laravel brightstar && cd brightstar
composer require laravel/breeze --dev && php artisan breeze:install blade   # install BEFORE copying the overlay
# This overlay's CSS uses Tailwind v4 syntax. Ensure v4 after Breeze:
#   npm i -D tailwindcss@4 @tailwindcss/vite   (add tailwindcss() to the plugins in vite.config.js; delete tailwind.config.js and postcss.config.js if Breeze created them)
# add `implements MustVerifyEmail` to app/Models/User.php (the admin area requires verified email)
npm i alpinejs && npm i            # Tailwind v4 ships with current Laravel; Vite is included
# copy this overlay's folders (app, config, database, resources, routes, tests) over the project
cat .env.additions >> .env         # then fill in keys and DB settings
# merge config/services.additions.php into config/services.php
php artisan storage:link
php artisan migrate --seed --class=BrightstarSeeder
npm run dev && php artisan serve
php artisan test
```
1. In `bootstrap/app.php` (inside `withMiddleware`): `$middleware->validateCsrfTokens(except: ['webhooks/*']);`
   and `$middleware->alias(['role' => \App\Http\Middleware\EnsureRole::class]);`
2. **Replace the placeholders** `public/images/logo.png` (a text-only stand-in, NOT your real logo), `public/images/hero.jpg`, and optionally `placeholder-furniture.svg` with your real brand assets.
3. Set the WhatsApp number (Setting key `whatsapp_phone`, international format) – buttons stay hidden until it is set.
4. Webhook URLs: `https://YOUR-DOMAIN/webhooks/paystack` and `/webhooks/flutterwave`. For Flutterwave set the same
   value as `FLUTTERWAVE_WEBHOOK_HASH` in its dashboard.
5. Change the seeded admin password immediately (`ADMIN_EMAIL` / `ADMIN_PASSWORD` in `.env` before seeding).

## Design decisions
- Money is stored as integer minor units (kobo); prices and totals are always recomputed server-side.
- Payment is "paid" only after the server verifies reference, amount and currency with the provider; callback and
  webhook can both fire safely (idempotent). Webhook signatures are checked (HMAC-SHA512 for Paystack, `verif-hash` for Flutterwave).
- Stock is reserved (row-locked) when an order is placed. Restoring stock on cancel/failed payment comes with the admin order tools.
- WhatsApp orders are saved as `pending_confirmation`; the page states opening WhatsApp is not proof of sending.

## Roles
`admin` everything · `manager` catalogue, orders, coupons, reviews, payments (no settings) · `staff` orders only.
Set a user's role with `php artisan tinker` → `User::where('email', ...)->first()->forceFill(['role' => 'manager'])->save();`

## Phase 3 operations
- **Queue worker:** emails are queued. Run `php artisan queue:work` (or a supervisor/cron equivalent on shared hosting:
  `* * * * * php artisan queue:work --stop-when-empty`). Configure `MAIL_*` in `.env` and set the store email in Settings
  to receive new-order alerts.
- **Scheduler:** add the cron `* * * * * php /path/to/artisan schedule:run`. It runs `orders:release-stale` hourly, which
  re-checks the provider and then cancels online-payment orders unpaid after 3 hours (change with `--hours`).
- **robots.txt:** delete Laravel's default `public/robots.txt` so the dynamic route (which includes the sitemap URL) is used.
