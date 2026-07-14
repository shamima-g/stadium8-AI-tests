/**
 * Tests for .claude/scripts/migrate-legacy-state.js
 *
 * One-shot migrator for pre-4-phase workflow-state.json files. Maps the legacy
 * phase vocabulary onto the INTAKE / PLAN / BUILD / COMPLETE model, drops removed
 * sub-objects, renames intake.frsExists → briefExists, and copies
 * feature-requirements.md → project-brief.md.
 *
 * Fixtures are the four real workflow-state.json files captured from the
 * stadium-8 test repos (AI-tests/fixtures/legacy-state/), plus synthetic
 * edge-case fixtures created inline. The script is exercised as a subprocess via
 * its --root/--apply/--restore CLI, so these are true black-box tests.
 */

import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import { it, expect, beforeEach, afterEach } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { createTempProject, runScript } from '../../helpers';
import type { TempProject } from '../../helpers/temp-project';

const SCRIPT = '.claude/scripts/migrate-legacy-state.js';
const FIXTURES_DIR = fileURLToPath(new URL('../../fixtures/legacy-state/', import.meta.url));

const STATE_REL = 'generated-docs/context/workflow-state.json';
const BACKUP_REL = 'generated-docs/context/workflow-state.legacy-backup.json';

interface MigrationResult {
  status: string;
  changes: Array<{ kind: string }>;
  warnings: string[];
  migrated?: Record<string, any>;
}

function run(root: string, args: string[]) {
  return runScript(SCRIPT, ['--root', root, ...args], { cwd: root, scriptLocation: 'repo' });
}

function copyFixtureState(project: TempProject, fixtureName: string) {
  project.write(STATE_REL, fs.readFileSync(path.join(FIXTURES_DIR, fixtureName)));
}

describe('migrate-legacy-state.js — detection', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject({ copyScripts: false, prefix: 'migrate-legacy' }); });
  afterEach(() => { project.cleanup(); });

  it('detects legacy currentPhase (DESIGN → state-rewrite)', () => {
    copyFixtureState(project, 'run-24-intake-state.json');
    const r = run(project.root, []);
    expect(r.exitCode, r.stderr).toBe(0);
    const res = r.json<MigrationResult>();
    expect(res.status).toBe('legacy_detected');
    expect(res.changes.some((c) => c.kind === 'state-rewrite')).toBe(true);
  });

  it('detects legacy story phases (REALIGN/QA)', () => {
    copyFixtureState(project, 'run-12-state.json');
    const res = run(project.root, []).json<MigrationResult>();
    expect(res.status).toBe('legacy_detected');
  });

  it('detects FRS without brief (spec-copy)', () => {
    project.write('generated-docs/specs/feature-requirements.md', '# FRS\n\nSome requirements.\n');
    const res = run(project.root, []).json<MigrationResult>();
    expect(res.status).toBe('legacy_detected');
    expect(res.changes.some((c) => c.kind === 'spec-copy')).toBe(true);
  });

  it('reports no_legacy when nothing exists', () => {
    const res = run(project.root, []).json<MigrationResult>();
    expect(res.status).toBe('no_legacy');
  });

  it('reports no_migration_needed for an already-migrated state', () => {
    project.write(STATE_REL, JSON.stringify({
      featureName: 'something', currentPhase: 'BUILD', phaseStatus: 'ready', epics: {}, featureComplete: false,
    }));
    project.write('generated-docs/specs/project-brief.md', '# Brief');
    const res = run(project.root, []).json<MigrationResult>();
    expect(res.status).toBe('no_migration_needed');
  });
});

