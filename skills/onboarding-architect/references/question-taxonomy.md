# Question Taxonomy

The catalog of onboarding-question *types*. Every question a flow asks belongs to one of these
categories — if it doesn't, it's probably filler and should be cut (see **Selection rule** below).
Sourced from repeated patterns across two corpora: a teardown series of individual app
onboarding/paywall flows, and Mobbin's dataset study of 1,460 onboarding flows. Any number
attached to a single app (a specific %, ×, or point lift) is a **hypothesis, not a law** — one
team's result, in one context, at one point in time.

This doc is domain-agnostic: it names the question *type* and its mechanism, not any particular
product's copy. Use it to decide *what kind* of question a given onboarding step needs, then write
the actual wording for the product at hand.

---

## Question categories

### Identity / who-are-you
- **Purpose:** capture a name (and sometimes a role) that becomes the personalization anchor used
  in copy for the rest of the product — greetings, plan reveals, notifications, everywhere.
- **Why it converts:** a name turns "the app" into a relationship; every later screen that echoes
  it back ("Nice to meet you, Cesar!") reads as attentiveness rather than a form field. Low cost to
  answer, so it's usually placed first to build momentum before harder questions.
- **Example phrasings:**
  - "First things first — what's your name?"
  - "Hi, I'm [mascot]. Who am I talking to?"
  - "What should we call you?"
- **Presentation format:** single free-text field, one idea per screen, conversational framing
  (often voiced by a mascot rather than a bare label).

### Demographic-for-personalization
- **Purpose:** collect a trait (age, gender, experience level) *only* when it changes the plan or
  content the user gets — e.g., adjusting calorie targets, difficulty tier, or avatar options.
- **Why it converts:** it converts only when the payoff is visible — the flow should say *why* in
  the same breath ("This helps me fine-tune your calorie estimates"). Asked with no stated reason,
  it reads as vanity data collection and adds pure friction with no trust return.
- **Example phrasings:**
  - "How old are you? Just adapting goals and pace — not counting candles."
  - "Which option fits you best? (Male / Female / Prefer not to say)"
  - "What's your experience level with [activity]? Brand new / Some experience / Advanced"
- **Presentation format:** single-select chips or pill buttons, always paired with a one-line
  reason for asking; include an opt-out ("Prefer not to say") when the trait is sensitive.

### Goal / intent
- **Purpose:** surface the transformation the user actually wants, so the plan, content, and copy
  downstream can be built around it instead of a generic default.
- **Why it converts:** users routinely arrive with more than one motivation, not a single tidy
  goal. Headspace let users pick multiple goals instead of forcing one (a multi-intent design) and
  reported a **+10% increase in free-trial conversion** — a hypothesis, not a law, but the
  mechanism (real intent is plural) generalizes: forcing a single choice truncates the honest
  answer and weakens the plan built from it.
- **Example phrasings:**
  - "What would you like to accomplish?" (checkbox list, pick all that apply)
  - "Why are you learning [X]? Just for fun / Prepare for travel / Boost my career / Other"
  - "What's your goal with [product]?"
- **Presentation format:** multi-select list or card grid — allow more than one selection by
  default unless there's a specific reason a single answer is required.

### Pain / problem
- **Purpose:** name the specific problem the user is facing so the app can be positioned as the
  answer to *that* problem, not a generic feature list. Feeds the emotional arc (problem → agitate
  → solve) that the rest of onboarding and the paywall lean on.
- **Why it converts:** stating the problem back to the user, in their own words, is what makes the
  eventual solution feel earned rather than pitched. One teardown of a screen-time app highlighted
  the pain point directly ("how many years you might be losing to screen time") right before
  showing the years the app could save — the before/after pairing is the conversion mechanism, not
  the fact of asking alone.
- **Example phrasings:**
  - "What's hardest about [X] right now?"
  - "What's stopping you from reaching your goal? Lack of consistency / Busy schedule / Lack of support"
  - "Do you currently struggle with [specific friction]?"
- **Presentation format:** single- or multi-select list of relatable, specific options (avoid an
  open text box here — specific options are what make the problem feel seen and are what the plan
  reveal can later point back to).

### Current-state / baseline
- **Purpose:** establish where the user is *right now* so later progress has something concrete to
  measure against, and so the plan can be calibrated instead of one-size-fits-all.
- **Why it converts:** framed with grace — no option should read as a shaming choice — this
  question makes the user feel accurately met rather than judged, and it's the baseline that later
  "look how far you've come" or "you'll reach X by [date]" screens depend on.
- **Example phrasings:**
  - "Where are you starting from today?"
  - "How would you describe your current [habit/skill] level?"
  - "Do you currently work with a [coach/tool] for this?"
- **Presentation format:** single-select list, options ordered low-to-high with neutral,
  non-judgmental labels (never "beginner (bad)" framing).

