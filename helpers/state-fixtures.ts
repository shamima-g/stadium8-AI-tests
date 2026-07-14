/**
 * Epic-branch fixtures — seed the files the current workflow reads.
 *
 * The unit of work is the epic, built on an `epic/<slug>` branch. State lives at
 * `generated-docs/epics/<slug>/state.json` (shape mirrors
 * `.claude/scripts/lib/epic-state.js` → defaultEpicState). Shared project facts
 * live in `generated-docs/project.md` on `main`; the plan in
 * `generated-docs/epic-plan.md`.
 *
 * These write the WORKING-TREE copies. Tests that need real cross-branch behaviour
 * (collect-dashboard-data reads other epics from their branch tips) pair these with
 * `gitSandbox()` to commit them onto `main` / an `epic/<slug>` branch.
 */

import fs from 'node:fs';
import path from 'node:path';

// Mirrors epic-state.js EPIC_PHASES (the single source of truth in the template).
export type EpicPhase =
  | 'PLAN'
  | 'BUILD'
  | 'EPIC-END'
  | 'MANUAL-TEST'
  | 'COMPLETE-ON-BRANCH'
  | 'COMPLETE';

export type StoryStatus = 'pending' | 'in-progress' | 'complete' | 'halted';
export type E2eStatus =
  | 'deferred'
  | 'passed'
  | 'passed-after-fix'
  | 'failed'
  | 'auto-skipped:non-routable'
  | 'auto-skipped:fixme';

export interface StorySeed {
  status?: StoryStatus;
  commit?: string | null;
  e2eStatus?: E2eStatus;
}

export interface EpicState {
  schemaVersion: number;
  epic: {
    slug: string;
    name: string;
    createdAt: string;
    dependsOn: string[];
    introducesSharedSurface: boolean;
    unverifiedAssumptions: string[];
    manualTestResults: unknown[];
  };
  phase: EpicPhase;
  stories: Record<string, StorySeed>;
  halt: { reason?: string } | null;
  lastUpdated: string;
  [k: string]: unknown;
}

export interface SeedEpicStateOptions {
  slug: string;
  name?: string;
  phase?: EpicPhase;
  /** Story index → seed. Bare strings are shorthand for `{ status }`. */
  stories?: Record<string, StorySeed | StoryStatus>;
  dependsOn?: string[];
  halt?: { reason?: string } | null;
  unverifiedAssumptions?: string[];
  manualTestResults?: unknown[];
}

const FIXED_TS = '2026-04-21T00:00:00.000Z';

const EPICS_DIR_REL = 'generated-docs/epics';

function statePathRel(slug: string): string {
  return `${EPICS_DIR_REL}/${slug}/state.json`;
}

/** Writes generated-docs/epics/<slug>/state.json. Returns the absolute path. */
export function seedEpicState(root: string, opts: SeedEpicStateOptions): string {
  const {
    slug,
    name = `Epic ${slug}`,
    phase = 'PLAN',
    stories = {},
    dependsOn = [],
    halt = null,
    unverifiedAssumptions = [],
    manualTestResults = [],
  } = opts;

  const normalisedStories: Record<string, StorySeed> = {};
  for (const [index, s] of Object.entries(stories)) {
    const seed: StorySeed = typeof s === 'string' ? { status: s } : s;
    normalisedStories[index] = {
      status: seed.status ?? 'pending',
      commit: seed.commit ?? null,
      e2eStatus: seed.e2eStatus ?? 'deferred',
    };
  }

  const state: EpicState = {
    schemaVersion: 1,
    epic: {
      slug,
      name,
      createdAt: FIXED_TS,
      dependsOn: [...dependsOn],
      introducesSharedSurface: false,
      unverifiedAssumptions: [...unverifiedAssumptions],
      manualTestResults: [...manualTestResults],
    },
    phase,
    stories: normalisedStories,
    halt,
    lastUpdated: FIXED_TS,
  };

  const abs = path.join(root, statePathRel(slug));
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, JSON.stringify(state, null, 2));
  return abs;
}

/** Reads generated-docs/epics/<slug>/state.json. */
export function readEpicState(root: string, slug: string): EpicState {
  return JSON.parse(fs.readFileSync(path.join(root, statePathRel(slug)), 'utf8')) as EpicState;
}

export interface SeedProjectMdOptions {
  name?: string;
  slug?: string;
  body?: string;
}

/**
 * Writes generated-docs/project.md — the shared project facts. collect-dashboard-data
 * reads the H1 as the project name and a `Project slug | \`...\`` table row as the slug.
 */
export function seedProjectMd(root: string, opts: SeedProjectMdOptions = {}): string {
  const { name = 'Team Task Manager', slug = 'team-task-manager', body } = opts;
  const content =
    body ??
    `# ${name}\n\n` +
      `| Field | Value |\n| --- | --- |\n| Project slug | \`${slug}\` |\n\n` +
      `## Users\nAdmin, Member.\n\n## Authentication\nFrontend-only (next-auth).\n`;
  const abs = path.join(root, 'generated-docs', 'project.md');
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, content);
  return abs;
}

export interface PlanEpic {
  slug: string;
  name: string;
  goal?: string;
  dependsOn?: string[];
}

/**
 * Writes generated-docs/epic-plan.md with a `## Epics` table in the v1 format
 * collect-dashboard-data's parseEpicPlan expects (slug in a trailing `(\`slug\`)`,
 * dependencies as backticked slugs in the "Builds on" column).
 */
export function seedEpicPlan(root: string, epics: PlanEpic[]): string {
  const rows = epics
    .map((e, i) => {
      const deps = (e.dependsOn ?? []).map((d) => `\`${d}\``).join(', ') || '—';
      return `| ${i + 1} | ${e.name} (\`${e.slug}\`) | ${e.goal ?? e.name} | ${deps} |`;
    })
    .join('\n');
  const content =
    `# Epic Plan\n\n## Epics\n\n` +
    `| # | Epic | Delivers | Builds on |\n| --- | --- | --- | --- |\n${rows}\n`;
  const abs = path.join(root, 'generated-docs', 'epic-plan.md');
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, content);
  return abs;
}

export interface SeedStoryFileOptions {
  slug: string;
  index: number;
  title: string;
  role?: string;
  titleSlug?: string;
}

/** Writes generated-docs/epics/<slug>/stories/story-<index>-<titleSlug>.md. */
export function seedStoryFile(root: string, opts: SeedStoryFileOptions): string {
  const { slug, index, title, role = 'Admin' } = opts;
  const titleSlug = opts.titleSlug ?? title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const content = `# Story ${index}: ${title}\n\n**Role:** ${role}\n\n## Manual-test checklist\n- Sign in and confirm the ${title.toLowerCase()} behaves as expected.\n`;
  const abs = path.join(root, EPICS_DIR_REL, slug, 'stories', `story-${index}-${titleSlug}.md`);
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, content);
  return abs;
}

/**
 * Writes the retired top-level workflow-state.json. Used only to exercise the
 * legacy-detection path (collect-dashboard-data returns `legacy_detected` when
 * project.md is absent but this file is present).
 */
export function seedLegacyState(root: string): string {
  const abs = path.join(root, 'generated-docs', 'context', 'workflow-state.json');
  fs.mkdirSync(path.dirname(abs), { recursive: true });
  fs.writeFileSync(abs, JSON.stringify({ currentPhase: 'BUILD', currentEpic: 1 }, null, 2));
  return abs;
}
