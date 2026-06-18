/** Barrel exports — import everything from @helpers. */

export { createTempProject, REPO_ROOT } from './temp-project';
export type { TempProject, CreateTempProjectOptions } from './temp-project';

// Standalone-target resolution: where the .claude/ template under test lives,
// whether it's present, and the gate for template-dependent suites.
export { TARGET_ROOT, TEMPLATE_DIR, TEMPLATE_PRESENT, NO_TEMPLATE_REASON } from './target';
export { describeTemplate } from './describe-template';

export { rollback } from './rollback';
export type { RollbackId, RollbackOptions } from './rollback';

export { seedState, readState, seedArtifact } from './state-fixtures';
export type { Phase, WorkflowState } from './state-fixtures';

export { seedManifest, readManifest } from './manifest-fixtures';
export type { IntakeManifest, ArtifactEntry } from './manifest-fixtures';

export { runScript } from './run-script';
export type { ScriptResult, RunScriptOptions } from './run-script';

export { gitSandbox } from './git-sandbox';
export type { GitSandbox } from './git-sandbox';

export { normalise } from './snapshot';
export type { NormaliseOptions } from './snapshot';

export { loadCheckpoint, CHECKPOINT_DESCRIPTIONS } from './checkpoint-fixtures';
export type { CheckpointId } from './checkpoint-fixtures';
