/**
 * Extract a normalized "chrome fingerprint" from a generated review page (epic-plan-review.html /
 * stories-review.html / manual-tests.html).
 *
 * WHY computed styles, not source CSS. The three review pages are authored LIVE by the orchestrator
 * LLM from one prose spec (`.claude/shared/approval-pattern.md` §Visual Style) — there is NO shared
 * stylesheet, token file, class name, or string constant. Rendering each page in a real headless Chromium
 * and reading `getComputedStyle` neutralizes *syntactic* differences between equivalent authorings:
 *   - COLOURS come back in the browser's canonical `rgb()/rgba()` form, so `#2F6FED` vs `rgb(47,111,237)`
 *     vs an alpha-1 `rgba(...)` all compare equal, and a CSS-variable/class/inline source makes no difference.
 *   - FONT STACKS are whitespace/case-normalized (`normFont`), so `"system-ui", sans-serif` == `system-ui ,SANS-SERIF`.
 * It does NOT neutralize *semantic* differences. The review-page look is authored from *qualitative* prose,
 * so two INDEPENDENT generations can both be spec-compliant yet differ slightly in accent hue, radius, shadow,
 * padding, or font metrics. The consistency test therefore compares the visual dimensions with **tolerances**
 * ("close enough", via `colorsClose` / `cardClose` / `headingClose` below) rather than exact equality — small
 * spec-compliant variation passes, while clear drift (a different colour family, a much larger radius, a
 * different heading font) still fails. Discrete *wording* — button labels and the hand-back message — stays an
 * EXACT match (that's fixed text, not a "close" quantity). Tolerances live in `DEFAULT_TOLERANCES` and are the
 * one knob to turn if a real capture false-fails or a real drift slips through.
 *
 * The fingerprint covers exactly the six observations + the hand-back the acceptance criteria name:
 *   - heading        → the page heading's TYPE (font family/size/weight/line-height)
 *   - primaryButton  → the main action button's COLOUR + its LABEL ("Approve" / "Done")
 *   - card           → how the CARDS are drawn (the dominant repeated card's bg/radius/shadow/border/pad)
 *   - handBackMessage→ the confirmation shown when the action button is CLICKED (with `handBackFromClick`
 *                      recording whether it was actually observed on click, vs lifted from source as a fallback)
 */
import fs from 'node:fs';
import path from 'node:path';
import { chromium, type Browser, type Page } from 'playwright';

export interface HeadingChrome {
  text: string;
  fontFamily: string;
  fontSize: string;
  fontWeight: string;
  lineHeight: string;
}
export interface ButtonChrome {
  label: string;
  backgroundColor: string;
  color: string;
  borderRadius: string;
}
export interface CardChrome {
  backgroundColor: string;
  borderRadius: string;
  boxShadow: string;
  border: string;
  padding: string;
  /** how many elements on the page shared this exact card signature (diagnostic only; not compared) */
  count: number;
}
export interface PageFingerprint {
  heading: HeadingChrome | null;
  primaryButton: ButtonChrome | null;
  card: CardChrome | null;
  /** the confirmation text; null if neither the click nor the source fallback found one */
  handBackMessage: string | null;
  /** true only when the message was observed as a NEW element appearing after the click (the real behaviour);
   *  false when it was lifted from the page source because the click surfaced nothing (clipboard/alert path). */
  handBackFromClick: boolean;
}

/** The STYLE fields that define "the same look" — used by the test to compare colour/cards/heading. */
export function lookOf(fp: PageFingerprint): {
  buttonColor: string | null;
  card: Omit<CardChrome, 'count'> | null;
  heading: Omit<HeadingChrome, 'text'> | null;
} {
  return {
    buttonColor: fp.primaryButton ? fp.primaryButton.backgroundColor : null,
    card: fp.card ? { backgroundColor: fp.card.backgroundColor, borderRadius: fp.card.borderRadius, boxShadow: fp.card.boxShadow, border: fp.card.border, padding: fp.card.padding } : null,
    heading: fp.heading ? { fontFamily: fp.heading.fontFamily, fontSize: fp.heading.fontSize, fontWeight: fp.heading.fontWeight, lineHeight: fp.heading.lineHeight } : null,
  };
}

/** Collapse whitespace + lowercase a font stack so `"system-ui", sans-serif` == `system-ui ,  sans-serif`. */
function normFont(s: string): string {
  return s.replace(/\s+/g, ' ').trim().toLowerCase();
}

