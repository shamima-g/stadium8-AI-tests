/**
 * Step 2 unit tests — the review-page generator (`helpers/build-review.ts`). Covers the pure
 * verdict-assembly logic that the page embeds and runs, plus the self-containment / escaping / stamp
 * guarantees of the generated HTML. Good AND broken case per check (workflow-tests §2 rule 1).
 */
import { describe, it, expect } from 'vitest';
import { buildReviewHtml, assembleVerdict, escapeHtml, type ReviewManifest } from '../../helpers/build-review';
import { stampFor } from '../../helpers/human-review';

const MANIFEST: ReviewManifest = {
  captureLabel: 'intake <contact-form>',
  items: [
    { id: 'facts', criterion: 'Are the facts correct?', guidance: 'match project.md', evidence: 'Roles: Visitor, Admin' },
    { id: 'design', criterion: 'Does the mockup match?', evidence: '<h1>Board</h1>', kind: 'html-mockup' },
  ],
};

describe('assembleVerdict — a Yes needs a citation (the embedded, tested logic)', () => {
  it('builds a verdict when every Yes has a citation', () => {
    const r = assembleVerdict(
      [{ id: 'facts', outcome: 'pass', citation: 'roles match' }, { id: 'design', outcome: 'skip', citation: '' }],
      'stamp123', 'alice', '2026-10-02T00:00:00.000Z',
    );
    expect(r.ok).toBe(true);
    expect(r.verdict?.stamp).toBe('stamp123');
    expect(r.verdict?.results).toEqual({ facts: 'pass', design: 'skip' });
    expect(r.verdict?.citations).toEqual({ facts: 'roles match' });
  });

  it('REFUSES when a Yes has no citation (the key guard)', () => {
    const r = assembleVerdict([{ id: 'facts', outcome: 'pass', citation: '  ' }], 'stamp123', 'alice', 'now');
    expect(r.ok).toBe(false);
    expect(r.errors.join(' ')).toMatch(/facts.*citation/);
    expect(r.verdict).toBeUndefined();
  });

  it('No / Skip never require a citation', () => {
    const r = assembleVerdict(
      [{ id: 'a', outcome: 'fail', citation: '' }, { id: 'b', outcome: 'skip', citation: '' }],
      's', 'x', 'now',
    );
    expect(r.ok).toBe(true);
  });
});

describe('buildReviewHtml — self-contained, escaped, correctly stamped', () => {
  const html = buildReviewHtml(MANIFEST);

  it('embeds the stamp, and it equals stampFor(items) (page and test agree)', () => {
    expect(html).toContain(JSON.stringify(stampFor(MANIFEST.items)));
  });

  it('shows each criterion', () => {
    expect(html).toContain('Are the facts correct?');
    expect(html).toContain('Does the mockup match?');
  });

  it('escapes text evidence — an injected <script> is inert, not live', () => {
    const evil = buildReviewHtml({ captureLabel: 'x', items: [{ id: 'a', criterion: 'q', evidence: '<script>alert(1)</script>' }] });
    expect(evil).toContain('&lt;script&gt;alert(1)&lt;/script&gt;');
    expect(evil).not.toContain('<script>alert(1)</script>');
  });

  it('renders an html-mockup in a SANDBOXED iframe with escaped srcdoc', () => {
    expect(html).toMatch(/<iframe class="mockup" sandbox=""/);
    expect(html).toContain('srcdoc="&lt;h1&gt;Board&lt;/h1&gt;"'); // source escaped into the attribute
  });

  it('is self-contained — no externally-loaded resources (CDN/script/link/img src)', () => {
    expect(html).not.toMatch(/<(script|link|img|iframe)\b[^>]*\b(src|href)\s*=\s*["']?https?:/i);
    expect(html).not.toMatch(/\bsrc\s*=\s*["']\/\//); // protocol-relative
  });

  it('embeds the EXACT tested assembleVerdict as self-sufficient browser JS (real parity, not a substring)', () => {
    const src = assembleVerdict.toString();
    // 1. the page embeds the exact source of the tested function (a broken stub would fail this)
    expect(html).toContain(src);
    // 2. that source is browser-safe: no transpiler helpers / module refs that would ReferenceError in a
    //    bare browser (guards the keepNames/esbuild fragility the council flagged).
    expect(src).not.toMatch(/\b__(name|spread\w*|publicField|defProp)\b|\brequire\s*\(|\bimport\b/);
    // 3. eval'd in a bare global context it behaves identically to the imported function across cases.
    // eslint-disable-next-line no-eval
    const embedded = (0, eval)(`(${src})`) as typeof assembleVerdict;
    const cases: Array<Parameters<typeof assembleVerdict>> = [
      [[{ id: 'a', outcome: 'pass', citation: '' }], 's', 'r', 'n'],
      [[{ id: 'a', outcome: 'pass', citation: 'ok' }], 's', 'r', 'n'],
      [[{ id: 'a', outcome: 'fail', citation: '' }], 's', 'r', 'n'],
      [[{ id: 'a', outcome: 'skip', citation: '' }], 's', 'r', 'n'],
    ];
    for (const c of cases) {
      expect(JSON.stringify(embedded(...c))).toBe(JSON.stringify(assembleVerdict(...c)));
    }
  });
});

describe('escapeHtml', () => {
  it('escapes the five dangerous chars', () => {
    expect(escapeHtml(`<a href="x" title='y'>&`)).toBe('&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;&amp;');
  });
});
