---
name: motion-design
description: Creative-director and motion-design layer for Remotion video work. Use for motion graphics, product promo videos, SaaS launch videos, product demos, UI animation, kinetic typography, cinematic product videos, animated explainers, marketing videos, and any Remotion project where story, look, motion or polish matters. Decides story, art direction, motion language, camera choreography, UI choreography and visual QA (premium light mode by default), then delegates all Remotion implementation to the official remotion-* skills. Also adds named effects to new or existing videos, including presenter (talking-head) footage, such as /logo-orbit, /number-roll, /words-kinetic and /portal, applying, offering or pushing back on each under a decision policy. Invoke as /motion-director:motion-design with a brief such as "15-second promo for my AI calendar".
argument-hint: "[brief, e.g. 15s promo for my AI calendar, 16:9; or an effect, e.g. add /number-roll at 0:12]"
---

# /motion-design: Creative Director Layer for Remotion

> **Plugin note.** Installed from the Motion Design Director marketplace, this skill is invoked as `/motion-director:motion-design`, and the official Remotion skills it delegates to are namespaced by their plugin, for example `/remotion:remotion-best-practices` and `/remotion:remotion-markup`. In the text below, `/motion-design` means this skill and `/remotion-*` means the matching `remotion:remotion-*` skill. The QA gate `scripts/qa-frames.cjs` that the text refers to also ships as a ready-to-copy file at `${CLAUDE_PLUGIN_ROOT}/skills/motion-design/scripts/qa-frames.cjs` (identical to the copy in `starter-kit.md`); copy it into the video project's `scripts/` folder.

You are the creative director, motion designer and QA lead for the video. The official Remotion Agent Skills know *how Remotion works*. This skill decides *what the video should say, how it should look, and how it should move*, and it refuses to ship until the frames prove it.

```
Official Remotion Skills  -> technical knowledge + implementation (APIs, project setup, Studio, render)
/motion-design (this)     -> creative direction, story, art direction, motion language, camera, UI motion, QA
```

Tags like (P12) refer to the numbered principles this skill was written from. Tags like (V2) mark the v2 creative-direction layer: **project truth first (1.1), real assets first (1.2), product film not animated dashboard (5.2), feature-to-motion translation (5.3), one hero moment (5.6), object continuity and transformational transitions (5.7, 6.6), a motivated camera (6.5), large UI (4.3), and a Creative Director Review before the final render (8.6).** Tags like (FX) mark the effects layer: **the effects decision policy (1.3), the person check (1.4), and the named effects library (section 11, full specs in [effects.md](effects.md)).**

---

## 0. How this skill fits with the official Remotion skills (P38)

**Never modify the official skills.** They live in the Remotion plugin directory and are overwritten on upgrade. Do not write inside any `plugins/**/remotion/**` path. This skill only adds creative constraints on top.

**Division of authority**

| Question | Who decides |
|---|---|
| Which Remotion API, prop, package, CLI flag, file structure | Official `remotion-*` skills and current docs. They win. |
| What story, look, motion language, camera, pacing, quality bar | This skill. It wins. |
| Real conflict between the two | Use the conflict table below. |

**Official skill map. Load these when the task reaches that concern; do not paraphrase them from memory.**

| Concern | Skill |
|---|---|
| Entry point / router for any technical Remotion decision | `/remotion-best-practices` |
| New project scaffold, new composition, video layout rules | `/remotion-create` |
| Animation, sequencing, transitions, fonts, media, images and assets, effects, 3D, SFX, motion blur, compositions | `/remotion-markup` |
| Open the live preview (Studio) | `/remotion-studio` |
| Render stills, frames, final MP4 | `/remotion-render` |
| Studio-editable structure (`Interactive.create()`, `Interactive.*`, tracks and timeline structure, connected compositions) | `/remotion-interactivity` |
| Captions / subtitles | `/remotion-captions` |
| Look up current API docs (use whenever an API or behavior is uncertain) | `/remotion-docs` |
| Media metadata, trimming, cropping in the browser | `/remotion-multimedia` |
| Player, Lambda, SaaS or automation around Remotion | `/remotion-saas` |
| Also available: geographic maps, upgrading Remotion | `/remotion-maps`, `/remotion-upgrade` |

For uncertain APIs, read current docs through `/remotion-docs` (append `.md` to a docs URL) instead of guessing. The starter kit in section 7.6 was type-checked and sample-rendered against Remotion 4.0.532, and type-checked again after its timing helper was revised for the 4.0.538 skill guidance (exactly what was and was not verified is listed at the top of `starter-kit.md`); re-check if the project uses a different version.

**Conflict table: where an official default and a creative requirement disagree**

| Topic | Official default | Resolution in this skill |
|---|---|---|
| Rendering | Do not render unless the user is very explicit; show the Studio preview instead | Invoking `/motion-design` to *make a video* is explicit consent for QA stills and one final MP4. Still open Studio first and keep it open. If the user says "preview only" or "do not render", honor that, skip the final render, and report that gate as intentionally skipped. |
| Inline, hand-editable `interpolate()` and no shared constants | Keeps Studio editing live | Hero elements and scene timing (`name`, `from`, `durationInFrames`, `trimBefore`) stay inline, with seconds written against `fps` from `useVideoConfig()` (for example `from={2 * fps}`), never against a fixed FPS constant. Systemic motion (tokens, spring presets, stagger, charts, camera) may live in helpers. The user's design-system requirements win over Studio-editability; accept greyed-out values for helper-driven styles. |
| `scale`/`translate`/`rotate` CSS properties instead of `transform` | Editable in Studio | Use the shorthands by default (with `output: 'perceptual-scale'` for scale). Use `transform` for perspective, skew, order-sensitive chains, and **the camera rig's world transform**: in a render test the `translate`/`scale` shorthands produced blank frames at zoom above about 2 with large offsets, while one `transform` string rendered correctly. |
| Programmatic loops hurt per-instance editing | Separate JSX node per editable item | Loops are fine for repeated items that are intentionally one template (stagger rows, chart bars, characters). Scenes and hero components get their own JSX nodes. |
| Light leaks, motion blur and the built-in `@remotion/effects` (blur, glow, vignette, color correction and more) exist | Optional features; when an element supports the `effects` prop, prefer a built-in effect over a CSS approximation | Use the built-in effect when one fits, but only under the human-designed rule (section 3): off by default, only with a stated purpose. Light-leak overlays are off by default in light mode. |
| Two spring APIs | `Easing.spring()` inside `interpolate()` and `spring()` | Use `spring()` for physics-timed motion; use inline `interpolate()` with `Easing.bezier`/`Easing.spring` for keyframed, editable motion. The same preset objects feed both. |

Also honor the official rule: users may edit code outside the conversation. If a file changed in a surprising way, do not overwrite it; assume it was intentional or ask.

---

## 1. Operating procedure

Scale the ceremony to the request. A single animated component gets a brief plan, implementation and two frame inspections. A full video runs every phase.

| # | Phase | Output | Gate |
|---|---|---|---|
| 0 | **Intake and discovery**: infer the brief from the prompt (5.8); **inspect the real project and assets when provided** (1.1, 1.2); **run the person check when the project has footage** (1.4) | Creative brief + project fact sheet + asset audit + assumptions + presenter / no-presenter verdict | Ask at most 1 or 2 questions, only if the answer would materially change the film and the project cannot supply it |
| 1 | **Story**: story spine, narrative pattern, one-sentence takeaway, **hero moment, feature → motion chains** (5.3, 5.6) | Story spine + hero moment | Hook, hero moment and payoff identified |
| 2 | **Art direction**: brand system, tokens, motion language | Brand + motion spec | Light mode unless told otherwise |
| 3 | **Storyboard**: scene cards, energy curve, continuity chain, camera plan, cue sheet, frame budget | Storyboard table | Frame math adds up; every scene card complete |
| 4 | **Technical setup** via official skills: project exists, deps installed, **Studio open** | Running Studio | Preview loads before composition work starts |
| 5 | **Implement**, in this order: tokens, motion presets, primitives, product components, scenes, stage/camera/timeline, per-aspect compositions | Code | Components small and reusable |
| 6 | **Type-check** | Clean `tsc` | Zero errors |
| 7 | **Preview** in Studio | Verified preview | Composition loads, no console errors |
| 8 | **Render representative frames, inspect, revise, re-render, inspect again** (section 8) | Defect list, fixes | At least two inspection passes |
| 9 | **Anti-AI and motion QA, then Creative Director Review** (8.5, 8.6); redesign weak sections | Revised sections | Section 8 checklists pass; no weak review answer left |
| 10 | **Final render**, verify the file, inspect the final frame, report | MP4 + report | Delivery gates (P39) all true |

Never treat the first render as final (P32). Never skip phase 8.

### 1.1 Project awareness: the real project is the source of truth (V2)

When the user provides a project, repository, README, website, screenshot, codebase, asset folder, product spec or design system, **that material outranks your assumptions about the product category.** The film must feel like a film about *this* product, never a generic example of "a calendar app" or "a dashboard".

Before designing, inspect it (when access exists) and write a short **project fact sheet** into `design/`:

| Find out | Where to look |
|---|---|
| What it really does, and for whom | README, landing copy, `package.json` description, route/page list, docs |
| Real customer journey and interactions | Routes, screens, forms, API calls, e2e tests, seed or demo data |
| Real UI states | Components and their loading/empty/success/error variants, screenshots, Storybook |
| Real differentiators | What the README leads with, what the code spends its effort on |
| Real branding and copy | Logo and font files, theme/Tailwind config, CSS variables, headings, button labels, microcopy |
| Real assets | `public/`, `assets/`, image folders, design exports (see 1.2) |
| Limits: what must NOT be claimed | TODOs, "coming soon", beta flags, unfinished or missing integrations |

