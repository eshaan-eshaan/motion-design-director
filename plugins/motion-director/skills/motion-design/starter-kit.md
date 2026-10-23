# Motion-design starter kit

Companion to [SKILL.md](SKILL.md). **What was actually verified** (`remotion@4.0.532`, TypeScript 5.9, React 18 types):
- All nine `// src/...` files **type-check** under `tsc --noEmit` with `strict` and `noUnusedLocals`.
- A test composition (1920x1080, 30fps) using the kit was **rendered at frames 12, 36, 76, 110, 149 and inspected**: Inter loads; descenders survive in `KineticText` (word and character modes); `Cursor` tip and click ripple align on the target; `staggerReveal`, `popIn`, `springIn`, `maskReveal` and `panelExpand` render correctly; `CameraRig` + `shotFor` centers the target exactly (pixel check), including with tilt (4 and -6 degrees) at about 2.3-3.2x zoom. That render exposed a bug (blank frames from the `translate`/`scale` shorthands at high zoom), which is fixed in the camera block below.
- `scripts/qa-frames.cjs` was run against good frames and against the broken ones (it flags the blank frames).
- **Not verified:** ESLint (`@remotion/eslint-config`), unit tests of the pure helpers, visual renders of `slideLeft`, `slideRight`, `scaleFade`, `springOut`, `cardReorder`, `cameraPush`, `cameraPull`, a full MP4 render, and 9:16 or 1:1 compositions.

Each block that begins with `// src/...` is a real file: copy it into the project at that path and adapt `design/tokens.ts` to the brand. Components use plain elements for portability; wrap hero elements in `Interactive.*` (see `/remotion-interactivity`) where Studio editing matters. Place `CameraRig` above scene `Sequence`s so it reads the global frame.

```ts
// src/design/tokens.ts
import {loadFont as loadInter} from '@remotion/google-fonts/Inter';
import {loadFont as loadMono} from '@remotion/google-fonts/JetBrainsMono';

// Placeholder faces: choose a display/text/mono pairing per brand (section 4.2).
const inter = loadInter('normal', {weights: ['400', '500', '600', '700'], subsets: ['latin']});
const mono = loadMono('normal', {weights: ['500'], subsets: ['latin']});

export const font = {display: inter.fontFamily, text: inter.fontFamily, mono: mono.fontFamily} as const;

export const color = {
  bg: '#FAFAF7',
  bgSunken: '#F2F1EC',
  surface: '#FFFFFF',
  border: 'rgba(17, 20, 24, 0.08)',
  borderStrong: 'rgba(17, 20, 24, 0.16)',
  ink: '#111418',
  inkSoft: '#4B5260',
  inkFaint: '#8A909C',
  accent: '#2F5BFF', // ONE accent per brand: replace from the brand system
  accentSoft: 'rgba(47, 91, 255, 0.10)',
  success: '#1F9D6B',
  successSoft: 'rgba(31, 157, 107, 0.12)',
  warning: '#C97A06',
  warningSoft: 'rgba(201, 122, 6, 0.12)',
  danger: '#D3453D',
  dangerSoft: 'rgba(211, 69, 61, 0.10)',
} as const;

export const radius = {sm: 8, md: 14, lg: 22, xl: 32, pill: 999} as const;

export const shadow = {
  rest: '0 1px 2px rgba(16, 24, 40, 0.06), 0 4px 12px -4px rgba(16, 24, 40, 0.08)',
  raised: '0 2px 4px rgba(16, 24, 40, 0.05), 0 16px 40px -12px rgba(16, 24, 40, 0.16)',
  lifted: '0 4px 8px rgba(16, 24, 40, 0.06), 0 32px 80px -24px rgba(16, 24, 40, 0.28)',
} as const;

export const space = {1: 8, 2: 16, 3: 24, 4: 32, 5: 48, 6: 64, 7: 96, 8: 128} as const;
```

```ts
// src/motion/springs.ts
import {spring} from 'remotion';

export type SpringPreset = {mass: number; damping: number; stiffness: number; overshootClamping?: boolean};

// Measured with remotion@4.0.532 at 30fps. Pace = stiffness/mass; only damping below critical bounces.
export const springFast: SpringPreset = {mass: 0.8, damping: 26, stiffness: 320}; // 0.37s, ~1% overshoot
export const springSoft: SpringPreset = {mass: 1, damping: 26, stiffness: 120}; // 0.70s, none (default)
export const springHeavy: SpringPreset = {mass: 2.5, damping: 36, stiffness: 120}; // 1.1s, none
export const springSubtle: SpringPreset = {mass: 1, damping: 40, stiffness: 300}; // 0.43s, none
export const springElastic: SpringPreset = {mass: 1, damping: 14, stiffness: 190}; // 0.67s, ~16% overshoot (rare)

export const springAt = (args: {
  frame: number;
  fps: number;
  preset?: SpringPreset;
  delay?: number;
  durationInFrames?: number;
}) =>
  spring({
    frame: args.frame,
    fps: args.fps,
    config: args.preset ?? springSoft,
    delay: args.delay ?? 0,
    durationInFrames: args.durationInFrames,
  });
```