describe('migrate-legacy-state.js — fixture-driven migration output', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject({ copyScripts: false, prefix: 'migrate-legacy' }); });
  afterEach(() => { project.cleanup(); });

  it('run-12: REALIGN currentPhase → BUILD, in-progress story → PENDING', () => {
    copyFixtureState(project, 'run-12-state.json');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.currentPhase).toBe('BUILD');
    expect(migrated.epics['2'].stories['4'].phase).toBe('PENDING');
    expect(migrated.epics['1'].stories['1'].phase).toBe('COMPLETE');
  });

  it('run-12: completed stories get synthesized e2e/manual fields with warnings', () => {
    copyFixtureState(project, 'run-12-state.json');
    const res = run(project.root, []).json<MigrationResult>();
    const story = res.migrated!.epics['1'].stories['1'];
    expect(story.e2eStatus).toBe('passed');
    expect(story.manualVerification).toBe('passed');
    expect(res.warnings.some((w) => w.includes('Epic 1 story 1') && w.includes('e2eStatus'))).toBe(true);
  });

  it('run-23: QA currentPhase → BUILD, completed stories preserve fields', () => {
    copyFixtureState(project, 'run-23-state.json');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.currentPhase).toBe('BUILD');
    expect(migrated.epics['1'].stories['1'].e2eStatus).toBe('passed-after-fix');
    expect(migrated.epics['1'].stories['1'].manualVerification).toBe('passed');
    expect(migrated.epics['1'].stories['3'].phase).toBe('PENDING');
  });

  it('run-23: design and designArtifacts blocks are dropped with warnings', () => {
    copyFixtureState(project, 'run-23-state.json');
    const res = run(project.root, []).json<MigrationResult>();
    expect(res.migrated!.design).toBeUndefined();
    expect(res.migrated!.designArtifacts).toBeUndefined();
    expect(res.warnings.some((w) => w.includes('design'))).toBe(true);
    expect(res.warnings.some((w) => w.includes('designArtifacts'))).toBe(true);
  });

  it('run-23: intake.frsExists renamed to briefExists', () => {
    copyFixtureState(project, 'run-23-state.json');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.intake.briefExists).toBe(true);
    expect(migrated.intake.frsExists).toBeUndefined();
  });

  it('run-23: epic.phase STORIES → PENDING', () => {
    copyFixtureState(project, 'run-23-state.json');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.epics['1'].phase).toBe('PENDING');
  });

  it('run-24-intake: SCOPE currentPhase → PLAN', () => {
    copyFixtureState(project, 'run-24-intake-state.json');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.currentPhase).toBe('PLAN');
  });

  it('run-24-playwright: round-trip apply → restore', () => {
    copyFixtureState(project, 'run-24-playwright-state.json');
    const originalContent = project.read(STATE_REL);

    const applyRes = run(project.root, ['--apply']);
    expect(applyRes.exitCode, applyRes.stderr).toBe(0);
    expect(applyRes.json<MigrationResult>().status).toBe('applied');
    expect(project.exists(BACKUP_REL)).toBe(true);

    // State on disk now reflects the new schema.
    expect(JSON.parse(project.read(STATE_REL)).currentPhase).toBe('BUILD');

    // Restore reverts to the original bytes and removes the backup.
    const restoreRes = run(project.root, ['--restore']);
    expect(restoreRes.exitCode, restoreRes.stderr).toBe(0);
    expect(restoreRes.json<MigrationResult>().status).toBe('restored');
    expect(project.read(STATE_REL)).toBe(originalContent);
    expect(project.exists(BACKUP_REL)).toBe(false);
  });
});

