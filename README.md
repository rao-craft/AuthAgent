# AuthAgent

Give an app its sign-in flow without drawing it by hand. `auth` writes four screens in your app's own look and words:
- Sign In;
- Sign Up;
- a one-time code sent by email;
- a sheet to reset a password.

What it writes is plain SwiftUI that moves between its own screens and calls your account service through closures. It
has no Granite dependency in it.

## What you can ask

```
$auth the sign-in flow, with our mark turning slowly at the top and our serif type
$auth sign in, sign up, email codes and password reset over AccountService, in the app's colours
$auth a login flow for the reading app: a four-digit code, its views prefixed Kit
$auth add screenshot destinations for each sign-in screen
```

Craft writes the call from your request and shows it on its agent map as `auth-1`. It builds and tests what `auth`
writes with the turn.

## What you get

- **The whole flow, wired.**
  - `AuthFlow` takes your service's `signIn`, `signUp`, `verify`, `resend` and `reset` as async closures.
  - It moves on when each one returns, and shows what each one throws under the fields.
  - Leave a closure out and its control is not drawn.
- **Your look, not ours.**
  - Each `look` line maps a role (a title, a link, a field, the button, the accent) to your own colour or font.
  - A role you leave out reads the system's.
  - Your mark sits at the head of Sign In and Sign Up, sized, and shadowed and turned if you ask.
- **Your words.** Every string on the screens is a key with a natural English default. That includes the prefix a
  refused sign-in reads with, such as "Unauthorized: ".
- **Every number is yours to set.** Spacing, insets, the button's height, radius and border, the code's length and
  tracking, the screen swap's spring, the sheet's detents, the glyphs and the haptic each have a `tuning` key.
- **Screenshots and UI tests reach every screen.** `launch` lines map a `-destination` name to Sign In, Sign Up, the code
  screen for an email, or Sign In with the reset sheet up. The flow opens there with no tap.
- **Ready to drop in.**
  - The views hold no global state and never route.
  - Every view has a `#Preview`.
  - The sheet's close button is labelled for VoiceOver.
  - iOS-only API stays behind `#if os(iOS)`, so the files build for the Mac too.

## How it works

- It reads each line. If a line cannot be read, it refuses it with the reason and what the line may say instead,
  every bad line at once, and writes nothing.
- It writes from templates and asks no model, so the same call makes the same files every time.
- Every file is parsed with `swiftc -parse` before any of them lands, and they land together.
- A later call into the same folder writes the same set of files and says which of them changed.

## Works well with

- `design` writes the colours and type scale that `look` lines name.
- `assets` writes the mark.
- `granite` writes the account service whose events the flow calls, and the page that shows `AuthFlow`, with the
  launch aliases.

## Get it

Install it from the Craft Agents store, or add it by hand with `craft agents add`. To link it into a Swift package:

```swift
.package(url: "https://github.com/rao-craft/AuthAgent.git", branch: "main")
```

The agent registers itself with Granite's roster: an app that links it finds `auth` with nothing listed by hand.
`Schema/Auth.md` lists every field, role, key and state.

## License

MIT, see `LICENSE`.
