# Accessibility: the manual pass

Eight WCAG criteria in `docs/ACCESSIBILITY.md` are marked **Unverified**, and
they will stay that way until somebody walks the app with a screen reader.
None of them can be settled by reading code or by asserting a semantics
property: they are about *order*, *sequence* and *whether a person can finish
the job*, and only a person can answer that.

This is the walk. It exists so the pass is repeatable and its result is a
record rather than an impression — run it, fill in §4, and move the rows it
settles in `ACCESSIBILITY.md` from Unverified to Reviewed or to a failure.

**Budget about 90 minutes per platform.** Do not do all three in one sitting;
the second half of a long pass stops noticing things.

---

## 1. What to run it on

| Platform | Reader | Turn it on |
|---|---|---|
| iOS | VoiceOver | Settings → Accessibility → VoiceOver, or triple-click the side button |
| macOS | VoiceOver | ⌘F5 |
| Android | TalkBack | Settings → Accessibility → TalkBack |
| Web | NVDA (Windows) or VoiceOver (Safari) | — |

One platform is worth more than none. If you only do one, **do iOS**: it is
where most of the congregation will run this, and VoiceOver's rotor makes the
heading and traversal problems obvious fastest.

Run it on a **release-mode build against real data** — a congregation with
enough participants that the picker scrolls. A debug build with three names
hides the ordering problems this pass exists to find.

## 2. How to walk it

Use the reader's own navigation, not taps:

- **iOS/macOS** — swipe right / left (or VO+→) to move by element. Use the
  rotor on Headings, then on Form Controls.
- **Android** — swipe right / left. Use the reading-controls menu to switch to
  Headings.
- **Web** — `Tab` for controls, `H` for headings in NVDA browse mode.

At each step, three questions. They are the whole pass:

1. **Does it have a name?** Something is read, and what is read is what the
   thing is — not "button", not the label of the thing beside it.
2. **Does it say its state?** Selected, disabled, toggled, busy.
3. **Did the order make sense?** You arrived here from where you would expect,
   and nothing was skipped or read twice.

Write down anything that fails, with the screen and the element. A "no" with no
location is not a finding.

## 3. The walk

### 3.1 First run

Fresh install, or Settings → delete all data.

1. **Boot splash.** The mark plays and settles. *Expect:* it announces the
   product name; the spinner, if it appears, announces that it is loading.
2. **Cover screen.** *Expect:* the title reads as a **heading** (rotor →
   Headings finds it). Three buttons, each named for what it does, in the order
   they appear on screen.
3. **Create a local profile.** *Expect:* every field announces its own label —
   name, password, confirm — not the label of the field above it. The password
   fields are announced as secure.
4. **Submit with a wrong confirmation.** *Expect:* **the error is announced
   without you moving focus to it.** This is criterion 4.1.3 and the single
   most likely thing to fail.
5. **Submit correctly.** *Expect:* you land in the app, and focus is somewhere
   sensible rather than back at the top of a screen you have already left.

### 3.2 The shell

6. **Navigation.** Find the three destinations — Inicio, Participantes,
   Configuración. *Expect:* each is named, and the active one **says it is
   selected**. On a phone this is Material's bar; on a desktop window it is the
   rail, which is a different implementation and has to be checked separately.
7. **Rotor → Headings, on each of the three screens.** *Expect:* the screen
   title is there, and so is every section header. If Headings finds nothing,
   the whole screen is one flat list and that is a failure.
8. **Resize to a phone width and back** (desktop/web only). *Expect:* the same
   elements, in the same order.

### 3.3 The dashboard with nothing in it

9. **A brand-new account.** *Expect:* the empty state is read — what is
   missing, then the button that fixes it — and the button lands you on the
   Congregation tab, not merely in Settings.

### 3.4 Doing the actual work

10. **Add a participant.** Fields, privilege, save.
11. **Open a project, then a week.** *Expect:* the week heading is read **in
    the meeting's language**, with the reader switching voice or pronunciation
    for it. If a Spanish heading is read with an English voice, criterion 3.1.2
    is failing even though the markup is there.
12. **Move through the assignment cards.** *Expect:* each part's title, then
    its slots, each slot named for its role — "Estudiante", "Ayudante" — and an
    unassigned one says it is empty rather than reading as an unnamed button.
13. **Open the person picker on a slot.** *Expect:* the search field is
    reachable, the list is navigable, and **the panel does not trap you**: you
    can dismiss it and return to the card you came from. This is 2.1.2 and the
    other likely failure.
14. **Assign somebody. Then remove them.** *Expect:* both changes are
    announced or immediately discoverable; the remove control is named
    something other than "close".
15. **Export.** *Expect:* the export button announces that it is working
    (4.1.3, the busy hint), and the outcome — success or failure — is read
    without you going looking for it.

### 3.5 Settings

16. **Switch the app language.** *Expect:* the reader picks up the new
    language rather than reading Spanish with an English voice. On the web,
    check that the page's own language changed with it.
17. **Switch the theme.** *Expect:* nothing about the reading changes.
18. **The sync card.** Turn the network off and wait. *Expect:* the status
    change is announced without you being focused on it.

### 3.6 The stress pass

Repeat §3.4 with:

19. **Text at 200%** (iOS: Accessibility → Display & Text Size → Larger Text).
    *Expect:* nothing clipped, nothing overlapping, and every control still
    reachable.
20. **Reduce Motion on.** *Expect:* everything still arrives; nothing is stuck
    waiting for an animation that no longer runs. The PDF preview's loader
    should still turn — it is the state, not decoration.

## 4. The record

Fill this in and keep it. A dated result with a name on it is what turns
"unverified" into "verified".

| | |
|---|---|
| Date | |
| Platform and OS version | |
| Reader and version | |
| App version / commit | |
| Who ran it | |

| § | Step | Pass / fail | Note |
|---|---|---|---|
| 3.1 | 1–5 first run | | |
| 3.2 | 6–8 shell | | |
| 3.3 | 9 empty dashboard | | |
| 3.4 | 10–15 the work | | |
| 3.5 | 16–18 settings | | |
| 3.6 | 19–20 stress | | |

### What each step settles

| Criterion | Settled by |
|---|---|
| 1.3.2 Meaningful Sequence | steps 2, 6, 12 |
| 1.3.3 Sensory Characteristics | the whole walk — anything read as "the button on the right" |
| 2.1.2 No Keyboard Trap | step 13, and any modal |
| 2.4.3 Focus Order | steps 3, 5, 12 |
| 2.4.11 Focus Not Obscured | step 12 on a scrolled screen with a fixed bar |
| 1.4.10 Reflow (web) | step 8 |
| 1.4.12 Text Spacing (web) | step 19 |
| 1.4.13 Content on Hover or Focus | any tooltipped icon button |

## 5. After the pass

1. Move every settled row in `ACCESSIBILITY.md` §3 and §6 out of Unverified.
2. Open an issue per failure, titled as the symptom — "the picker cannot be
   dismissed with VoiceOver", not "fix 2.1.2".
3. If a failure is one a test could have caught, add the test with the fix.
   `test/ui/semantics_test.dart` is where those live.

Until §4 has a filled-in row, `ACCESSIBILITY.md` is a self-assessment of the
code, not of the product.
