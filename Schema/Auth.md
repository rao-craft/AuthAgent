# craft-agent/1 · auth

Writes an app's sign-in flow as plain SwiftUI: Sign In, Sign Up, a one-time code sent by email, and a sheet to reset a
password. It draws them in the app's own look and words, moves between its own screens, and calls the app's account
service through closures.

This is auth's copy of Craft's agent standard (`craft-agent/1`, Craft's `Schema/Agent.md`).
- Everything above **Changes** describes the record as it stands.
- Changes is auth's own log.

| File | What it holds |
| --- | --- |
| [`auth.input.schema.json`](auth.input.schema.json) | What it takes, as JSON Schema |
| [`auth.answer.schema.json`](auth.answer.schema.json) | What it answers: `granite-answer/1` with its own kinds |
| [`examples/seer.json`](examples/seer.json) | The call that draws Seer's sign-in flow as the original composes it |
| [`examples/seer.answer.json`](examples/seer.answer.json) | That call's answer, with paths relative to the project |
| [`examples/shelf.json`](examples/shelf.json) | A call for another app: its own mark, look, words, a prefix and a design module |

## What it takes

| Field | Required | What it is |
| --- | --- | --- |
| `into` | no | the folder for the flow, relative to the project; Components/Auth when left out |
| `mark` | no | the app's mark at the head of Sign In and Sign Up: the Swift that makes a view the app has (`BrandMark()`), or an SF Symbol's name (`seal.fill`); person.crop.circle when left out |
| `look` | no | one line a look role, `role = Swift` naming the app's own colour or font: `accent = Color.accent`, `title = Font.brandTitle`; a role left out reads the system's |
| `strings` | no | one line a word on the screens, `key = "words"`: `signIn.title = "Welcome back"`; a key left out says its English default |
| `tuning` | no | one line a timing, size or symbol, `key = value`: `swap = spring 0.38 0.88`, `mark.turn = 42`, `forgot.detents = medium large`; a key left out keeps its default |
| `launch` | no | one line a `-destination` the flow opens for, `name = state`: signIn, signUp, forgot (Sign In with the reset sheet up), or code with an email (`auth.code = code "name@example.com"`) |
| `prefix` | no | a prefix for the kit's types when the app already has names that clash: `Kit` writes KitAuthFlow |
| `imports` | no | modules the mark and the look's names live in, when the app's own target does not declare them |

Craft fills `directory` with the project folder. The person's request and the host's model are offered beside the
call, never in it.

### Line syntax

Each line is one assignment: `key = value`. Blank lines are skipped. A key is matched in any case.

- **`look`**: `role = Swift`.
  - The value is the Swift of the app's own colour or font: `accent = Color.accent`, `title = Font.brandTitle`.
  - It may also be any SwiftUI expression: `titleColor = Color.primary.opacity(0.75)`, `field = Font.system(size: 16, design: .serif)`.
  - A colour role takes a colour, and a font role a font. Words in quotes and hex codes are refused.
- **`strings`**: `key = "words"`.
  - The words go in quotes, with `\"` and `\n` inside.
  - Words without quotes are read as they stand.
  - An empty string turns a key off where it has no default.
- **`tuning`**: `key = value`.
  - Numbers are points or seconds within each key's bounds.
  - Animations:
    - `spring <response> <damping>`;
    - `easeInOut <seconds>`, also `easeIn`, `easeOut` and `linear`;
    - `smooth`, `snappy`, `bouncy` or `none`;
    - or SwiftUI's own spelling, such as `.spring(response: 0.38, dampingFraction: 0.88)`.
  - Symbols are SF Symbol names.
  - Detents are `medium`, `large`, `fraction(0.6)` or `height(320)`, each once.
  - A shadow is `opacity radius x y` in the primary colour, or `none`.
  - `haptic` is `light`, `medium`, `heavy`, `soft`, `rigid` or `none`.
- **`launch`**: `destination = state`. The states are:
  - `signIn`;
  - `signUp`;
  - `forgot`, which is Sign In with the reset sheet up;
  - `code "name@example.com"`, the code screen for that email;
  - `code reset "name@example.com"`, its reset form;
  - `code` with no email, which opens the code screen for `pendingEmail`.
- **`mark`**: the app's view (`BrandMark()`, `Image("Logo").resizable()`) or an SF Symbol's name. When left out it is `person.crop.circle`.
- **`prefix`**: an UpperCamelCase prefix for the kit's types. It renames the kit's names only.
- **`imports`**: module names. They are imported where the app's names are: the mark's file and the look's file.

### Look roles

| Role | Kind | What it paints | When no line maps it |
| --- | --- | --- | --- |
| `background` | colour | Behind the flow, edge to edge; the reset sheet keeps the system's sheet background. | `Color(uiColor: .systemBackground)` (iOS), `Color(nsColor: .windowBackgroundColor)` (macOS) |
| `titleColor` | colour | Sign In's and Sign Up's titles, and the reset sheet's title in its bar. | `Color.primary` |
| `subtitleColor` | colour | The line under Sign In's and Sign Up's titles. | `Color.secondary` |
| `foreground` | colour | The code screen's title. | `Color.primary` |
| `secondaryForeground` | colour | The footer's question, the glyphs, where the code went and the reset sheet's instruction. | `Color.secondary` |
| `tertiaryForeground` | colour | The caption under the code field. | `Color(uiColor: .tertiaryLabel)` (iOS), `Color(nsColor: .tertiaryLabelColor)` (macOS) |
| `accent` | colour | "Forgot password?", the footer's link and the reset sheet's close button. | `Color.accentColor` |
| `danger` | colour | What went wrong, and the mismatch hint. | `Color.red.opacity(0.85)` |
| `line` | colour | The line under a field. | `Color.primary.opacity(0.2)` |
| `lineError` | colour | The line under a field that is wrong: a confirmation that does not match. | `Color.red.opacity(0.4)` |
| `control` | colour | The outlined button's label and border while it can act. | `Color.primary` |
| `controlFaint` | colour | The outlined button's label and border while it cannot act or is busy. | `Color.primary.opacity(0.3)` |
| `spinner` | colour | The spinner that stands in for the button's label while busy. | `Color.primary` |
| `codeFill` | colour | The rounded fill behind the code field. | `Color.secondary.opacity(0.08)` |
| `title` | font | Sign In's and Sign Up's titles. | `.title2` |
| `subtitle` | font | The line under Sign In's and Sign Up's titles; `.italic()` on the font slants it. | `.subheadline` |
| `field` | font | What is typed into a field, and its placeholder. | `.body` |
| `link` | font | "Forgot password?" and "Use a different email". | `.footnote.weight(.medium)` |
| `message` | font | What went wrong on Sign In, Sign Up and the code screen, and the mismatch hint. | `.footnote` |
| `button` | font | The outlined button's label. | `.headline` |
| `footer` | font | The footer's question: "Don't have an account?". | `.subheadline` |
| `footerLink` | font | The footer's link: "Create one", "Sign in". | `.subheadline.weight(.semibold)` |
| `glyph` | font | The symbol at the head of the code screen and the reset sheet. | `.system(size: 44, weight: .light)` |
| `codeTitle` | font | The code screen's title. | `.system(size: 28, weight: .semibold)` |
| `codeBody` | font | Where the code went, under the code screen's title. | `.system(size: 15, weight: .regular)` |
| `codeField` | font | The digits of the code as they are typed, and its placeholder. | `.system(size: 32, weight: .semibold, design: .monospaced)` |
| `caption` | font | The caption under the code field. | `.system(size: 12)` |
| `sheetTitle` | font | The reset sheet's title, centred in its bar. | `.headline` |
| `instruction` | font | The reset sheet's instruction. | `.body` |
| `sheetMessage` | font | What went wrong in the reset sheet. | `.footnote` |

### Strings

| Key | Default | Where it shows |
| --- | --- | --- |
| `email` | “Email” | The email field's placeholder, on every screen that asks for it. |
| `signIn.title` | “Welcome back” | Sign In's title, under the mark. |
| `signIn.subtitle` | “Sign in to continue” | The line under Sign In's title. |
| `signIn.password` | “Password” | Sign In's password field. |
| `signIn.forgot` | “Forgot password?” | The link under the fields that opens the reset sheet. |
| `signIn.button` | “Sign In” | Sign In's button. |
| `signIn.footer` | “Don't have an account?” | The footer's question on Sign In. |
| `signIn.footerLink` | “Create one” | The footer's link to Sign Up. |
| `signIn.refused` | (none) | Put before the reason a sign-in was refused: `Unauthorized: ` reads "Unauthorized: Invalid login credentials"; never written twice. |
| `signIn.invalid` | (none) | With words here, a malformed email or a password shorter than `password.minimum` is refused on the screen with them, after `signIn.refused`, and `signIn` is not asked. |
| `signUp.title` | “Create account” | Sign Up's title, under the mark. |
| `signUp.subtitle` | “It only takes a minute” | The line under Sign Up's title. |
| `signUp.password` | “Password” | Sign Up's password field. |
| `signUp.confirm` | “Confirm password” | Sign Up's field that repeats the password. |
| `signUp.mismatch` | “Passwords do not match” | Under the fields while the confirmation differs. |
| `signUp.button` | “Create Account” | Sign Up's button. |
| `signUp.footer` | “Already have an account?” | The footer's question on Sign Up. |
| `signUp.footerLink` | “Sign in” | The footer's link back to Sign In. |
| `code.title` | “Verify your email” | The code screen's title after Sign Up. |
| `code.resetTitle` | “Check your email” | The code screen's title after a reset was asked for. |
| `code.sent` | “We sent a code to” | Where the code went; the email follows on the next line. |
| `code.placeholder` | “Code” | The code field's placeholder. |
| `code.hint` | “Didn't receive it? Check your spam folder.” | The caption under the code field. |
| `code.button` | “Verify” | The code screen's button after Sign Up. |
| `code.resetButton` | “Verify & Reset” | The code screen's button after a reset was asked for. |
| `code.back` | “Use a different email” | The link back to the screen the code came from. |
| `code.resend` | “Resend code” | The link that sends the code again, drawn when the flow has `resend`. |
| `forgot.title` | “Reset Password” | The reset sheet's title, in its bar. |
| `forgot.instruction` | “Enter your email and we'll send you a reset code.” | The reset sheet's instruction. |
| `forgot.button` | “Send Reset Code” | The reset sheet's button. |
| `forgot.sent` | “Check your email for a reset link.” | Said in the sheet once the reset is sent, when the flow has no code screen to go to. |
| `forgot.close` | “Close” | What VoiceOver says for the sheet's close button. |

### Tuning

| Key | Default | What it sets |
| --- | --- | --- |
| `swap` | `spring 0.38 0.88` | How one screen gives way to the next: the new one slides in from the trailing edge, Sign In from the leading edge. |
| `press` | `easeInOut 0.15` | How the button eases between enabled, disabled and busy. |
| `haptic` | `light` | The tap felt on the button and on the footer's link. |
| `mark.size` | `100` | The mark's width and height. |
| `mark.turn` | `0` | Seconds the mark takes to turn once, linear and never reversing; 0 keeps it still. |
| `mark.shadow` | `none` | The mark's shadow in the primary colour: `opacity radius x y`, like `0.3 3 1 1`. |
| `mark.padding` | `24` | Space above and below the mark, inside the head. |
| `mark.below` | `8` | More space under the mark, before the title. |
| `header.spacing` | `8` | Space between the parts of every head: the mark or glyph, the title and the line under it. |
| `header.below` | `42` | Space from Sign In's and Sign Up's head to the first field. |
| `fields.gap` | `12` | Space between fields. |
| `fields.inset` | `42` | The inset from each side of the fields, the link and the messages, and of the reset sheet's head and field. |
| `field.horizontal` | `16` | A field's padding at each side. |
| `field.vertical` | `12` | A field's padding above and below. |
| `field.line` | `1` | The thickness of the line under a field. |
| `field.lineInset` | `8` | The line's inset from each side of its field. |
| `link.above` | `8` | Space from the last field to "Forgot password?". |
| `message.above` | `12` | Space above what went wrong. |
| `hint.above` | `6` | Space from the confirmation to the mismatch hint. |
| `button.above` | `28` | Space above the button, on every screen. |
| `button.inset` | `50` | The button's inset from each side on Sign In, Sign Up and the reset sheet. |
| `button.height` | `52` | The button's height. |
| `button.radius` | `4` | The corner radius of the button's border. |
| `button.border` | `1` | The width of the button's border. |
| `button.spinner` | `0.85` | The scale of the spinner that stands in for the label while busy. |
| `footer.gap` | `4` | Space between the footer's question and its link. |
| `footer.below` | `32` | Space under the footer. |
| `password.minimum` | `6` | The fewest characters Sign Up takes for a password. |
| `code.length` | `6` | How many digits the code has; the last one sends it. |
| `code.tracking` | `12` | Space between the code's digits. |
| `code.glyph` | `envelope.badge` | The symbol at the head of the code screen. |
| `code.glyphBelow` | `12` | More space under the code screen's glyph, before its title. |
| `code.lineSpacing` | `3` | Space between the lines of where the code went. |
| `code.headerBelow` | `40` | Space from the code screen's head to the code field. |
| `code.inset` | `24` | The inset from each side of the code screen's head, field, message and button. |
| `code.fieldPadding` | `16` | The code field's padding above and below. |
| `code.fieldRadius` | `12` | The corner radius of the code field's fill. |
| `code.gap` | `16` | Space from the code field to its caption. |
| `code.backAbove` | `16` | Space above "Use a different email". |
| `forgot.glyph` | `lock.rotation` | The symbol at the head of the reset sheet. |
| `forgot.glyphBelow` | `8` | More space under the reset sheet's glyph, before its instruction. |
| `forgot.lineSpacing` | `3` | Space between the lines of the instruction. |
| `forgot.headerBelow` | `40` | Space from the reset sheet's head to its field. |
| `forgot.closeGlyph` | `xmark` | The symbol of the sheet's close button. |
| `forgot.detents` | `medium large` | The heights the reset sheet rests at. |

## What it makes

| Kind | What | Into | Never |
| --- | --- | --- | --- |
| `view` | the sign-in flow's views: AuthFlow, the root a page shows, and the screens and parts it is built from (AuthSignInView, AuthSignUpView, AuthCodeView, AuthForgotView, AuthField, AuthButton, AuthMark) | `Components/Auth/*` | a page, the app's navigation, a session or an account service |
| `support` | what the views read: AuthLook (each colour and font, the app's or the system's), AuthLaunch (the screen a -destination opens) and AuthStep | `Components/Auth/*` | the app's design names themselves |

## What it answers

A `granite-answer/1` answer (Granite's `Schema/GraniteAgent.md` §4.2). It holds:
- `paths`;
- `made` against `expected`, by kind and name;
- `problems`.

Beside them are its own keys:
- `path`, the root view's file;
- `views`;
- `initializers`, the root view's initializer;
- `body`, a page body over the app's account service;
- `destinations`, the launch names, the first one the page's own;
- `notes`, which say what the app must provide: the launch aliases, the app's own look names and the mark.

## How it refuses

It refuses with an `AgentRefusal` of kind `call`, holding every reason at once, each with its fix, and writes nothing.

A reason names:
- the field;
- the line;
- what the line may say instead, such as the keys of the part it named, the bounds of a number, or the states of a launch.

## Changes

Each change that makes this agent more precise, dated, with what measured it (`TESTING.md`). Newest first.

### 2026-11-15 · first version: Seer's sign-in flow at design parity

The templates mirror the original's `Components/Auth` views subview by subview: the same composition, modifiers and
values.
- The headers are VStack(spacing: 8).
- The mark is sized, padded, shadowed, then turned.
- Fields are underlined, inset 42.
- The outlined button is inset 50, 52 tall with radius 4. Its label and border go faint at primary 0.3.
- The code screen and the reset sheet have their own heads.
- The sheet has a drag indicator, a serif principal title and a bronze xmark.

Every value the original draws is a look role or a tuning key. Its defaults are the original's, except:
- the type and the accent, which are system text styles and the app's accent;
- the mark's motion and shadow, which are off.

The Seer call sets the rest.

Measured:
- the suite;
- the gated build, for the Mac in Swift 6 and Swift 5 and for `generic/platform=iOS Simulator`;
- every `code` item of area `auth` in the measure's scorecard, plus B-design-2/3 and B-data-1/4;
- every quoted string of the four screens.

The visual loop has not been run yet.
