# Finance Portal — Install as App (PWA)

After Sprint 5, the portal can be installed to your phone or computer like a real app.

## Files needed

Keep all of these in the **same folder**:
- `finance-tracker.html` — the app
- `manifest.webmanifest` — install metadata
- `sw.js` — service worker (offline support)
- `icon-192.svg` · `icon-512.svg` · `icon-maskable.svg` — app icons

⚠️ **Important:** All files must be in one folder. The HTML references the others by relative path.

## To install (per device)

### Android (Chrome / Edge / Samsung Internet)
1. Open `finance-tracker.html` in browser
2. Wait a few seconds for the install prompt to appear, OR
3. Tap the **⋮ menu** in your browser → "Install app" or "Add to Home screen"
4. Confirm — app appears on your home screen
5. Open from home screen — runs fullscreen, no browser bars

### iPhone / iPad (Safari)
1. Open `finance-tracker.html` in Safari (must be Safari, not Chrome on iOS)
2. Tap the **Share** button (square with arrow up)
3. Scroll down → "Add to Home Screen"
4. Tap **Add** — icon on home screen
5. Open from home screen — runs fullscreen

### Desktop (Chrome / Edge / Brave)
1. Open `finance-tracker.html` in browser
2. Look for the **install icon** in the address bar (right side, looks like ⊕ or a screen with arrow)
3. Click it → confirm install
4. App opens in its own window, no tabs/address bar

## Hosting it on the internet (optional, for true cross-device access)

If you want to open the app from a URL instead of a local file:

### Easiest: Netlify Drop
1. Go to https://app.netlify.com/drop
2. Drag the entire **APK Project** folder onto the page
3. You get a free URL like `random-name.netlify.app`
4. Use this URL to install the app on any device — much smoother than opening local files

### GitHub Pages
1. Create a free GitHub repo, upload the files
2. Settings → Pages → Source: main branch
3. Get URL `yourname.github.io/repo-name`

### Vercel (similar to Netlify)
1. Sign up at vercel.com
2. Import project from GitHub or drag folder

## What you get with PWA install

| Feature | Browser tab | Installed PWA |
|---|---|---|
| Address bar | Yes | No (full app feel) |
| Home screen icon | No | Yes |
| Standalone window | No | Yes |
| Offline support | No | **Yes — works without internet** |
| Push notifications | Limited | Full (with permission) |
| Update on launch | Yes (manual refresh) | Yes (background) |

## Offline behavior

After first load, the service worker caches:
- The HTML, manifest, icons
- Chart.js, Lucide icons, SheetJS, JSZip
- Supabase SDK

Open the app **without internet** → it works fully for browsing local data.

If you've connected cloud sync, changes you make offline will sync automatically when you're back online.

## Notifications

1. Open app → Settings → Cloud & Profiles tab → **Enable notifications**
2. Browser asks for permission → click **Allow**
3. App will show a notification each day for:
   - Credit card payments due in ≤7 days
   - Loan EMIs due in ≤5 days
   - Insurance renewals in ≤30 days
   - Account low-balance warnings

Notifications appear in your system tray (Windows / Mac) or notification shade (Android / iOS).

## Troubleshooting

**"Install" button doesn't appear:**
- Open from a real URL (not `file://` local path) for best PWA support
- Some browsers require HTTPS — host on Netlify for free HTTPS
- iOS Safari uses "Add to Home Screen" instead of an automatic prompt

**Service worker not registering:**
- Open browser DevTools (F12) → Application → Service Workers — see if it's registered
- Try `file://` paths often don't allow service workers — use a real URL

**App not working offline:**
- After first install, open the app once while online so the SW can cache everything
- DevTools → Application → Cache Storage → look for `fp-v1.0.0`

**To completely uninstall:**
- Android: long-press the app icon → Remove → Confirm
- iOS: long-press → Delete app
- Desktop: right-click in app window → Uninstall
