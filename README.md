# DisplayClassPlanner — Demo App

**A fold is a capacity event. This app lets you watch one happen and count what it cost.**

Three buttons, one actor, and a live read of the plan diff underneath. It exists to make three
things visible that are otherwise invisible in a real app — they only show up as a bandwidth bill,
a flash of empty cells, and a re-request you never see.

This is the runnable companion to
[**display-class-planner-kit**](https://github.com/rajatslakhina/display-class-planner-kit), which it
consumes as a **remote Swift Package pinned to an exact version** — not a local path, not `main`.

---

## Why this matters

Every guide about foldables, Split View and Stage Manager stops at "adopt `NavigationSplitView`".
That handles the *layout*. It does nothing about the fact that the viewport just doubled **while
requests were in flight**, that a detail pane now exists demanding content nobody asked for, and that
the whole thing can reverse in 300 ms.

The naive re-plan is `cancelAll(); startAll()`. It ships in a lot of apps. It has two bugs and a
third one you can't see:

1. **The duplicated fetch** — most of what you cancelled is in the list you're about to start.
2. **The storm** — fold, unfold, fold. Each crossing runs the cycle again.
3. **The dropped response** — a request you cancelled still arrives. If your handler discards it and
   the item has since been re-admitted, you pay for those bytes twice.

The library's answer is to emit a *diff* keyed by stable identity, hold contractions behind
asymmetric hysteresis, and fence responses by generation. This app is where you can see each of
those do its job, with the counters to prove it.

---

## What the three buttons do

| Control | What it demonstrates |
|---|---|
| **Surface** (Cover / Inner / External) | Expanding applies instantly and **retains** what is already running. Contracting enters a 400 ms hold and only then cancels. Watch `retained` stay high and `cancelled` stay at 0 across an expansion. |
| **Run fold storm** | Contract, then revert before the hold elapses. `storms absorbed` increments; **`cancelled` does not move.** Without hysteresis this sequence would cancel the speculative tail and re-request it a moment later. |
| **Run salvage scenario** | Issue → cancel → re-admit → the original response finally lands. The planner returns `.salvaged(originalGeneration:currentAdmission:)` instead of dropping the payload. This is the case a hand-rolled generation guard gets wrong. |
| **Complete highest-priority request** | Drains one cell so you can watch the in-flight set shrink and the verdict for a normal, current-generation response. |

Below the buttons, the last transition is broken into its four buckets — `retained`,
`reprioritized`, `cancelled`, `admitted` — and run through `PlanTransition.validate()` live, so the
invariant is asserted on screen rather than claimed in a README.

**What you should see on launch:** the app starts at **Cover** and immediately seeds a plan, so the
grid is already populated — **45 of the 48 catalogue items are admitted**, limited by the decode
budget (40,824,000 bytes ÷ 900,000 bytes per item = 45.36), not by prefetch depth. Switching to Inner
or External admits all 48. Nothing here requires a network or a fixture file; the catalogue is
synthetic and deterministic.

---

## Screenshots

**There are none, and this section exists to say so plainly rather than leave a gap you'd have to
interpret.**

The app was **not** run on a Simulator during the run that produced this repo. Screen-control access
*was* granted, but a screenshot showed Xcode already open on an unrelated project with two live
Simulators — someone else's work on the same machine. The automation's own rule is to stop rather
than click through that, so it stopped. No screenshots were captured, and no `Demo/Screenshots/`
directory exists.

**"It builds" and "it ran" are two different claims and this README makes only the first.** See
[Verification](#verification) for exactly what was and was not checked.

---

## How to run it

```bash
git clone https://github.com/rajatslakhina/display-class-planner-kit-demo-app.git
cd display-class-planner-kit-demo-app
open Demo.xcodeproj
```

Then in Xcode: wait for **DisplayClassPlanner** to resolve from GitHub (Report navigator shows the
fetch), select the **Demo** scheme, pick any iOS 17+ Simulator, and **⌘R**.

The scheme is committed as shared (`Demo.xcodeproj/xcshareddata/xcschemes/Demo.xcscheme`), so it is
selectable on a fresh clone with no setup.

Requirements: Xcode 15+, iOS 17+ Simulator. No signing needed to run on Simulator; no API keys, no
fixtures, no network at runtime.

---

## The dependency, on purpose

```
XCRemoteSwiftPackageReference "display-class-planner-kit"
    repositoryURL = https://github.com/rajatslakhina/display-class-planner-kit.git
    requirement   = { kind = exactVersion; version = 1.0.0; }
```

Two deliberate choices worth defending:

- **Remote, not a local path.** A demo that references `../library` proves nothing about whether the
  package is actually consumable. This one resolves over the network like any other dependency, and
  CI fails if it can't.
- **`exactVersion`, not `upToNextMajorVersion`.** A range means every clone and every CI run
  resolves whatever the newest 1.x happens to be that day. For a portfolio artifact — something
  meant to still behave identically in six months — that is the wrong default. The trade-off is real:
  an exact pin means patch fixes to the library do not flow here until this repo is updated
  deliberately. For a demo, reproducibility wins.

`Package.resolved` is **not** committed; it is generated by CI's `-resolvePackageDependencies` step
and printed in the log, so you can see the exact revision that was resolved without this repo
carrying a file no human maintains.

The app also imports `DisplayClassPlanner` (the core module) directly, not just the UI module —
`Demo/DemoApp.swift` owns the stage list, the budget policy and the hysteresis policy and hands them
to the library. That is the boundary the package argues for: the algorithm belongs to the library,
the numbers belong to the app.

---

## Verification

**What was actually checked:**

- ✅ The library builds and its 90 tests pass with `-warnings-as-errors`, on a clean tree.
  ([library CI](https://github.com/rajatslakhina/display-class-planner-kit/actions))
- ✅ `Demo.xcodeproj` was structurally validated — balanced braces and parens, every referenced
  object id defined, all ids 24-hex, `objectVersion = 60`.
- ✅ CI on **this** repo resolves the remote package from GitHub at the pinned version and compiles
  the app against it for `generic/platform=iOS Simulator`. See the
  [Actions tab](https://github.com/rajatslakhina/display-class-planner-kit-demo-app/actions) — the
  `Resolve package dependencies` step proves the pin resolves, `Show resolved version` prints the
  exact revision, and `Build` proves the app compiles.
- ✅ An independent Opus reviewer graded both repos against a strict checklist and every finding it
  returned was fixed.

**What was not:**

- ❌ **The app was never launched on a Simulator.** No screenshot exists. The reason is in
  [Screenshots](#screenshots) above.
- ❌ No performance measurement is claimed anywhere. The numbers in the library README are
  hand-computed budget arithmetic verified against the tests, not benchmarks.

The CI destination is `generic/platform=iOS Simulator` rather than a named device on purpose:
pinning to `name=iPhone 16,OS=latest` ties the job to whichever simulator *runtimes* happen to be
installed on that day's runner image, and they are not guaranteed. A compile-only check needs no
device to exist.

---

## Licence

MIT — see [LICENSE](LICENSE). Library: [display-class-planner-kit](https://github.com/rajatslakhina/display-class-planner-kit).
