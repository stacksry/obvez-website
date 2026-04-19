# Deploy to GitHub Pages

Step-by-step. Goal: get the site live on a free `*.github.io` preview URL, QA on mobile + desktop, then (later) point `obvezlabs.com` at it.

---

## Phase 1 — Preview URL

### 1. Create the repository

In your terminal, from `/Users/tallapa/obvez-website/`:

```bash
cd "/Users/tallapa/obvez-website"
git init
git add .
git commit -m "Initial site — Apple-pure revamp + brand system"
git branch -M main
```

Then create a new **public** repository on GitHub (private works too but Pages on private requires a paid plan). Go to https://github.com/new — name it `obvez-website` (or anything you like; the name becomes part of the URL).

After creating it, GitHub will show you two commands. Run them:

```bash
git remote add origin https://github.com/<your-username>/obvez-website.git
git push -u origin main
```

### 2. Enable GitHub Pages

1. On GitHub, go to your repo → **Settings** → **Pages** (left sidebar).
2. Under **Build and deployment** → **Source**, choose **"GitHub Actions"** (not "Deploy from a branch").
3. You're done. The workflow at `.github/workflows/deploy.yml` will run on every push to `main`.

### 3. Watch the first deploy

1. Go to the **Actions** tab. You should see a run called "Deploy to GitHub Pages" in progress.
2. When it finishes (~30-60 seconds), the run page shows the deployed URL — typically:
   `https://<your-username>.github.io/obvez-website/`
3. Open that URL on desktop *and* mobile. Share the link via WhatsApp/iMessage — this time images load because everything is served over HTTPS from GitHub's CDN.

### 4. QA checklist

- [ ] Hero image loads
- [ ] About + service images load
- [ ] CTA band background image loads
- [ ] Nav sticky + blur works on scroll
- [ ] Mobile nav toggle opens the sheet
- [ ] Contact form accepts input + shows success message
- [ ] Fonts render (Inter — from Google Fonts)
- [ ] Reveal animations fire as you scroll
- [ ] Skip-to-content works with keyboard
- [ ] `sitemap.xml` reachable at `/sitemap.xml`
- [ ] `robots.txt` reachable at `/robots.txt`
- [ ] Brand guidelines reachable at `/brand/logo-guidelines.html`

If anything's broken, edit locally, `git commit -am "fix: ..."` and `git push` — the workflow redeploys automatically.

---

## Phase 2 — Switch obvezlabs.com to the new site

Only do this after Phase 1 QA is green.

### 1. Add the CNAME file

Create a file called `CNAME` at the repo root (no extension) with exactly one line:

```
obvezlabs.com
```

Commit and push. (You can also do this through GitHub's web UI: **Add file → Create new file → `CNAME`**.)

### 2. Configure DNS at your domain registrar

Log in wherever you bought `obvezlabs.com`. You need **four A records** on the apex (`@`) and **one CNAME** for `www`.

| Type  | Host | Value                  |
| ----- | ---- | ---------------------- |
| A     | @    | 185.199.108.153        |
| A     | @    | 185.199.109.153        |
| A     | @    | 185.199.110.153        |
| A     | @    | 185.199.111.153        |
| CNAME | www  | `<your-username>.github.io` |

**Important:** delete any existing A/AAAA/CNAME records for `@` and `www` before adding these. Keep MX records (email) untouched.

### 3. Enable custom domain + HTTPS

1. Back in **Settings → Pages**, under **Custom domain**, enter `obvezlabs.com` and click **Save**.
2. GitHub runs a DNS check. Once it passes (can take a few minutes up to 24 hours), check **Enforce HTTPS**.
3. GitHub provisions a free Let's Encrypt certificate — usually within 15 minutes.

Verify: open `https://obvezlabs.com` — the site loads with a valid lock icon.

### 4. Update the canonical URL (optional but recommended)

In `index.html` the canonical is already `https://obvezlabs.com/` and the sitemap points there — no changes needed. But double-check there are no hard-coded references to the `*.github.io` preview URL.

---

## Phase 3 — Maintenance

- **To update content:** edit files locally → `git commit -am "msg"` → `git push`. The workflow redeploys automatically in ~30s.
- **To roll back:** in the **Actions** tab, open any previous successful run → click **Re-run jobs**. GitHub redeploys that version.
- **To preview changes before going live:** create a branch, open a PR. (GitHub Pages only auto-deploys `main` with our current workflow; PR previews would need Cloudflare Pages or Netlify instead.)

---

## Files added for deployment

- `.github/workflows/deploy.yml` — the Pages deploy workflow
- `.nojekyll` — tells Pages to skip Jekyll processing (preserves `brand/`, `.well-known/`, etc.)
- `.gitignore` — keeps OS junk + the `.plugin` bundle out of git
- `404.html` — on-brand 404 page (GitHub Pages serves this automatically for missing paths)

## Files to ignore for deployment

If you have a `design.plugin` file in this folder from earlier, it's already excluded by `.gitignore`. It shouldn't ship to production.
