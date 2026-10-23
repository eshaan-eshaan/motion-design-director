# Motion Design Director

A creative-director layer for [Remotion](https://www.remotion.dev) videos, packaged as a Claude Code plugin.

Install it once and you get two things:

- **Motion Design Director** (`motion-director`): the creative-direction skill in this repository.
- **The official Remotion plugin** (`remotion-dev/claude-code-plugin`): installed **automatically** by Claude Code as a declared dependency. You never install or discover it yourself.

Motion Design Director decides *what the video should say, how it should look, and how it should move*. The official Remotion skills know *how Remotion works* and do the implementation.

## What makes it different from ordinary Remotion guidance

Ordinary Remotion guidance tells an agent how to build a video. This skill tells it how to direct one, and refuses to finish until the frames prove it.

- **Project truth first.** It reads your project (copy, UI, tokens, assets) before inventing anything.
- **Real assets first.** Supplied screenshots, logos and product shots are inspected and used as supplied, not replaced with stock or invented UI.
- **A product film, not an animated dashboard.** Features are translated into motion, with one hero moment.
- **Camera choreography and transformational transitions.** A motivated camera, and objects that carry across scenes instead of cutting.
- **Premium light mode by default**, with a motion language and design tokens chosen per brand.
- **Creative Director Review.** Before the final render it asks whether a human studio would make each choice, and flags generic or AI-looking output.
- **Tested technical fixes.** The bundled starter kit was type-checked and sample-rendered, and it records exactly what was and was not verified. A frame-level QA script catches blank and too-dark frames.

## Install

```bash
claude plugin marketplace add eshaan-eshaan/motion-design-director
claude plugin install motion-director@motion-design-director
```

Then restart Claude Code, or run `/reload-plugins` in a session that is already open.

Installing `motion-director` makes Claude Code install and enable the official Remotion plugin too (the install output ends with `(+ 1 dependency: remotion)`). Check with `claude plugin list`: both `motion-director@motion-design-director` and `remotion@motion-design-director` should show `enabled`.

**One-command alternative.** These scripts run the same two commands, check that Claude Code is installed, verify the result, and change nothing else:

```powershell
# Windows PowerShell
.\scripts\install.ps1
```

```bash
# macOS / Linux
bash scripts/install.sh
```

Both accept a source other than GitHub (`-Source <path>` / `--source <path>`), a scope, and an optional bare-command switch (see [Commands](#commands)). They never touch your git or SSH configuration.

### How the automatic dependency works

- `.claude-plugin/marketplace.json` lists two plugins: `motion-director` (from this repo) and `remotion`, whose source is the official GitHub repository `remotion-dev/claude-code-plugin`.
- `plugins/motion-director/.claude-plugin/plugin.json` declares `"dependencies": ["remotion"]`. A bare name resolves inside the same marketplace, so Claude Code finds the `remotion` entry above.
- Nothing from the Remotion plugin is copied into this repository. It is fetched from its own repository at install time, and it is not pinned, so you get the upstream default branch and its updates.

## Commands

| Command | What it does |
|---|---|
| `/motion-director:motion-design <brief>` | The skill. Plugin skills are always namespaced with the plugin name, so this is the real command. |
| `/remotion:remotion-best-practices` and the other `/remotion:*` skills | The official Remotion skills. The director skill loads them itself when it reaches implementation. |

**Optional bare `/motion-design`.** Claude Code does not offer an un-namespaced command from a plugin. The supported workaround is a personal skill: `install.ps1 -BareCommand` / `install.sh --bare-command` copies the skill to `~/.claude/skills/motion-design` (or `$CLAUDE_CONFIG_DIR/skills`), and refuses to overwrite an existing folder. Trade-offs: that copy does not update with the plugin, and the skill is then listed twice. Delete the folder to undo it.

## Effects

The skill also adds named effects to new or existing videos, including talking-head footage. Name them in your brief:

```text
/motion-director:motion-design add /number-roll for 12,400 signups (source: Stripe, Oct 2026), landing on "signups"
```

| Category | Effects |
|---|---|
| Presenter (need a person on camera) | /logo-orbit, /claude-beside-me, /typewriter-cut, /reel-fan, /shutter-strike, /before-after, /all-at-once, /title-orbit, /clone-room, /frame-break, /head-pop-out, /vertigo, /spotlight, /depth-ui, /ribbon-wrap, /tile-tunnel |
| Data (need your real numbers and a source) | /growth-chart, /line-draw, /number-roll |
| Text | /pixel-title, /words-kinetic |
| Shot and transition | /grid-dive, /magnifying-lens, /portal, /infinite-zoom, /cube-spin, /liquid-glass, /screen-in-screen, /phone-fan, /shatter, /pull-back-reveal, /zoom-through |

These are effect names inside the skill, not separate Claude Code commands. For each request the skill applies the effect directly when everything it needs is there, offers 2 or 3 options when there is a real choice, or pushes back. It pushes back, for example, on a chart with no real numbers, a logo you may not have rights to, or too many effects close together. For footage it first checks whether a person is on camera, and builds a person matte by itself when presenter effects need one. Specs for every effect are in [`effects.md`](plugins/motion-director/skills/motion-design/effects.md).

## Prerequisites

- Claude Code with plugin support (tested with 2.1.212 and 2.1.309; update Claude Code if `claude plugin` is not recognised).
- Node.js and Git. This plugin does **not** embed Remotion's rendering engine; Remotion is installed per project with npm. See Remotion's own docs for supported Node versions, and the [license notes](#license-and-third-party-notices) below, because Remotion has its own license.
- A Remotion project. If you don't have one, the skill creates one for you (`npx create-video@latest`, then `npm i`).
- For the automated frame check, `npm i -D pngjs` in the video project.
- Network access on first install, because plugins are cloned from GitHub.

## Make your first video

1. Open a terminal in an existing Remotion project, or in a new empty folder, and start `claude`.
2. Run the skill with a brief:

   ```text
   /motion-director:motion-design 15-second launch video for my AI calendar app, 16:9
   ```

3. The skill reads your project and assets, writes a short creative brief, story and storyboard (asking one or two questions only if something is truly ambiguous), sets up the project if needed, and opens the **Remotion Studio** preview (`npx remotion studio`). Open the URL it prints and confirm the composition plays.
4. **Inspect frames.** It renders representative stills to `out/qa/` (`npx remotion render <CompId> out/qa --frames=0,6,45,90 --image-format=png`) and looks at them. To run the automated gate yourself: `npm i -D pngjs`, copy `scripts/qa-frames.cjs` into your project (the plugin ships it at `skills/motion-design/scripts/qa-frames.cjs`), then `node scripts/qa-frames.cjs out/qa`.
5. **Iterate.** Ask for changes in plain language. Edit tokens, cues and scene durations as the skill's final report describes.
6. **Render the final MP4:** `npx remotion render <CompId> out/<name>.mp4`. Check it with `npx remotion ffprobe out/<name>.mp4`.

Invoking the skill to make a video counts as consent for QA stills and one final MP4. Say "preview only" or "do not render" and it will stop at the Studio preview.

## Update

```bash
claude plugin marketplace update motion-design-director
claude plugin update motion-director@motion-design-director
claude plugin update remotion@motion-design-director
```

Then run `/reload-plugins` or restart Claude Code. A new version of `motion-director` reaches users when `version` in `plugin.json` is bumped.

## Uninstall

```bash
claude plugin uninstall motion-director@motion-design-director
claude plugin prune -y
```

`prune` removes the Remotion copy that was installed automatically, if nothing else needs it.

## Troubleshooting

**`motion-director` shows `failed to load` with `Dependency "remotion@motion-design-director" is not installed`.** Claude Code could not clone the official Remotion repository. On older Claude Code versions (seen on 2.1.212) a machine that has never connected to github.com over SSH fails with `SSH host key is not in your known_hosts`. Newer versions (2.1.309) detect that SSH is not set up and fall back to HTTPS on their own, so updating Claude Code also fixes it. Otherwise, clone over HTTPS, then install the dependency:

```bash
# macOS / Linux / Git Bash
export CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1
claude plugin install remotion@motion-design-director
```

```powershell
# Windows PowerShell
$env:CLAUDE_CODE_PLUGIN_PREFER_HTTPS = '1'
claude plugin install remotion@motion-design-director
```

The install scripts set this variable for their own process automatically.

**Two copies of the Remotion plugin are installed.** You already had the official plugin installed on its own (`remotion@remotion`), so the dependency added a second copy (`remotion@motion-design-director`). It is harmless: Claude Code 2.1.309 de-duplicates the skills, while 2.1.212 lists every Remotion skill twice. To keep one copy, run `claude plugin uninstall remotion@remotion`. The copy installed by this plugin is the same official source.

**Anything else.** `claude plugin list` shows the load error for each plugin, and `/plugin` has an **Errors** tab.

## License and third-party notices

The original work in this repository is released under the [MIT License](LICENSE): the skill (`SKILL.md`), the effects library (`effects.md`), the starter kit (`starter-kit.md`), `qa-frames.cjs`, the install scripts and the manifests.

The MIT License does **not** cover anything this repository only points to:

- **The official Remotion plugin** (`remotion-dev/claude-code-plugin`) is fetched from its own repository at install time and is not redistributed here. Its terms are set by its owners.
- **Remotion itself** (the `remotion` npm packages you install in a video project) uses the [Remotion License](https://github.com/remotion-dev/remotion/blob/main/LICENSE.md), which is not MIT. At the time of writing it is free for individuals, non-profits and for-profit organizations of up to 3 employees, and a Company License is required otherwise. Read it before using Remotion commercially.
- **Packages and fonts** that the skill tells you to install in your own project (for example `pngjs`, and Inter and JetBrains Mono through `@remotion/google-fonts`) come from their own sources under their own licenses. None are bundled here.

## Repository layout

```text
LICENSE                                    MIT, covers the original work listed above
.claude-plugin/marketplace.json            marketplace: motion-design-director
plugins/motion-director/
  .claude-plugin/plugin.json               plugin manifest, declares the dependency
  skills/motion-design/
    SKILL.md                               the creative-direction skill
    effects.md                             specs for the named effects (/logo-orbit, /number-roll, ...)
    starter-kit.md                         type-checked starter code and its verification notes
    scripts/qa-frames.cjs                  frame QA gate (same script as the one in starter-kit.md)
scripts/install.ps1, scripts/install.sh    optional convenience installers
```

## For maintainers

Validate before every release:

```bash
claude plugin validate . --strict
claude plugin validate ./plugins/motion-director --strict
```

Test a local checkout without publishing, in a throwaway config directory so your own setup is untouched:

```bash
export CLAUDE_CONFIG_DIR=/tmp/mdd-test
claude plugin marketplace add .
claude plugin install motion-director@motion-design-director
claude plugin list
```