```ts
// src/motion/easings.ts
import {Easing} from 'remotion';

export const ease = {
  outExpo: Easing.bezier(0.16, 1, 0.3, 1), // entrances
  outQuart: Easing.bezier(0.25, 1, 0.5, 1), // data, reorders
  inOut: Easing.bezier(0.65, 0, 0.35, 1), // cursor and segment moves
  in: Easing.bezier(0.4, 0, 1, 1), // exits accelerate away
  camera: Easing.bezier(0.45, 0, 0.15, 1), // long-tail camera moves
} as const;
```

```ts
// src/motion/timeline.ts
export const FPS = 30;
export const sec = (seconds: number, fps: number = FPS) => Math.round(seconds * fps);

export type Cue = {
  frame: number;
  kind: 'click' | 'impact' | 'transition' | 'metric-complete' | 'workflow-activate' | 'feature-reveal' | 'cta';
  note: string;
};

// Sync points for later audio/SFX. Keep sorted and in step with the storyboard's cue column.
export const CUES: Cue[] = [
  {frame: sec(0.3), kind: 'impact', note: 'Headline lands'},
  {frame: sec(4.4), kind: 'click', note: 'Command bar opens'},
  {frame: sec(10), kind: 'metric-complete', note: 'Conflicts reach zero'},
  {frame: sec(13.8), kind: 'cta', note: 'CTA button settles'},
];
```

```ts
// src/motion/useLayout.ts
import {useVideoConfig} from 'remotion';

export type Orientation = 'landscape' | 'portrait' | 'square';

export const useLayout = () => {
  const {width, height} = useVideoConfig();
  const orientation: Orientation = width > height ? 'landscape' : width < height ? 'portrait' : 'square';
  const k = width / 1080; // official minimums are defined at 1080 width
  const pick = <T>(v: {landscape: T; portrait: T; square?: T}): T =>
    orientation === 'portrait' ? v.portrait : orientation === 'square' ? (v.square ?? v.portrait) : v.landscape;

  return {
    width,
    height,
    orientation,
    safe: {x: Math.round(80 * k), y: Math.round(100 * k)},
    minType: {headline: Math.round(84 * k), support: Math.round(44 * k)},
    social: orientation === 'portrait' ? {top: Math.round(height * 0.13), bottom: Math.round(height * 0.18)} : {top: 0, bottom: 0},
    pick,
  };
};
```

