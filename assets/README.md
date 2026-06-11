# Assets

Visuals for the README. Capture from a **real WezTerm window** (VHS/asciinema use
their own terminals and won't show BiDi).

## `before-after.png` — the money shot
Same Hebrew table, side by side:
- **before:** `cat ~/hebrew-rtl-test.txt` in **cmux / Terminal.app** (reversed, gappy)
- **after:** same command in **WezTerm** (right-to-left, tight)

A test fixture is created at `~/hebrew-rtl-test.txt` by the setup. Screenshot both,
combine side-by-side (Preview, or `convert before.png after.png +append before-after.png`).

## `demo.gif` — the workflow
~15–20s screen recording (⌘⇧5) of WezTerm showing:
1. **⌘P** → fuzzy project picker → pick a project (tab labels it)
2. **⌘⇧P** → launches `claude` in a project
3. tab badge goes **◐ working → ● needs you**
4. the **"Claude is waiting · Show"** notification → click **Show** → jumps to that tab
5. a Hebrew table rendering right-to-left

Then: `./scripts/make-gif.sh ~/Desktop/recording.mov assets/demo.gif`
