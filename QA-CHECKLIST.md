# Manual QA checklist (run after install, before go-live)

Tick each item on a phone-width screen AND a desktop. Use payment **sandbox** keys.

## Storefront
- [ ] Home loads; logo, nav, announcement (enable it in Settings), hero, categories, product sections appear.
- [ ] Shop: search by name and by SKU; filters + sort combine; URL keeps the filters; "Clear all" works; empty results show suggestions.
- [ ] Product page: gallery thumbnails, variant dropdown changes the price, quantity, wishlist, review submit (appears only after admin approval).
- [ ] Out-of-stock product: Add to cart / Buy now disabled. Enquiry-only product: shows "Price on request" and only WhatsApp enquiry.
- [ ] Cart: change quantity, remove, coupon (valid, expired, below minimum), totals right. Log in with a guest cart: items merge.
- [ ] Open the browser dev tools, tamper with a price field in a form: the order total must not change.

## WhatsApp
- [ ] No number set → no WhatsApp buttons anywhere. Set a number → buttons appear.
- [ ] Product button opens WhatsApp with the SELECTED variant, quantity, SKU, price, link.
- [ ] "Order cart on WhatsApp" lists all items and totals. "Complete order on WhatsApp" creates a **pending confirmation** order first, then opens the chat; the order page says opening WhatsApp isn't confirmation.

## Payments (sandbox)
- [ ] Paystack success → order becomes paid ONLY after returning; email received; stock not double-reduced.
- [ ] Close the payment tab before paying → order stays unpaid; admin "Re-check" leaves it unpaid.
- [ ] Pay, then block the callback page (close tab): webhook alone marks it paid.
- [ ] Replay the same webhook twice (provider dashboard "resend"): still one payment, no duplicate emails.
- [ ] Bad webhook signature (curl with wrong header) → 401.
- [ ] Repeat the key items for Flutterwave. Try COD and manual bank transfer if enabled.
- [ ] Admin refund (partial then rest): statuses update; provider dashboard shows the refund.

## Admin
- [ ] staff account: sees Orders only. manager: no Settings, no refund button. admin: everything.
- [ ] Create product with variants + images (check a WebP + thumbnail are stored), duplicate, bulk publish, bulk price %, CSV export → edit → import (bad rows are listed).
- [ ] Cancel an unpaid order → stock returns once. Print an invoice (logo, items, totals).
- [ ] Nested categories; hero slide with start/end dates; nav mega-menu with image; page edit; article with products; newsletter test send + unsubscribe link.

## Accessibility & performance
- [ ] Keyboard only: skip link, menu, filters, checkout form, focus outline visible.
- [ ] Zoom 200%: no horizontal scroll. Lighthouse (mobile) on home + product: note scores and fix big images first.
