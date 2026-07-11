# Onboarding & Paywall Principles

Distilled from two data studies of real onboarding/paywall flows: Mobbin's analysis of **1,460 onboarding
flows** across app categories, and a running teardown series of individual high-revenue apps' onboarding
and paywalls. Use this as the knowledge base for sequencing and framing any app's onboarding + paywall flow.

Two kinds of claims appear below, and they carry different weight:
- **Academic / dataset mechanisms** (patterns observed across hundreds–thousands of flows) are treated as
  firm principles — they're not one company's guess, they're a repeated pattern.
- **Single-app vendor-reported stats** (a specific app claiming a specific %, ×, or point lift) are always
  labeled a **directional A/B hypothesis, not a law** — one team's result, in one context, at one point in
  time. Treat the number as "worth testing," not "guaranteed."

---

## Sequence

**The aha-moment arc: signup → setup → aha.** The best onboarding flows follow one shape: get the user
signed up, get their account set up, then get them to the moment they *feel* the product's value — as
fast as the product allows. Everything before the aha moment is scaffolding; everything after it is the
actual pitch. *Exemplars:* Airbnb (aha = making your first booking), Netflix (aha = finding and watching a
show), Mobbin (aha = finding a screen/animation you love and saving it to your collection). *Evidence:*
[Mobbin, "I Studied 1,460 Onboarding Flows" — dataset pattern across the study, not a single-app stat].

**Sell the outcome, not the features.** The onboarding screens that stick don't list capabilities — they
show the product already delivering the result, or they make the pitch feel human instead of like a spec
sheet. *Exemplars:* Timehop (welcome screen simply shows the product in action, no copy needed), Runkeeper
(an animation on open gives you the feel of the app before you read a single word), Superhuman (turns a
plain signup screen into a pitch by adding recognizable logos as social proof). *Evidence:* [Mobbin, "I
Studied 1,460 Onboarding Flows"].

**Do the real thing once before the paywall.** Letting a user taste the *actual* core experience — not a
demo, not a video, the real mechanic — before asking them to sign up or pay is rare and disproportionately
effective, especially for AI-feature products where this is almost never done. *Exemplars:* Elma (lets you
try the core experience before you even create an account), Duolingo (you complete a real first lesson and
feel the satisfaction of finishing it — all *before* account creation, ~60 screens in), a sign-language
learning app teardown that led with an "interactive lesson from the start" rather than a passive tour.
*Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows" for Elma/Duolingo; César breakdowns
(@cesaralvarezll onboarding/paywall teardowns) for the sign-language app pattern].

**Splitting a form across screens can raise conversion.** Breaking one long signup form into several
single-question screens sounds like more friction, but it can convert better than one dense form — the
friction you remove in one place can show up as a lift somewhere else in the funnel. *Exemplar:* House
(saw a reported **+15% increase in conversion** after splitting its signup form across multiple screens —
a directional A/B hypothesis, not a law). *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows"].

**Culture shapes what "good" sequencing looks like — don't blind-copy a pattern across markets.**
Info-dense, multi-step interfaces that feel cluttered to a Western user can read as efficient and
trustworthy to users in some Eastern markets. There is no single best-in-class sequence; what feels
long or busy is audience-dependent. *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows" — qualitative
dataset observation across markets].

---

## Personalization

**Personalize, and make it worth the user's time.** Only 23% of apps personalize during onboarding at all,
and AI apps do it even less (7%) — AI products tend to let the product learn from usage instead of asking
up front. The apps that do ask make the questions feel purposeful rather than like a survey. *Exemplars:*
Headspace let users pick **multiple goals instead of one** (multi-intent) and reported a **+10% increase in
free-trial conversion** — a directional A/B hypothesis, not a law. Dollar Shave Club made its quiz copy
more **conversational** and reported a **+5% increase in subscriptions** — also a hypothesis, not a law.
Focus Flight lets users choose their map style during onboarding, making the app feel like theirs before
they've even used it. Tide keeps it minimal: download, answer two questions, watch recommendations
customize live, then get prompted to sign up. *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows"].

**Show users what their answers unlocked — before they've used the product.** Rather than silently
collecting quiz answers, the strongest flows immediately reveal a personalized plan or result built from
those answers, so the product already feels tailored and "working" before a single real session happens.
*Exemplars:* Endless (six questions, then a result screen shown before any product use), Byte Pal (builds
a personal plan and states the exact date you'll hit your goal), Brilliant (recommends courses from quiz
answers and pre-populates the home screen with only that content), Speak (a language app that asks your
target language and goal, then shows one screen: "In 2 months you'll be able to communicate while
traveling in France," with a graph — and the screens *before* that screen already had the user speaking
instead of typing). *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows"].

