/**
 * TG-32 — UI primitives must come from Shadcn (@/components/ui/).
 *
 * Rule: in .tsx files under web/src/, any import of a common UI primitive
 * (Button, Card, Dialog, Input, …) must resolve to @/components/ui/ — not a
 * hand-rolled module.
 *
 * The detector is tested against fixtures; a regression scan runs it over the
 * real web/src/ when it exists, and is skipped (visibly) otherwise.
 */

import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { REPO_ROOT } from '../../helpers';
import { findNonShadcnUiImports, walkFiles, isTsx } from './linters';

describe('TG-32 rule — findNonShadcnUiImports', () => {
  it('FAIL: flags a hand-crafted Button import', () => {
    const code = `import { Button } from "./CustomButton";\nexport default () => <Button />;\n`;
    expect(findNonShadcnUiImports(code)).toHaveLength(1);
  });

  it('PASS: accepts a Shadcn Button import', () => {
    expect(findNonShadcnUiImports(`import { Button } from "@/components/ui/button";\n`)).toHaveLength(0);
  });

  it('PASS: ignores non-UI imports', () => {
    const code = `import { useRouter } from "next/navigation";\nimport { z } from "zod";\n`;
    expect(findNonShadcnUiImports(code)).toHaveLength(0);
  });

  it('FAIL: flags one offender even when mixed with a valid import', () => {
    const code =
      `import { Button } from "@/components/ui/button";\n` +
      `import { Dialog } from "../widgets/Dialog";\n`;
    const violations = findNonShadcnUiImports(code);
    expect(violations).toHaveLength(1);
    expect(violations[0]).toContain('Dialog');
  });
});

const SRC_DIR = path.join(REPO_ROOT, 'web', 'src');
const hasSrc = fs.existsSync(SRC_DIR);

describe('TG-32 regression — real web/src/', () => {
  it.skipIf(!hasSrc)('all UI-primitive imports come from @/components/ui/', () => {
    const violations: string[] = [];
    for (const file of walkFiles(SRC_DIR, isTsx)) {
      for (const v of findNonShadcnUiImports(fs.readFileSync(file, 'utf8'))) {
        violations.push(`${path.relative(REPO_ROOT, file)}: ${v}`);
      }
    }
    expect(violations, `Non-Shadcn UI imports:\n${violations.join('\n')}`).toHaveLength(0);
  });
});
