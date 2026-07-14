/**
 * loadCheckpoint() — apply a named starting state (CP-0..CP-5) to a temp project.
 *
 * Rather than running the full workflow to reach each checkpoint (slow, requires
 * Claude), we seed the minimum files each checkpoint requires. This is enough for
 * mechanical tests of scripts that read state + artifacts.
 *
 * Checkpoints follow the epic-branch model, for a single active epic checked out
 * on its `epic/<slug>` branch (the files are seeded into the working tree — a test
 * that needs a real git branch wraps this with gitSandbox()). Uses the make-believe
 * Team Task Manager epic "task-browsing".
 *
 * If you need a genuinely realistic CP-N state, harvest a real run's generated-docs/
 * tree into fixtures/checkpoints/CP-N.tar and load it instead.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { seedProjectMd, seedEpicPlan, seedEpicState, seedStoryFile } from './state-fixtures';

export type CheckpointId = 'CP-0' | 'CP-1' | 'CP-2' | 'CP-3' | 'CP-4' | 'CP-5';

const SLUG = 'task-browsing';

/** Human-readable description of each checkpoint. */
export const CHECKPOINT_DESCRIPTIONS: Record<CheckpointId, string> = {
  'CP-0': 'Clean project on main, nothing started',
  'CP-1': 'INTAKE done — project.md and epic-plan.md approved on main',
  'CP-2': 'PLAN done — the epic branch exists with an approved story list',
  'CP-3': 'BUILD in progress — at least one story committed',
  'CP-4': 'EPIC-END passed / MANUAL-TEST reached',
  'CP-5': 'Epic merged into main (COMPLETE)',
};

function seedProjectFacts(root: string): void {
  seedProjectMd(root);
  seedEpicPlan(root, [
    { slug: SLUG, name: 'Task Browsing', goal: 'View and filter the task list' },
    { slug: 'task-actions', name: 'Task Actions', goal: 'Create, edit, and delete tasks', dependsOn: [SLUG] },
  ]);
}

function seedStories(root: string): void {
  seedStoryFile(root, { slug: SLUG, index: 1, title: 'View the task list' });
  seedStoryFile(root, { slug: SLUG, index: 2, title: 'Empty state' });
}

export function loadCheckpoint(root: string, id: CheckpointId): void {
  // If a tarball fixture exists, prefer it (a real harvested run).
  const tarPath = path.resolve(__dirname, '..', 'fixtures', 'checkpoints', `${id}.tar`);
  if (fs.existsSync(tarPath)) {
    const res = spawnSync('tar', ['-xf', tarPath, '-C', root], { encoding: 'utf8' });
    if (res.status === 0) return;
    // Fall through to synthetic checkpoint on tar failure.
  }

  switch (id) {
    case 'CP-0':
      // Fresh project — nothing seeded.
      break;

    case 'CP-1':
      // INTAKE done — shared facts + the epic plan approved on main.
      seedProjectFacts(root);
      break;

    case 'CP-2':
      // PLAN done — the epic's story list approved; state at PLAN.
      seedProjectFacts(root);
      seedStories(root);
      seedEpicState(root, {
        slug: SLUG,
        name: 'Task Browsing',
        phase: 'PLAN',
        stories: { '1': 'pending', '2': 'pending' },
      });
      break;

    case 'CP-3':
      // BUILD in progress — story 1 complete, story 2 in progress.
      seedProjectFacts(root);
      seedStories(root);
      seedEpicState(root, {
        slug: SLUG,
        name: 'Task Browsing',
        phase: 'BUILD',
        stories: {
          '1': { status: 'complete', commit: 'abc1234' },
          '2': { status: 'in-progress' },
        },
      });
      break;

    case 'CP-4':
      // EPIC-END passed → MANUAL-TEST: all stories built, browser tests passed.
      seedProjectFacts(root);
      seedStories(root);
      seedEpicState(root, {
        slug: SLUG,
        name: 'Task Browsing',
        phase: 'MANUAL-TEST',
        stories: {
          '1': { status: 'complete', commit: 'abc1234', e2eStatus: 'passed' },
          '2': { status: 'complete', commit: 'def5678', e2eStatus: 'passed' },
        },
      });
      break;

    case 'CP-5':
      // Merged into main — the epic record is frozen at COMPLETE.
      seedProjectFacts(root);
      seedStories(root);
      seedEpicState(root, {
        slug: SLUG,
        name: 'Task Browsing',
        phase: 'COMPLETE',
        stories: {
          '1': { status: 'complete', commit: 'abc1234', e2eStatus: 'passed' },
          '2': { status: 'complete', commit: 'def5678', e2eStatus: 'passed' },
        },
      });
      break;

    default:
      throw new Error(`Unknown checkpoint: ${id satisfies never}`);
  }
}
