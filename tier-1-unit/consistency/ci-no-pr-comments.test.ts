/**
 * CI does not comment on pull requests (post-v1.2.0).
 *
 * The automated checks used to post three comments — three emails — on every PR.
 * Post-v1.2.0 they stopped: results live on each check's run page and in the job
 * summary / `::error` annotations, never a PR comment. This is a static guard over
 * `.github/workflows/*.yml` so a re-introduced comment step is caught before it ships.
 *
 * It's a cross-cutting config check with no co-located equivalent (§14 planned #11).
 * Feature-detected on `.github/workflows/` so a checkout without it skips, never fails.
 */

import { it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { describeTemplate as describe } from '../../helpers';
import { REPO_ROOT } from '../../helpers';

const WF_DIR = path.join(REPO_ROOT, '.github', 'workflows');
const WF_PRESENT = fs.existsSync(WF_DIR);

// Mechanisms that post a comment onto a PR or issue — the thing that was removed.
// Each is a concrete API call or marketplace action, not a mere permission, so a
// workflow that only *reads* PRs never trips it.
const COMMENT_PATTERNS: { id: string; re: RegExp }[] = [
  { id: 'octokit createComment', re: /\.createComment\s*\(/ },
  { id: 'octokit updateComment', re: /\.updateComment\s*\(/ },
  { id: 'octokit createReviewComment', re: /\.createReviewComment\s*\(/ },
  { id: 'create-or-update-comment action', re: /create-or-update-comment/ },
  { id: 'comment-pull-request action', re: /comment-pull-request/ },
  { id: 'sticky-pull-request-comment action', re: /sticky-pull-request-comment/ },
  { id: 'gh pr comment', re: /gh\s+pr\s+comment/ },
  { id: 'gh issue comment', re: /gh\s+issue\s+comment/ },
];

function commentMechanismsIn(text: string): string[] {
  return COMMENT_PATTERNS.filter((p) => p.re.test(text)).map((p) => p.id);
}

function workflowFiles(): string[] {
  return fs
    .readdirSync(WF_DIR)
    .filter((f) => /\.ya?ml$/.test(f))
    .map((f) => path.join(WF_DIR, f));
}

describe('CI does not comment on pull requests (post-v1.2.0)', () => {
  it.skipIf(!WF_PRESENT)('PASS: no workflow posts a PR/issue comment', () => {
    const files = workflowFiles();
    // Non-vacuous: there must actually be workflows to scan.
    expect(files.length, 'expected at least one workflow to scan').toBeGreaterThan(0);

    const offenders: string[] = [];
    for (const file of files) {
      const found = commentMechanismsIn(fs.readFileSync(file, 'utf8'));
      if (found.length) offenders.push(`${path.basename(file)}: ${found.join(', ')}`);
    }
    expect(offenders, `CI workflows must not comment on PRs:\n${offenders.join('\n')}`).toEqual([]);
  });

  // Teeth over the real matcher: a genuine comment step is detected. Without this,
  // the PASS above could go quietly green even if the matcher stopped matching.
  it('FAIL (teeth): the matcher catches a real github-script comment step', () => {
    const withComment = [
      '      - uses: actions/github-script@v7',
      '        with:',
      '          script: |',
      "            await github.rest.issues.createComment({ issue_number: 1, body: 'gates failed' });",
    ].join('\n');
    const withoutComment = [
      '      - uses: actions/github-script@v7',
      '        with:',
      '          script: |',
      "            core.setOutput('result', 'ok');",
    ].join('\n');
    expect(commentMechanismsIn(withComment)).toContain('octokit createComment');
    expect(commentMechanismsIn(withoutComment)).toEqual([]);
  });
});
