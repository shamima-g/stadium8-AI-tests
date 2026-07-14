/**
 * Artifact-lint rules — pure functions, one per check.
 *
 * Each rule takes file *content* (a string) and returns the violations it finds.
 * They are deliberately decoupled from the filesystem so they can be tested
 * against known-good / known-bad fixtures deterministically — the rule is the
 * unit under test, not "what the repo happens to contain right now".
 *
 * The artifact-lint test files use these in two ways:
 *   1. Rule tests — feed inline good/bad samples, assert the rule flags/passes.
 *      These always run and are the real contract.
 *   2. Regression scan — walk the real generated output (web/src/, generated-docs/)
 *      and run the SAME rule over it. That scan is skipped (visibly, not silently)
 *      when no generated output exists yet, so a clean template can't show a
 *      vacuous green.
 *
 * Not a *.test.ts file, so Vitest never collects it as a suite; it's imported
 * by the tests and transformed on demand.
 */

import fs from 'node:fs';
import path from 'node:path';
import yaml from 'js-yaml';

// ---------------------------------------------------------------------------
// Filesystem walk (shared by the regression scans)
// ---------------------------------------------------------------------------

/** Absolute paths of files under `dir` whose basename satisfies `match`. */
export function walkFiles(dir: string, match: (name: string) => boolean): string[] {
  const out: string[] = [];
  if (!fs.existsSync(dir)) return out;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
      out.push(...walkFiles(full, match));
    } else if (entry.isFile() && match(entry.name)) {
      out.push(full);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// TG-33 — No error-suppression directives (web/src/**/*.ts,tsx)
// ---------------------------------------------------------------------------

export const SUPPRESSION_PATTERN = /eslint-disable|@ts-ignore|@ts-expect-error|@ts-nocheck/g;
export const isSourceFile = (name: string): boolean => /\.(ts|tsx)$/.test(name);

/** Every suppression directive found in the content (empty = clean). */
export function findSuppressions(content: string): string[] {
  return content.match(SUPPRESSION_PATTERN) ?? [];
}

// ---------------------------------------------------------------------------
// TG-34 — Plain language in user-facing verification checklists
// ---------------------------------------------------------------------------

export const JARGON_PATTERNS: RegExp[] = [
  /\bisLoading\b/,
  /\bSkeleton\b/,
  /\bexit code\b/i,
  /\btsc\b/,
  /\btypecheck\b/i,
  /\bESLint\b/,
  /\bGate\s*3\b/,
  /\buseState\b/,
  /\buseEffect\b/,
  /\bjsdom\b/,
  /\bvitest\b/i,
  /\bMSW\b/,
];
// Legacy standalone checklists (retired flat layout). Kept so the detector still
// recognises an old `*-verification-checklist.md` if one is ever present.
export const isChecklist = (name: string): boolean => name.endsWith('-verification-checklist.md');

/** Jargon patterns that match the content (empty = plain language). */
export function findJargon(content: string): RegExp[] {
  return JARGON_PATTERNS.filter((rx) => rx.test(content));
}

/**
 * The user-facing manual-test checklist now lives INSIDE each epic story file
 * (`generated-docs/epics/<slug>/stories/story-*.md`), under a heading that mentions
 * "manual" + "test"/"check". This pulls just that section — so the plain-language
 * scan checks the checklist wording without tripping on the dev-facing metadata
 * (targetFile, requirementIds, routes) elsewhere in the story file. Returns '' when
 * the file has no such section.
 */
export function extractManualChecklist(content: string): string {
  const lines = content.split(/\r?\n/);
  const startRe = /^#{1,6}\s.*\bmanual\b.*\b(test|check)/i;
  const start = lines.findIndex((l) => startRe.test(l));
  if (start === -1) return '';
  const headingLevel = lines[start].match(/^#+/)?.[0].length ?? 2;
  const out: string[] = [];
  for (let i = start + 1; i < lines.length; i++) {
    const h = lines[i].match(/^(#+)\s/);
    if (h && h[1].length <= headingLevel) break; // next same/higher-level heading ends the section
    out.push(lines[i]);
  }
  return out.join('\n');
}

// ---------------------------------------------------------------------------
// TG-38 — Every story file declares a non-empty Role
// ---------------------------------------------------------------------------

export const EMPTY_ROLE_VALUES = new Set(['', 'n/a', 'tbd', 'unknown']);
export const isStoryFile = (name: string): boolean => /^story-.+\.md$/.test(name);

/** The role value from a story file, or null when no Role field is present. */
export function extractRole(content: string): string | null {
  // Matches `**Role:** admin` or `| **Role:** | admin |` etc.
  const m = content.match(/\*\*Role:?\*\*\s*[:|]?\s*([^\n|]+)/i);
  return m ? m[1].trim() : null;
}

/** A description of the role problem, or null when the role is valid. */
export function roleViolation(content: string): string | null {
  const role = extractRole(content);
  if (role === null) return 'missing **Role:** field';
  if (EMPTY_ROLE_VALUES.has(role.toLowerCase())) return `empty/ambiguous role "${role}"`;
  return null;
}

// ---------------------------------------------------------------------------
// TG-31 — API paths in code must match the OpenAPI spec exactly
// ---------------------------------------------------------------------------

export function extractSpecPaths(yamlContent: string): string[] {
  try {
    const doc = yaml.load(yamlContent) as { paths?: Record<string, unknown> };
    return Object.keys(doc?.paths ?? {});
  } catch {
    return [];
  }
}

export function extractCodePaths(code: string): string[] {
  // Match strings like "/api/v2/tasks" or '/api/tasks/{id}' or template literals.
  const matches = code.match(/["'`](\/api\/[^"'`]+)["'`]/g) ?? [];
  return matches.map((m) => m.slice(1, -1).replace(/\$\{[^}]+\}/g, '{param}'));
}

export function pathMatchesSpec(codePath: string, specPaths: string[]): boolean {
  const normalise = (p: string) => p.replace(/\{[^}]+\}/g, '{}');
  const normCode = normalise(codePath);
  return specPaths.some((sp) => normalise(sp) === normCode);
}

/** Code API paths that aren't declared in the spec (empty = all accounted for). */
export function findInventedPaths(code: string, specPaths: string[]): string[] {
  return extractCodePaths(code).filter((p) => !pathMatchesSpec(p, specPaths));
}

// ---------------------------------------------------------------------------
// TG-32 — UI primitives must be imported from Shadcn (@/components/ui/)
// ---------------------------------------------------------------------------

export const COMMON_UI = new Set([
  'Button', 'Card', 'Dialog', 'Input', 'Label', 'Select', 'Table',
  'Textarea', 'Alert', 'Badge', 'Form', 'Tabs', 'Tooltip',
]);
export const isTsx = (name: string): boolean => /\.tsx$/.test(name);

export function extractImports(code: string): Array<{ names: string[]; from: string }> {
  const out: Array<{ names: string[]; from: string }> = [];
  const re = /import\s*\{([^}]+)\}\s*from\s*["']([^"']+)["']/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(code)) !== null) {
    const names = m[1].split(',').map((s) => s.trim()).filter(Boolean);
    out.push({ names, from: m[2] });
  }
  return out;
}

/** UI-primitive imports that don't come from @/components/ui/ (empty = clean). */
export function findNonShadcnUiImports(code: string): string[] {
  return extractImports(code)
    .filter((i) => i.names.some((n) => COMMON_UI.has(n)))
    .filter((i) => !i.from.includes('components/ui'))
    .map((i) => `{ ${i.names.join(', ')} } from '${i.from}'`);
}