### Commitment / effort
- **Purpose:** get the user to state a concrete effort level (time per day, frequency, reminder
  time) up front, and use that moment to prime the notification-permission ask that usually follows
  immediately after.
- **Why it converts:** this is the goal-gradient mechanism — asking someone to commit to a number
  ("10 min/day") before they've done anything makes the eventual system permission prompt ("I'll
  remind you to practice so it becomes a habit!") feel like a natural continuation of a promise
  they just made, not a cold OS dialog. Priming with a custom screen before the native prompt is
  reported to measurably improve accept rates.
- **Example phrasings:**
  - "What's your daily goal? 5 min (Casual) / 10 min (Regular) / 15 min (Serious) / 20 min (Intense)"
  - "How fast do you want to reach your goal?" (pace slider, slow → fast)
  - "When should I remind you?"
- **Presentation format:** slider or discrete chips (not free text — a concrete, tappable commitment
  is the point), immediately followed by a custom pre-permission screen before the system
  notification dialog.

### Preference / customization
- **Purpose:** let the user pick a cosmetic or experiential preference (theme, mascot, map style,
  environment) that makes the product feel like *theirs* before they've used it at all.
- **Why it converts:** ownership precedes use — picking your own mascot, map style, or theme is a
  small act of authorship that increases attachment to the product before a single real session has
  happened. Focus Flight lets users choose a map style during onboarding specifically to create this
  effect.
- **Example phrasings:**
  - "Choose your [mascot / companion]."
  - "Pick a look you like." (theme/color swatches)
  - "Set up your space — choose an environment."
- **Presentation format:** visual picker (swatches, character cards, style thumbnails) — this
  category should always be visual, never a text list, since the payoff is aesthetic and immediate.

### Segmentation
- **Purpose:** route the user to tailored copy, a tailored plan, or a tailored price by capturing
  where they came from or what they intend to use the product for.
- **Why it converts:** attribution answers ("How did you hear about us?") let later screens
  reference the channel the user arrived through, and use-case answers can route straight into a
  differentiated price. Grammarly's teardown reports quiz-driven tailored pricing plans led to
  almost a **+20% increase in plan upgrades** — a hypothesis, not a law, but it's the clearest
  example of a question feeding pricing rather than content.
- **Example phrasings:**
  - "How did you hear about us? Instagram / TikTok / Friends and family / Creator or influencer"
  - "What will you mainly use [product] for?"
  - "Are you using this for yourself or for a team?"
- **Presentation format:** single-select list, typically placed early (attribution) or right before
  the plan/paywall reveal (use-case, when it feeds pricing).

---

## Selection rule

Include a question **only if** its answer does at least one of these:

- **(a) personalizes the plan or content** the user sees later (a demographic, goal, or
  current-state answer that visibly changes what gets built or recommended),
- **(b) makes the problem salient** — surfaces or sharpens a pain point the product will then solve,
- **(c) primes a permission** — sets up a commitment or expectation right before an OS-level ask
  (notifications, tracking, etc.), or
- **(d) feeds pricing or segmentation** — routes the user to a tailored offer, plan, or copy track.

If a candidate question does none of the four, cut it — it is friction with no payoff. And every
question that *is* kept must **visibly pay off later**: the flow should show the user what their
answer unlocked (a populated plan, a personalized recommendation, a reflected-back summary at the
plan reveal), not just silently store it. A question with no visible payoff trains the user to
stop trusting that the next question matters either.

---

## Wording & presentation

- **Conversational beats clinical.** Dollar Shave Club rewrote its quiz copy to sound like a person
  talking rather than a form, and reported a **+5% increase in subscriptions** — a hypothesis, not
  a law, but the direction (warm, first-person copy over clinical labels) shows up repeatedly across
  teardowns.
- **One idea per screen.** Don't stack a name field, a goal question, and a demographic question on
  one screen — each screen should ask exactly one thing, so the user's full attention goes to that
  one answer.
- **Show progress.** A visible step indicator (dots, a progress bar, "2 of 3") tells the user how
  much is left and makes a long question sequence feel bounded rather than open-ended.
- **A mascot can ask the questions.** Several high-performing flows have a character — not a bare
  UI — pose each question directly ("Hi! I'm Wardy... So, first things first, what's your name?").
  The mascot guides the questionnaire, which turns data collection into a conversation instead of a
  survey.
- **Reflect answers back at the plan reveal.** The strongest flows don't just move on after an
  answer — they show the user, before any real product use, what those answers produced: a
  personalized plan, a recommended course list, a date they'll hit their goal by. This is the
  payoff the **Selection rule** above requires, made concrete: the plan reveal screen should
  visibly reference the specific answers the user gave (their name, their stated goal, their chosen
  pace), not a generic summary.
