/**
 * control-refs — unit tests for the accessible-control extractor and the two-file parity comparison
 * (build-tests-together, commit 4666e23). Template-independent: imports the helper directly (not the
 * barrel) and reads only local ./fixtures/, so it runs anywhere with no REPO_ROOT.
 *
 * The calibration fixture pairs under ./fixtures/ are the "planted-bad" cases that prove the parity
 * check can go RED — role divergence (the reported radio-vs-dropdown bug) and strategy divergence — and
 * that the case it cannot catch (same control, different name) is SURFACED, not silently green. The
 * inline tests cover the extractor's robustness: comment/string masking, locator selectors, regex/escape
 * name canonicalisation, multi-signature sets, and the throw/unresolved paths through compareControls.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { extractControlRefs, compareControls } from '../../helpers/control-refs';

const fix = (dir: string, file: string) => fs.readFileSync(path.join(__dirname, 'fixtures', dir, file), 'utf8');
const pair = (dir: string) => {
  const files = fs.readdirSync(path.join(__dirname, 'fixtures', dir));
  const t = files.find((f) => f.endsWith('.test.tsx'))!;
  const s = files.find((f) => f.endsWith('.spec.ts'))!;
  return { vitest: fix(dir, t), playwright: fix(dir, s) };
};

// ---------------------------------------------------------------------------
// extractor — basics
// ---------------------------------------------------------------------------

describe('extractControlRefs — basics', () => {
  it('reads getByRole role + string name, preserving raw + pre-normalised name', () => {
    const [r] = extractControlRefs(`screen.getByRole('radiogroup', { name: 'Save Changes' })`);
    expect(r).toMatchObject({ strategy: 'role', role: 'radiogroup', name: 'Save Changes', nameKey: 'save changes', resolved: true });
    expect(r.raw).toContain("getByRole('radiogroup'");
  });

  it('normalises a regex name to the same key as the equivalent string', () => {
    const [re] = extractControlRefs(`getByRole('button', { name: /save changes/i })`);
    const [str] = extractControlRefs(`getByRole('button', { name: 'Save changes' })`);
    expect(re.nameKey).toBe('save changes');
    expect(re.nameIsPattern).toBe(true);
    expect(re.nameKey).toBe(str.nameKey);
  });

  it('captures Testing-Library getByLabelText and Playwright getByLabel as the same strategy', () => {
    expect(extractControlRefs(`getByLabelText('Email')`)[0]).toMatchObject({ strategy: 'label', role: null, nameKey: 'email' });
    expect(extractControlRefs(`await page.getByLabel('Email').fill('x')`)[0]).toMatchObject({ strategy: 'label', nameKey: 'email' });
  });

  it('handles chained, within(), and All variants', () => {
    const refs = extractControlRefs(
      `page.getByRole('radiogroup', { name: 'Status' }).getByRole('radio', { name: 'Open' });` +
        `within(screen.getByRole('list')).getByRole('listitem');` +
        `screen.getAllByRole('tab', { name: 'Home' });`,
    );
    expect(refs.map((r) => r.role)).toEqual(['radiogroup', 'radio', 'list', 'listitem', 'tab']);
  });

  it('parses multi-line / trailing-comma queries (Prettier output)', () => {
    const [r] = extractControlRefs(`page.getByRole('button', {\n  name: 'Sign In',\n})`);
    expect(r).toMatchObject({ role: 'button', nameKey: 'sign in' });
  });

  it('extracts every query family and prefix', () => {
    const refs = extractControlRefs(
      `findByPlaceholderText('Search'); getByAltText('Logo'); queryByTitle('Close');` +
        `getByDisplayValue('42'); page.getByPlaceholder('Email'); getByTestId('row-5'); getByText('Welcome');`,
    );
    expect(refs.map((r) => r.strategy)).toEqual(['placeholder', 'altText', 'title', 'displayValue', 'placeholder', 'testId', 'text']);
  });

  it('getByRole with no name → resolved:true but nameKey:null (not dynamic)', () => {
    const [r] = extractControlRefs(`getAllByRole('listitem')`);
    expect(r).toMatchObject({ resolved: true, nameKey: null, role: 'listitem' });
  });

  it('marks a dynamic name as unresolved (nameKey null)', () => {
    const [r] = extractControlRefs(`getByRole('button', { name: submitLabel })`);
    expect(r.resolved).toBe(false);
    expect(r.nameKey).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// extractor — robustness (the council-hardened paths)
// ---------------------------------------------------------------------------

describe('extractControlRefs — robustness', () => {
  it('IGNORES queries inside line/block comments and string literals (no phantom refs)', () => {
    const src =
      `// old: getByRole('radio', { name: 'Status' })\n` +
      `/* was getByRole('tab', { name: 'Status' }) */\n` +
      `const DOC = "find it with getByRole('menuitem', { name: 'Status' })";\n` +
      `screen.getByRole('combobox', { name: 'Status' });`;
    const refs = extractControlRefs(src);
    expect(refs).toHaveLength(1);
    expect(refs[0]).toMatchObject({ role: 'combobox', nameKey: 'status' });
  });

  it('extracts Playwright locator("role=...") selectors (name as string or regex)', () => {
    const str = extractControlRefs(`await page.locator('role=button[name="Save"]').click()`);
    expect(str[0]).toMatchObject({ strategy: 'role', role: 'button', nameKey: 'save' });
    const re = extractControlRefs(`page.locator('role=textbox[name=/email/i]')`);
    expect(re[0]).toMatchObject({ role: 'textbox', nameKey: 'email', nameIsPattern: true });
  });

  it('joins regex-anchored, regex-escaped, and string-escaped names with their plain equivalents', () => {
    expect(extractControlRefs(`getByRole('button', { name: /^Save$/ })`)[0].nameKey).toBe('save');
    expect(extractControlRefs(`getByRole('button', { name: /Save \\(now\\)/ })`)[0].nameKey).toBe('save (now)');
    expect(extractControlRefs(`getByText('it\\'s here')`)[0].nameKey).toBe("it's here");
  });

  it('template literal: resolves without interpolation, unresolved with it', () => {
    expect(extractControlRefs('getByRole(`button`, { name: `Save` })')[0].nameKey).toBe('save');
    expect(extractControlRefs('getByRole(`button`, { name: `Save ${id}` })')[0].resolved).toBe(false);
  });

  it('THROWS when the source has a query but nothing parses (no silent empty map)', () => {
    expect(() => extractControlRefs(`render(); screen.getByRole('button'`)).toThrow(/none parsed/);
  });

  it('returns [] for a file with no queries (not a throw)', () => {
    expect(extractControlRefs(`import { test } from '@playwright/test';`)).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// compareControls — calibration fixture pairs
// ---------------------------------------------------------------------------

describe('compareControls — calibration pairs', () => {
  it('GOOD pair: every shared control agrees → status "match", exactly 3 shared', () => {
    const { vitest, playwright } = pair('good');
    const res = compareControls(vitest, playwright);
    expect(res.status).toBe('match');
    expect(res.mismatches).toEqual([]);
    expect(res.shared.map((s) => s.nameKey).sort()).toEqual(['open', 'save changes', 'status']);
    expect(res.comparedCount).toBe(3);
  });

  it('ROLE-DIVERGENT pair (the reported bug): radiogroup vs combobox for "Status" → mismatch', () => {
    const { vitest, playwright } = pair('role-divergent');
    const res = compareControls(vitest, playwright);
    expect(res.status).toBe('mismatch');
    const m = res.mismatches.find((x) => x.nameKey === 'status');
    expect(m).toBeTruthy();
    expect(m!.vitest).toEqual(['role=radiogroup']);
    expect(m!.playwright).toEqual(['role=combobox']);
  });

  it('STRATEGY-DIVERGENT pair: getByRole(textbox) vs getByLabel for "Email" → mismatch; "Send" agrees', () => {
    const { vitest, playwright } = pair('strategy-divergent');
    const res = compareControls(vitest, playwright);
    expect(res.status).toBe('mismatch');
    expect(res.mismatches.map((m) => m.nameKey)).toEqual(['email']);
    expect(res.shared.find((s) => s.nameKey === 'send')).toMatchObject({ match: true });
  });

  it('NAME-DIVERGENT pair: the uncatchable case is SURFACED (uncompared), not a false green', () => {
    const { vitest, playwright } = pair('name-divergent');
    const res = compareControls(vitest, playwright);
    expect(res.status).toBe('skipped-no-overlap');
    expect(res.mismatches).toEqual([]);
    expect(res.uncompared.vitestOnly).toContain('priority');
    expect(res.uncompared.playwrightOnly).toContain('priority level');
  });
});

// ---------------------------------------------------------------------------
// compareControls — inline edge cases
// ---------------------------------------------------------------------------

describe('compareControls — inline', () => {
  it('a commented-out query cannot mask a real role divergence', () => {
    const vitest = `// old: getByRole('radio', { name: 'Status' })\nscreen.getByRole('combobox', { name: 'Status' });`;
    const playwright = `// was combobox: getByRole('combobox', { name: 'Status' })\nawait page.getByRole('radio', { name: 'Status' }).check();`;
    const res = compareControls(vitest, playwright);
    expect(res.status).toBe('mismatch');
    const m = res.mismatches.find((x) => x.nameKey === 'status')!;
    expect(m.vitest).toEqual(['role=combobox']);
    expect(m.playwright).toEqual(['role=radio']);
  });

  it('getByLabelText (Vitest) ≡ getByLabel (Playwright) for the same name → match', () => {
    expect(compareControls(`getByLabelText('Email')`, `page.getByLabel('Email')`).status).toBe('match');
  });

  it('getByRole ≡ locator("role=...") for the same control → match', () => {
    expect(compareControls(`getByRole('button', { name: 'Save' })`, `page.locator('role=button[name="Save"]')`).status).toBe('match');
  });

  it('compares multi-signature-per-name sets: match, and flags a dropped signature', () => {
    const v = `getByRole('button', { name: 'Filters' }); getByRole('region', { name: 'Filters' })`;
    const pMatch = `page.getByRole('region', { name: 'Filters' }); page.getByRole('button', { name: 'Filters' })`;
    expect(compareControls(v, pMatch).status).toBe('match');
    const res = compareControls(v, `page.getByRole('button', { name: 'Filters' })`);
    expect(res.status).toBe('mismatch');
    const m = res.mismatches.find((x) => x.nameKey === 'filters')!;
    expect(m.vitest).toEqual(['role=button', 'role=region']);
    expect(m.playwright).toEqual(['role=button']);
  });

  it('non-role strategies compare: getByText match; getByText vs getByTestId → mismatch', () => {
    expect(compareControls(`getByText('Welcome')`, `page.getByText('Welcome')`).status).toBe('match');
    expect(compareControls(`getByText('Welcome')`, `getByTestId('Welcome')`).status).toBe('mismatch');
  });

  it('a dynamic-named control in both files surfaces as unresolved (never swallowed)', () => {
    const res = compareControls(`getByRole('button', { name: submitLabel })`, `page.getByRole('button', { name: submitLabel })`);
    expect(res.status).toBe('skipped-no-overlap');
    expect(res.uncompared.unresolved).toHaveLength(2);
  });

  it('throws through compareControls when either file has queries but none parse', () => {
    expect(() => compareControls(`getByRole('button', { name: 'X' })`, `render(); screen.getByRole('button'`)).toThrow(/none parsed/);
  });
});
