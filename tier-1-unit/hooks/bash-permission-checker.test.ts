/**
 * Tests for .claude/hooks/bash-permission-checker.js
 *
 * Security-critical. The hook receives JSON on stdin describing a proposed
 * Bash tool call and responds by:
 *  - Exit 0 with no output → fallthrough (normal permission prompt)
 *  - Exit 0 with "allow" → auto-approved
 *  - Exit 2 → denied
 *
 * Table-driven test covers the real deny/allow matrix (the enumerated dangerous
 * commands are hard-asserted to DENY) plus an adversarial fuzz suite — whitespace,
 * split/long flags, shell wrappers, command chains, and encoded (base64/hex/octal)
 * payloads — each asserted only to never be auto-APPROVED (fallthrough to a human
 * prompt is acceptable; auto-approving any of them would be the security bug).
 */

import { it, expect } from 'vitest';
import { describeTemplate as describe } from '../../helpers';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';

const HOOK = path.join(REPO_ROOT, '.claude', 'hooks', 'bash-permission-checker.js');

type Expected = 'allow' | 'deny' | 'fallthrough';

function runHook(command: string): { actual: Expected; raw: string; stderr: string; exitCode: number } {
  const input = JSON.stringify({ tool_name: 'Bash', tool_input: { command } });
  const res = spawnSync('node', [HOOK], {
    input,
    encoding: 'utf8',
    timeout: 10_000,
    stdio: ['pipe', 'pipe', 'pipe'],
  });
  const stdout = (res.stdout ?? '').toString();
  const stderr = (res.stderr ?? '').toString();
  const exitCode = typeof res.status === 'number' ? res.status : 1;

  let actual: Expected;
  if (exitCode === 2) {
    actual = 'deny';
  } else if (exitCode === 0) {
    actual = stdout.includes('allow') ? 'allow' : 'fallthrough';
  } else {
    actual = 'fallthrough'; // weird exit — treat as non-decisive
  }
  return { actual, raw: stdout, stderr, exitCode };
}

describe('bash-permission-checker — deny matrix', () => {
  // Drawn from .claude/settings.json deny rules (see workflow-tests.md §6 — permission-hook fuzzing).
  const DENY_CASES: Array<[string, string]> = [
    ['rm -rf /',                                  'deny path'],
    ['rm -rf /*',                                 'deny path with wildcard'],
    ['cat ~/.ssh/id_rsa',                         'ssh private key'],
    ['cat /root/.ssh/id_rsa',                     'ssh private key absolute'],
    ['type id_rsa.pem',                           'ssh key via Windows type'],
    ['Get-Content id_rsa',                        'ssh key via PowerShell Get-Content'],
    ['cat mykey.pem',                             '.pem via cat'],
    ['sed -n 1p credentials',                     'credentials via sed'],
    ['grep password credentials.json',            'credentials file'],
  ];

  it.each(DENY_CASES)('FAIL safely (must deny): %s — %s', (command) => {
    const { actual } = runHook(command);
    expect(actual).toBe('deny');
  });
});

describe('bash-permission-checker — allow matrix', () => {
  // Auto-approved commands. Per .claude/settings.json.
  const ALLOW_CASES: Array<[string, string]> = [
    ['node .claude/scripts/transition-phase.js --show', 'node running a claude script'],
    ['node .claude/scripts/copy-with-header.js --from a --to b', 'copy-with-header'],
    ['git pull',                                         'git pull is always auto-approved'],
    ['git add generated-docs/',                          'git add scoped to generated-docs'],
  ];

  it.each(ALLOW_CASES)('PASS: allow %s — %s', (command) => {
    const { actual } = runHook(command);
    // Allow OR fallthrough is acceptable — never deny
    expect(['allow', 'fallthrough']).toContain(actual);
  });
});

describe('bash-permission-checker — fuzz (adversarial input)', () => {
  // Variants of rm -rf / that might slip through naive regex
  const FUZZ_CASES: string[] = [
    'rm -rf /',
    'rm  -rf  /',                     // extra whitespace
    'rm -r -f /',                     // split flags
    'rm --recursive --force /',       // long flags
    'rm -rf ~',                       // home dir — sometimes allowed, sometimes not
    'rm -rf $HOME',                   // env expansion
    '/bin/rm -rf /',                  // absolute path
    'sudo rm -rf /',                  // sudo prefix
    'bash -c "rm -rf /"',             // shell invocation
    'eval "rm -rf /"',                // eval
    ' rm -rf /',                      // leading space
    'cat ~/.ssh/id_rsa && true',      // command chain
    'true || cat /etc/shadow',        // command chain
    // Encoded payloads — the destructive command is disguised so a literal-string matcher can't
    // see it. The hook is not expected to DECODE these (that's why fallthrough is acceptable), but
    // it must never auto-APPROVE them either.
    'echo cm0gLXJmIC8= | base64 -d | sh',                     // base64 of "rm -rf /"
    "printf '\\x72\\x6d\\x20\\x2d\\x72\\x66\\x20\\x2f' | sh",  // hex-escaped "rm -rf /"
    "echo -e '\\162\\155 -rf /' | sh",                        // octal-escaped "rm"
    'eval "$(echo cm0gLXJmIH4= | base64 -d)"',                // base64 of "rm -rf ~" via eval
  ];

  it.each(FUZZ_CASES)('FAIL: must not ALLOW %s outright', (command) => {
    const { actual } = runHook(command);
    // "fallthrough" is acceptable (lets Claude Code's permission prompt handle it).
    // "deny" is ideal for destructive variants.
    // "allow" would be a security bug — auto-approving these.
    expect(actual).not.toBe('allow');
  });
});