```ts
// src/motion/presets.ts
import type {CSSProperties} from 'react';
import {interpolate, spring} from 'remotion';
import {ease} from './easings';
import {springSoft, springFast, springSubtle, type SpringPreset} from './springs';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
type Easer = (t: number) => number;
type Beat = {frame: number; start?: number; duration?: number};
type SpringBeat = {frame: number; fps: number; start?: number; preset?: SpringPreset};

export type Rect = {x: number; y: number; w: number; h: number; r?: number};

export const progress = (frame: number, start: number, duration: number, easing: Easer = ease.outExpo) =>
  interpolate(frame, [start, start + duration], [0, 1], {...clamp, easing});

export const fadeUp = ({frame, start = 0, duration = 18, distance = 36}: Beat & {distance?: number}): CSSProperties => {
  const p = progress(frame, start, duration);
  return {opacity: p, translate: `0px ${(1 - p) * distance}px`};
};

export const fadeScale = ({frame, start = 0, duration = 18, from = 0.94}: Beat & {from?: number}): CSSProperties => ({
  opacity: progress(frame, start, duration),
  scale: interpolate(frame, [start, start + duration], [from, 1], {
    ...clamp,
    easing: ease.outExpo,
    output: 'perceptual-scale',
  }),
});

// Travels leftward (enters from the right).
export const slideLeft = ({frame, start = 0, duration = 20, distance = 120}: Beat & {distance?: number}): CSSProperties => {
  const p = progress(frame, start, duration);
  return {opacity: p, translate: `${(1 - p) * distance}px 0px`};
};

// Travels rightward (enters from the left).
export const slideRight = ({frame, start = 0, duration = 20, distance = 120}: Beat & {distance?: number}): CSSProperties => {
  const p = progress(frame, start, duration);
  return {opacity: p, translate: `${-(1 - p) * distance}px 0px`};
};

export const popIn = ({frame, fps, start = 0, preset = springSubtle, from = 0.86}: SpringBeat & {from?: number}): CSSProperties => {
  const s = spring({frame, fps, delay: start, config: preset});
  return {opacity: Math.min(1, s * 2), scale: from + (1 - from) * s};
};

export const springIn = ({frame, fps, start = 0, preset = springSoft, x = 0, y = 48}: SpringBeat & {x?: number; y?: number}): CSSProperties => {
  const s = spring({frame, fps, delay: start, config: preset});
  return {opacity: Math.min(1, s * 1.6), translate: `${(1 - s) * x}px ${(1 - s) * y}px`};
};

// Exits are faster than entrances: default preset is springFast.
export const springOut = ({frame, fps, start = 0, preset = springFast, x = 0, y = -24}: SpringBeat & {x?: number; y?: number}): CSSProperties => {
  const s = spring({frame, fps, delay: start, config: preset});
  return {opacity: Math.max(0, 1 - s * 1.2), translate: `${s * x}px ${s * y}px`};
};

export const scaleFade = ({frame, start = 0, duration = 12, to = 0.96}: Beat & {to?: number}): CSSProperties => {
  const p = progress(frame, start, duration, ease.in);
  return {opacity: 1 - p, scale: 1 - (1 - to) * p};
};

export const maskReveal = ({
  frame,
  start = 0,
  duration = 20,
  from = 'left',
}: Beat & {from?: 'left' | 'right' | 'top' | 'bottom'}): CSSProperties => {
  const rest = (1 - progress(frame, start, duration, ease.outQuart)) * 100;
  const inset = {
    left: `0% ${rest}% 0% 0%`,
    right: `0% 0% 0% ${rest}%`,
    top: `0% 0% ${rest}% 0%`,
    bottom: `${rest}% 0% 0% 0%`,
  }[from];
  return {clipPath: `inset(${inset})`};
};

// Indexed entrance with a capped delay so long lists never run past the scene.
export const staggerReveal = ({
  index,
  step = 5,
  maxDelay = 36,
  start = 0,
  ...rest
}: Beat & {index: number; step?: number; maxDelay?: number; distance?: number}): CSSProperties =>
  fadeUp({...rest, start: start + Math.min(index * step, maxDelay)});

// Shared-element morph: interpolate between two authored rects (FLIP, deterministic).
export const panelExpand = ({
  frame,
  start = 0,
  duration = 24,
  from,
  to,
  easing = ease.outExpo,
}: Beat & {from: Rect; to: Rect; easing?: Easer}): CSSProperties => {
  const p = progress(frame, start, duration, easing);
  const mix = (a: number, b: number) => a + (b - a) * p;
  return {
    position: 'absolute',
    left: mix(from.x, to.x),
    top: mix(from.y, to.y),
    width: mix(from.w, to.w),
    height: mix(from.h, to.h),
    borderRadius: mix(from.r ?? 0, to.r ?? 0),
  };
};

// Slot-to-slot move with a mid-move lift.
export const cardReorder = ({
  frame,
  start = 0,
  duration = 22,
  fromIndex,
  toIndex,
  slot,
}: Beat & {fromIndex: number; toIndex: number; slot: number}): CSSProperties => {
  const p = progress(frame, start, duration, ease.outQuart);
  const lift = Math.sin(Math.PI * p);
  return {
    translate: `0px ${(fromIndex + (toIndex - fromIndex) * p) * slot}px`,
    scale: 1 + 0.025 * lift,
    zIndex: lift > 0.01 ? 2 : 0,
  };
};
```

