# Effects library

Companion to [SKILL.md](SKILL.md), section 11. Every effect here runs under the decision policy (1.3), the person check (1.4) and the rules in 11.3, and finishes with 11.4. **What is verified:** nothing in this file has been render-tested yet; these are design specs. Build each effect with the official skills (`/remotion-markup` for animation, video, 3D, masks and transitions; `/remotion-docs` when an API is uncertain), and inspect the first render of every new effect at entry, peak and exit.

How to read an entry:

| Field | Meaning |
|---|---|
| Category, Weight, Default | Weight feeds the density budget (11.3): **Hero** owns the frame and the moment (and is also heavy), **Heavy** is a slam, flash, full-frame or 3D move, **Light** is local motion that leaves the shot readable. Default duration includes entry and exit. |
| Needs | Inputs that must exist before the effect can be applied directly (1.3) |
| Best for / Not when | Where it earns its place, and where to push back or pick another effect |
| If missing | The adaptation to offer when an input is missing, or when there is no presenter (1.4) |
| Swap | Parameters the user can change; defaults come from the project's tokens (11.3) |
| Build | How to construct it; implementation details come from the official skills |

**Presenter layering.** Every presenter effect is three layers: background (the original clip) → effect → person (the cached matte cut-out) on top (1.4). An element that passes both behind and in front of the head (orbits, ribbons) is split in two: the far half renders below the person layer, the near half above it. Find the head from the matte (top of the person's bounding box, smoothed over a few frames so the orbit centre does not jitter). Keep the shot's `<Video>`, the matte layer and the effect inside the shot's own `Sequence` (or `TransitionSeries.Sequence`) so a trim or speed change moves all three together, and place anything tied to a spoken word at the word's source time minus the shot's `trimBefore` (11.3).

**Built-in effects (Remotion 4.0.538).** `@remotion/effects` ships about 80 GPU effects (blur, glow, vignette, exposure, color correction, distortion and more). They go on the `effects` prop of `<Video>` from `@remotion/media`, `<Img>`, `<CanvasImage>`, `<AnimatedImage>`, `<Solid>`, `<HtmlInCanvas>` and the `@remotion/shapes` shapes. Plain HTML, `Interactive.*` wrappers, `AbsoluteFill` and `Sequence` do not take `effects`: wrap them in `<HtmlInCanvas>` first. When an element supports `effects` and a built-in fits, prefer it over a CSS approximation (the official rule). Read the `/remotion-markup` effects reference for imports, parameters and the WebGL render setting before using one; the Build notes below name the built-ins that fit, and section 3 still decides whether an effect belongs at all.

---

## Presenter effects

### /logo-orbit
Tool logos circle the speaker's head, passing behind it on the far side.
- **Category:** Presenter · **Weight:** Hero · **Default:** 3.0 s
- **Needs:** person matte; 3 to 8 logo files (SVG, or PNG with alpha) that the user has the right to use; a slot, ideally the spoken word that names the tools.
- **Best for:** "the tools I use" or stack-reveal moments while the speaker names them.
- **Not when:** the logos are trademarks the user cannot clear (push back, 1.3); more than about 8 logos; the speaker moves fast or leaves the frame.
- **If missing:** no logo files → offer name chips set in the project's type (never download logos from the web); no presenter → orbit the title or product mark centred on screen, with no occlusion.
- **Swap:** logo set and order, orbit radius, ring squash (default 0.3, reads as a tilted ring), revolutions (default 1), direction, logo size, entry (pop vs. spiral in).
- **Build:** logos on an ellipse around the head centre; far half under the person layer, near half above; scale the far half to about 0.85 and soften it slightly for depth. Logos are never recoloured (1.2).

### /claude-beside-me
A Claude window swings out from behind the speaker and settles beside them.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 2.5 s
- **Needs:** person matte; a screenshot or screen recording of the user's own Claude window; free screen space on one side of the speaker.
- **Best for:** "I asked Claude..." moments, showing the real prompt or answer while the speaker talks about it.
- **Not when:** no free side (the window would cover the face); the screenshot shows private data (crop it or ask); a calm explainer where a swing distracts (use /screen-in-screen).
- **If missing:** no screenshot → ask for one, and never redraw or imitate Claude's interface; no presenter → /screen-in-screen or /liquid-glass holding the same screenshot.
- **Swap:** side, swing angle, final size (default about 40% of frame width), corner radius and shadow from the tokens, hold length.
- **Build:** the window starts hidden behind the person layer and rotates out around a hinge on its inner edge (3D rotation in one `transform` string, perspective 1800-2600px), settling with `springHeavy`. Text in the window must meet the 4.3 legibility minimums at its final size; crop to the relevant message if it does not.

### /typewriter-cut
A typed page flicks in behind the speaker; one word stays locked in place while the page moves on.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 2.0 s
- **Needs:** person matte; the text (a sentence to a short paragraph, at most about 40 visible words); the word to lock, which must appear in the text.
- **Best for:** quoting a script, prompt or note, with the lock landing on the spoken word.
- **Not when:** the text is long; the locked word is not spoken near the slot; another text effect is on screen.
- **If missing:** no lock word → offer the 2 or 3 strongest words from the text as options; no presenter → the page flicks in behind the title, or centred.
- **Swap:** text, lock word, lock colour (the accent), face (the project's mono or text face), typing speed (11-16 characters/s, 6.3), flick direction.
- **Build:** characters appear with the deterministic typing spec in 6.3; the page sits behind the person layer; the locked word is a separate element that holds its position and scale while the page flicks out.

### /reel-fan
The user's own reels fan out in an arc around the speaker's head.
- **Category:** Presenter · **Weight:** Hero · **Default:** 2.5 s
- **Needs:** person matte; 3 to 7 reel thumbnails or clips owned by the user.
- **Best for:** "my work" and portfolio beats; creator intros.
- **Not when:** the reels belong to someone else; fewer than 3 (looks thin) or more than 7 (clutter); right after another fan or orbit.
- **If missing:** clips missing → use stills; fewer than 3 reels → offer /phone-fan; no presenter → /phone-fan.
- **Swap:** count, arc span (default 140 degrees), card size and radius, stills vs. playing clips (muted), card stagger (5-9f, 6.8), exit (collapse vs. fly out).
- **Build:** cards on an arc behind the head with the person layer on top; stagger per 6.8; clips play muted.

### /shutter-strike
Photo prints of the speaker slam in around them like camera flashes.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 1.2 s
- **Needs:** person matte; 2 to 5 photos of the speaker that the user has the right to use.
- **Best for:** a punchy "this is me" or achievement beat on one strong word.
- **Not when:** calm or educational tone; photos of other people (push back, 1.3); within 3 s of another heavy effect.
- **If missing:** no photos → offer stills taken from the user's own clip, or skip; no presenter → the prints slam onto the centre of the frame (no occlusion needed).
- **Swap:** number of prints, print border style, rotation spread (default ±8 degrees), pulse strength, slam rhythm.
- **Build:** each print lands hard with a non-bouncing preset; the "flash" is a soft brightness pulse made by animating `brightness()` or `exposure()` on the shot's `<Video>`, never a white frame. **Flash safety (11.3) applies:** at most 3 flashes per second, no full-frame pure white.

### /before-after
A wipe turns the speaker's real room into a clean white studio behind them.
- **Category:** Presenter · **Weight:** Hero · **Default:** 1.5 s wipe, then the hold the story needs
- **Needs:** person matte (background replacement); a static or near-static shot; a matte that holds up at the hair and edges (check at full scale).
- **Best for:** transformation stories (messy to clear, before and after), the Chaos → Order pattern of 5.1.
- **Not when:** the room is part of the message; a handheld camera (the studio will not follow the motion); the matte fails at the edges.
- **If missing:** no presenter → offer a plain mask wipe between two states of the shot, or /pull-back-reveal.
- **Swap:** wipe direction and shape (line, or a circle growing from the speaker), studio colours (`bg`/`bgSunken` tokens), floor shadow under the speaker, hold length, revert at the end (yes/no).
- **Build:** studio = token background with a soft floor shadow and a barely visible vignette; wipe the original-room layer away with a `clipPath` mask (`maskReveal` pattern); the person stays on top throughout. Match the speaker to the white studio with `colorCorrection()` (white balance, exposure) on their layer; footage shot on a green screen can use `colorKey()` instead of the matte.

### /all-at-once
/logo-orbit and /reel-fan land together on one spoken word.
- **Category:** Presenter · **Weight:** Hero · **Default:** 3.5 s · **At most once per video.**
- **Needs:** everything /logo-orbit and /reel-fan need, plus the trigger word and its timing.
- **Best for:** the single climax of a creator intro.
- **Not when:** already used in this video; either input set is incomplete; the frame cannot hold both (reels need the outer arc, logos the inner ring).
- **If missing:** one effect's inputs missing → offer the other alone; no word timing → get word timings (11.3) or offer 2 or 3 candidate words.
- **Swap:** trigger word, which lands first (default: both on the word; or offset by 2-4f), orbit radius vs. fan radius.
- **Build:** reel fan on the outer arc behind the head, logo orbit on the inner ring; both anchored to the trigger word's first frame; they exit together.

### /title-orbit
The title circles the speaker's head as a ring of text.
- **Category:** Presenter · **Weight:** Hero · **Default:** 3.0 s
- **Needs:** person matte; title text (about 2 to 6 words).
- **Best for:** an opening title over a presenter.
- **Not when:** the title is long (curved text reads slowly); it must be read instantly; another title effect is on screen.
- **If missing:** no presenter → orbit the title around the centre of the screen or around the product mark.
- **Swap:** text, ring radius and squash, rotation speed (keep each word readable at the front for at least 1.2 s, 6.4), face and weight (the display face), direction, separator glyph.
- **Build:** text on a circular SVG path; far half under the person layer and dimmed slightly, near half above.

### /clone-room
Copies of the speaker step out from behind them into the room.
- **Category:** Presenter · **Weight:** Hero · **Default:** 2.5 s
- **Needs:** person matte; a static camera; free room on both sides of the speaker.
- **Best for:** "doing every job myself", multitasking, team-of-one metaphors.
- **Not when:** a moving camera; big gestures (the clones copy them); a cramped room.
- **If missing:** no presenter → say it needs a person on camera and suggest /grid-dive.
- **Swap:** number of clones (default 2 to 4), spacing, time offset per clone (default 6f echo), clone treatment (slightly smaller and desaturated), step direction.
- **Build:** extra copies of the person layer with time offsets, placed behind the original at smaller scale; they step out with a stagger; the original stays on top. Desaturate the clones with `saturation()` on their `<Video>` layers.

### /frame-break
The speaker sits inside a photo frame, then their head breaks out of it.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 2.0 s
- **Needs:** person matte; head room above the frame's top edge.
- **Best for:** "outside the box", breaking a limit, a lively intro.
- **Not when:** the head moves outside the frame area; no head room; a formal tone.
- **If missing:** no presenter → say it needs a person on camera and suggest /infinite-zoom.
- **Swap:** frame style (print, polaroid, or a card from the tokens), frame size, tilt (at most 8 degrees, section 3), break moment.
- **Build:** the frame clips the shot; from the break moment the person layer also shows outside the frame, revealed by a growing mask above the frame edge.

### /head-pop-out
The speaker's head springs up out of a panel.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 1.5 s
- **Needs:** person matte; a panel (card or UI) in front of the lower body.
- **Best for:** a quick emphatic or comic beat; reactions.
- **Not when:** a serious tone; it has already been used (it works once).
- **If missing:** no presenter → suggest /liquid-glass revealing a panel.
- **Swap:** panel style (tokens), pop height, spring (this may be the scene's one `springElastic` moment, 6.7).
- **Build:** the panel covers the lower body; the person layer is masked to the region above the panel edge and springs upward.

### /vertigo
A dolly zoom: the room stretches while the speaker stays the same size.
- **Category:** Presenter · **Weight:** Hero · **Default:** 2.0 s
- **Needs:** person matte (or a depth map) and a static, locked-off shot; a background with visible depth.
- **Best for:** realisation or tension beats just before the payoff.
- **Not when:** handheld or moving camera; a flat background such as a plain wall; a calm explainer.
- **If missing:** no matte or depth → do not fake it; offer a slow push-in (6.5); no presenter but a static shot with depth and a clear central object → apply it to the object.
- **Swap:** direction (room stretches away vs. collapses in), strength (default background scale 1.0 to 1.35), duration, easing (the `camera` token).
- **Build:** needs a clean plate, because the scaled background would otherwise show a second, larger speaker around the cut-out: fill the speaker's area in the background layer (from a frame without them, or by stretching the surrounding pixels). Scale the plate around the head centre with one `transform` string (6.5) while the person layer stays at constant scale. A subtle `zoomBlur()` on the plate (never on the person) can sell the stretch.

### /spotlight
One theatre light sweeps in and finds the speaker's face.
- **Category:** Presenter · **Weight:** Light · **Default:** 2.0 s
- **Needs:** the face position across the effect (face detection, or one manual keyframe when the speaker is still).
- **Best for:** introducing the speaker; a "here's the thing" beat.
- **Not when:** the face moves fast; a light-mode film where dimming would break 4.1 (keep the dim moderate).
- **If missing:** no face position → run face detection on the effect's frames, or ask for one keyframe; no presenter → aim the light at a detail, or use /magnifying-lens.
- **Swap:** light warmth, cone size and softness, surround dim (default 35%, never black), sweep path.
- **Build:** dim the surround with `exposure()` (or `colorCorrection()`) on the shot's `<Video>` through a soft radial mask, or use `vignette()` if its centre can follow the face (check its parameters); the face stays at full exposure and the surround never goes black. It needs the face position, not the matte.

### /depth-ui
App windows float around the speaker at different depths.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 3.0 s
- **Needs:** person matte; 2 to 5 screenshots of the user's own product UI.
- **Best for:** product demos while talking; "here's what I built".
- **Not when:** a window would cover the face; screenshots unreadable at the size they need (4.3); third-party brand UI (push back, 1.3).
- **If missing:** no screenshots → ask, and never invent UI (1.1); no presenter → float the windows around the centre of the screen.
- **Swap:** number of windows, depth spread (parallax 0.3-0.6x, 6.5), drift amplitude (tertiary motion, 6.1), which window comes forward to be read.
- **Build:** windows placed behind and in front of the person layer by depth; one window may come forward to hero size (4.3) for reading. The screenshots are `<Img>` elements, so far windows can soften with `blur()` (2-5px, section 3) and every window can carry `dropShadow()`.

### /ribbon-wrap
A ribbon carrying the user's words wraps around the speaker.
- **Category:** Presenter · **Weight:** Heavy · **Default:** 3.0 s
- **Needs:** person matte; a short phrase of at most about 8 words.
- **Best for:** a tagline, promise or channel slogan.
- **Not when:** the phrase is longer than about 8 words; the text must be read precisely (wrapped text reads slowly).
- **If missing:** phrase too long → offer 2 or 3 tightened versions, or /words-kinetic; no presenter → wrap the ribbon around the title or product.
- **Swap:** phrase, ribbon colour (accent or a neutral from the tokens), width, turns (default 1.5), speed.
- **Build:** text along a helical path; far segments under the person layer, near segments above.

### /tile-tunnel
A tunnel of tiles opens behind the speaker. It also works as a transition.
- **Category:** Presenter or transition · **Weight:** Heavy · **Default:** 2.0 s (1.0 s as a transition)
- **Needs:** person matte when used behind a presenter; tile content (the project's own stills or clips, or plain token-coloured tiles).
- **Best for:** going deeper into a topic; chapter transitions.
- **Not when:** a busy foreground; the same transition twice in a row (6.6).
- **If missing:** no presenter → use it as a transition between shots.
- **Swap:** tile content (solid tokens vs. images), tunnel depth, travel speed, direction (in or out).
- **Build:** tiles on the inner walls of a box in CSS 3D (one `transform` string with perspective), moving toward the camera; the person layer stays on top when used behind a presenter.

---

## Data effects

Real numbers only. Every data effect shows its source as a small on-screen caption and marks partial data on screen (11.3). If the user has no real figures, push back (1.3): ask for the figure and its source, or offer a data-free alternative such as a /words-kinetic line that makes the claim without a number.

### /growth-chart
3D bars rise to the user's real numbers.
- **Category:** Data · **Weight:** Hero · **Default:** 3.0 s, plus a reading hold
- **Needs:** labels, values, unit and source, all supplied by the user; which periods are partial.
- **Best for:** a growth or comparison payoff with 3 to 7 bars.
- **Not when:** no real numbers; a single value (use /number-roll); more than about 8 categories (use the flat bar chart of 6.9).
- **If missing:** no numbers or no source → push back and ask; never show the chart without a source.
- **Swap:** bar colours (a ramp built from the project's accent), bar order, 3D depth (tilt at most 8 degrees, section 3), number formatting, stagger (3f, 6.9).
- **Honesty:** label each value directly on its bar; no back-wall grid (in 3D it reads higher than the bar tops and misstates the values); bars start at zero; mark partial periods on screen (for example a hatched bar labelled "partial"); source caption.
- **Build:** bars grow with `outQuart` and a 3f stagger, value labels count up in sync (6.9).

### /line-draw
A chart that draws itself: gradient line, glowing head, filled area and an end chip.
- **Category:** Data · **Weight:** Heavy · **Default:** 3.0 s
- **Needs:** a real series (at least about 5 points), unit and source.
- **Best for:** a trend over time.
- **Not when:** fewer than about 5 points; no real data.
- **If missing:** push back as above; with only 1 or 2 values offer /number-roll.
- **Swap:** line gradient (built from the project's palette), glow strength, area opacity, end-chip text (final value and unit), axis labels, draw duration (30-45f, 6.9).
- **Honesty:** label the axis range clearly; draw the last segment dashed and labelled when the final period is partial; source caption. The glow is a focus indicator on the line's current point in the accent colour, not ambient decoration (section 3).
- **Build:** the 6.9 line-chart spec: axes fade first, the line draws with `evolvePath` from `@remotion/paths`, the area follows 10f behind, the head dot rides the path's current end (a `<Circle>` from `@remotion/shapes` with `glow()`), the end chip pops when the draw completes.

### /number-roll
A number rolls up like an odometer, with motion blur, and lands.
- **Category:** Data · **Weight:** Light · **Default:** 2.5 s
- **Needs:** the real figure, its unit and source; ideally the spoken word to land on.
- **Best for:** one headline metric.
- **Not when:** no real number; several numbers at once (use a chart).
- **If missing:** no source → ask; no word timing → offer 2 or 3 landing words.
- **Swap:** digit face (a tabular mono from the tokens), roll duration, blur strength, landing ease, prefix and suffix, number formatting.
- **Honesty:** the roll stops on the final value. Keep it ticking after landing only when the user confirms the figure is genuinely live (a real rate), and caption it as a rate. Source caption.
- **Build:** one column per digit, each a vertical strip of 0-9 moved with `outQuart`; motion blur only while a column moves fast (see `/remotion-markup` motion blur); `font-variant-numeric: tabular-nums` and real formatting (6.9).

---

## Text effects

### /pixel-title
The title builds itself out of dots.
- **Category:** Text · **Weight:** Heavy · **Default:** 2.5 s
- **Needs:** title text (at most about 4 words).
- **Best for:** opening and chapter titles. With a presenter, place it above the head (needs head room); without one, anywhere.
- **Not when:** the dots could be mistaken for real data, such as a star map or a scatter plot; then use /words-kinetic.
- **If missing:** no head room above the presenter → place it beside them, or offer /title-orbit.
- **Swap:** dot size and spacing, dot colour (ink or accent), assembly (scatter in vs. sweep), the display face it samples.
- **Honesty:** it must read as typography: a regular dot grid, complete letterforms at the end, no twinkling or star-like glow.
- **Build:** rasterise the title onto a grid to get dot positions; each dot travels from a start position chosen with `random(seed)` (deterministic) to its slot, with a stagger. Do not substitute the built-in `dotGrid()`: it is a texture, not letterforms.

### /words-kinetic
Words slam in line by line; the last word lands in a gradient.
- **Category:** Text · **Weight:** Heavy · **Default:** 2.5 s
- **Needs:** 1 to 3 short lines (6-8 words or fewer each, 6.4).
- **Best for:** the claim, the punchline, the hook.
- **Not when:** a calm educational film (use the soft word reveal of 6.4 instead); more than 3 lines.
- **If missing:** copy too long → offer 2 or 3 tightened versions.
- **Swap:** slam strength, line stagger (6-8f, 6.4), the last word's gradient (built from the project's palette), alignment.
- **Build:** `KineticText` from the starter kit, one line at a time, each landing hard from about 1.15 to 1 scale on a non-bouncing preset (if the project says "damped, not bouncy", no wobble); hold at least 1.2 s after the full reveal (6.4).

---

## Shot and transition effects

These work on any footage and are best placed at cuts. Transitions follow 6.6: never the same type twice in a row.

### /grid-dive
The shot starts as one tile in a wall of video, then the camera dives into it.
- **Category:** Shot · **Weight:** Hero · **Default:** 2.0 s
- **Needs:** 8 or more other clips or stills, the user's own, for the wall.
- **Best for:** "out of all of these, this one"; portfolios; showing volume.
- **Not when:** fewer than 8 other items (an empty or repeating wall reads cheap).
- **If missing:** too few items → offer a smaller wall built from other moments of the same video, or /infinite-zoom.
- **Swap:** grid size (default 4x3), gap, tile radius, target tile, move (pull out then dive, or dive only).
- **Build:** lay the wall out in world space and frame the target tile with `shotFor` on the `CameraRig`, then zoom in with the single `transform` string (6.5).

### /magnifying-lens
A glass disc slides over the shot and magnifies a detail.
- **Category:** Shot · **Weight:** Light · **Default:** 2.0 s
- **Needs:** the detail's position; source resolution that survives the magnification (1.2).
- **Best for:** small UI text, a number, a detail in a product shot.
- **Not when:** the detail moves; the source is too low-resolution for the zoom (1.2).
- **If missing:** no position → offer 2 or 3 candidate details marked on a still.
- **Swap:** lens size, magnification (default 2x), rim (hairline border and soft shadow from the tokens), path.
- **Build:** a circular clip of a scaled copy of the shot, centred on the detail; `fisheye()` or `barrelDistortion()` on the copy gives the glass curvature.

### /portal
A ring of light opens and the camera flies straight through it into the next shot.
- **Category:** Transition · **Weight:** Heavy · **Default:** 1.0 s
- **Needs:** the outgoing and incoming shots.
- **Best for:** chapter changes; "entering" the product.
- **Not when:** within 3 s of another heavy effect; a calm film; right after another fly-through transition (6.6).
- **If missing:** nothing extra is needed.
- **Swap:** ring colour (the accent), ring thickness, where it opens (centre, or on an object), fly-through speed.
- **Build:** draw the ring as a `<Circle>` from `@remotion/shapes` with `glow()` in the accent colour; the incoming shot shows inside the ring; the camera scales through it with one `transform` string; a custom `TransitionPresentation` when built as a scene transition (6.6).

### /infinite-zoom
Frames nested inside frames; the camera pushes through them into the next shot.
- **Category:** Transition · **Weight:** Heavy · **Default:** 1.5 s
- **Needs:** 2 or more shots or stills; the last is the destination.
- **Best for:** "and inside that...", recursive or drill-down stories.
- **Not when:** within 3 s of another heavy effect; after another zoom-through transition (6.6, 6.5 "no endless zooming").
- **If missing:** only one shot → nest frames of the same shot.
- **Swap:** frame count, frame style (tokens), zoom factor per frame, speed.
- **Build:** frames nested at a constant scale factor, one continuous zoom on the camera rig; the final frame lands exactly on the destination shot.

### /cube-spin
The shot turns like a cube face to reveal the next shot.
- **Category:** Transition · **Weight:** Heavy · **Default:** 0.8 s
- **Needs:** the outgoing and incoming shots.
- **Best for:** switching topics or sides; energetic edits.
- **Not when:** calm films; more than once or twice per video.
- **If missing:** nothing extra is needed.
- **Swap:** direction, perspective (1800-2600px, 6.5), easing.
- **Build:** the official cube presentation if `/remotion-markup` lists one, otherwise a custom `TransitionPresentation` rotating two faces in CSS 3D.

### /liquid-glass
A drop of glass lands and expands into a glass pane that holds text or UI.
- **Category:** Shot · **Weight:** Light · **Default:** 1.2 s, then the hold its content needs
- **Needs:** the pane's content (text or UI).
- **Best for:** lower thirds, emphasised captions, UI callouts over footage.
- **Not when:** glass is already on screen (4.1 bans excessive glassmorphism: one pane at a time).
- **If missing:** no content → ask, or skip.
- **Swap:** pane size, blur (2-5px, section 3), tint (the `surface` token, semi-opaque), corner radius (tokens), where the drop lands.
- **Build:** morph from a circle to a rounded rectangle with `panelExpand`; frost what sits behind the pane with `regionBlur()` or `blur()` on the underlying `<Video>` (wrap HTML content in `<HtmlInCanvas>`). The blur is render-costly, so keep it to one pane.

### /screen-in-screen
The shot plays on a laptop screen.
- **Category:** Shot · **Weight:** Light · **Default:** 3.0 s
- **Needs:** nothing extra.
- **Best for:** framing a screen recording; "watch this" moments.
- **Not when:** small text in the footage becomes unreadable on the smaller screen (4.3).
- **If missing:** nothing extra is needed.
- **Swap:** device shape (a generic laptop drawn in code, no brand logos), angle (at most 8 degrees), whether it pushes in to full screen.
- **Build:** a generic laptop in SVG or CSS from the tokens, the clip playing on its screen (`cornerPin()` on the `<Video>` maps it onto an angled screen without a 3D transform); an optional push from device to full frame with the camera rig.

### /phone-fan
Phones fan out like a hand of cards.
- **Category:** Shot · **Weight:** Heavy · **Default:** 2.5 s
- **Needs:** 3 to 5 phone screenshots of the user's own app or content.
- **Best for:** mobile products; several screens at once.
- **Not when:** fewer than 3 screenshots; screenshots of other companies' apps (push back, 1.3).
- **If missing:** fewer screenshots → ask, or fan the ones supplied if there are at least 3.
- **Swap:** count, spread angle (default 40 degrees), phone frame (generic, no device branding), stagger (5-9f, 6.8).
- **Build:** generic phone frames rotating around a shared bottom pivot with a stagger.

### /shatter
The shot cracks like glass and falls away to reveal the next shot.
- **Category:** Transition · **Weight:** Heavy · **Default:** 0.8 s
- **Needs:** the outgoing and incoming shots.
- **Best for:** a hard turn in the story; breaking a status quo.
- **Not when:** calm, educational or premium-brand films; within 3 s of another heavy effect.
- **If missing:** nothing extra is needed.
- **Swap:** shard count, crack origin, fall direction, speed.
- **Build:** shards precomputed with `random(seed)` (deterministic), each a clipped copy of the outgoing frame. **Flash safety (11.3) applies:** no white flash on the crack.

### /pull-back-reveal
The camera pulls back to reveal the shot was playing inside a video editor.
- **Category:** Shot · **Weight:** Hero · **Default:** 2.5 s
- **Needs:** nothing extra. Draw the editor UI generically (viewer, timeline, panels) from the project's tokens; never copy a real editor's brand UI.
- **Best for:** behind-the-scenes or "how I made this" moments.
- **Not when:** it would break the immersion of a story film.
- **If missing:** nothing extra is needed.
- **Swap:** editor layout, pull-back distance, timeline content (thumbnails from this video).
- **Build:** the editor is the world, with the shot playing in its viewer; `CameraRig` starts framed on the viewer with `shotFor` and pulls back (6.5).

### /zoom-through
A Claude chat flies in and the camera zooms through it into the clip.
- **Category:** Transition · **Weight:** Heavy · **Default:** 1.5 s
- **Needs:** a screenshot of the user's own Claude chat, used as supplied.
- **Best for:** prompt-to-result moments ("I asked Claude, here's what came out").
- **Not when:** the chat shows private data (crop it or ask); Claude is not part of the story.
- **If missing:** no screenshot → ask for one; never redraw or imitate Claude's interface.
- **Swap:** zoom target (the reply, or a word in it), entry direction, speed.
- **Build:** the screenshot enters, the camera zooms through the chosen point, and the clip resolves from that point.