// ── Tolerant ("close enough") comparison (Option B) ─────────────────────────────────────────────────
// Two independently-generated pages that follow the same qualitative prose rarely match byte-for-byte on
// the visual dimensions, so the test compares them within these tolerances. Clear drift (a different colour
// family, a much bigger radius, a different heading category) exceeds them and still fails. The committed
// calibration fixtures are authored to exceed every tolerance, proving each check still bites.
//
// KNOWN LOOSENESS (accepted trade-offs of "close enough"): a card's shadow/border is compared only by
// PRESENCE (intensity/width/colour aren't), font family is compared only by generic CATEGORY (serif vs
// sans vs mono — two different sans fonts read as "the same type"), and each dimension can sit at its
// tolerance simultaneously, so a page can drift to the edge on every axis at once and still pass. Widen or
// tighten any single axis via DEFAULT_TOLERANCES. colorDistance is raw-RGB Euclidean (perceptually
// non-uniform): ~60 separates real accent FAMILIES (blue↔teal ≈ 113) but two light/dark shades of one hue
// can exceed it — revisit the threshold if same-hue accents false-fail.

export interface Tolerances {
  /** max Euclidean distance in 0–255 RGBA space treated as "the same colour" (alpha scaled ×255) */
  colorDistance: number;
  /** max |Δ| in border-radius px */
  radiusPx: number;
  /** max |Δ| in padding px (checked on both top and side) */
  paddingPx: number;
  /** max |Δ| in font-size px */
  fontSizePx: number;
  /** max |Δ| in numeric font-weight (75 keeps 400↔500 distinct while still allowing minor rounding) */
  fontWeight: number;
  /** max |Δ| in line-height px (compared only when both resolve to px) */
  lineHeightPx: number;
}

/** Defaults: small enough that the calibration drifts all fail, loose enough that same-intent variation passes. */
export const DEFAULT_TOLERANCES: Tolerances = {
  colorDistance: 60,
  radiusPx: 4,
  paddingPx: 6,
  fontSizePx: 3,
  fontWeight: 75,
  lineHeightPx: 4,
};

/** Parse a computed colour to [r,g,b,a] (a in 0–1, default 1); null if unparseable. Handles legacy comma and
 *  modern space/slash `rgb()` serializations (computed styles are normally comma form, but be robust). */
function parseRgb(s: string | null | undefined): [number, number, number, number] | null {
  if (!s) return null;
  const m = s.match(/rgba?\(([^)]+)\)/i);
  if (!m) return null;
  const parts = m[1].split(/[,/\s]+/).map((x) => x.trim()).filter(Boolean).map((x) => parseFloat(x));
  if (parts.length < 3 || parts.slice(0, 3).some((n) => Number.isNaN(n))) return null;
  const a = parts.length >= 4 && !Number.isNaN(parts[3]) ? parts[3] : 1;
  return [parts[0], parts[1], parts[2], a];
}

/** Euclidean distance over RGB + alpha (alpha scaled to the 0–255 range), or null if either can't be parsed. */
export function colorDistance(a: string | null | undefined, b: string | null | undefined): number | null {
  const pa = parseRgb(a);
  const pb = parseRgb(b);
  if (!pa || !pb) return null;
  return Math.sqrt(
    (pa[0] - pb[0]) ** 2 + (pa[1] - pb[1]) ** 2 + (pa[2] - pb[2]) ** 2 + ((pa[3] - pb[3]) * 255) ** 2
  );
}

function px(s: string | null | undefined): number | null {
  if (s == null) return null;
  const m = String(s).trim().match(/^(-?\d+(?:\.\d+)?)px/);
  return m ? parseFloat(m[1]) : null;
}
/** Top and side padding from a shorthand: "16px" → [16,16]; "16px 8px" → [16,8]; "16px 8px 24px 40px" → [16,40]. */
function padTopSide(s: string | null | undefined): [number | null, number | null] {
  const parts = String(s ?? '').trim().split(/\s+/);
  const top = px(parts[0]);
  const side = px(parts.length >= 4 ? parts[3] : parts[1] ?? parts[0]); // left of 4-value, else right/horizontal
  return [top, side];
}

/** Collapse a font stack to its generic category so equivalent system stacks match but serif↔sans drift fails. */
function fontCategory(stack: string): 'serif' | 'mono' | 'sans' {
  const s = (stack || '').toLowerCase();
  if (/\bmonospace\b|\bmono\b|courier|consolas|menlo|ui-monospace/.test(s)) return 'mono';
  const withoutSans = s.replace(/sans-serif/g, ''); // 'sans-serif' contains 'serif' — strip it before the serif test
  if (/\bserif\b|georgia|times|cambria|garamond|ui-serif/.test(withoutSans)) return 'serif';
  return 'sans';
}

