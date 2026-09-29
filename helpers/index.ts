/** Barrel exports — import everything from @helpers. */

export { createTempProject, REPO_ROOT } from './temp-project';
export type { TempProject, CreateTempProjectOptions } from './temp-project';

// Standalone-target resolution: where the .claude/ template under test lives,
// whether it's present, and the gate for template-dependent suites.
export { TARGET_ROOT, TEMPLATE_DIR, TEMPLATE_PRESENT, TEMPLATE_REF, NO_TEMPLATE_REASON } from './target';
export { describeTemplate } from './describe-template';

export { rollback } from './rollback';
export type { RollbackId, RollbackOptions } from './rollback';

export {
  seedEpicState,
  readEpicState,
  seedProjectMd,
  seedEpicPlan,
  seedStoryFile,
  seedLegacyState,
} from './state-fixtures';
export type {
  EpicPhase,
  StoryStatus,
  E2eStatus,
  StorySeed,
  EpicState,
  PlanEpic,
} from './state-fixtures';

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

export { loadGoldenRun } from './golden-run';
export type { GoldenRun } from './golden-run';

// INTAKE `## Project Overview` analysis — pure, string-only; shared across Tier 1/2/3.
export {
  PLACEHOLDER,
  POINTER_TARGETS,
  resolveShippedUserFile,
  extractSection,
  countWords,
  withinBudget,
  LINE_BUDGET,
  WORD_BUDGET,
  isPointerLine,
  pointersIn,
  analyzeStructure,
  neverPresentTokenLeaks,
  parseOverviewRoles,
  parseProjectRoles,
  roleSetEquals,
  claimsClosedList,
  sectionSpan,
  criticalRulesAndPoliciesUnchanged,
  auditOverview,
} from './project-overview';
export type { ShippedUserFile, Section, Budget, Structure, Leak, OverviewAudit } from './project-overview';
