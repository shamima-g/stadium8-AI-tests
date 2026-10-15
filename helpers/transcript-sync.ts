/**
 * Helpers for the session-recording / transcript-collection acceptance tests.
 *
 * The feature lives in the TARGET template (`.claude/hooks/transcript-sync-hook.js`,
 * `.claude/scripts/transcript-sync.js`, `.claude/scripts/lib/transcript-sync-core.js`). These helpers run
 * that target code over a throwaway project, with every side-effect redirected to temp dirs via env, so the
 * tests never touch the real `~/.stadium-builder` or the network:
 *   - STADIUM_BUILDER_HOME → a temp home (notices.json / device.json / state / lock / log)
 *   - STADIUM_RECEIVER_URL → controls whether collection is configured (default constant = on; '' = inert)
 *   - CLAUDE_CODE_ENTRYPOINT → interactive ('') vs headless ('sdk'/'print'/…)
 *   - CLAUDE_PROJECT_DIR (set by run-script to cwd) → the hook's project root
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import crypto from 'node:crypto';
import { createRequire } from 'node:module';
import { TARGET_ROOT, TEMPLATE_PRESENT } from './target';
import { runScript, type ScriptResult } from './run-script';

export const HOOK_REL = '.claude/hooks/transcript-sync-hook.js';
export const CLI_REL = '.claude/scripts/transcript-sync.js';
export const CORE_REL = '.claude/scripts/lib/transcript-sync-core.js';
export const NOTICE_REL = '.claude/shared/transcript-notice.md';
export const HELP_REL = '.template-docs/users/Help/Session-Recording.md';
export const STATUS_CMD_REL = '.claude/commands/status.md';
export const START_CMD_REL = '.claude/commands/start.md';

/** The transcript-sync surface is present in the target template (feature-detect: skip when absent). */
export const PRESENT =
  TEMPLATE_PRESENT &&
  fs.existsSync(path.join(TARGET_ROOT, HOOK_REL)) &&
  fs.existsSync(path.join(TARGET_ROOT, CLI_REL));

export function uuid(): string {
  return crypto.randomUUID();
}

/** Read a file from the target template as text. */
export function targetFile(rel: string): string {
  return fs.readFileSync(path.join(TARGET_ROOT, rel), 'utf8');
}

/** A throwaway STADIUM_BUILDER_HOME so notices/device/state never touch the real machine. */
export function freshHome(): { home: string; cleanup: () => void } {
  const home = fs.mkdtempSync(path.join(os.tmpdir(), 'sbhome-'));
  return { home, cleanup: () => { try { fs.rmSync(home, { recursive: true, force: true }); } catch { /* best effort */ } } };
}

export interface HookEnv {
  home: string;
  /** STADIUM_RECEIVER_URL; omit for the shipped default (configured); '' for inert. */
  receiverUrl?: string | null;
  /** CLAUDE_CODE_ENTRYPOINT; omit/'' = interactive; 'sdk'/'print' = headless. */
  entrypoint?: string;
}

function buildEnv(e: HookEnv): NodeJS.ProcessEnv {
  const env: NodeJS.ProcessEnv = { STADIUM_BUILDER_HOME: e.home, CLAUDE_CODE_ENTRYPOINT: e.entrypoint ?? '' };
  if (e.receiverUrl !== undefined) env.STADIUM_RECEIVER_URL = e.receiverUrl ?? '';
  return env;
}

/** Fire the UserPromptSubmit/Stop hook over a temp project; returns the parsed result. */
export function runHook(cwd: string, input: Record<string, unknown>, e: HookEnv): ScriptResult {
  return runScript(HOOK_REL, [], { cwd, input: JSON.stringify(input), env: buildEnv(e) });
}

/**
 * Run the transcript-sync CLI (e.g. ['--status']) over a temp project. We pass `--root <cwd>` exactly as the
 * hook does in production (`spawn(... '--root', root)`), because the CLI otherwise resolves its root from the
 * script's own location — which, in THIS harness, is the target checkout, not the temp project under test.
 *
 * Consequence: the no-`--root` path production `/status` uses (getProjectRoot() co-located with the project) is
 * NOT exercised here — it can't be, since the harness runs the target's script over a separate tree. That
 * resolution is covered by the feature's own shipped unit tests; here we verify statusLine logic for a given root.
 */
export function runCli(cwd: string, args: string[], e: HookEnv): ScriptResult {
  return runScript(CLI_REL, [...args, '--root', cwd], { cwd, env: buildEnv(e) });
}

/** A UserPromptSubmit payload with a fresh (or given) session id. */
export function userPrompt(sessionId: string = uuid(), prompt = 'hello'): Record<string, unknown> {
  return { hook_event_name: 'UserPromptSubmit', session_id: sessionId, prompt };
}

/**
 * A Stop payload for a session. `lastAssistantMessage` is Claude's final reply text (the hook's first proof
 * route); `transcriptPath`, when given, is the session transcript the hook falls back to (the second route,
 * `claudeTextInTranscript`) — pass '' for the message to force the transcript route.
 */
export function stop(
  sessionId: string,
  lastAssistantMessage = '',
  transcriptPath?: string
): Record<string, unknown> {
  const payload: Record<string, unknown> = {
    hook_event_name: 'Stop',
    session_id: sessionId,
    last_assistant_message: lastAssistantMessage,
  };
  if (transcriptPath) payload.transcript_path = transcriptPath;
  return payload;
}

/**
 * The `additionalContext` the hook asks Claude to show (the redesigned notice channel), or '' when the hook
 * emitted nothing. The notice is carried here — NOT as a `systemMessage`, which the VS Code extension receives
 * but never displays.
 */
export function additionalContext(res: ScriptResult): string {
  const out = (res.parsedJson as { hookSpecificOutput?: { additionalContext?: string } })?.hookSpecificOutput;
  return out?.additionalContext ?? '';
}

/** Load the target's transcript-sync-core module in-process (for fetch-injection gating tests). */
export function loadCore(): {
  createCore: (deps?: Record<string, unknown>) => Record<string, any>;
  COLLECTION_FILE: string;
} {
  const req = createRequire(__filename);
  return req(path.join(TARGET_ROOT, CORE_REL));
}