/** Two button/background colours are "the same" within the colour tolerance. False if either is unparseable. */
export function colorsClose(a: string | null, b: string | null, tol: Tolerances = DEFAULT_TOLERANCES): boolean {
  const d = colorDistance(a, b);
  return d !== null && d <= tol.colorDistance;
}

type CardLook = Omit<CardChrome, 'count'>;
type HeadingLook = Omit<HeadingChrome, 'text'>;

/** Cards are "drawn the same way" within tolerance: close bg + radius + padding (top & side), same presence of
 *  shadow and of border. (Shadow intensity and border width/colour are accepted looseness — presence only.) */
export function cardsClose(a: CardLook | null, b: CardLook | null, tol: Tolerances = DEFAULT_TOLERANCES): boolean {
  if (!a || !b) return false;
  if (!colorsClose(a.backgroundColor, b.backgroundColor, tol)) return false;
  const ra = firstRadius(a.borderRadius);
  const rb = firstRadius(b.borderRadius);
  if (ra === null || rb === null || Math.abs(ra - rb) > tol.radiusPx) return false;
  const [at, as] = padTopSide(a.padding);
  const [bt, bs] = padTopSide(b.padding);
  if (at === null || bt === null || Math.abs(at - bt) > tol.paddingPx) return false;
  if (as === null || bs === null || Math.abs(as - bs) > tol.paddingPx) return false;
  const has = (s: string) => !!s && s !== 'none';
  if (has(a.boxShadow) !== has(b.boxShadow)) return false; // a flat card vs a shadowed card is a real difference
  if (has(a.border) !== has(b.border)) return false;
  return true;
}

/** First value of a border-radius shorthand (handles the `12px / 8px` horizontal/vertical form too). */
function firstRadius(s: string | null | undefined): number | null {
  return px(String(s ?? '').trim().split('/')[0].trim().split(/\s+/)[0]);
}

/** Heading is "the same type" within tolerance: same font CATEGORY, close size/weight/line-height. */
export function headingsClose(a: HeadingLook | null, b: HeadingLook | null, tol: Tolerances = DEFAULT_TOLERANCES): boolean {
  if (!a || !b) return false;
  if (fontCategory(a.fontFamily) !== fontCategory(b.fontFamily)) return false; // serif↔sans is a real type change
  const fa = px(a.fontSize);
  const fb = px(b.fontSize);
  if (fa === null || fb === null || Math.abs(fa - fb) > tol.fontSizePx) return false;
  const wa = parseFloat(a.fontWeight);
  const wb = parseFloat(b.fontWeight);
  if (Number.isNaN(wa) || Number.isNaN(wb) || Math.abs(wa - wb) > tol.fontWeight) return false;
  const la = px(a.lineHeight);
  const lb = px(b.lineHeight);
  if (la !== null && lb !== null && Math.abs(la - lb) > tol.lineHeightPx) return false; // skip if 'normal'
  return true;
}

/** Launch a headless Chromium for a batch of extractions. Caller owns `.close()`. */
export async function launchBrowser(): Promise<Browser> {
  try {
    return await chromium.launch();
  } catch (e) {
    throw new Error(
      'Playwright Chromium could not launch — install it with `npx playwright install chromium` in AI-tests.\n' +
        `Original error: ${(e as Error).message}`
    );
  }
}

/** True if a headless Chromium can actually launch here. Lets callers SKIP (not error) when the browser
 *  isn't installed — so the default suite stays green on a machine/CI without it, rather than throwing. */
export async function chromiumAvailable(): Promise<boolean> {
  try {
    const b = await chromium.launch();
    await b.close();
    return true;
  } catch {
    return false;
  }
}

/**
 * Pull the static structure (heading, primary button, dominant card) from the rendered page. Runs in the
 * browser so it sees the real computed cascade.
 *   - heading: first <h1>, else first <h2>, else first [role=heading] (the spec asks for "a short header"
 *     but doesn't mandate an <h1>, so falling back avoids a structural false-fail).
 *   - primary button: the action button whose accessible text contains "approve"/"done" (tolerates a leading
 *     glyph like "✓ Approve"); else the first non-transparent-background button; else the first button.
 *   - card: the dominant repeated card box — rounded AND (shadowed OR bordered), a real block (not a control),
 *     of card-ish size. Background-distinct-from-body is a BONUS signal (preferred) but NOT a hard gate, so
 *     white-on-white soft cards (shadow only) and flat bordered cards (border only) are both detected.
 */
