# Testing AuthAgent

`auth` is tested by its own suite, by a gated build of real output, and by a check against the measure's Seer
scorecard.

## The suite

```
swift test                                        # the record, the schema, the lines, the files, a call through the roster
AUTH_BUILD=1 swift test --filter AuthBuildTests   # the output built for real (gated, minutes)
```

- **`AuthAgentTests`** covers the call as a host makes it:
  - the record and the schema;
  - the guide, which names every role, key and state;
  - a call through Granite's roster that writes and names every file;
  - a refused call, which says every reason at once and writes nothing;
  - the same call again, which writes the same bytes.
- **`LineTests`** reads every form a `look`, `strings`, `tuning`, `launch`, `mark`, `prefix` or `imports` line takes, and
  every way each is refused.
- **`TemplateTests`** checks the output is app Swift and nothing else:
  - every combination of the call's flags renders whole, and the toolchain parses the extremes;
  - nothing imports Granite;
  - nothing holds stored state;
  - iOS-only API stays inside `#if os(iOS)`;
  - every view has a preview;
  - the close button is labelled.
- **`AuthEmitTests`** checks what each call writes:
  - the Seer call draws each screen as the original composes it, with the subview tree in order and its values;
  - the least call draws the system's look;
  - a prefix renames only the kit's types, and imports land where the app's names are.
- **`SeerConformanceTests`** runs the scorecard's `code` items and the original's quoted strings (see below).
- **`AuthBuildTests`** is gated by `AUTH_BUILD=1`. It writes one package from four calls, beside stand-ins for the rest
  of each app:
  - Seer in Swift 6;
  - Seer in Swift 5, as the generated apps are;
  - the least call;
  - another app with a prefix and a design module.

  It then:
  - builds the package for the Mac, with no warning in any of its files;
  - runs a `Check` that opens every launch destination and draws each screen;
  - builds it for `generic/platform=iOS Simulator`.

  No simulator is booted.

## Conformance on Seer

The Seer call (`Schema/examples/seer.json`) is the call the one-shot prompt copies. Its output is checked against
`task/seer/scorecard.json` of the measure:
- every `code` item of area `auth`: B-auth-3, 4, 5, 8, 9, 13, 14, 15, 18 and 19;
- the design and data items the flow carries: B-design-2, B-design-3, B-data-1 and B-data-4;
- every `text` item's words, and every string in quotes on the original's Sign In, Sign Up, code and reset screens.

The scorecard's patterns are copied into `SeerConformanceTests`, so the suite needs nothing outside this repository.

### Design parity

The templates mirror the original's `Components/Auth` views subview by subview: the same composition, modifiers and
values. `AuthEmitTests.tree` pins each file's parts in the original's order.

These parts differ from the original, by design:
- **The flow paints one system ground behind its screens.** The original's screens draw on the window's.
- **The flow hides its host's navigation bar** with `.toolbar(.hidden, for: .navigationBar)` on iOS. Shown in a page
  inside a NavigationStack with a title, it draws as the original does, with no bar.
- **The code screen keeps both lines of where the code went** with `.fixedSize(horizontal: false, vertical: true)`.
  A screen squeezed by the keyboard shortens its spacers, never the address.
- **The spinner uses `.tint(_:)`**, not the deprecated `CircularProgressViewStyle(tint:)`. The colour comes from the
  `spinner` role, which the Seer call sets to the original's white.
- **The button's label has `.contentShape(Rectangle())`**, so its whole face takes a tap.

The rest of the visual check is the measure's loop: the floor app is shot in light and dark and compared with the
reference shots.
