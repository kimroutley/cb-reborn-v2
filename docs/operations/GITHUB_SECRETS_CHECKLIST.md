# GitHub Actions secrets checklist

Implement these three repository secrets so the **Deploy to Firebase** workflow can run on push to `main`.

**Where to add:** GitHub → this repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

---

## 1. FIREBASE_SERVICE_ACCOUNT

- [ ] **Get the key**
  1. Open [Firebase Console](https://console.firebase.google.com) and select your project.
  2. Click the gear icon → **Project settings**.
  3. Open the **Service accounts** tab.
  4. Click **Generate new private key** → confirm. A JSON file downloads.
  5. Open the file in a text editor and copy the **entire contents** (one object, from `{` to `}`).

- [ ] **Add in GitHub**
  1. GitHub → repo **Settings** → **Secrets and variables** → **Actions**.
  2. Click **New repository secret**.
  3. **Name:** `FIREBASE_SERVICE_ACCOUNT`
  4. **Value:** Paste the full JSON (entire file). Save.

---

## 2. FIREBASE_PROJECT_ID

- [ ] **Get the ID**
  1. In [Firebase Console](https://console.firebase.google.com) → **Project settings** (gear) → **General**.
  2. Copy **Project ID** (e.g. `cb-reborn-xxxx`).

- [ ] **Add in GitHub**
  1. **New repository secret**.
  2. **Name:** `FIREBASE_PROJECT_ID`
  3. **Value:** Paste the project ID. Save.

---

## 3. FIREBASE_TOKEN

- [ ] **Get the token**
  1. On your machine, open a terminal in this repo (or any folder).
  2. Run: `firebase login:ci`
  3. Complete the browser sign-in if prompted.
  4. The CLI prints a long token. Copy the **entire** token.

- [ ] **Add in GitHub**
  1. **New repository secret**.
  2. **Name:** `FIREBASE_TOKEN`
  3. **Value:** Paste the token. Save.

---

## Verify

- [ ] All three secrets appear under **Actions** → **Secrets** (values are hidden).
- [ ] Push to `main` or go to **Actions** → **Deploy to Firebase** → **Re-run all jobs**. The job should pass the “Validate Firebase deploy secrets” step and proceed to deploy.

See [LETS_DO_IT_RUNBOOK.md](LETS_DO_IT_RUNBOOK.md) Section 1 for context.
