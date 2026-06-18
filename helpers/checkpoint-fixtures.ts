/**
 * loadCheckpoint() — apply a named starting state (CP-0..CP-4) to a temp project.
 *
 * Rather than running the full workflow to reach each checkpoint (slow, requires
 * Claude), we seed the minimum files each checkpoint requires. This is enough
 * for mechanical tests of scripts that read state + artifacts.
 *
 * Checkpoints follow the 4-phase model: INTAKE → PLAN → BUILD → COMPLETE.
 *
 * If you need a genuinely realistic CP-N state (e.g. for snapshot tests that
 * verify the dashboard renders correctly), harvest a real run's generated-docs/
 * tree into fixtures/checkpoints/CP-N.tar and load it instead.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { seedState } from './state-fixtures';
import { seedManifest } from './manifest-fixtures';
import { seedArtifact } from './state-fixtures';

export type CheckpointId = 'CP-0' | 'CP-1' | 'CP-2' | 'CP-3' | 'CP-4';

/** Human-readable description of each checkpoint, mirroring TEST-GUIDE.md. */
export const CHECKPOINT_DESCRIPTIONS: Record<CheckpointId, string> = {
  'CP-0': 'Clean repo, no workflow started',
  'CP-1': 'INTAKE complete — project brief approved',
  'CP-2': 'PLAN complete — epics and stories approved',
  'CP-3': 'BUILD in progress — at least one story committed',
  'CP-4': 'Feature COMPLETE',
};

export function loadCheckpoint(root: string, id: CheckpointId): void {
  // If a tarball fixture exists, prefer it
  const tarPath = path.resolve(__dirname, '..', 'fixtures', 'checkpoints', `${id}.tar`);
  if (fs.existsSync(tarPath)) {
    const res = spawnSync('tar', ['-xf', tarPath, '-C', root], { encoding: 'utf8' });
    if (res.status === 0) return;
    // Fall through to synthetic checkpoint on tar failure
  }

  // Synthetic checkpoint — minimum files to pass validate-phase-output.js
  switch (id) {
    case 'CP-0':
      // Nothing — fresh project
      break;

    case 'CP-1':
      // INTAKE complete — project brief approved
      seedManifest(root);
      seedArtifact(root, 'brief');
      seedState(root, { currentPhase: 'INTAKE', phaseStatus: 'complete' });
      break;

    case 'CP-2':
      // PLAN complete — epics and stories approved for Epic 1
      seedManifest(root);
      seedArtifact(root, 'brief');
      seedArtifact(root, 'feature-overview');
      seedArtifact(root, 'epic-overview', undefined, { epicNum: 1, slug: 'browsing' });
      seedArtifact(root, 'story', undefined, { epicNum: 1, storyNum: 1, slug: 'browsing' });
      seedArtifact(root, 'story', undefined, { epicNum: 1, storyNum: 2, slug: 'browsing' });
      seedState(root, {
        currentPhase: 'PLAN',
        currentEpic: 1,
        phaseStatus: 'complete',
        totalEpics: 2,
      });
      break;

    case 'CP-3':
      // BUILD in progress — Story 1 built, its tests and page exist
      loadCheckpoint(root, 'CP-2');
      fs.mkdirSync(path.join(root, 'web', 'src', '__tests__'), { recursive: true });
      fs.writeFileSync(
        path.join(root, 'web', 'src', '__tests__', 'epic-1-story-1.test.tsx'),
        `import { describe, it, expect } from 'vitest';\ndescribe('story 1', () => { it('renders', () => { expect(true).toBe(true); }); });\n`
      );
      fs.mkdirSync(path.join(root, 'web', 'src', 'app', 'tasks'), { recursive: true });
      fs.writeFileSync(
        path.join(root, 'web', 'src', 'app', 'tasks', 'page.tsx'),
        `export default function TasksPage() { return <div>Tasks</div>; }\n`
      );
      seedState(root, {
        currentPhase: 'BUILD',
        currentEpic: 1,
        currentStory: 2,
        phaseStatus: 'in_progress',
        totalEpics: 2,
      });
      break;

    case 'CP-4':
      // Feature COMPLETE
      loadCheckpoint(root, 'CP-3');
      seedState(root, {
        currentPhase: 'COMPLETE',
        currentEpic: 2,
        phaseStatus: 'complete',
        featureComplete: true,
        totalEpics: 2,
      });
      break;

    default:
      throw new Error(`Unknown checkpoint: ${id satisfies never}`);
  }
}
