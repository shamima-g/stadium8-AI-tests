/**
 * describeTemplate — a `describe` for suites that need the .claude/ template.
 *
 * With a template present it's the normal Vitest `describe`. Without one, it
 * registers a single *skipped* placeholder and DOES NOT run the suite factory.
 *
 * That last part matters: many template-dependent suites read the filesystem at
 * collection time (e.g. `readdirSync` over .claude/agents to build per-file
 * tests). Plain `describe.skip` still executes the factory — so it would crash
 * on the missing directory before the skip takes effect. By not calling the
 * factory at all, this gate skips the suite cleanly and visibly.
 *
 * Usage in a template-dependent test file — swap the import of `describe`:
 *   import { it, expect } from 'vitest';
 *   import { describeTemplate as describe } from '../../helpers';
 *
 * Template-independent suites keep importing `describe` from 'vitest'.
 */

import { describe, it } from 'vitest';
import { TEMPLATE_PRESENT } from './target';

export const describeTemplate: typeof describe = TEMPLATE_PRESENT
  ? describe
  : (((name: unknown) => {
      const title = typeof name === 'string' ? name : 'template-dependent suite';
      // Note: the original suite factory (2nd arg) is intentionally NOT invoked.
      describe.skip(`${title} — skipped: no .claude/ template (set REPO_ROOT)`, () => {
        it('requires a Stadium-8 template under test', () => {
          /* skipped — see the suite name */
        });
      });
    }) as unknown as typeof describe);