---

## Delight & memorability

**Make a long flow feel short with delight.** Screen count is not what makes onboarding feel long —
lifeless screens do. Animation, lively loading/verification states, and a nameable character can carry a
user through dozens of screens without the flow registering as a slog. *Exemplars:* Duolingo (~60 screens
before signup, yet it doesn't feel long, because each step is doing something), Bump (wild, animated
loading and verification states — moments that "rarely get special treatment" elsewhere), Bipul (61
screens, made light by amazing animations and a nameable virtual pet raccoon). *Evidence:* [Mobbin, "I
Studied 1,460 Onboarding Flows"].

---

## Trust & momentum

**Human and founder touches at the aha moment build trust fast.** Some of the highest-trust onboarding
moments skip the pitch entirely and just feel human — a real signature, a real voice, a real
acknowledgment of the user as a person. *Exemplars:* Timehop's welcome screen simply showing the real
product; One Year includes a founder's note with a **handwritten signature and a hand-drawn flower**;
Basecamp sends a personal note from the CEO right after account creation; Airbnb sends a CEO video after a
host's first successful listing (a founder's touch placed exactly at the aha moment, not in the onboarding
flow itself); Tinder acknowledges when a user's birthday is coming up. *Evidence:* [Mobbin, "I Studied
1,460 Onboarding Flows"].

**Guide step-by-step; don't front-load education.** Dumping all the necessary background up front creates
a wall the user has to climb before they can start. The better pattern is contextual: tooltips exactly
when they matter, reassuring microcopy, real-time validation, and one small nudge in the right place
instead of a guided tour. *Exemplars:* Cake Equity (turns dry concepts like equity and vesting into
something approachable with reassuring copy, contextual tooltips, and a password field that validates in
real time), generic to-do apps (show a populated example state with one small nudge instead of a blank
empty state or a forced tour). *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows"].

**Checklists beat pop-ups for sustained retention.** A persistent, dismissible checklist keeps guiding the
user after the formal onboarding flow ends, whereas pop-ups and banners are one-shot and get closed and
forgotten. *Exemplar:* Mural replaced pop-ups/banners with a clear 6-step checklist and reported a
**+10% relative increase in one-week retention** — a directional A/B hypothesis, not a law; the mechanism
worth keeping regardless of the exact number is that the checklist persists even after a user dismisses the
initial flow. *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows"].

---

## Permissions

**Prime permissions with a custom screen before the native OS prompt.** Asking the OS for a permission
cold, with no context, wastes the one shot most platforms give you. Showing your own screen first — one
that explains the *why* or even previews what the permission unlocks — measurably improves acceptance.
*Exemplars:* Brilliant frames it as habit-building ("I'll remind you so it becomes a long-term habit")
before the system dialog appears; Center goes further and actually shows a preview of the notification the
user would receive if they opt in. This kind of screen is one reason web onboarding tends to run about
**21% shorter than iOS onboarding** — mobile simply has more permission and paywall screens baked in.
*Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows" — the accept-rate improvement and the web-vs-iOS
screen-count gap are both dataset patterns, not single-vendor stats].

---

## When NOT to onboard

**If the product speaks for itself, minimize or skip onboarding entirely.** Not every product needs a
setup-to-aha ramp — some products *are* the aha moment on first use, and adding ceremony in front of that
only delays value. *Exemplars:* Mobbin itself (a design-inspiration browsing product — the product's value
is visible the instant you look at it), AI-chat products generally (the first prompt is where the user
finds value, so a heavy front-loaded flow gets in the way rather than helping). *Evidence:* [Mobbin, "I
Studied 1,460 Onboarding Flows"].

**Length is not the enemy — *feeling* long is.** Across the dataset, the average app runs about **25
onboarding screens**, and the categories with the longest flows — finance, health/fitness, and education —
include some of the most successful apps in the study. A flow can be long and still not register as long
if every screen is doing real work (personalizing, delighting, proving value); a short flow can still feel
tedious if it's just friction. Decide screen count by what the product needs to prove, not by an arbitrary
minimalism target. *Evidence:* [Mobbin, "I Studied 1,460 Onboarding Flows" — aggregate dataset finding
across 1,460 flows, not a single-app claim].
