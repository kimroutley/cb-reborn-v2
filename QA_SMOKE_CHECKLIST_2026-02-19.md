# QA Smoke Checklist — 2026-02-19

## Host app

- [ ] Open `Profile` from drawer.
- [ ] Edit username/public ID/avatar/style.
- [ ] Try leaving profile via drawer without saving and verify discard prompt appears.
- [ ] Cancel prompt and confirm you remain on profile with edits preserved.
- [ ] Repeat and choose discard; confirm navigation proceeds and changes reset.
- [ ] Save profile; confirm success feedback and dirty state clears.
- [ ] Re-open profile and verify saved values persisted.

## Player app

- [ ] Open `Profile` from drawer.
- [ ] Make profile edits (username/public ID/avatar/style).
- [ ] Navigate away through drawer and verify discard confirmation appears.
- [ ] Cancel once (stay on profile), then discard once (leave profile).
- [ ] Use Reload From Cloud and confirm values rehydrate correctly.

## About / changelog

- [ ] Open About in Host and Player.
- [ ] Verify About includes:
  - [ ] “A game by Kyrian Co.”
  - [ ] Version/build label
  - [ ] Release date
  - [ ] Credits
  - [ ] Copyright line
- [ ] Expand “View latest updates”.
- [ ] Confirm only the 3 latest builds are shown.

## Hall of Fame navigation

- [ ] Host Home quick action opens Hall of Fame.
- [ ] Player Stats action opens Hall of Fame.

## Regression sanity

- [ ] Host drawer remains responsive after profile discard/cancel cycles.
- [ ] Player drawer shows no layout overflow on common screen sizes.
- [ ] No stuck overlays/dialogs after cancelling discard prompts.