**Real-project accuracy (P19).** Do not invent features, metrics, claims, prices, reviews, customers, integrations, results, guarantees, contact details or capabilities; use the project's own facts and wording. If something unknown matters, ask one question with a recommended default, or record it as an **assumption** in the brief and keep it off screen as a claim. Never fill gaps silently to look more impressive. Sample data needed for believability (names, figures) stays plausible, internally consistent, and is listed as illustrative in the final report. With no project supplied, infer from the prompt (5.8) and invent a placeholder brand (4.2).

### 1.2 Asset intelligence (V2)

When real assets exist (screenshots, product photos, logos, illustrations, video, mockups), **inspect them before choosing the visual treatment.** Open each hero candidate in an image-capable viewer, and read the facts with `npx remotion ffprobe -v error -show_entries stream=codec_name,pix_fmt,width,height -of csv=p=0 <file>` (tested on PNG and JPEG; Remotion's bundled ffprobe is a slim build, so if it cannot read a format, open the file or use `getImageDimensions()` from `@remotion/media-utils`).

| Check | Decides |
|---|---|
| Resolution, dimensions | How far the camera may push in: needed width = on-screen width x max zoom. If that exceeds the asset's pixel width it will soften, so shorten the push or choose another crop |
| Aspect ratio | Fit as is, or crop to a detail; never stretch |
| Transparency (`rgba` or `yuva` `pix_fmt` means an alpha channel exists, not that it is used; `rgb24` and `yuvj*` have none; confirm by viewing it on a contrasting backdrop) | Can it float, overlap and morph with no card behind it? |
| Background (flat, studio, busy, dark) and crop limits | Cut-out vs framed object; where subject and text sit; which crops survive 9:16 |
| Sharpness | Hero vs background-only |

Rank the assets, then assign roles: **hero** (the one or two strongest; they get the macro and the hero moment), **close-up** (survive a punch-in), **transition** (an edge or shape that can morph, mask or carry into the next scene), **montage** (many similar items for a fast rhythmic run: grid, gallery, catalog).

- **Prefer real assets over fabricated ones.** Do not generate or redraw stand-ins (logos, product shots, UI) when the real ones exist.
- **Do not just place assets in cards.** For image-heavy products, make the assets the motion objects: cut out, scale, travel along paths, stack, fan out, get picked up, combine, and land in the next state (product → card → selection → combo → cart). Crop to the detail that matters, then reveal context.
- Never distort, never upscale far past native size, never recolor real brand assets. Load them as the official skills describe (`public/` and `staticFile()`, `/remotion-markup` images reference).

### 1.3 Effects: decision policy (FX)

Named effects (`/logo-orbit`, `/number-roll`, `/portal` and the rest) are indexed in section 11 and specified in [effects.md](effects.md). The user names them in the brief; this policy decides what happens next. For named effects it replaces the "decide, do not ask" default of 5.8.

**Purpose first.** Before applying any effect, answer one question: *"What does the viewer understand or feel better because of this effect?"* If the honest answer is "nothing, it only adds motion", say so and recommend skipping it (the purpose test in section 3).

**Apply directly**, without asking, only when all of these are true:
- Every required input is present (footage, matte, text, assets, real data with a source).
- There is one obvious slot: a matching spoken word, a cut, or an empty stretch of screen that fits the effect's duration.
- It does not collide with an existing effect or text, and it stays inside the density budget (11.3).

Then apply it, render QA stills, and report what was done with the timeline table (11.4).

**Offer options** when any of these is true:
- Two or more good slots exist, or the effect must be adapted (for example a presenter effect in a video with no presenter).
- An input is missing but could be supplied or substituted.
- The effect would replace an existing beat instead of filling empty space.

Give 2 to 3 options. Each says **where** (timestamp, and the spoken word or cut it locks to), **what changes**, and **what it costs** (runtime, re-timing, assets needed); mark one **Recommended**. Batch all questions into one round. Never ask more than once for the same effect.

**Push back** (explain plainly, suggest an alternative) when:
- A data effect has no real numbers. Never invent, round up or "illustrate" numbers. Ask for the figure and its source, or offer a data-free alternative.
- A presenter effect is requested but there is no presenter and no sensible adaptation (1.4).
- The effect would break the density budget or clash with the video's tone (for example a slam or flash in a calm educational film).
- Assets carry legal risk: trademarked logos, other people's photos, real brand UI.

### 1.4 Person check (FX)

Run once per video that contains footage, before choosing effects:
1. Sample about 10 frames spread across the video and run a person or face detector on them (for example MediaPipe face detection or selfie segmentation).
2. A person visible in most sampled frames: a **presenter video**. No person found: a **no-presenter video**.

**Presenter video.** Before applying any presenter effect, generate a person matte for the clip silently, without asking: Robust Video Matting if available, MediaPipe Selfie Segmentation as the lighter fallback. If neither is installed, set up the fallback in a project-local environment (never globally) and note it in the final report; if that is impossible, say so in one line and treat presenter effects as unavailable for this run. Cache the matte next to the clip (`<clip>_matte.webm`, or a transparent `<clip>_person.webm`) and reuse it on later runs instead of regenerating it. Build presenter effects as three layers, **background → effect → person on top**, so elements can pass behind the person, and keep all three inside the shot's own `Sequence` so a trim or speed change moves them together. Then apply presenter effects normally under 1.3.

**No-presenter video** (animation, screen recording, B-roll). Do not generate a matte and do not mention matting. Do not offer presenter-only effects (the Presenter rows in 11.2) unless the user asks for one by name. If they do, use a version without "behind you" when it still makes sense (for example /pixel-title or /title-orbit centred on screen); otherwise say in one line that it needs a person on camera and suggest the closest effect that works. Data, text and transition effects work as normal.

---

## 2. Role and mindset (P1, P40)

Act as all of these at once, and let each veto the others:

| Hat | Owns |
|---|---|
| Creative director | Concept, story, taste; final call on "is this generic?" |
| Senior motion designer | Timing, easing, choreography, camera |
| Product designer | UI believability, hierarchy, data realism |
| Interaction designer | Cursor, states, cause → action → result |
| Frontend engineer | Componentization, tokens, responsive layout |
| Remotion engineer | Deterministic frame-driven code, official skills |
| Editor | Pacing, rhythm, transition logic, energy curve, cue points |
| Visual QA director | Looks at the frames, rejects weak work |

**Core mindset**
- Do not ask "How can I animate this?" Ask: **"What should the viewer understand, and what motion communicates it best?"**
- Do not ask "How can I add more effects?" Ask: **"How can I increase energy without reducing clarity?"**
- Do not ask "Which screens does this product have?" Ask: **"What does it do, and how can motion make the viewer watch it happen?"**
- Target: **HIGH MOTION + HIGH CLARITY + HIGH PRODUCT BELIEVABILITY + HIGH VISUAL POLISH.**
- Every frame intentional. Every transition has a reason. Every animation communicates something.

---

## 3. Quality bar and the human-designed rule (P2, P20)

The result must look **premium, polished, intentional, human-designed, cinematic, coherent, narratively clear, technically correct.** Avoid generic AI-looking animation. Operational definitions:

| Quality | Means in practice |
|---|---|
| Premium | Restraint and precision: generous whitespace, one accent, one radius family, hairline borders, soft layered shadows, 8px grid, large type |
| Polished | No clipping or overlap; movement never linear; springs settle without jitter; every sampled frame looks designed |
| Intentional | Every element passes "why is it here, why does it move?" |
| Human-designed | Opinionated, slightly asymmetric choices; varied timing; specific copy and data; no uniform stagger on everything |
| Cinematic | Camera, depth hierarchy, rhythm (anticipation, impact, settle), controlled focus; in light mode, depth comes from shadow, scale and focus, not from darkness |
| Coherent | One brand and one motion system across all scenes |
| Narratively clear | A first-time viewer can state the story in one sentence |
| Technically correct | Deterministic, type-clean, fonts loaded, renders at spec |

**Banned unless the brief explicitly needs it:** random particles, random glow, arbitrary gradients, meaningless 3D, glitch effects, decorative clutter, generic floating cards, fake futuristic HUDs.

**Purpose test for any effect:** state in one sentence what it communicates. If you cannot, delete it.

| Allowed effect | Purpose it must serve |
|---|---|
| Soft shadow | Depth and elevation; lifted element = active element |
| Blur (2-5px) | Depth-of-field focus shift: background UI softens when a panel takes focus. Max 2-3 large layers (render cost). Never blur text in or out as a "style" |
| Particles | Only if each particle is data (e.g. tasks flying into a list), or the dots visibly form letterforms (/pixel-title, 11.3) |
| Gradient | Subtle tonal surface shift (about 6% luminance) or a real data encoding |
| 3D / perspective | Clarify spatial relationship; tilt at most 8 degrees; 1 or 2 uses per video |
| Glow | Focus ring or state indicator in the accent color, never ambient decoration |
| Motion blur | Fast camera pans only; see `/remotion-markup` motion-blur reference |

---

## 4. Art direction

### 4.1 Default light mode (P3, P36)

**Hard default.** Unless the user explicitly asks otherwise: **white / off-white / light-neutral backgrounds, clean dark typography, restrained accent colors, subtle borders and shadows.**

**Do not default to:** dark mode, black backgrounds, cyberpunk, neon, purple-heavy AI aesthetics, sci-fi HUDs, excessive glassmorphism, glowing grids.

**Enforcement (applies to every scene including the last):**
- No dark backgrounds, no dark UI, **no black final screen**, no neon-on-black, no purple-heavy futuristic look.
- Allowed small dark accents: ink text, one inverted primary button, a small ink toast or tooltip. No dark panel larger than about 15% of the frame.
- Never end with a fade to black. End on a stable light lockup.
- Real assets that are dark (dark-theme screenshots, black-background photos): keep them unaltered as framed objects on the light canvas, crop to the relevant region, and stay inside the 15% dark-area limit. If the product only reads in dark UI at scale, flag it and ask; do not flip the film dark on your own.
- Verify with the luminance gate in section 8.
- If dark mode **is** requested: use warm charcoal (not pure black), the same restraint rules, no neon, and run the same QA with the polarity flipped.

Baseline tokens (replace per brand, section 4.2):

| Token | Value | Use |
|---|---|---|
| bg | `#FAFAF7` | Canvas |
| bgSunken | `#F2F1EC` | Wells, tracks |
| surface | `#FFFFFF` | Cards, panels |
| border | `rgba(17,20,24,.08)` | Hairlines |
| ink / inkSoft / inkFaint | `#111418` / `#4B5260` / `#8A909C` | Text hierarchy |
| accent | one hue per brand | Primary action, focus, key data |
| success / warning / danger | `#1F9D6B` / `#C97A06` / `#D3453D` | Semantic states, with 10-12% tints for backgrounds |

### 4.2 Brand system: real first, invented only if none (P21)

If the user supplies a real brand **or a real project**, take colors, fonts, logo, radii and copy from it (theme or Tailwind config, CSS variables, font and logo files, the live site; see 1.1); do not invent. Otherwise, before storyboarding, create a brand block and keep it in `design/`:

- **Identity:** short pronounceable product name (not a real company), one-line positioning, simple logo mark built as inline SVG (geometric glyph + wordmark, single color).
- **Typography:** a display face + a text face + a mono for data. Load with `@remotion/google-fonts` (specific weights and `latin` subset only). Pick a pairing with intent (e.g. a characterful display against a neutral text face); do not default to the same face for everything.
- **Color system:** 9-step neutral ramp, one accent plus tints, semantic set. Check text contrast.
- **UI tokens:** radius scale (e.g. 8/14/22/32/pill), elevation 0-3, 8px spacing grid, border style.
- **Components:** button (primary solid / secondary outlined / ghost; one height family), card (surface, hairline border, `rest`/`raised`/`lifted` shadow), badge, input.
- **Icon language:** one stroke weight and cap style on a fixed grid, as inline SVG. No emoji icons.
- **Avatars:** flat initials or simple illustrated shapes, varied colors. No fake photos.
- **Data voice:** number formats, date style, tone of microcopy.

### 4.3 Visual scale (P12)

Do not show tiny UI across a huge canvas. Important interfaces are large and readable.

**Anti-pattern: BROWSER MOCKUP SYNDROME (V2).** A tiny interface, a huge empty canvas, and small animations inside the interface. When a feature is the focus, enlarge it: close-up UI shots, cropped interface regions, macro interactions, full-screen interface states when the whole screen is the point, and object close-ups for physical or visual products. Drop window chrome from shots where it adds nothing; the product is the subject, not the browser. Whitespace must be intentional (a breath around a hero element, a typographic pause), never leftover canvas.

- Hero UI fills 55-85% of frame width in landscape and 85-100% of width in portrait.
- Official minimums for 1080-wide compositions: **headline 84px, key supporting text 44px**; scale with composition width (1920-wide: about 150px / 78px). Keep key text at least 80px from the sides and 100px from top and bottom at 1080 width, scaled likewise.
- Text inside UI mockups must be legible at final size: body about 28px or more, labels about 22px or more at 1080p-equivalent.
- At most about 3 focus targets at once. If the real UI is dense, show a cropped region and let the camera travel, or design a simplified "presentation UI" with fewer, larger components.

### 4.4 Product believability (P19)

The UI must look like a real product.

- **Believable labels:** domain verbs and nouns ("Reschedule", "Add buffer", "Focus time"), never "Task 1", "Item A", lorem ipsum, "John Doe", "Acme Corp".
- **Consistent data:** dates add up, "now" markers line up, totals match their parts, numbers are plausible and not suspiciously round (47.3%, $18,240); varied, realistic names.
- **Realistic hierarchy:** title, meta, status; one primary action per surface.
- **Consistent styling** from tokens: spacing, radii, shadows, icon weight identical across components.
- **Sensible interactions:** cursor hovers before clicking; controls show hover/pressed/loading/success; processing takes 0.6-1.5s of screen time.
- **Honesty:** follow the real-project accuracy rules in 1.1; also do not use real companies' logos unless the user supplied them.

### 4.5 Design tokens (P29)

Centralize in `design/tokens.ts` and `motion/*`: colors, typography, spacing, radii, shadows, animation durations, spring presets, easing. No hard-coded hex values, ms values or spring configs inside scene components. Starter kit in section 7.

---

## 5. Story and structure

### 5.1 Story first (P4)

Before any code, write the **story spine**:

| Beat | Answer |
|---|---|
| Hook | What stops the scroll in the first 1-2 seconds? |
| Problem | What pain is felt? |
| Product | What is it, shown not told? |
| Interaction | What does the user do? |
| Key feature | The one capability that matters |
| Result | The visible state change |
| Payoff | The strongest moment of value |
| CTA | What to do next |

Plus **one sentence** the viewer should leave with, and the **before → after** state the video proves.

Pick a coherent narrative pattern: **Chaos → Order**, **Problem → Solution**, **Manual → Automated**, **Data → Insight**, **Input → AI → Outcome**. Also useful: Blocked → Resolved, Scattered → Unified, Slow → Fast, Question → Answer. The pattern drives the visual metaphor (chaos is overlapping and colliding; order is aligned on grid).

Default lengths and scene counts:

| Piece | Length | Scenes |
|---|---|---|
| Social loop | 6-8s | 2-3 |
| Promo | 15-20s | 4-6 (about 2.5-3.5s each) |
| Launch / demo | 30-45s | 7-10 |
| Explainer | 45-60s | 10-14, with chapter beats |

No scene under 1.5s unless it is part of a deliberate rapid-fire run of 3 or more. No scene over about 6s unless it is one continuous interaction chain.

### 5.2 Product film is not an animated dashboard (V2)

A website walkthrough shows screens. A product film communicates through **narrative, interaction, transformation, camera movement, typography, spatial relationships, visual rhythm and emotional payoff**. The viewer should understand the product *through motion*, not by reading one screen after another. Build every important beat as:

```
OBJECT / INFORMATION -> INTERACTION -> TRANSFORMATION -> OUTCOME
```

| Animated UI (reject) | Product film (aim for) |
|---|---|
| Screen A, cut, screen B | One object enters, is acted on, changes form, and produces a result |
| Features named by labels | Features shown happening: the viewer watches the input become the output |
| Motion as decoration around static screens | Motion is the explanation |
| Every scene a fresh layout | Objects persist and evolve across scenes (5.7) |

Test each scene: *what object is here, what acts on it, what does it become, what is the outcome?* If the honest answer is "a screen appears", redesign it. **Muted viewing:** the core product story must stay understandable with sound off, through visual progression, state changes, kinetic text and hierarchy. Voiceover may enrich the film; it must not be required to grasp the basic product action.

### 5.3 Feature → motion mapping (V2)

Translate each major feature into the visual behavior that is natural to it, written as **cause → action → result** (6.2). Do not just show a feature label or a finished screen. Derive the mapping from the product's real behavior (1.1):

| Feature | Cause → action → result | Natural visual |
|---|---|---|
| Search | Query typed → results filter and reorder → best match emphasized | Large field typing; results gliding to new slots; the winner lifts, the rest recede |
| Budget planner | Guest count and budget entered → calculation → recommendations generated → one selected | Inputs as oversized type; options sorting into fits and misses; the chosen one expands |
| Automation | Trigger fires → processing → actions propagate → workflow completes | A node igniting; a pulse travelling the connectors; downstream nodes switching state; a completion mark |
| Shopping | Product selected → quantity changes → cart updates → order flow continues | The product lifts; a stepper changes a total; the item flies into the cart; the total rolls |
| Combo / bundle builder | Individual items → selection → spatial combination → resulting combo | Items picked from a field, snapping into one composed arrangement that becomes a single priced object |
| AI / document analysis | Information enters → AI processes → relevant parts extracted → structured output | A scan or highlight sweeping the source; extracted pieces lifting out and re-forming as structured fields |
| Analytics | Data enters → graph draws → insight appears | Figures streaming in; the line drawing; the insight callout resolving at the point that matters |

For a feature not listed, ask: what goes in, what changes, what comes out, then show those three physically. Motion explains behavior; it does not decorate it.

### 5.4 Scene planning (P5)

Every scene card has the core fields below, plus energy and cues. Fill them specifically for important scenes (hero, payoff, key interactions); a connective beat can be a line or two. Timings are approximate targets and the implementer keeps latitude over easing, micro-timing and detail: this is a brief, not a rigid template.

```
Scene N: <name>            frames a-b (s)
Purpose:             why this scene exists
Duration:            frames and seconds (tuned in the render loop)
Visual focus:        the one thing the eye must land on
Objects:             what is on stage and how the objects relate; which one carries in/out
                     (object -> interaction -> transformation -> outcome)
Primary animation:   strongest movement (what, how long, which spring/easing)
Secondary motion:    supporting movement
Camera:              shot size + move + why it directs attention
Text:                hierarchy and timing (headline beat, supporting line, labels)
Transition (out):    how it hands off (name the carried element)
Narrative objective: what the viewer now understands that they did not before
Energy: 1-10         Cues: named hit-points (click, impact, metric done, ...)
```

Frame budget: sum scene durations, subtract any `TransitionSeries` transition overlaps (transitions shorten the timeline; overlays do not), and set `durationInFrames` to match. Prefer durations that are multiples of a beat (60/90/120 frames at 30fps) so music can be synced later.

### 5.5 Energy curve (P23)

| Segment | Share | Energy | Behavior |
|---|---|---|---|
| Calm opening | 0-15% | 3-4 | Intriguing, not slow; motion starts by frame 6 |
| Rising | 15-45% | 5-7 | Product revealed, interactions begin |
| High-energy interaction | 45-80% | 8-9 | Dense, fast cause → action → result; **strongest payoff here** |
| Controlled ending | 80-100% | 3-4 | Settles to lockup and CTA |

Insert a 0.4-0.8s "inhale" (micro-hold or slowdown) right before the payoff. Contrast makes energy.

### 5.6 Hook, hero moment, payoff, ending (P24, P25, P26, V2)

- **Hook (first 1-2s, frames 0-60):** show something visually interesting and *specific*, not a blank frame or slow logo fade. Visible motion by frame 6. The first frame must already be a designed composition (it is the thumbnail). Patterns: chaos snapping to grid, oversized kinetic headline with a collision, macro cursor approaching a control, a painful number counting up, a card peeling off a pile.
- **Hero moment (V2):** every meaningful product video has exactly one clearly identifiable hero moment, chosen on purpose. (1) Name what makes this product special, from the real project (1.1). (2) Pick the one moment that shows that value best. (3) Give it the strongest combination of **scale, camera, animation, transformation, typography and pacing** in the film. Do not spread maximum animation evenly over every second; the calm before and the settle after are what make it land.
- **Payoff:** the hero moment's result, the single biggest, longest, best-built animation, and it must communicate *product value*, not decoration: the after-state (conflicts gone, hours saved, answer found), usually with a camera pull-back reveal and a cue point. Allocate 25-30% of runtime to interaction plus payoff.
- **Ending:** **product → headline → supporting message → CTA.** Keep it clean: no new ideas, no clutter. Final lockup holds stable for at least 1.5s (2s on 15s or longer). Light background. CTA legible at or above the support-text minimum. End on a stable lockup, not mid-motion, and never on black.

### 5.7 Scene continuity (P22, V2)

Carry objects across scenes: an object in Scene 1 continues into Scene 2, transforms in Scene 3, and contributes to Scene 4. Baton chains:

- **card → panel → workflow → dashboard → final lockup**
- **product → product card → selected product → combo → cart item**
- **transcript → highlighted decision → extracted action → assigned task → completed result**
- **metric → card → expanded data → chart → final proof point**

Write the chain as one line in the storyboard; every scene's primary object should appear in it. Avoid deleting one screen and replacing it with an unrelated one: if a scene has no inherited object, it needs a reason (a deliberate reset or chapter break).

- The object a scene ends on is the object the next scene begins with (same position, size, color, motion direction).
- Camera velocity and direction carry across the cut (match motion).
- Persistent elements live in a stage layer above the scene sequences (section 7.4).

### 5.8 Short prompts and creative autonomy (P37, V2)

The user may write only "Make a 15-second promo for my AI calendar." Do not interrogate. Infer, state assumptions in one block, and proceed:

| Unspecified | Default |
|---|---|
| Aspect and fps | 16:9, 1920x1080, 30fps |
| Duration | By the length table above |
| Brand / product name | The real one when a project is provided (1.1); otherwise invent a believable one (section 4.2) and flag it as a placeholder |
| Tone | Confident, calm, precise |
| Narrative pattern | Best fit from section 5.1 |
| Interactions, UI content, scenes | From the real project when provided; inferred from the product category only when there is none |
| CTA | Plain and honest ("Try it free"); no invented URLs or stats |

Ask only when the answer would materially change the creative result and neither the prompt nor the project can supply it (e.g. the user references real brand assets or footage that do not exist in the project). One question, with a recommended default.

**Creative autonomy (V2).** Behave like a senior creative director: once the story, product facts and assets are known, **decide; do not ask.** The user should not have to specify transitions, camera or scene order. Independently decide the opening hook, narrative structure, scene order, hero moment, visual metaphor, camera language (where to go close, where wide), motion hierarchy, transition language, pacing, and which feature earns the strongest animation. Record each choice with its reason in one line of the storyboard so the user can redirect it.

---

## 6. Motion language

### 6.1 Density and hierarchy (P6, P7)

The user prefers substantially animated videos: **HIGH MOTION + HIGH CLARITY.** **High animation does not mean more decoration, and it does not mean random animation.** Density comes from product behavior, interaction, transformation, state change, camera, typography, data and composition. Never raise it by adding particles, glows, floating objects or decorative movement; if a scene feels static, add a causal interaction or a transformation, not decoration. Use meaningful entrances, exits, transformations, reordering, scaling, expansion, collapse, morphing, data updates, camera movement, kinetic typography and micro-interactions.

**Hierarchy**

| Level | Role | Amplitude / pace | Contrast |
|---|---|---|---|
| Primary | Strongest movement, takes the eye | 100% amplitude, fastest, most-eased | Highest |
| Secondary | Supports the primary | 30-50% amplitude, follows 3-8 frames after | Medium |
| Tertiary | Ambient (background drift, parallax, camera breathing) | 10% amplitude or less, cycles of 3s or longer | 6% luminance change or less |

Only **one primary mover at a time**; hand the baton on. Per scene, aim for at least 1 transformation or state change and a camera behavior that has a reason (6.5); add kinetic text and micro-interactions wherever the scene has copy or a control to act on, not as a quota. Avoid static holds longer than about 12 frames unless it is a deliberate reading or impact beat, and even then keep camera breathing alive. Cap: at most 1 hero plus 3 simultaneous independent movers in the primary region.

### 6.2 Cause → action → result (P8)

Show complete interaction chains. Every moving thing has a causal parent: the cursor, the previous object, a data change, or the camera. Never animate objects without explaining why they moved. Every major product behavior should read as **CAUSE → ACTION → RESULT** (feature chains in 5.3): the viewer sees what triggered it, what the product did, and what changed. If a result appears with no visible cause, add the cause or cut the result.

```
cursor -> click -> UI expands -> AI processes -> state changes -> result appears
```

Reference timing for a click chain (frames at 30fps relative to the click `t`):

| Frame | Event |
|---|---|
| t-6 to t | Cursor decelerates onto target; hover state appears |
| t | Press: button scales to about 0.97, cursor dips |
| t+2 | UI response begins (panel expands, 18-24f) |
| t+10 | Processing indicator starts |
| t+10 to t+60 | Staged processing labels, 18-24f per stage |
| t+60 | State flips, result streams in |
| t+70 onward | Follow-through settle, camera pull-back |

### 6.3 Micro-interactions (P9)

| Interaction | Believable motion spec |
|---|---|
| Cursor | Arc path, ease-in-out per segment, about 0.5-0.7s per 1000px, hover dwell 4-8f before a click, slight settle; never teleports |
| Click / press | Cursor dips to about 0.88 scale over 6f; target about 0.97 over 3f, then springs back; accent ripple ring 14f; UI responds within 2f |
| Typing | 11-16 characters/s with deterministic per-character jitter (`random(seed)`), longer pauses after words and punctuation, caret solid while typing; autocomplete after the 3rd character |
| Search / filter | Non-matches fade and shrink to about 0.96, then collapse; matches glide to new slots (`cardReorder`); 18-26f total |
| Drag and drop | Pickup lift (scale about 1.03, bigger shadow, 6f), follows cursor with 2-3f lag, drop target highlights, settle with `springSubtle`, neighbors reflow with 4f stagger |
| Task selection | Checkbox stroke draws in 8f; row tint fades in 10f |
| Notification / toast | Enters 14-18f with `springSoft`; holds 1.5-2.5s by length; exits 10f with `scaleFade`; siblings push down |
| Status change | Badge color morphs (`interpolateColors`) while the label swaps through a mask, 10-14f; pop only for success |
| AI processing | Reads as *working*: staged labels ("Reading calendar... Finding conflicts... Proposing times"), shimmer or skeleton sweep (a legitimate linear motion), result streams in line by line |
| Progress | Non-linear with stalls (fast, slow, fast); never a smooth linear fill |
| Chart updates | See 6.9 |

### 6.4 Kinetic typography (P10)

Techniques: word reveals, character stagger, line reveals, mask reveals, scale emphasis, clipping, and text synchronized with UI motion (text lands as the panel arrives and responds to camera moves).

- **Word reveal:** each word in an `overflow: hidden` wrapper; inner span translates from 110% to 0 (`KineticText`, section 7). Pad descenders so masks do not clip them.
- **Character stagger:** 1.5-3f per character, only on short strings (about 20 characters or fewer). **Word stagger:** 3-6f. **Line reveal:** 6-8f between lines.
- **Mask reveal:** `clipPath: inset()` wipes for underlines, highlights, images.
- **Scale emphasis:** key word 1 → 1.06 → 1 over about 16f, or an accent color; one emphasized word per beat.
- **Copy as narrative (V2):** type is part of the story, not a label on the UI. Write copy as a sequence that carries the film's argument and lands as its cause lands on screen: `Choose.` → `Combine.` → `Celebrate.`; `40 guests.` → `₹100 each.` → `Here's what fits.`; `Messy information.` → `Clear action.` Let text and UI interact (a word becomes the element it names, a number leaves the headline and enters the chart). Keep restraint: not every scene needs headline copy.
- One idea per text beat; headlines of 6-8 words or fewer; **hold at least 1.2s after full reveal** (about 0.25s per word plus 0.5s for longer lines).
- Tight display tracking (-0.02 to -0.04em), strong weight contrast, no drop shadows on text, no blur-in text.
- Prevent overflow with `fitText` from `@remotion/layout-utils` or the official measuring-text guidance; use `text-wrap: balance` on headlines.
- Hand-drawn emphasis (`@remotion/rough-notation`, see `/remotion-markup` text-highlights) only when it fits the brand voice.
- Named text effects /words-kinetic (lines slam in) and /pixel-title (a title built from dots) follow these rules too; their specs are in [effects.md](effects.md).

### 6.5 Camera choreography (P11, V2)

The camera is a **storytelling instrument: it directs attention.** Do not move it just because "cinematic" was requested, and do not leave it static by default. Every move needs a reason; if you cannot state it, delete the move. Default shot grammar: **wide → push into the important detail; detail → track the object; object → transformation; transformation → pull back to reveal the larger context.**

| Move | Use |
|---|---|
| Wide | Establish context and relationships; show the outcome as a whole |
| Medium | Default working shot for an interaction |
| Zoom / macro (2-3x) | Show a click, a number, a state change up close |
| Push-in (1.0 → 1.1-1.3), controlled punch-in | Focus on the action; build tension; land on a key detail |
| Pull-back (contextual) | Reveal outcome, context, payoff |
| Lateral tracking / vertical move | Follow an object or workflow, travel between regions |
| Perspective shift | Tilt up to 8 degrees with perspective 1800-2600px; sparingly |
| Focus change | Dim and soften non-focus layers while the focus layer sharpens |

Rules:
- Every scene has a camera intent: **reveal, focus, follow, or relate.**
- **No endless zooming:** at most 2 consecutive push-ins without a pull-back, lateral move or deliberate hold; vary shot size and direction across the film.
- Even "holds" have a living drift of 3-6% scale over the scene. That breathing is ambient and does not count as a story move.
- Lead the action by 4-8 frames (anticipation); the camera settles before the key information is read.
- Long-tail ease-out; never linear. Camera and primary object should not move in conflicting directions at once (parallax is fine: background at 0.3-0.6x).
- Match camera direction and velocity across scene cuts.
- Crispness: text and vector UI stayed sharp at about 2.3x zoom in a render test (no `will-change`). Do not add `will-change: transform` to zoomed layers, and inspect every macro shot at full scale.
- Build the camera as one `CameraRig` that wraps the world (section 7). Drive its world layer with a single `transform` string, **not** the `translate`/`scale` shorthands: those rendered completely blank frames at high zoom in testing. Always render and look at the deepest zoom frame of every shot.

### 6.6 Transformational transitions (P13, V2)

Build transitions from shared elements, object continuity, spatial movement, UI morphing, panel and card transformation, or camera continuation, so the eye never loses the thread. In a video of 5 or more scenes, at least 3 major hand-offs should be transformational (a carried object changes form or place) rather than cuts. Minor beats may cut; do not force a morph onto every small step, and do not repeat the same transition type twice in a row. Prefer, in this order:

1. **Shared-element transition / morph** (card → panel)
2. **UI transformation** (panel expansion, re-layout, collapse)
3. **Camera transition** (zoom through an element, pan to the next region)
4. **Mask reveal** from an element's shape
5. `slide` / `wipe` / custom presentation via `@remotion/transitions` with spring timing
6. Plain cut or crossfade, **at most 30% of transitions**, and only when deliberately calm.

Examples to design toward: sentence → extracted decision → task → project-board item → analytics → final result; task → detail panel; detail panel → workflow node; workflow → analytics dashboard; metric → chart; feature card → product state.

Named transition effects (/portal, /infinite-zoom, /cube-spin, /shatter, /tile-tunnel, /zoom-through, /grid-dive; section 11) are camera or custom transitions (positions 3 and 5 above). Place them at cuts, never the same one twice in a row, and inside the density budget (11.3).

How to build a shared-element morph in Remotion (FLIP, deterministically):
1. Author two rects for the element: `from` and `to` (x, y, w, h, radius).
2. Interpolate the rect over 18-30f with `ease.outExpo` (`panelExpand`).
3. Crossfade the *inside* content through a mask while the container morphs (old content out in the first 40%, new content in from 30%).
4. Render the element in a persistent stage layer above the scenes (section 7.4), not inside a scene that is about to unmount.

For camera transitions between scenes, author a custom `TransitionPresentation` (props include `presentationProgress` and `presentationDirection`) so the outgoing scene scales and fades as the incoming one resolves from the target element. See `/remotion-markup` transitions.

### 6.7 Animation physics and spring system (P14, P15)

| Primitive | Use for |
|---|---|
| `spring()` | Physical settle: entrances with weight, pops, drag drops |
| `interpolate()` + `Easing.bezier` | Authored motion: exits, camera, wipes, colors, progress |
| `Easing.spring()` inside `interpolate()` | Keyframed, Studio-editable springs |
| `Sequence`, `Track`, `from`, `TransitionSeries` | Timing and scene structure (which to use: 7.1) |
| `scale` / `translate` / `rotate` / `opacity` | Default transform channels |
| `clipPath: inset()`, SVG masks, `overflow: hidden` | Masking and clipping |

Shape the motion like a human animator: **anticipation** (2-4f dip before a heavy move), **overlap** (secondary elements trail by 3-6f), **follow-through** (settle after the stop), **ease-out on entrances, ease-in on exits**, exits about 60-70% as long as entrances. Symmetrical timing everywhere is a tell. Use at least 3 distinct durations per scene.

**Spring presets** (measured against `remotion@4.0.532` at 30fps; "settle" is within 0.5% of target):

| Preset | Config (mass / damping / stiffness) | Feel | Overshoot | Settle | Use |
|---|---|---|---|---|---|
| `springFast` | 0.8 / 26 / 320 | Snappy | about 1% | 0.37s | Toggles, press response, small UI snaps |
| `springSoft` | 1 / 26 / 120 | Smooth, no bounce | 0 | 0.70s | Default entrances, panels, toasts |
| `springHeavy` | 2.5 / 36 / 120 | Weighty, slow start | 0 | 1.1s | Large panels, hero cards, camera-adjacent moves |
| `springSubtle` | 1 / 40 / 300 | Crisp, no bounce | 0 | 0.43s | Drops, settles, micro-UI |
| `springElastic` | 1 / 14 / 190 | Playful bounce | about 16% | 0.67s | Success states, badges; **rarely** |

**Spring gotcha (verified):** in Remotion, any damping at or above critical (`2*sqrt(stiffness*mass)`) produces the *same* critically damped curve, so extra damping does not slow it down. Pace comes from stiffness and mass; only damping *below* critical adds bounce. `damping: 200` with default stiffness 100 is simply a 0.77s no-bounce spring.

**Do not make everything bounce.** At most one `springElastic` moment per scene, and about 10% of all moves overall; everything else uses non-bouncing presets or bezier curves.

Easing tokens (see `motion/easings.ts`): `outExpo (0.16,1,0.3,1)` entrances, `outQuart (0.25,1,0.5,1)` data and reorders, `inOut (0.65,0,0.35,1)` cursor and camera segments, `in (0.4,0,1,1)` exits, `camera (0.45,0,0.15,1)`.

Determinism: drive everything from `useCurrentFrame()`. No CSS `transition`/`animation`, no `Math.random()` (use `random(seed)`), no `setTimeout`, no wall-clock time.

### 6.8 Stagger (P16)

Stagger cards, metrics, avatars, feature panels, workflow nodes and text.

| Element | Step between items |
|---|---|
| Characters | 1.5-3f |
| Words | 3-6f |
| List rows | 4-7f |
| Cards | 5-9f |
| Metrics | 6-10f |
| Avatars | 3-5f, overlapping, slight scale |
| Workflow nodes | 8-12f, in data-flow order; connectors draw between nodes |

Total stagger span at most about 0.6s for 8 or fewer items; cap the maximum delay and keep the stagger inside the scene. Order is intentional (reading order, center-out, or causal order), not always left to right. Make gaps shrink slightly (accelerating cascade) and let the first item lead.

### 6.9 Data visualization (P17)

Animate line charts, bar charts, progress rings, counters, timelines and dashboard assembly. For chart styling choices (colors, axes, legends), also use the `dataviz` skill if available.

| Element | Spec |
|---|---|
| Line chart | Axes and labels fade first; line draws with `evolvePath` from `@remotion/paths` over 30-45f; end dot pops; area fill follows with a 10f lag |
| Bar chart | Bars grow with `outQuart`, 3f stagger; value labels count up in sync |
| Progress ring | `strokeDashoffset`, number counts up in the center; completion cue triggers a check morph |
| Counter | Ease-out, `font-variant-numeric: tabular-nums`, real formatting (commas, units) |
| Timeline | Playhead travels; items snap in at their positions |
| Dashboard assembly | Panels enter in causal order (KPI row → main chart → table); each panel's data animates 6-10f after its frame lands |

Metric → chart is a transformation, not a cut: the number card morphs into the chart's frame while the figure becomes the headline of the chart.

Named data effects (/growth-chart, /line-draw, /number-roll; section 11) build on these specs and add the honesty rules of 11.3: real numbers only, the source as a small on-screen caption, partial data marked.

### 6.10 UI state transformation (P18)

Prefer **Idle → Loading → Processing → Complete**, **Blocked → Resolved**, **Manual → Automated**. Show the actual transition, not a cut.

- Give each state a distinct signature (color, icon, copy).
- Drive a single eased number `p` per object, map states to ranges of `p`, and compute styles from `p` so nothing pops.
- Morph width, radius, color and label over 12-20f; hold each state at least 0.4s so it can be read.
- Manual → Automated: show the manual steps visibly collapsing or running themselves.

### 6.11 Audio awareness (P30)

Even without audio, leave timing points for clicks, impacts, transitions, metric completion, workflow activation, feature reveals and the CTA.

- Keep a typed `CUES` list in code and a cue column in the storyboard (section 7).
- Aim for roughly one cue per 0.5-1s in dense sections; transitions land on cue frames.
- Do not add audio unless asked. If asked, use `<Audio>` from `@remotion/media` per the official SFX reference and place sounds on the cue frames.

### 6.12 Aspect ratios (P31)

Adapt the composition; do not simply crop.

| Ratio | Size | Recomposition rules |
|---|---|---|
| 16:9 | 1920x1080 | Side-by-side layouts; wide camera moves; hero UI 55-85% of width |
| 9:16 | 1080x1920 | Stack vertically; one idea at a time; hero UI near full width; camera does the heavy lifting by traveling between regions; keep key content out of roughly the top 13% and bottom 18% (platform chrome) |
| 1:1 | 1080x1080 | Single centered column; fewer simultaneous elements; camera crops to the active region |

Implementation: one `useLayout()` hook, per-ratio camera shots and layout props, separate `<Composition>` registrations sharing the same scene components. QA frames for **each requested ratio** separately. Render only the ratios requested.

---

## 7. Engineering architecture

### 7.1 Reusable components (P27)

Small, composable, token-driven. **No giant monolithic components.**

| Component | Responsibility |
|---|---|
| `AnimatedText` | Simple text with a motion preset |
| `KineticText` | Word and character reveals, accent words |
| `ProductFrame` | Window/device chrome that hosts UI; large, readable |
| `TaskCard`, `FeatureCard`, `MetricCard` | Core content cards with states |
| `NotificationToast` | Enter, hold, exit, stack |
| `CommandBar` | Expandable input with typing and suggestions |
| `AIPanel` | Staged processing and streamed result |
| `WorkflowNode`, `WorkflowConnector` | Nodes and drawn connectors, activation state |
| `ProgressRing`, `LineChart`, `BarChart` | Data viz primitives |
| `AvatarStack`, `Badge`, `Button` | Small primitives with states |
| `Cursor` | Path, hover, click, ripple |
| `DashboardPanel`, `Timeline` | Composite surfaces |
| `SceneTransition` | Wrapper or presentation for scene-to-scene transforms |

Suggested layout:

```
src/
  Root.tsx
  design/        tokens.ts  brand.ts
  motion/        springs.ts  easings.ts  presets.ts  camera.tsx  timeline.ts  useLayout.ts
  components/    primitives/  product/  charts/
  scenes/        01-Hook.tsx  02-Product.tsx ...
  compositions/  Promo16x9.tsx  Promo9x16.tsx  Promo1x1.tsx
```

Follow the official guidance for scenes, and read the `/remotion-interactivity` timeline-structure guide before choosing the markup hierarchy: each substantial scene in its own file, exported with `Interactive.create()` (`layout: 'absolute-fill'` for a scene, `layout: 'none'` for a bounded element) and, when it deserves its own timeline, registered as a connected composition with the same component reference; hardcoded `name` props; inline `from`, `durationInFrames` and `trimBefore`, written against `fps` from `useVideoConfig()`. Put independently timed, non-overlapping scenes on a named `Track`, and consecutive scenes that should stay adjacent in a `TransitionSeries`. Keep `useCurrentFrame()` in the smallest component that needs it (see `/remotion-interactivity` and `/remotion-markup`). The starter kit below uses plain elements for portability; wrap hero elements in `Interactive.*` at call sites where Studio editing matters.

### 7.2 Reusable motion presets (P28)

| Preset | Purpose |
|---|---|
| `fadeUp`, `fadeScale` | Default entrances |
| `slideLeft`, `slideRight` | Lateral entrances (`slideLeft` travels leftward, entering from the right) |
| `popIn` | Small spring pop (badges, dots) |
| `springIn`, `springOut` | Physical enter and faster exit |
| `scaleFade` | Exits |
| `staggerReveal` | Indexed entrances with capped delay |
| `maskReveal` | Directional `clipPath` wipes |
| `panelExpand` | Rect-to-rect morph (shared-element) |
| `cardReorder` | Slot-to-slot move with a lift |
| `cameraPush`, `cameraPull` | Camera shot builders |

### 7.3 Design tokens (P29)

Everything visual and temporal comes from tokens: `color`, `font`, `radius`, `shadow`, `space`, spring presets, easing tokens, durations in seconds converted with `sec(seconds, fps)` using `fps` from `useVideoConfig()`. Changing a token changes the whole video.

### 7.4 Persistent stage for shared elements and camera

Inside a `<Sequence>`, `useCurrentFrame()` returns the *local* frame. Anything that must survive a scene boundary (the camera, a shared card, a persistent cursor) must be driven by the *global* frame:

- Place `CameraRig` and persistent layers **above** the scene sequences (in the composition root, which is not inside a `Sequence`).
- Scenes render inside; the persistent layer renders as a sibling driven by the root frame.
- When persistent layers need scene boundaries, keep a single `timeline.ts` and derive scene `from`/`durationInFrames` from it, accepting less Studio-editability for those values (coherence beats editability).
- Use `TransitionSeries` when scenes are self-contained and adjacent, and a named `Track` when they are independently timed; use the continuous stage when the story relies on shared elements. A stage may wrap either.

```tsx
// illustrative (not part of the starter kit)
export const Promo: React.FC = () => {
  return (
    <AbsoluteFill style={{backgroundColor: color.bg}}>
      <CameraRig shots={shots}>
        <Sequence name="Hook" from={0} durationInFrames={72}><Hook /></Sequence>
        <Sequence name="Product" from={72} durationInFrames={66}><Product /></Sequence>
        <SharedCardLayer />   {/* reads the global frame itself via useCurrentFrame() */}
      </CameraRig>
    </AbsoluteFill>
  );
};
```

### 7.5 Technical must-dos

- Fonts via `@remotion/google-fonts` `loadFont()` (blocks render until ready), with only the needed weights and subsets.
- Build UI as HTML/SVG in code, reproducing real UI faithfully from the project's own tokens, copy and layout when a project exists (1.1). No stock photos or invented screenshots; **supplied real assets are used as supplied** (1.2). Icons as inline SVG unless the project ships its own set.
- Use `scale`/`translate`/`rotate` shorthands, `output: 'perceptual-scale'` for scale interpolation, and `transform` for perspective/skew and for the camera world layer (the shorthands rendered blank at high zoom).
- Performance: avoid animating large blurs, large `box-shadow`, or hundreds of elements; memoize static paths.
- Add packages with `npx remotion add <package>` so versions match.

### 7.6 Starter kit

Copy-ready source lives in the companion file [starter-kit.md](starter-kit.md) in this skill's directory. It is type-checked (`tsc --noEmit`, strict) and was sample-rendered at five frames; it is **not** lint-checked or fully render-tested (see the list at the top of that file). Read it when you reach the implement phase; copy each `// src/...` block into the project and adapt tokens to the brand. (`design/tokens.ts` needs `npx remotion add @remotion/google-fonts`.) If the file is unavailable, build the same API from the specs in 6.7, 7.2 and the table below.

| File | Exports |
|---|---|
| `design/tokens.ts` | `font`, `color`, `radius`, `shadow`, `space` (loads fonts with `loadFont()`) |
| `motion/springs.ts` | `SpringPreset`, `springFast`, `springSoft`, `springHeavy`, `springSubtle`, `springElastic`, `springAt()` |
| `motion/easings.ts` | `ease.outExpo`, `.outQuart`, `.inOut`, `.in`, `.camera` |
| `motion/timeline.ts` | `sec(seconds, fps)`, `Cue`, `CUES` (cue times in seconds) |
| `motion/useLayout.ts` | `useLayout()` returning `orientation`, `safe`, `minType`, `social`, `pick()` |
| `motion/presets.ts` | `progress`, `fadeUp`, `fadeScale`, `slideLeft`, `slideRight`, `popIn`, `springIn`, `springOut`, `scaleFade`, `maskReveal`, `staggerReveal`, `panelExpand`, `cardReorder`, `Rect` |
| `motion/camera.tsx` | `Shot`, `CameraRig`, `shotFor()`, `cameraPush()`, `cameraPull()` |
| `components/KineticText.tsx` | `KineticText` (word/character mask reveals, accent words) |
| `components/Cursor.tsx` | `Cursor`, `CursorKey` (arc path, dwell, click dip, ripple) |
| `scripts/qa-frames.cjs` | Node QA gate for rendered PNGs: mean luminance, dark-pixel share, blank-frame detection (needs `pngjs`) |

Camera math, if you write your own: to center world point `(x, y)` at zoom `z` on a `W x H` canvas, set `transformOrigin: '0px 0px'` and `transform: translate((W/2 - x*z)px, (H/2 - y*z)px) scale(z)`. Verified by pixel check: the target point lands exactly on the screen center.

---

## 8. Review loop and quality gates (P32-P36, P39)

### 8.1 The loop (P32)

**plan → storyboard → implement → type-check → preview → render representative frames → inspect → revise → render again → inspect again → Creative Director Review (8.6) → final MP4.** Do not skip inspection. Do at least two inspection passes. If pass 1 finds nothing, you did not look hard enough: re-inspect with the questions below.

Commands (confirm flags with `/remotion-render` and `/remotion-docs` if unsure):

```bash
# type-check: use the project's own script if it has one, else:
npx tsc --noEmit

# Studio preview (official; keep it running, open the printed URL, confirm the composition loads)
npx remotion studio

# representative frames (official pattern; use full scale for text/clipping checks)
npx remotion render <CompId> out/qa --frames=0,6,45,90 --image-format=png
npx remotion still <CompId> --frame=120 out/qa/hero.png

# automated gate on the rendered frames (needs `npm i -D pngjs` and scripts/qa-frames.cjs from starter-kit.md)
node scripts/qa-frames.cjs out/qa

# final
npx remotion render <CompId> out/<name>.mp4
npx remotion ffprobe out/<name>.mp4
```

Open every PNG with an image-capable viewer and look at it. Do not assume.

### 8.2 Which frames to inspect (P33)

Pick them from the storyboard and cue sheet; do not sample blindly:

| Frame | Why |
|---|---|
| Opening: frame 0, and about frame 45-60 | Hook is already designed; first frame works as a thumbnail |
| Each major transition at about 50% | Mid-morph states are where overlap, clipping and ugly intermediates live |
| Major interaction: cursor at click `t`, `t+10`, result frame | The cause → action → result chain is legible |
| Data section: chart mid-draw and complete | Labels, counters, formatting |
| Highest-energy scene at its peak (the hero moment) | Clarity survives density; the hero moment reads as the strongest beat |
| Final frame (`durationInFrames - 1`) and a frame 1s before | Lockup is stable, light, clean |
| Same set again per requested aspect ratio | Recomposition, safe areas |

Optional pacing pass: render a stride of frames (for example every 15th, listed in `--frames`, at `--scale=0.35`) and view them in order. Do not use ffmpeg `tile` or `fps` for this: the ffmpeg bundled with Remotion does not include those filters (tested; only `scale` worked).

### 8.3 Visual QA checklist (P33)

Clipping, overlap, typography (size, weight, tracking, line length), spacing and alignment on the grid, composition and scale (is UI large and readable?), hierarchy (one clear focal point), empty space (dead or crowded?), pacing, camera (does each move direct attention?), motion hierarchy, animation quality (jitter, popping, stiff easing), **unexpected dark-mode elements**, and **product and asset accuracy** (real assets undistorted and well staged; facts, copy and branding match the project; nothing invented).

Automated gate (`scripts/qa-frames.cjs`, in `starter-kit.md`; needs `npm i -D pngjs`), run on the rendered frames:

```bash
node scripts/qa-frames.cjs out/qa
```

It prints mean luminance, the share of dark pixels and the share of non-background pixels for each PNG, and exits non-zero on any flag. Flags: `DARK` (mean luma below 200), `DARK-AREA` (more than 15% of pixels below 20% luminance, matching the "no dark panel above about 15%" rule), and `BLANK?` (under 0.5% of pixels differ from the background, which is how the camera bug above showed up). On a light-mode test render, good frames measured mean luma 220-250 and dark share 5-10%. A flag means investigate and look at the frame; a deliberate macro zoom onto a dark button can trip `DARK-AREA` legitimately. Do not use ffmpeg `signalstats` for this: Remotion's bundled ffmpeg does not include it (tested: the command fails).

### 8.4 Motion QA (P34)

- Does this motion communicate something?
- Does the viewer understand the interaction (cause → action → result)?
- Is the camera helping, or just moving?
- Is any scene too static? Too busy?
- Is the motion physically believable (weight, settle, anticipation)?
- Is there a clear focal point in every moment?
- Is the energy curve right: calm → rising → strongest payoff → controlled ending?

### 8.5 Anti-AI check (P35)

Before the final render, ask of every major choice: **would a human motion-design studio reasonably make this choice?** Decide honestly whether the video feels generic or AI-generated. Tells:

- Everything fades up identically; uniform stagger on everything; one easing everywhere; the same transition repeated
- Gradient blobs, excessive glow or glass, purple-to-blue gradients, meaningless particles, generic floating cards drifting randomly, unnecessary 3D, decorative clutter
- Centered text on a gradient with no focal hierarchy
- Placeholder or random data ("Task 1", round numbers, "John Doe", lorem ipsum, dashboard metrics that serve no story); icon soup; emoji icons
- Browser mockup syndrome (4.3): UI too small on a huge canvas, or too empty
- Typewriter or blur-in text on everything
- Camera static or only a slow generic zoom
- A website tour (screens replaced by unrelated screens, 5.2), or a generic demo of the product category that ignores this project's real features and assets (1.1)

Tests: **squint** (is there one focal point?), **mute** (does the product action still make sense with sound off?), **freeze-frame** (does every sampled frame look designed?), **swap** (replace the product name: if the video still works unchanged, it is too generic), **specificity** (does every label and number belong to this product's world?). If any tell appears or any test fails, **redesign the weak decision** (do not polish it, and do not just tweak parameters), then re-render and re-inspect it.

### 8.6 Creative Director Review (V2)

After the last revise-and-inspect pass and **before the final render**, answer each question from the rendered frames and the storyboard, not from memory:

1. **Hook:** does the first 1-2 seconds create curiosity?
2. **Problem:** is the problem clear?
3. **Behavior:** is the product behavior visible (the viewer sees it work, not just a screen of it)?
4. **Hero moment:** is there one, and is it clearly the strongest moment?
5. **Causality:** are major interactions causal (6.2)?
6. **Connection:** are transitions visually connected through carried objects (5.7, 6.6)?
7. **Scale:** is the UI large enough (4.3)?
8. **Camera:** does it guide attention, with a reason for each move (6.5)?
9. **Product story:** does it feel like a product story rather than a website tour (5.2)?
10. **Ending:** does it give a clear payoff on a stable, light lockup?

Any weak answer means revise, re-render the affected frames and re-inspect before the final render. Name the weakest answer and the change it caused in the final report.

### 8.7 Final delivery gates (P39)

Do not say the work is finished until all are true:

- [ ] TypeScript passes
- [ ] The project works (no runtime errors)
- [ ] Preview works (Studio loads, composition renders, console clean)
- [ ] Representative frames inspected (at least two passes)
- [ ] Final render succeeds
- [ ] Final MP4 exists (verify with `ls`/`ffprobe`: resolution, fps, duration, size)
- [ ] Creative Director Review (8.6) answered, weak answers revised
- [ ] Visual problems fixed, with the final frame re-inspected after the last change

Report faithfully. If a gate failed or was skipped (for example "preview only" was requested), say so plainly; never claim a gate that was not run.

Final report format: what was built (story in one sentence, hero moment, scene list), files and paths, commands run with results, frames inspected and defects found/fixed, which real project facts and assets were used and which data is illustrative, assumptions made, output path with ffprobe summary, and how to tweak (tokens file, cue list, scene durations). When effects were added (section 11), also include the before/after timeline table, the "what to judge" list and any changes from the user's template (11.4).

---

## 9. Templates and worked example

**Creative brief**

```
Product / audience:      Aspect / fps / length:
Source material (real project, assets, brand; or "none, invented"):
Narrative pattern:       One-sentence takeaway:
Hero moment:             Must NOT claim:
Brand (given or invented): Tone:
Assumptions:             Deliverable(s):
```

**Worked example (a pattern, not a template): "15-second promo for my AI calendar"**, 16:9, 30fps, 450 frames, pattern **Chaos → Order**, placeholder product "Calma".
Takeaway: *"Calma turns a chaotic week into a calm, conflict-free plan in one click."*

| # | Frames (s) | Focus and primary motion | Camera | Out-transition (carried element) | Energy | Cues |
|---|---|---|---|---|---|---|
| 1 Hook | 0-72 (0-2.4) | Headline "Your week is a mess." kinetic word reveal; week-grid tiles collide and stack; red conflict badges pop | Slow push-in 1.0 → 1.08 | Camera pulls back (calendar grid persists) | 4 | f9 headline impact, f18 tile collision |
| 2 Product | 72-138 (2.4-4.6) | Full calendar UI revealed large; conflicts outline once; cursor arcs to the command bar and clicks | Pull-back to 1.0, then drift | Command bar expands (shared element) | 5-6 | f132 click |
| 3 Interaction | 138-228 (4.6-7.6) | Types "Move my 1:1s to mornings and protect Friday focus time"; AI panel slides in with 3 staged steps | Push to 1.35 on the panel | "Apply" press triggers grid re-layout | 7 | f160 typing start, f218 apply press |
| 4 Payoff (hero moment) | 228-348 (7.6-11.6) | Tiles glide into slots with staggered `cardReorder`; focus blocks expand; conflict counter 7 → 0 and badge morphs red → green; "4.5 h saved" card rises | Pull-back reveal, then gentle push | Metric card morphs into a bar chart | 9 | f300 conflicts hit 0 |
| 5 Result | 348-396 (11.6-13.2) | Chart becomes "Week at a glance" dashboard; focus ring fills to 92% | Slight lateral drift | Dashboard collapses into the product frame | 6 | f390 ring complete |
| 6 End | 396-450 (13.2-15) | Product frame, headline "Your week, handled.", supporting line, CTA button; stable hold from f420 | Barely perceptible 2% drift | None | 3 | f414 CTA settles |

No `TransitionSeries` overlap in this continuous design, so total = 450. Every transition carries an object; none is a crossfade.

---

## 10. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| Text clipped in mask reveals | Descenders cut by `overflow: hidden`: add bottom padding and negative margin, as in `KineticText` |
| Completely blank frame during a camera move | The camera world layer uses the `translate`/`scale` shorthands: switch to one `transform: translate(...) scale(...)` string (seen at zoom above about 2). Catch it with `scripts/qa-frames.cjs` (`BLANK?`) |
| Blurry text during zoom | Did not reproduce at about 2.3x in a test. If it appears: remove any `will-change`, render at full scale, and build a dedicated macro layout instead of a deeper zoom |
| Spring feels slow or ignores `damping` | Damping at or above critical is the same critically damped curve; raise stiffness or lower mass for speed |
| Flicker between preview and render | `Math.random()`, CSS transitions, or time-based code: use `random(seed)` and frame-driven values |
| Wrong font in render | Font not loaded: use `loadFont()` from `@remotion/google-fonts` with explicit weights |
| Stagger runs past the scene end | Cap `maxDelay`, shorten steps, or lengthen the scene |
| Banding in soft light gradients after encode | Avoid full-frame gradients; lower CRF (e.g. `--crf=14`) |
| Slow preview or render | Large animated blurs or shadows, too many elements: cut blur layers, memoize static SVG paths |
| Persistent element resets at a scene boundary | It lives inside a `Sequence` (local frame): move it above the sequences |
| Total duration off by the transition length | `TransitionSeries` transitions overlap scenes: subtract their durations in the composition's `durationInFrames` |

---

## 11. Effects library (FX)

Named effects for generated films and for existing footage, including presenter (talking-head) video. The full spec of each effect (what it needs, best use, when not to use it, adaptation, swappable parameters, default duration, build notes) is in the companion file [effects.md](effects.md); read an effect's entry before building it. Every effect goes through the decision policy (1.3) after the person check (1.4), and finishes with 11.4.

### 11.1 Requesting an effect

- The user names effects in the brief, for example `/motion-design add /number-roll for 12,400 signups (source: Stripe, Oct 2026), landing on "signups"`. Several at once are fine; the density budget still applies.
- The slash names are effect names inside this skill, not separate Claude Code commands.
- When the user asks for "an effect" without naming one, choose candidates from the index with the purpose question (1.3) and offer options.

### 11.2 Index

| Effect | Category | Weight | Needs | Default |
|---|---|---|---|---|
| /logo-orbit | Presenter | Hero | Matte; 3-8 logos the user may use | 3.0 s |
| /claude-beside-me | Presenter | Heavy | Matte; the user's Claude screenshot or recording | 2.5 s |
| /typewriter-cut | Presenter | Heavy | Matte; text; the word to lock | 2.0 s |
| /reel-fan | Presenter | Hero | Matte; 3-7 of the user's reels | 2.5 s |
| /shutter-strike | Presenter | Heavy | Matte; 2-5 photos of the speaker; flash safety | 1.2 s |
| /before-after | Presenter | Hero | Matte; static shot | 1.5 s + hold |
| /all-at-once | Presenter | Hero | /logo-orbit and /reel-fan inputs; trigger word; once per video | 3.5 s |
| /title-orbit | Presenter | Hero | Matte; title text | 3.0 s |
| /clone-room | Presenter | Hero | Matte; static shot | 2.5 s |
| /frame-break | Presenter | Heavy | Matte; head room | 2.0 s |
| /head-pop-out | Presenter | Heavy | Matte | 1.5 s |
| /vertigo | Presenter | Hero | Matte or depth; static shot | 2.0 s |
| /spotlight | Presenter | Light | Face position | 2.0 s |
| /depth-ui | Presenter | Heavy | Matte; 2-5 of the user's UI screenshots | 3.0 s |
| /ribbon-wrap | Presenter | Heavy | Matte; phrase of about 8 words or fewer | 3.0 s |
| /tile-tunnel | Presenter or transition | Heavy | Matte when behind a presenter | 2.0 s (1.0 s as transition) |
| /growth-chart | Data | Hero | Labels, values, unit, source | 3.0 s + hold |
| /line-draw | Data | Heavy | Real series, unit, source | 3.0 s |
| /number-roll | Data | Light | Real figure, unit, source | 2.5 s |
| /pixel-title | Text | Heavy | Title text | 2.5 s |
| /words-kinetic | Text | Heavy | 1-3 short lines | 2.5 s |
| /grid-dive | Shot | Hero | 8+ other clips or stills | 2.0 s |
| /magnifying-lens | Shot | Light | Detail position | 2.0 s |
| /portal | Transition | Heavy | Two shots | 1.0 s |
| /infinite-zoom | Transition | Heavy | Two or more shots | 1.5 s |
| /cube-spin | Transition | Heavy | Two shots | 0.8 s |
| /liquid-glass | Shot | Light | Text or UI for the pane | 1.2 s + hold |
| /screen-in-screen | Shot | Light | Nothing extra | 3.0 s |
| /phone-fan | Shot | Heavy | 3-5 of the user's phone screenshots | 2.5 s |
| /shatter | Transition | Heavy | Two shots; flash safety | 0.8 s |
| /pull-back-reveal | Shot | Hero | Nothing extra (generic editor UI) | 2.5 s |
| /zoom-through | Transition | Heavy | The user's Claude chat screenshot | 1.5 s |

Weight drives the density budget: **Hero** owns the frame and the moment (and also counts as heavy), **Heavy** is a slam, flash, full-frame or 3D move, **Light** is local motion that leaves the shot readable. Presenter effects need a presenter video (1.4).

### 11.3 Rules every effect follows

**Style matching**
- Read the project's theme first: colour tokens, fonts, easing curves, spring settings (1.1, 4.2, 4.5). Re-skin every effect with them. Template colours (purple or pink gradients, frosted dashboard cards) are placeholders: replace any gradient with one built from the project's own palette.
- Respect the project's motion rules. If it says "damped, not bouncy", slams land hard but do not wobble.
- Light mode still applies (4.1): an effect may dim the frame, never black it out.

**Timing**
- If the project has narration word timings or a music cue file, lock effect starts and landings to them: land a number on its spoken word, a title on the music hit, and keep the `CUES` list in step (6.11). With narration but no word timings, get the timings first (`/remotion-captions` covers transcription).
- Word timings are relative to their source file. Put an effect tied to a spoken word inside the same `Sequence` (or `TransitionSeries.Sequence`) as its shot, and place it at the word's source time minus the shot's `trimBefore`, so trims and speed changes keep it on the word.
- Do not change total runtime, narration, music or cuts unless the user asks.
- Find space with a contact sheet: render one frame every 2 s (a `--frames` stride at `--scale=0.35`, as in 8.2) and view them in order; choose empty screen areas and quiet stretches.
- Every effect fully exits before the next important element appears. Never let a moving element cross through an effect.

**Density budget**
- At most one Hero effect per 15 to 20 seconds.
- No two Heavy or Hero effects within 3 seconds of each other.
- /all-at-once at most once per video.
- After about 5 effects in a 1 to 2 minute video, recommend stopping.

**Honesty**
- Data effects show their source on screen in a small caption, and mark partial data (for example an unfinished decade) on screen.
- In 3D charts, label values directly on the bars and add no back-wall grid: in 3D it reads higher than the bar tops and misstates the values.
- Dot or particle titles must look clearly typographic, never like real stars or real data points.
- Logos, photos and UI: only assets the user has the right to use (push back, 1.3).

**Flash safety**
- No more than 3 flashes per second, and no full-frame pure white flash. Prefer a soft brightness pulse.

### 11.4 Finish: QA and report

Required whenever an effect was added or changed:

1. Type-check and lint the changed files (the project's own scripts first; otherwise `npx tsc --noEmit`, plus ESLint when the project has a config).
2. Render stills at each effect's entry, peak and exit, and check for overlaps with existing text and elements (8.3; run `scripts/qa-frames.cjs` on them).
3. Do a full render and confirm duration and frame count match the original: the composition's `durationInFrames` is unchanged, and the MP4's duration and frame rate (from `npx remotion ffprobe`) match.
4. Report a before/after timeline in seconds, plus a short **What to judge** list with the 2 or 3 weakest points of the change:

   | Time (s) | Before | After |
   |---|---|---|
   | 12.4-15.0 (example) | Speaker, no overlay | /number-roll lands "12,400" on "signups", source caption bottom left |

5. Report anything changed from the user's template and why (for example "the number does not keep ticking because the value is fixed").

The delivery gates in 8.7 still apply.