describe('migrate-legacy-state.js — spec copy', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject({ copyScripts: false, prefix: 'migrate-legacy' }); });
  afterEach(() => { project.cleanup(); });

  it('--apply copies FRS to brief with a migration header', () => {
    const frsBody = '# Feature Requirements\n\n- R1: Something\n';
    project.write('generated-docs/specs/feature-requirements.md', frsBody);
    const res = run(project.root, ['--apply']);
    expect(res.json<MigrationResult>().status).toBe('applied');
    const brief = project.read('generated-docs/specs/project-brief.md');
    expect(brief.startsWith('<!-- Migrated from feature-requirements.md')).toBe(true);
    expect(brief.includes(frsBody)).toBe(true);
  });

  it('--apply skips FRS copy if brief already exists, with a warning', () => {
    // The legacy state gives the migration a reason to run; the spec-coexistence
    // warning only surfaces when there is already other work to migrate.
    copyFixtureState(project, 'run-23-state.json');
    project.write('generated-docs/specs/feature-requirements.md', '# FRS');
    project.write('generated-docs/specs/project-brief.md', '# Existing brief');
    const res = run(project.root, ['--apply']).json<MigrationResult>();
    expect(project.read('generated-docs/specs/project-brief.md')).toBe('# Existing brief');
    expect(res.warnings.some((w) => w.includes('Both feature-requirements.md and project-brief.md exist'))).toBe(true);
  });

  it('--restore removes only a migration-header brief, leaving a user-edited brief', () => {
    copyFixtureState(project, 'run-24-playwright-state.json');
    project.write('generated-docs/specs/feature-requirements.md', '# FRS body\n');
    run(project.root, ['--apply']);
    project.write('generated-docs/specs/project-brief.md', '# User-edited brief\n');

    const restoreRes = run(project.root, ['--restore']).json<MigrationResult>();
    expect(project.exists('generated-docs/specs/project-brief.md')).toBe(true);
    expect(restoreRes.warnings.some((w) => w.includes('does not carry the migration header'))).toBe(true);
  });
});

describe('migrate-legacy-state.js — edge cases', () => {
  let project: TempProject;
  beforeEach(() => { project = createTempProject({ copyScripts: false, prefix: 'migrate-legacy' }); });
  afterEach(() => { project.cleanup(); });

  it('--restore with no backup exits 1', () => {
    const r = run(project.root, ['--restore']);
    expect(r.exitCode).toBe(1);
  });

  it('warns on an existing backup during a second apply', () => {
    copyFixtureState(project, 'run-23-state.json');
    run(project.root, ['--apply']);
    // After the first apply, state is on the 4-phase model, so a second --apply
    // would be a no-op. Forge a fresh legacy state next to the existing backup to
    // exercise the warning path.
    copyFixtureState(project, 'run-12-state.json');
    const res = run(project.root, ['--apply']).json<MigrationResult>();
    expect(res.warnings.some((w) => w.includes('Backup') && w.includes('already exists'))).toBe(true);
  });

  it('a second apply over an existing backup reports status "skipped", not "applied"', () => {
    copyFixtureState(project, 'run-23-state.json');
    run(project.root, ['--apply']);
    copyFixtureState(project, 'run-12-state.json');
    const before = project.read(STATE_REL);
    const res = run(project.root, ['--apply']).json<MigrationResult>();
    expect(res.status).toBe('skipped');
    expect(project.read(STATE_REL)).toBe(before);
  });

  it('integration tests are counted once, not double-counted', () => {
    copyFixtureState(project, 'run-12-state.json');
    // run-12 has epic 1 / story 1 COMPLETE. A single integration test lives under
    // the integration/ subdir of __tests__ — it must contribute testFiles=1, not 2.
    project.write('web/src/__tests__/integration/epic-1-story-1-foo.test.tsx', 'test("x", () => {});\n');
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.epics['1'].stories['1'].testFiles).toBe(1);
  });

  it('a present-but-falsy completion field (e2eStatus: "") is preserved, not synthesized over', () => {
    copyFixtureState(project, 'run-12-state.json');
    const state = JSON.parse(project.read(STATE_REL));
    state.epics['1'].stories['1'].e2eStatus = ''; // present but falsy — real data
    project.write(STATE_REL, JSON.stringify(state, null, 2));
    const migrated = run(project.root, []).json<MigrationResult>().migrated!;
    expect(migrated.epics['1'].stories['1'].e2eStatus).toBe('');
  });

  it('AC count is synthesized from the story file when available', () => {
    copyFixtureState(project, 'run-12-state.json');
    project.write(
      'generated-docs/stories/epic-1-foo/story-1-bar.md',
      '# Story 1\n\n## Acceptance Criteria\n\n- [x] AC-1: thing\n- [x] AC-2: other\n- [x] AC-3: third\n',
    );
    const story = run(project.root, []).json<MigrationResult>().migrated!.epics['1'].stories['1'];
    expect(story.acceptance.total).toBe(3);
    expect(story.acceptance.checked).toBe(3);
  });
});
