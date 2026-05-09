# Reel Ops Postmortem (2026-05-09)

This document captures what required manual effort, what worked reliably, and the default robust flow to follow.

## 1) What Needed Manual Effort

- Meta app onboarding fields in Developer Dashboard:
  - `App icon (1024x1024)`
  - `User data deletion`
  - `Category`
- Meta UI intermittently showed stale validation errors even when values were correct.
- Grok generation UI required strict control discipline (fresh page, correct prompt replacement, correct download control).

## 2) Root Causes We Observed

- Meta dashboard form state drift:
  - hidden form values and visible values could diverge;
  - save appeared to run, but required fields reset to defaults.
- Icon uploader intermittently returned generic `Something went wrong`.
- Grok scene generation drift:
  - accidental submission from wrong prompt state;
  - prompt not fully replaced (`Ctrl+A`/replace missing);
  - download readiness inferred incorrectly.

## 3) What Worked

## Meta

- Enabling `Allow API Access to app settings` in App `Settings -> Advanced`.
- Writing app fields via Graph API (more reliable than UI typing for some fields).
- For icon failures, generating plain validator-safe icon variants (1024x1024, stripped metadata).
- Facebook publish via local MP4 upload API (`/video_reels` flow start/upload/finish/poll).
- Fallback publish via Page video endpoint (`/{page_id}/videos`) when Reel object visibility is inconsistent.

## Grok

- Fresh `https://grok.com/imagine` start for first scene.
- Same-page prompt replacement for subsequent scenes:
  - click input, `Ctrl+A`, Backspace, paste next full prompt, submit.
- Check generation completion from actionable download state (not spinner text only).
- Keep workspace import mapping deterministic (`scene01.mp4`, `scene02.mp4`, ...).

## 4) Robust Default Flow (Project Standard)

1. Build reel locally end-to-end and finalize:
   - output: `final/reel_v2_logicloom.mp4`
   - preflight must pass (`audio`, `1080x1920`, naming checks).
2. Grok scene generation discipline:
   - first scene on fresh imagine page;
   - next scenes on same page with full replace of previous prompt;
   - download each scene and import immediately.
3. Meta app configuration stabilization (one-time / when broken):
   - verify app is not ineligible;
   - if stuck, set fields via API + re-open dashboard.
4. Publish order:
   - Facebook first via local upload API;
   - verify object visibility by querying page posts/videos;
   - Instagram publish after Facebook success.
5. If Facebook Reel appears “successful” but not visible:
   - run fallback publish through `/{page_id}/videos`;
   - use returned `permalink_url`.

## 5) Manual Steps We Should Keep (Minimum)

- Captcha / anti-bot challenges.
- First-time Meta app compliance fields if dashboard enforces fresh UI confirmation.
- Rare icon upload retry in a clean browser session.

## 6) Automation Improvements To Implement Next

- Add one script to validate and set app compliance fields via API:
  - privacy URL, terms URL, user deletion URL, category, domains, namespace, logo URL.
- Add `publish_facebook_verify.ps1`:
  - publish;
  - poll processing;
  - assert appearance in `/{page_id}/posts` or `/{page_id}/videos`;
  - if missing, auto-run fallback endpoint and return permalink.
- Add Grok prompt runner guardrails:
  - hard `Ctrl+A` replacement before every submit;
  - reject submit if input does not match expected scene prefix;
  - require download-ready check before advancing scene index.

## 7) Final Working Baseline

- Facebook post now works via API.
- Meta compliance warning can be cleared.
- Reel generation + local caption pipeline works.
- Remaining fragility is mostly third-party UI state, not core local pipeline.