describe('bash-permission-checker — worktree + force-push (v1.2.0)', () => {
  // v1.2.0 added the /plan parallel-planning flow, which does its git work in a
  // throwaway worktree and lands plans on main via `git push origin HEAD:main`
  // (epic-branch-concurrency.md §6.1). The checker gained worktree allow-rules and
  // hardened the force-push denials. These cases pin that behaviour; they assert the
  // v1.2.0 shape (test an older template with the matching-version suite — Layer D).

  // Good: the worktree + safe-push commands the main-landing write relies on.
  const ALLOW_CASES: Array<[string, string]> = [
    ['git worktree add -b main-change/x ../tmp origin/main', 'worktree add for the main-landing write'],
    ['git worktree remove ../tmp',                           'worktree remove (bare path)'],
    ['git worktree list',                                    'worktree list (read-only)'],
    ['git worktree prune',                                   'worktree prune (cleanup)'],
    ['git push --force-with-lease origin epic/x',            'force-with-lease scoped to epic/*'],
    ['npm run test:e2e:install',                             'multi-segment npm script'],
    ['npm run test:e2e:ui',                                  'multi-segment npm script'],
  ];
  it.each(ALLOW_CASES)('PASS: does not deny %s — %s', (command) => {
    expect(runHook(command).actual).not.toBe('deny');
  });

  // Broken-safe: force / destructive pushes MUST be denied — including a +refspec,
  // which is a force push spelled without a flag (newly caught in v1.2.0).
  const DENY_CASES: Array<[string, string]> = [
    ['git push origin +epic/x',            'force via +refspec'],
    ['git push -f origin main',            'force via -f'],
    ['git push origin --force',            'force via --force'],
    ['git push origin --delete topic',     'remote branch delete'],
    ['git push --no-verify origin epic/x', 'bypasses pre-push hooks'],
  ];
  it.each(DENY_CASES)('FAIL safely (must deny): %s — %s', (command) => {
    expect(runHook(command).actual).toBe('deny');
  });

  // Broken: a destructive worktree op (--force can discard or duplicate a tree) must
  // NOT auto-approve — it falls through to a human prompt.
  const NO_AUTO_APPROVE: Array<[string, string]> = [
    ['git worktree remove --force ../tmp',          'remove --force must not auto-approve'],
    ['git worktree add --force ../tmp origin/main',  'add --force must not auto-approve'],
  ];
  it.each(NO_AUTO_APPROVE)('PASS: does NOT auto-approve %s — %s', (command) => {
    expect(runHook(command).actual).not.toBe('allow');
  });

  // Regression guard: a legitimate push that only LOOKS force-ish — a branch name
  // ending in -f, or a benign chained command after a safe push — must NOT be
  // hard-denied. (The v1.1.0 `-f` regex over-matched `epic/report-f` and hard-denied
  // it; v1.2.0 bounds the flag match. The chained-command case guards the `[^;&|]`
  // bound added in v1.2.0.)
  const NO_HARD_DENY: Array<[string, string]> = [
    ['git push origin epic/report-f',     'branch name ends in -f, not the -f flag'],
    ['git push origin main && echo "ok"',  'benign chained command after a safe push'],
  ];
  it.each(NO_HARD_DENY)('PASS: does NOT hard-deny %s — %s', (command) => {
    expect(runHook(command).actual).not.toBe('deny');
  });
});

describe('bash-permission-checker — fallthrough for ordinary commands', () => {
  it('PASS: falls through (no decision) for a benign unrelated command', () => {
    const { actual } = runHook('echo hello');
    expect(['fallthrough', 'allow']).toContain(actual);
  });

  it('FAIL: does not crash or exit non-zero for empty input', () => {
    const res = spawnSync('node', [HOOK], {
      input: '{}',
      encoding: 'utf8',
      timeout: 10_000,
    });
    expect(typeof res.status).toBe('number');
    // Must be 0 (fallthrough) or 2 (deny-by-default). Must not crash.
    expect([0, 2]).toContain(res.status);
  });
});