```tsx
// src/motion/camera.tsx
import type {ReactNode} from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame, useVideoConfig} from 'remotion';
import {ease} from './easings';

// x, y: world point (canvas px) to centre on. zoom: 1 = full canvas. tilt in degrees (keep <= 8).
export type Shot = {at: number; x: number; y: number; zoom: number; tiltX?: number; tiltY?: number};

// Place CameraRig ABOVE scene Sequences so it reads the global frame.
export const CameraRig: React.FC<{shots: Shot[]; easing?: (t: number) => number; children: ReactNode}> = ({
  shots,
  easing = ease.camera,
  children,
}) => {
  const frame = useCurrentFrame();
  const {width, height} = useVideoConfig();
  const list = shots.length > 1 ? shots : [shots[0], {...shots[0], at: shots[0].at + 1}];
  const at = list.map((s) => s.at); // strictly increasing
  const opts = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp', easing} as const;

  const x = interpolate(frame, at, list.map((s) => s.x), opts);
  const y = interpolate(frame, at, list.map((s) => s.y), opts);
  const zoom = interpolate(frame, at, list.map((s) => s.zoom), {...opts, output: 'perceptual-scale'});
  const tiltX = interpolate(frame, at, list.map((s) => s.tiltX ?? 0), opts);
  const tiltY = interpolate(frame, at, list.map((s) => s.tiltY ?? 0), opts);

  return (
    <AbsoluteFill style={{perspective: 2400, overflow: 'hidden'}}>
      <AbsoluteFill style={{transform: `rotateX(${tiltX}deg) rotateY(${tiltY}deg)`}}>
        {/* One transform string on purpose: the translate/scale shorthands rendered BLANK frames at zoom above ~2 (see SKILL.md 6.5) */}
        <AbsoluteFill
          style={{
            transformOrigin: '0px 0px',
            transform: `translate(${width / 2 - x * zoom}px, ${height / 2 - y * zoom}px) scale(${zoom})`,
          }}
        >
          {children}
        </AbsoluteFill>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};

// Frame a rect (world px) so it fills `fill` of the canvas.
export const shotFor = (
  rect: {x: number; y: number; w: number; h: number},
  canvas: {width: number; height: number},
  {at, fill = 0.78}: {at: number; fill?: number},
): Shot => ({
  at,
  x: rect.x + rect.w / 2,
  y: rect.y + rect.h / 2,
  zoom: Math.min((canvas.width * fill) / rect.w, (canvas.height * fill) / rect.h),
});

export const cameraPush = (at: number, duration: number, center: {x: number; y: number}, from = 1, to = 1.18): Shot[] => [
  {at, x: center.x, y: center.y, zoom: from},
  {at: at + duration, x: center.x, y: center.y, zoom: to},
];

export const cameraPull = (at: number, duration: number, center: {x: number; y: number}, from = 1.25, to = 1): Shot[] =>
  cameraPush(at, duration, center, from, to);
```

```tsx
// src/components/KineticText.tsx
import type {CSSProperties} from 'react';
import {interpolate, useCurrentFrame} from 'remotion';
import {ease} from '../motion/easings';

type Props = {
  text: string;
  start?: number;
  step?: number; // frames between units (default 4 per word, 2 per character)
  duration?: number; // frames for each unit's reveal
  mode?: 'word' | 'char';
  accentWords?: number[]; // word indices to emphasise
  accentColor?: string;
  style?: CSSProperties;
};

export const KineticText: React.FC<Props> = ({
  text,
  start = 0,
  step,
  duration = 16,
  mode = 'word',
  accentWords = [],
  accentColor = 'currentColor',
  style,
}) => {
  const frame = useCurrentFrame();
  const gap = step ?? (mode === 'char' ? 2 : 4);
  let unit = 0;

  return (
    <div style={{display: 'flex', flexWrap: 'wrap', columnGap: '0.28em', ...style}}>
      {text.split(' ').map((word, w) => {
        const pieces = mode === 'char' ? Array.from(word) : [word];
        return (
          <span key={w} style={{display: 'inline-flex', color: accentWords.includes(w) ? accentColor : undefined}}>
            {pieces.map((piece, i) => {
              const t0 = start + unit++ * gap;
              const p = interpolate(frame, [t0, t0 + duration], [0, 1], {
                extrapolateLeft: 'clamp',
                extrapolateRight: 'clamp',
                easing: ease.outExpo,
              });
              return (
                // overflow mask with descender padding so glyphs are not clipped
                <span key={i} style={{display: 'inline-block', overflow: 'hidden', paddingBottom: '0.14em', marginBottom: '-0.14em'}}>
                  <span style={{display: 'inline-block', translate: `0px ${(1 - p) * 110}%`}}>{piece}</span>
                </span>
              );
            })}
          </span>
        );
      })}
    </div>
  );
};
```