async function extractStatic(page: Page): Promise<Omit<PageFingerprint, 'handBackMessage' | 'handBackFromClick'>> {
  return page.evaluate(() => {
    const cs = (el: Element) => getComputedStyle(el);
    const bodyBg = cs(document.body).backgroundColor;
    const transparent = (c: string) => c === 'rgba(0, 0, 0, 0)' || c === 'transparent';

    // ── heading ───────────────────────────────────────────────────────────────────────────────────
    const hEl =
      document.querySelector('h1') || document.querySelector('h2') || document.querySelector('[role="heading"]');
    const heading = hEl
      ? {
          text: (hEl.textContent || '').replace(/\s+/g, ' ').trim(),
          fontFamily: cs(hEl).fontFamily,
          fontSize: cs(hEl).fontSize,
          fontWeight: cs(hEl).fontWeight,
          lineHeight: cs(hEl).lineHeight,
        }
      : null;

    // ── primary button ────────────────────────────────────────────────────────────────────────────
    const btns = Array.from(
      document.querySelectorAll('button, [role="button"], a.button, input[type="submit"], input[type="button"]')
    ) as HTMLElement[];
    const labelOf = (b: HTMLElement) =>
      ((b as HTMLInputElement).value || b.textContent || '').replace(/\s+/g, ' ').trim();
    const re = /\b(approve|done)\b/i;
    const picked =
      btns.find((b) => re.test(labelOf(b))) ||
      btns.find((b) => !transparent(cs(b).backgroundColor)) ||
      btns[0] ||
      null;
    const primaryButton = picked
      ? {
          label: labelOf(picked),
          backgroundColor: cs(picked).backgroundColor,
          color: cs(picked).color,
          borderRadius: cs(picked).borderRadius,
        }
      : null;

    // ── card: dominant rounded block set off by a shadow OR a border (bg-distinct preferred, not required) ──
    const CONTROL = new Set(['BUTTON', 'A', 'INPUT', 'SELECT', 'TEXTAREA', 'LABEL', 'SVG', 'IMG']);
    type Cand = { s: Omit<CardChrome, 'count'>; count: number; distinct: number };
    const sig = new Map<string, Cand>();
    for (const el of Array.from(document.querySelectorAll<HTMLElement>('body *'))) {
      if (CONTROL.has(el.tagName)) continue;
      const s = cs(el);
      const rounded = s.borderRadius && s.borderRadius !== '0px';
      const shadowed = s.boxShadow && s.boxShadow !== 'none';
      const noBorder = s.borderTopStyle === 'none' || s.borderTopWidth === '0px';
      // A card is a rounded block set off from the page by a shadow OR a border — so flat bordered cards
      // (no shadow) are detected too, not just soft-shadow cards.
      if (!(rounded && (shadowed || !noBorder))) continue;
      const r = el.getBoundingClientRect();
      if (r.width < 120 || r.height < 40) continue; // card-ish size, not a chip/badge/pill
      const card = {
        backgroundColor: s.backgroundColor,
        borderRadius: s.borderRadius,
        boxShadow: s.boxShadow,
        // A 0px/none border's colour is invisible and computes to currentcolor — normalize so a text-colour
        // difference between two generations doesn't masquerade as a card-border drift.
        border: noBorder ? 'none' : `${s.borderTopWidth} ${s.borderTopStyle} ${s.borderTopColor}`,
        padding: s.padding,
      };
      const distinct = s.backgroundColor && s.backgroundColor !== bodyBg && !transparent(s.backgroundColor) ? 1 : 0;
      const key = JSON.stringify(card);
      const prev = sig.get(key);
      if (prev) prev.count++;
      else sig.set(key, { s: card, count: 1, distinct });
    }
    // Prefer a bg-distinct card; among those, the most frequent. (Falls back to shadowed-only cards.)
    let best: Cand | null = null;
    for (const v of sig.values()) {
      if (!best || v.distinct > best.distinct || (v.distinct === best.distinct && v.count > best.count)) best = v;
    }
    const card = best ? { ...best.s, count: best.count } : null;

    return { heading, primaryButton, card };
  });
}

