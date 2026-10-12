#!/usr/bin/env bash
# Developer/VPS installer (needs SSH, PHP 8.2+, Composer, Node). For cPanel shared hosting see CPANEL.md.
#   bash install.sh ../brightstar-app
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-../brightstar-app}"
say() { printf '\n==> %s\n' "$*"; }

bash "$SRC/scripts/prepare.sh" "$TARGET"
cd "$TARGET"
grep -q ADMIN_EMAIL .env || printf '\nADMIN_EMAIL=admin@example.com\nADMIN_PASSWORD=change-me-now\n' >> .env

say "Database, storage link, seed"
php artisan key:generate --force
echo "Make sure DB_* in .env point at an EMPTY database, then press Enter (Ctrl+C to stop)."; read -r _
php artisan migrate --force
php artisan db:seed --class=BrightstarSeeder
php artisan storage:link || true
printf 'Installed via install.sh\n' > storage/app/installed.lock   # tells the app the web installer is not needed

say "Build assets and run tests"
npm run build
php artisan test || echo "!! Some tests failed. Send me the output."

cat <<MSG

Done. Next:
  1. php artisan serve      -> http://127.0.0.1:8000   (admin: /admin, login from .env ADMIN_EMAIL / ADMIN_PASSWORD)
  2. Replace public/images/logo.png + hero.jpg (or upload your logo in Admin -> Settings)
  3. Follow QA-CHECKLIST.md;  php artisan queue:work  and  php artisan schedule:work  for emails and cleanup
MSG
