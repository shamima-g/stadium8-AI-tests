/**
 * Single-source schema for generated-docs/context/workflow-state.json.
 *
 * The set of valid `currentPhase` values is NOT hand-maintained here. It is
 * imported from the template's own phase constant —
 * `.claude/scripts/lib/workflow-helpers.js` → `ALL_PHASES` — which is the exact
 * list `transition-phase.js` validates transitions against. Add or rename a
 * phase there and this schema follows automatically, so the QA suite can no
 * longer drift from the producer (the drift that previously left the old
 * 9-phase names enumerated here long after the workflow became 4-phase).
 *
 * Note on `'NONE'`: it is a transient read-fallback inside transition-phase.js,
 * never written to disk as `currentPhase`, so it is intentionally absent from
 * `ALL_PHASES` and from this enum.
 *
 * Why only this schema is single-sourced (and not intake-manifest's): the
 * workflow-state shape has a deterministic code producer that owns the phase
 * list. The intake manifest is produced by the intake-agent (an LLM prompt) and
 * its enums have no single template constant to derive from, so its schema in
 * this folder remains the authored spec rather than a mirror.
 */

import { createRequire } from 'node:module';
import path from 'node:path';
import { TARGET_ROOT, TEMPLATE_PRESENT } from '../target';

const require = createRequire(import.meta.url);

// Single source of truth for the phase list — but only when a template is
// present. When QA-TESTS runs standalone with no .claude/, importing this module
// must not throw; the workflow-state schema test is skipped in that case
// (describeTemplate), so the empty fallback is never exercised.
const ALL_PHASES: string[] = TEMPLATE_PRESENT
  ? (require(path.join(TARGET_ROOT, '.claude', 'scripts', 'lib', 'workflow-helpers.js')) as { ALL_PHASES: string[] }).ALL_PHASES
  : [];

/**
 * The phases the producer (`transition-phase.js`) can persist as
 * `state.currentPhase`. Re-exported so tests iterate the same single source.
 */
export const VALID_PERSISTED_PHASES: readonly string[] = [...ALL_PHASES];

export const workflowStateSchema: Record<string, unknown> = {
  $schema: 'http://json-schema.org/draft-07/schema#',
  $id: 'https://stadium-software.internal/schemas/workflow-state.json',
  title: 'Workflow State',
  description:
    'Shape of generated-docs/context/workflow-state.json produced by ' +
    '.claude/scripts/transition-phase.js. The currentPhase enum is derived from ' +
    'workflow-helpers.ALL_PHASES — do not hand-edit it here.',
  type: 'object',
  additionalProperties: true,
  required: ['currentPhase'],
  properties: {
    // Null when INTAKE is initialised before a project brief exists
    // (transition-phase.js initState sets featureName to null in that case).
    featureName: { type: ['string', 'null'] },
    currentPhase: { type: 'string', enum: [...ALL_PHASES] },
    currentEpic: { type: ['integer', 'null'], minimum: 1 },
    currentStory: { type: ['integer', 'null'], minimum: 1 },
    phaseStatus: { type: 'string', enum: ['ready', 'in_progress', 'paused', 'complete'] },
    featureComplete: { type: 'boolean' },
    totalEpics: { type: 'integer', minimum: 0 },
    epics: { type: 'object' },
    lastUpdated: { type: 'string', format: 'date-time' },
    pausedAt: { type: ['string', 'null'], format: 'date-time' },
    intakeRoute: { type: 'string', enum: ['docs', 'prototype', 'qa'] },
  },
};
