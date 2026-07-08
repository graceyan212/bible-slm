## Purpose

### Purpose

**Goal:** The purpose of this BrainLift is to decide what a trustworthy kids' Bible product must be, what the existing (and existing AI) faith apps actually do, and evidence of how general-purpose AI already fails for children, for religion, and for Christianity specifically.

### In Scope

- **User:** the Christian-parent buyer and the 6–9 year old user
    - Who they are, what they value, what they fear/reject
- **Current Landscape:** existing faith apps (YouVersion, Hallow, etc), existing AI faith apps (Bible Chat/CrossTalk, Text With Jesus, "AI Jesus," Magisterium AI), existing children's faith apps
    - What they do and where they fail
- **Why AI underperforms:** for children, for religion generally, and for Christianity specifically.
- What those constraints imply the product must be

### Out of Scope

- **How to build/fine-tune a model** — QLoRA, parameters, base-model choice, training recipe. Cut per instructor guidance.
- Full app architecture, monetization mechanics, GTM sequencing.
- The v2 "configurable doctrine" engine (SPOV 3 argues it's the wrong frame anyway).
- Crisis-disclosure product design beyond naming it a launch requirement.

---

## DOK 4: Spiky Points of View (SPOVs)

- **Spiky POV 1:** AI doesn't fail at faith because it isn't smart enough. It fails because it's built to agree.
    - **Elaboration:** The failures in Category 3 aren't gaps that a bigger model fixes — they're the predictable output of the training. Models optimize for the answer a human rater prefers, and matching the user's existing view is one of the strongest predictors of that preference (Sharma et al.). So the model learns to affirm. That's fine for most consumer tasks but not for faith formation, where the formative answer is frequently no — "that's not what this teaches," "sit with the hard part," "ask your parents." A smarter model trained the same way is just a better sycophant. This is why "just use a better model" isn't the fix, and why the product has to be built around a behavior.
- **Spiky POV 2:** Deflection is the whole product, not the fallback. One behavior solves three separate failures at once.
    - **Elaboration:** When a kid asks something hard and the app "wonders" instead of answering, that looks like a cop-out. However, the warm wondering question is the most valuable thing the product does for three reasons:
        1. It is the opposite of sycophancy — it neither caves to the child's premise nor asserts a possibly-wrong answer.
        2. It delivers doctrine-neutrality through the PRD's loop: kid asks hard question → warm wondering → parent gets a conversation guide, so contested belief is handed to the family that owns it.
        3. It reduces the likelihood of hallucinations, because the model isn't producing an authoritative answer it could get wrong.
- **Spiky POV 3:** The most trustworthy Bible AI is one that never quotes the Bible.
    - **Elaboration:** It sounds backwards — a Bible product whose model won't produce Bible verses. But generating Scripture from a model's memory is exactly where the fatal errors live: ChatGPT invented a fake scripture-styled passage of Jesus affirming a transgender person (Answers in Genesis), and Bible Chat — which markets itself as "theologian-reviewed" — quoted Romans 12:2 while labeling it Philippians 4:8 (Brave Parenting), the very kind of confident misquote Christianity Today documented. A fabricated or misattributed verse shown to a child is the single most damaging screenshot the product could produce. So the model never free-generates verse text or references; it retells stories in its own warm words, and any verbatim verse is retrieved from a fixed Bible file in the translation the parent chose at onboarding. The file is the guardrail: the only Scripture a child ever sees is text that physically exists in a real, family-chosen Bible — never something the model wrote. That is a guarantee the leading AI Bible apps demonstrably can't make, which turns "our AI can't quote the Bible" from a limitation into the trust claim.

---

## Experts

- **Expert 1**
    - **Who:** David Rozado
    - **Focus:** Computational social scientist and audits LLM political/ideological bias.
    - **Why Follow:** Quantified, reproducible evidence behind the "hidden values bias" argument: his audits show most LLMs default left-of-center and can be shifted across the spectrum with only modest fine-tuning.
    - **Where:** https://davidrozado.substack.com
- **Expert 2**
    - **Who:** Barna Group
    - **Focus:** Research on Christians, parents, faith formation, and attitudes to AI.
    - **Why Follow:** Barna talks about the buyer persona and the core market thesis: parents are the #1 agents of faith formation, they intend to disciple at home but mostly don't (the intention–execution gap), and their attitudes toward AI + faith are the adoption gate. Follow to keep confirming the buyer exists, what they value, and whether openness to AI in faith is moving.
    - **Where:** https://www.barna.com/research

---

## DOK 3: Insights

- **Insight 1:** There is a large consumer base that is willing to pay for apps but is hesitant about AI + faith.
- **Insight 2:** There is a gap between a desire for parents to pass on their faith and little structure and practice.
- **Insight 3:** AI's Scripture errors are a distinct failure from getting doctrine wrong — a fabricated or misquoted verse is a discrete, screenshot-fatal event, and it comes specifically from the model *generating* text it should only ever *retrieve*.

---

## DOK 2: Knowledge Tree

- **Category 1:** The User (Buyer Persona & Child End-User)
    - **Subcategory 1.1:** Who the Christian-parent buyer is
        - **Source 1: Pew Research Center (2023–24) — Religious Landscape Study**
            - **DOK 1 - Facts:**
                - 62% of U.S. adults identify as Christian (40% Protestant, 19% Catholic, 3% other Christian); evangelical Protestants are 23% of all adults.
                - The Christian share has held between 60–64% since 2019 after falling from 78% (2007) — the long decline has leveled off.
                - Christians have a higher completed fertility rate (2.2) than the religiously unaffiliated (1.8).
            - **DOK 2 - Summary:**
                - The buyer is a no-longer-shrinking Christian majority; the evangelical/practicing segment is the sharpest target and skews toward larger families with young kids.
            - **Link to source:** https://www.pewresearch.org/religion/2025/02/26/decline-of-christianity-in-the-us-has-slowed-may-have-leveled-off/
        - **Source 2: Pew Research Center (2025) — How parents are raising their children religiously**
            - **DOK 1 - Facts:**
                - 81% of U.S. parents of minors say they and their children share the same religion.
                - 43% say their kids attend services at least monthly; Protestant parents (61%) attend more than Catholic (47%).
            - **DOK 2 - Summary:**
                - Faith transmission is the norm and an active family practice for this buyer — the product plugs into an existing behavior, not a new one.
            - **Link to source:** https://www.pewresearch.org/religion/2025/12/15/how-parents-are-raising-their-children-religiously/
        - **Source 3: Pew Research Center (2023) — 70% of White evangelical parents say it's very important that their kids have similar religious beliefs to theirs**
            - **DOK 1 - Facts:**
                - 70% of White evangelical parents say it's extremely/very important their kids share their religious beliefs — double the 35% national average (Catholic 35%, unaffiliated 8%).
                - Comparison: just 16% of parents say it's extremely or very important that their children grow up with political views similar to their own.
            - **DOK 2 - Summary:**
                - Passing on faith is a defining, high-intensity value for the core evangelical buyer — the emotional driver behind willingness to adopt and pay.
            - **Link to source:** https://www.pewresearch.org/short-reads/2023/02/06/70-of-white-evangelical-parents-say-its-very-important-that-their-kids-have-similar-religious-beliefs-to-theirs/
        - **Source 4: Barna Group (with Cardus) — Children's Faith Formation**
            - **DOK 1 - Facts:**
                - 99% of Protestant pastors and 96% of Catholic priests rank **parents** as #1 for children's faith formation.
                - Only about 20% Protestant, 17% Catholic clergy prioritize parent training, yet nearly half of non-mainline (47%) and Catholic (42%) clergy report parents coming to them for advice — a clear gap between demand and what churches actually offer.
            - **DOK 2 - Summary:**
                - Clergy near-unanimously name parents as the primary agents of faith formation, but churches invest almost nothing in equipping them — so the stated priority and the actual programming point in opposite directions.
                - Because parents are already coming to clergy for guidance, the gap isn't a lack of demand but a lack of supply: there's an unmet, self-identified need that a parent-equipping resource could fill without competing with the church's own role.
            - **Link to source:** https://www.barna.com/research/children-faith-formation/
        - **Source 5: American Bible Society — State of the Bible 2025 (Chapter 5)**
            - **DOK 1 - Facts:**
                - Only 16% of parents are "Scripture engaged"; just 16% read Scripture daily and 5% pray daily *with* their children.
                - Practicing Christians far outperform: 72% pray and 45% read the Bible "often" with their kids.
            - **DOK 2 - Summary:**
                - The intention–execution gap is real and measurable: parents want home discipleship but mostly don't manage it; this product's selling point is making it doable.
            - **Link to source:** https://www.americanbible.org/news/press-releases/articles/state-of-the-bible-2025-chapter-5/
- **Category 2:** The Current Landscape
    - **Subcategory 2.1:** Non-AI faith app leaders
        - **YouVersion — Bible App for Kids**
            - **DOK 1 - Facts:**
                - Bible App for Kids (YouVersion + OneHope): 100M+ downloads, 170M+ children reached; free; 41 animated stories; ages ~2–8; touch-activated animation and earnable rewards.
                - It is deliberately **non-AI** (scripted, animated), and remains the dominant kids' product.
            - **DOK 2 - Summary:**
                - The kids' category leader proves enormous demand and deliberately avoids generative AI.
            - **Link to source:** https://www.youversion.com/bible-app-for-kids
        - **Hallow**
            - **DOK 1 - Facts:**
                - Catholic prayer app: 14M+ downloads, 400M+ prayers by early 2025; first religious app to hit #1 on Apple's App Store (Feb 2024, post-Super Bowl ad); $105M raised (Thiel among investors); ~$9.99/mo or $69.99/yr; ~40% of users non-Catholic.
            - **DOK 2 - Summary:**
                - Proves Christian consumers will pay premium subscription prices for a trusted faith product.
                - Audio-guided prayer, not a chatbot.
            - **Link to source:** https://en.wikipedia.org/wiki/Hallow_(app)
    - **Subcategory 2.2:** Consumer AI Bible chatbots (the closest competitors)
        - **Source 1: Tech.eu (2025) — How Romanian startup Bible Chat turned AI and faith into a global phenomenon**
            - **DOK 1 - Facts:**
                - Bible Chat (BibleChat.ai, rebranding to CrossTalk; by BookVitals, Romania) raised €13.4M (Feb 2025); briefly the 5th most-downloaded app worldwide.
                - Pricing $4.99/week, $12.99/month, or $59.99/year; claims to self-host and fine-tune LLMs with a proprietary "faith refinement" layer, "reviewed by theologians."
            - **DOK 2 - Summary:**
                - This is the closest direct competitor, a venture-scale consumer AI Bible chatbot.
            - **Link to source:** https://tech.eu/2025/06/20/how-romanian-startup-bible-chat-turned-ai-and-faith-into-a-global-phenomenon/
        - **Source 2: Brave Parenting — Guide to the Bible Chat App**
            - **DOK 1 - Facts:**
                - Bible Chat quoted the text of Romans 12:2 but cited it as Philippians 4:8 — a concrete misattribution flagged as a QA failure.
                - Marketed as offering "Christian counseling support," it failed to direct a reviewer discussing depression/suicidal themes to a hotline or human.
                - App Store rates it 4+ / Play "Everyone," yet its own Terms of Service require users to be 18; independently rated 18+.
            - **DOK 2 - Summary:**
                - The leading AI Bible chatbot fabricates the very Scripture it exists to teach and mishandles crisis.
            - **Link to source:** https://braveparenting.net/brave-parenting-guide-to-the-bible-chat-app/
- **Category 3: Why AI Underperforms for Religion & Christianity (the core)**
    - **Subcategory 3.1:** Sycophancy (trained to agree)
        - **Source 1: Sharma et al. Anthropic (ICLR 2024) — Towards Understanding Sycophancy in Language Models**
            - **DOK 1 - Facts:**
                - Across Claude/GPT/Llama, "matching a user's views" is one of the strongest predictors of which response humans prefer (~6% increase in selection probability).
                - Both humans and preference models prefer convincing-but-wrong answers a non-negligible fraction of the time; RLHF therefore trains sycophancy.
                - Independent tests have found chatbots abandon a correct answer about 58% of the time when a user simply pushes back — and in April 2025 OpenAI had to reverse a ChatGPT update because it had become excessively flattering.
            - **DOK 2 - Summary:**
                - AI chatbots are built to agree with you and tell you what you want to hear — that's not a flaw, it's how they're designed. That makes them a bad fit for guiding someone's moral or spiritual growth, where the right answer is often no.
            - **Link to source:** https://arxiv.org/abs/2310.13548
    - **Subcategory 3.2:** Doctrinal flattening & hidden values bias
        - **Source 1: Owen (2026) — AI and Ethics "Detecting doctrinal flattening in AI generated responses"**
            - **DOK 1 - Facts:**
                - Built a reproducible doctrinal knowledge base of 576 atomic claims from catechisms, confessions, creeds, and denominational statements across 11 Christian traditions, organized into 8 loci (Authority, Trinity, Salvation, Sacraments, Eschatology, Anthropology, Ecclesiology, Ethics); scored GPT-4o and Gemini 2.5 Flash against it over 155 prompt–response pairs.
                - Finding: high precision, low recall (GPT-4o ~0.86 precision / ~0.56 recall; Gemini lower on both) — models echo well-known doctrines accurately but omit large portions of each tradition's teaching.
                - Dominant error was flattening/omission (collapsing distinctives into a generic "Christians"); outright contradiction was rare but serious, concentrated in sacraments and eschatology (e.g., Eucharist described as merely symbolic, denying Catholic/Orthodox real presence). Minority traditions (Orthodox, Pentecostal, LDS, Jehovah's Witnesses) were systematically underrepresented.
            - **DOK 2 - Summary:**
                - The only peer-reviewed, Christianity-specific study proving models sound orthodox while getting doctrine substantively wrong. The core threat isn't outright error (rare) but partial truth — fluent, surface-accurate answers that often omit.
            - **Link to source:** https://link.springer.com/article/10.1007/s43681-026-01051-0
        - **Source 2: Rozado — "The Political Preferences of LLMs," *PLOS ONE* (2024)**
            - **DOK 1 - Facts:**
                - 11 political-orientation tests across 24 LLMs; most diagnosed as left-of-center (an earlier run found 23 of 24 left-leaning).
                - Models can be steered to any point on the spectrum with "modest amounts" of fine-tuning data.
            - **DOK 2 - Summary:**
                - Mainstream models carry a documented secular/left default — so the model's baseline worldview is not the family's.
            - **Link to source:** https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0306621
    - **Subcategory 3.3:** Scripture hallucination
        - **Source 1: Answers in Genesis / Fox News (2023) — fabricated Bible verse responses**
            - **DOK 1 - Facts:**
                - ChatGPT generated a fake, scripture-styled passage depicting Jesus affirming a transgender person; widely shared and criticized as the bot "pulling from the culture, not God's Word."
            - **DOK 2 - Summary:**
                - A viral, screenshot-ready fabrication of Scripture — the exact "fatal screenshot" scenario a kids' product cannot risk.
            - **Link to source:** https://answersingenesis.org/technology/chatgpt-generates-bible-verse/
        - **Source 2: Christianity Today (2023) — "Misreading Scripture with Artificial Eyes"**
            - **DOK 1 - Facts:**
                - ChatGPT confidently asserted a Greek second-person pronoun in 1 Cor 6:19–20 was singular, then admitted it is plural and reversed — stating Scripture facts wrongly with confidence.
                - Warned that BibleGPTs can "hallucinate" heretical statements.
            - **DOK 2 - Summary:**
                - Documented, confident scriptural/exegetical error (plus a sycophantic flip when pressed).
            - **Link to source:** https://www.christianitytoday.com/2023/07/ai-chatgpt-exegetical-tool-bible-scripture-sermon-mount/
    - **Subcategory 3.4:** Public rejection
        - **Source 1: Pew Research Center (2025) — How Americans view AI**
            - **DOK 1 - Facts:**
                - 73% of Americans say AI should play no role in advising people about their faith in God — the single most-rejected use of AI in the survey.
            - **DOK 2 - Summary:**
                - The public has already rejected AI-as-faith-advisor.
            - **Link to source:** https://www.pewresearch.org/science/2025/09/17/how-americans-view-ai-and-its-impact-on-people-and-society/

---

## References

- Pew Research Center (2025). Decline of Christianity in the U.S. Has Slowed, May Have Leveled Off (2023–24 Religious Landscape Study). https://www.pewresearch.org/religion/2025/02/26/decline-of-christianity-in-the-us-has-slowed-may-have-leveled-off/
- Pew Research Center (2025). How U.S. Parents Are Raising Their Children Religiously. https://www.pewresearch.org/religion/2025/12/15/how-parents-are-raising-their-children-religiously/
- Pew Research Center (2023). 70% of White Evangelical Parents Say It's Very Important That Their Kids Have Similar Religious Beliefs to Theirs. https://www.pewresearch.org/short-reads/2023/02/06/70-of-white-evangelical-parents-say-its-very-important-that-their-kids-have-similar-religious-beliefs-to-theirs/
- Barna Group (with Cardus). Children's Faith Formation. https://www.barna.com/research/children-faith-formation/
- American Bible Society. State of the Bible 2025, Chapter 5. https://www.americanbible.org/news/press-releases/articles/state-of-the-bible-2025-chapter-5/
- YouVersion (with OneHope). Bible App for Kids. https://www.youversion.com/bible-app-for-kids
- Hallow (app) — Wikipedia. https://en.wikipedia.org/wiki/Hallow_(app)
- Tech.eu (2025). How Romanian Startup Bible Chat Turned AI and Faith Into a Global Phenomenon. https://tech.eu/2025/06/20/how-romanian-startup-bible-chat-turned-ai-and-faith-into-a-global-phenomenon/
- Brave Parenting. Guide to the Bible Chat App. https://braveparenting.net/brave-parenting-guide-to-the-bible-chat-app/
- Sharma et al., Anthropic (ICLR 2024). Towards Understanding Sycophancy in Language Models. https://arxiv.org/abs/2310.13548
- Owen (2026). Detecting Doctrinal Flattening in AI-Generated Responses, AI and Ethics. https://link.springer.com/article/10.1007/s43681-026-01051-0
- Rozado (2024). The Political Preferences of LLMs, PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0306621
- Answers in Genesis (2023). ChatGPT Generates Bible Verse. https://answersingenesis.org/technology/chatgpt-generates-bible-verse/
- Christianity Today (2023). Misreading Scripture with Artificial Eyes. https://www.christianitytoday.com/2023/07/ai-chatgpt-exegetical-tool-bible-scripture-sermon-mount/
- Pew Research Center (2025). How Americans View AI and Its Impact on People and Society. https://www.pewresearch.org/science/2025/09/17/how-americans-view-ai-and-its-impact-on-people-and-society/