```tsx
// src/components/Cursor.tsx
import {interpolate, useCurrentFrame} from 'remotion';
import {color} from '../design/tokens';
import {ease} from '../motion/easings';

export type CursorKey = {at: number; x: number; y: number; click?: boolean};

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

// Arc path, eased per segment. Add two keys at one position to make the cursor dwell.
const positionAt = (frame: number, path: CursorKey[]) => {
  if (frame <= path[0].at) return {x: path[0].x, y: path[0].y};
  for (let i = 0; i < path.length - 1; i++) {
    const a = path[i];
    const b = path[i + 1];
    if (frame <= b.at) {
      const p = interpolate(frame, [a.at, b.at], [0, 1], {...clamp, easing: ease.inOut});
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const len = Math.hypot(dx, dy) || 1;
      const arc = Math.sin(Math.PI * p) * Math.min(60, len * 0.12);
      return {x: a.x + dx * p + (-dy / len) * arc, y: a.y + dy * p + (dx / len) * arc};
    }
  }
  const last = path[path.length - 1];
  return {x: last.x, y: last.y};
};

export const Cursor: React.FC<{path: CursorKey[]; size?: number}> = ({path, size = 44}) => {
  const frame = useCurrentFrame();
  const {x, y} = positionAt(frame, path);
  const click = path.find((k) => k.click && frame >= k.at && frame <= k.at + 14);
  const t = click ? frame - click.at : -1;
  const press = t >= 0 && t <= 6 ? Math.sin((Math.PI * t) / 6) : 0; // 6f dip
  const ring = t >= 0 ? interpolate(t, [0, 14], [0, 1], {...clamp, easing: ease.outQuart}) : 0;
  const tipX = (3 / 24) * size; // arrow tip inside the 24-unit viewBox
  const tipY = (2 / 24) * size;

  return (
    <>
      {click ? (
        <div
          style={{
            position: 'absolute',
            left: click.x - 36,
            top: click.y - 36,
            width: 72,
            height: 72,
            borderRadius: 999,
            border: `3px solid ${color.accent}`,
            opacity: 0.35 * (1 - ring),
            scale: 0.4 + ring * 1.1,
          }}
        />
      ) : null}
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        style={{
          position: 'absolute',
          left: x - tipX,
          top: y - tipY,
          transformOrigin: `${tipX}px ${tipY}px`,
          scale: 1 - 0.12 * press,
          filter: 'drop-shadow(0 2px 3px rgba(16, 24, 40, 0.25))',
        }}
      >
        <path
          d="M3 2 L3 18.5 L7.6 14.6 L10.6 21 L13.2 19.8 L10.3 13.6 L16.5 13.2 Z"
          fill={color.ink}
          stroke="#fff"
          strokeWidth={1.5}
          strokeLinejoin="round"
        />
      </svg>
    </>
  );
};
```

## QA script (not a Remotion source file)

Run after rendering frames: `npm i -D pngjs`, then `node scripts/qa-frames.cjs out/qa`. It reports mean luminance, the share of dark pixels, and flags frames that are blank (the camera bug above produced exactly these) or too dark for light mode. The top-left pixel is used as the background estimate, so the "content" figure is approximate when an element covers that corner. This replaces ffmpeg-based checks: the ffmpeg bundled with Remotion lacks the `signalstats`, `fps` and `tile` filters.

```js
// scripts/qa-frames.cjs  (needs: npm i -D pngjs)   run: node scripts/qa-frames.cjs out/qa
// Light-mode and blank-frame gate for rendered PNG frames.
const fs = require('fs');
const path = require('path');
const {PNG} = require('pngjs');

const dir = process.argv[2] || 'out/qa';
const names = fs.readdirSync(dir).filter((n) => n.endsWith('.png')).sort();
let bad = 0;

for (const name of names) {
  const {width, height, data} = PNG.sync.read(fs.readFileSync(path.join(dir, name)));
  const total = width * height;
  const bg = [data[0], data[1], data[2]]; // top-left pixel approximates the canvas background
  let lumaSum = 0;
  let dark = 0;
  let content = 0;
  for (let i = 0; i < data.length; i += 4) {
    const luma = 0.2126 * data[i] + 0.7152 * data[i + 1] + 0.0722 * data[i + 2];
    lumaSum += luma;
    if (luma < 51) dark++; // below 20% luminance
    if (Math.abs(data[i] - bg[0]) > 6 || Math.abs(data[i + 1] - bg[1]) > 6 || Math.abs(data[i + 2] - bg[2]) > 6) content++;
  }
  const mean = lumaSum / total;
  const darkPct = (100 * dark) / total;
  const contentPct = (100 * content) / total;
  const flags = [];
  if (mean < 200) flags.push('DARK (mean luma < 200)');
  if (darkPct > 15) flags.push('DARK-AREA (> 15% of pixels)');
  if (contentPct < 0.5) flags.push('BLANK? (< 0.5% differs from background)');
  if (flags.length) bad++;
  console.log(`${name}  mean=${mean.toFixed(0)}  dark=${darkPct.toFixed(1)}%  content=${contentPct.toFixed(1)}%  ${flags.join(', ') || 'ok'}`);
}
process.exitCode = bad ? 1 : 0;
```