/**
 * Read the hand-back confirmation message by actually CLICKING the action button (the criterion's "click
 * Approve / click Done and read the message that appears"). WORDING-AGNOSTIC: we snapshot the visible leaf
 * texts, click, then take the newly-visible leaf — preferring one that looks like a confirmation
 * (paste/copied/clipboard/chat) over raw DOM order, so a button-label flip ("Copied!") doesn't masquerade
 * as the message. `fromClick` records whether the click actually surfaced something.
 *
 * Fallback (fromClick=false): if the click surfaces nothing — e.g. the page confirms via `alert()` or a
 * clipboard write that throws on file:// before any DOM renders — lift a confirmation sentence from source.
 * The test treats a fallback-sourced message as UNVERIFIED (it won't let two pages "match" on source text
 * copied from the same shared prose), so this path can't manufacture a vacuous pass.
 */
async function extractHandBack(page: Page, rawHtml: string): Promise<{ message: string | null; fromClick: boolean }> {
  const visibleLeafTexts = `(() => {
    const vis = (el) => { const r = el.getBoundingClientRect(); return !!(r.width && r.height) && getComputedStyle(el).visibility !== 'hidden'; };
    return Array.from(document.querySelectorAll('body *'))
      .filter((el) => el.children.length === 0 && vis(el))
      .map((el) => (el.textContent || '').replace(/\\s+/g, ' ').trim())
      .filter(Boolean);
  })()`;

  const before: string[] = await page.evaluate(visibleLeafTexts);

  const clicked = await page.evaluate(() => {
    const labelOf = (b: Element) =>
      (((b as HTMLInputElement).value || b.textContent) || '').replace(/\s+/g, ' ').trim();
    const re = /\b(approve|done)\b/i;
    const btns = Array.from(
      document.querySelectorAll('button, [role="button"], a.button, input[type="submit"], input[type="button"]')
    );
    const target = btns.find((b) => re.test(labelOf(b))) as HTMLElement | undefined;
    if (!target) return false;
    try {
      target.click();
    } catch {
      /* clipboard may throw on file://; the confirmation text usually still renders */
    }
    return true;
  });

  if (clicked) {
    await page.waitForTimeout(400); // let a toast/confirmation render
    const after: string[] = await page.evaluate(visibleLeafTexts);
    const beforeSet = new Set(before);
    const fresh = after.filter((t) => !beforeSet.has(t));
    if (fresh.length) {
      const conf = fresh.find((t) => /paste|copied|clipboard|chat/i.test(t));
      return { message: conf ?? fresh[0], fromClick: true };
    }
  }

  // Fallback: lift a confirmation sentence from source (loose match for plausible wordings).
  const m = rawHtml.match(/([^"'`>]*paste[^"'`<]*chat[^"'`<]*)/i);
  return { message: m ? m[1].replace(/\s+/g, ' ').trim() : null, fromClick: false };
}

/** Fingerprint one page file. Pass a shared `browser` when fingerprinting several pages in a run. */
export async function fingerprintPage(filePath: string, browser?: Browser): Promise<PageFingerprint> {
  const abs = path.resolve(filePath);
  if (!fs.existsSync(abs)) throw new Error(`fingerprintPage: no file at ${abs}`);
  const rawHtml = fs.readFileSync(abs, 'utf8');
  const own = browser ? null : await launchBrowser();
  const b = browser ?? (own as Browser);
  const context = await b.newContext();
  try {
    await context.grantPermissions(['clipboard-read', 'clipboard-write']).catch(() => {});
    const page = await context.newPage();
    await page.goto('file://' + abs.replace(/\\/g, '/'));
    const stat = await extractStatic(page);
    const hb = await extractHandBack(page, rawHtml);
    const fp: PageFingerprint = { ...stat, handBackMessage: hb.message, handBackFromClick: hb.fromClick };
    if (fp.heading) fp.heading.fontFamily = normFont(fp.heading.fontFamily);
    return fp;
  } finally {
    await context.close();
    if (own) await own.close();
  }
}

/** Fingerprint a map of {label: filePath} reusing one browser. Returns {label: fingerprint}. */
export async function fingerprintPages(files: Record<string, string>): Promise<Record<string, PageFingerprint>> {
  const browser = await launchBrowser();
  try {
    const out: Record<string, PageFingerprint> = {};
    for (const [label, file] of Object.entries(files)) {
      out[label] = await fingerprintPage(file, browser);
    }
    return out;
  } finally {
    await browser.close();
  }
}
