# Test report — 3 August 2026, 7:08am

A plain-language summary of every check we ran on the project, and how each one did.

## In short

**❌ Some checks need attention**

We ran **312** checks in total: **217 passed**, **92 need attention**, 3 not run this time.

## The numbers

| | |
|---|---|
| Result | ❌ Needs attention |
| Checks run | 312 |
| Passed | 217 |
| Need attention | 92 |
| Not run this time | 3 |
| Time taken | 14.5s |
| AI usage | No AI was used in these checks |
| Run by | shamima-g on SHAMIMA-NB |
| When | 3 August 2026, 7:08am → finished 7:08am |

## How each area did

| Area | Result | Passed | Need attention | Not run |
|---|:--:|--:|--:|--:|
| Project files follow the rules | ✅ | 28 | 0 | 3 |
| Everything lines up and is consistent | ✅ | 113 | 0 | 0 |
| Flexibility | ✅ | 30 | 0 | 0 |
| Git machinery | ❌ | 2 | 1 | 0 |
| Built-in safety checks | ❌ | 18 | 26 | 0 |
| Saved data has the right shape | ✅ | 5 | 0 | 0 |
| Helper tools work correctly | ❌ | 21 | 65 | 0 |
| The app's own tests | — | — | — | — |
| Using the app like a person would | — | — | — | — |
| Final quality gates | — | — | — | — |

> **The app's own tests:** Not run yet — no saved result to show.
> **Using the app like a person would:** Not run yet — no saved result to show.
> **Final quality gates:** Not run yet — no saved result to show.

## What needs attention

92 checks did not pass. Here is what each one was checking and what went wrong:

### ❌ git-machinery — epic lifecycle: branch → merge → complete → merged on the dashboard PASS: after merge + mark-epic-complete, the epic shows as merged (COMPLETE), not in-flight
_Area: Git machinery_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\git-machinery\branch-merge.test.ts:64:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf / — deny path
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf /* — deny path with wildcard
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): cat ~/.ssh/id_rsa — ssh private key
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): cat /root/.ssh/id_rsa — ssh private key absolute
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): type id_rsa.pem — ssh key via Windows type
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): Get-Content id_rsa — ssh key via PowerShell Get-Content
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): cat mykey.pem — .pem via cat
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): sed -n 1p credentials — credentials via sed
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file
_Area: Built-in safety checks_

```
AssertionError: expected 'fallthrough' to be 'deny' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:63:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:629:21
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ bash-permission-checker — fallthrough for ordinary commands FAIL: does not crash or exit non-zero for empty input
_Area: Built-in safety checks_

```
AssertionError: expected [ +0, 2 ] to include 1
    at Proxy.<anonymous> (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/expect/dist/index.js:1196:17)
    at Proxy.<anonymous> (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/expect/dist/index.js:972:17)
    at Proxy.methodWrapper (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/chai/index.js:1686:25)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\bash-permission-checker.test.ts:124:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [project-facts] a correctly-named new file is allowed (project.md)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [project-facts] a drift-named new file is blocked (project-facts.md)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [epic-brief] a correctly-named new file is allowed (brief.md)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [epic-brief] a drift-named new file is blocked (epic-brief.md)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [epic-state] a correctly-named new file is allowed (state.json)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [epic-state] a drift-named new file is blocked (epic-state.json)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [epic-journal] a correctly-named new file is allowed (journal.md)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [epic-journal] a drift-named new file is blocked (epic-journal.md)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [story-file] a correctly-named new file is allowed (story-3-nav.md)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [story-file] a drift-named new file is blocked (story-3.md)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions PASS: [e2e-spec] a correctly-named new file is allowed (epic-task-browsing-story-3-nav.spec.ts)
_Area: Built-in safety checks_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/hooks/enforce-generated-doc-names.js:24:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:56:36
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — the six conventions FAIL: [e2e-spec] a drift-named new file is blocked (story-3-nav.spec.ts)
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:61:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — fall-through and guards PASS: a non-gated tool (Read) falls through
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:73:87
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — fall-through and guards PASS: an ungoverned filename under a governed dir falls through
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:77:65
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — fall-through and guards PASS: a drift name is grandfathered when the file already exists on disk
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:83:71
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ enforce-generated-doc-names.js — fall-through and guards FAIL: the write-location guard blocks an artifact path nested under web/
_Area: Built-in safety checks_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\hooks\enforce-generated-doc-names.test.ts:88:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ collect-dashboard-data.js — status detection PASS: returns "no_project" when nothing has started
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:38:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ collect-dashboard-data.js — status detection FAIL: does NOT report "ok" or crash when only legacy state exists
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:47:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ collect-dashboard-data.js — the plan and its readiness PASS: with project.md + epic-plan.md, returns "ok" with the plan and derived readiness
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:68:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ collect-dashboard-data.js — the plan and its readiness FAIL: does not mark a dependent epic "ready" while its dependency is unmet
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:96:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ collect-dashboard-data.js — an in-flight epic on its branch PASS: an epic/<slug> branch with a state.json surfaces as in-flight with its phase and story counts
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:125:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ collect-dashboard-data.js — an in-flight epic on its branch FAIL: a branch whose slug is not a valid epic/<kebab-slug> is surfaced, not silently dropped
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/collect-dashboard-data.js:30:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:150:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ collect-dashboard-data.js — --format=text PASS: text format is human-readable and names the project and its plan
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\collect-dashboard-data.test.ts:165:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ generate-dashboard-html.js PASS: writes dashboard.html with an auto-refresh meta tag when a project exists
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\generate-dashboard-html.test.ts:39:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ generate-dashboard-html.js FAIL: still writes usable HTML (never a half-written/empty file) with no project at all
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\generate-dashboard-html.test.ts:50:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ generate-dashboard-html.js — snapshot (stable HTML) PASS: produces deterministic HTML for a fixed state (after normalising timestamps)
_Area: Helper tools work correctly_

```
Error: ENOENT: no such file or directory, open 'C:\Users\SHAMIM~1\AppData\Local\Temp\claude-query-11eac6d1b00f-4xLwUZ\generated-docs\dashboard.html'
    at Object.readFileSync (node:fs:440:20)
    at Object.read (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\temp-project.ts:108:35)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\generate-dashboard-html.test.ts:68:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
```

### ❌ generate-dashboard-html.js — snapshot (stable HTML) FAIL: different states produce different HTML (proves the normaliser isn't stripping signal)
_Area: Helper tools work correctly_

```
Error: ENOENT: no such file or directory, open 'C:\Users\SHAMIM~1\AppData\Local\Temp\claude-query-4d1da799fa7c-9V5WOv\generated-docs\dashboard.html'
    at Object.readFileSync (node:fs:440:20)
    at Object.read (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\temp-project.ts:108:35)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\generate-dashboard-html.test.ts:78:23
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
```

### ❌ import-prototype.js — genesis layout PASS: copies genesis marker files into documentation/ when genesis.md is present
_Area: Helper tools work correctly_

```
AssertionError: expected false to be true // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\import-prototype.test.ts:57:45
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ import-prototype.js — genesis layout FAIL: returns status=error when --from path does not exist
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be 'error' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\import-prototype.test.ts:63:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ init-preferences.js — initial write PASS: writes .claude/preferences.json with the given flags
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\init-preferences.test.ts:34:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ init-preferences.js — initial write FAIL: rejects non-boolean flag values
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be 'error' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\init-preferences.test.ts:51:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ init-preferences.js — idempotency PASS: second invocation without --force skips (reports "skipped" or similar)
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\init-preferences.test.ts:68:25
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ init-preferences.js — idempotency FAIL: --force overwrites, proving idempotency can be bypassed deliberately
_Area: Helper tools work correctly_

```
Error: ENOENT: no such file or directory, open 'C:\Users\SHAMIM~1\AppData\Local\Temp\claude-query-81c2990ecd51-vAQ5e3\.claude\preferences.json'
    at Object.readFileSync (node:fs:440:20)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\init-preferences.test.ts:78:33
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ mark-epic-complete.js — valid finalisation PASS: flips COMPLETE-ON-BRANCH → COMPLETE and refreshes lastUpdated
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:29:34
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ mark-epic-complete.js — valid finalisation PASS: also finalises from EPIC-END and MANUAL-TEST (uncommitted-tip recovery)
_Area: Helper tools work correctly_

```
AssertionError: EPIC-END: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/mark-epic-complete.js:22:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:41:51
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ mark-epic-complete.js — valid finalisation PASS: is idempotent — a second run stays COMPLETE and reports "already complete"
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:50:29
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ mark-epic-complete.js — refuses invalid input FAIL: refuses a premature phase (BUILD) and leaves the state untouched
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be 'error' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:67:59
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ mark-epic-complete.js — refuses invalid input FAIL: errors when the epic has no state.json
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be 'error' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:75:77
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ mark-epic-complete.js — refuses invalid input FAIL: rejects a path-traversal slug rather than resolving outside generated-docs/epics
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be 'error' // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\mark-epic-complete.test.ts:82:77
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ migrate-legacy-state.js — detection detects legacy currentPhase (DESIGN → state-rewrite)
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:52:34
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ migrate-legacy-state.js — detection detects legacy story phases (REALIGN/QA)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:60:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — detection detects FRS without brief (spec-copy)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:66:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — detection reports no_legacy when nothing exists
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:72:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — detection reports no_migration_needed for an already-migrated state
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:81:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-12: REALIGN currentPhase → BUILD, in-progress story → PENDING
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:93:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-12: completed stories get synthesized e2e/manual fields with warnings
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:101:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-23: QA currentPhase → BUILD, completed stories preserve fields
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:110:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-23: design and designArtifacts blocks are dropped with warnings
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:119:39
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-23: intake.frsExists renamed to briefExists
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:128:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-23: epic.phase STORIES → PENDING
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:135:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-24-intake: SCOPE currentPhase → PLAN
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:141:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — fixture-driven migration output run-24-playwright: round-trip apply → restore
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:150:48
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ migrate-legacy-state.js — spec copy --apply copies FRS to brief with a migration header
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:175:16
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — spec copy --apply skips FRS copy if brief already exists, with a warning
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:187:48
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — spec copy --restore removes only a migration-header brief, leaving a user-edited brief
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:198:57
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — edge cases warns on an existing backup during a second apply
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:221:48
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — edge cases a second apply over an existing backup reports status "skipped", not "applied"
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:230:48
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — edge cases integration tests are counted once, not double-counted
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:240:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — edge cases a present-but-falsy completion field (e2eStatus: "") is preserved, not synthesized over
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:249:44
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ migrate-legacy-state.js — edge cases AC count is synthesized from the story file when available
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/migrate-legacy-state.js:19:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\migrate-legacy-state.test.ts:259:41
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ resolve-state-path.js — epic branch PASS: epic/<slug> resolves to the per-epic state.json path
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\resolve-state-path.test.ts:39:34
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ resolve-state-path.js — epic branch PASS: reports exists:true once the state.json is present
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\resolve-state-path.test.ts:50:61
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ resolve-state-path.js — non-epic and invalid PASS: on main it resolves to kind:none with no path
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\resolve-state-path.test.ts:62:47
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ resolve-state-path.js — non-epic and invalid FAIL: an invalid (non-kebab) epic slug is an error (exit 1)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\resolve-state-path.test.ts:71:19
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ resolve-state-path.js — non-epic and invalid FAIL: legacy workflow-state.json is NOT treated as a valid state source
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/resolve-state-path.js:38:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\resolve-state-path.test.ts:80:47
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ run-smoke-test.js — credential safety PASS: reports credentials_missing (without printing the value) when an env var is unset
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\run-smoke-test.test.ts:74:18
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:5
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:11)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:126:11
    at withEnv (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:90:5)
```

### ❌ run-smoke-test.js — credential safety PASS: the .sh artifact carries an env-var REFERENCE, never the credential value
_Area: Helper tools work correctly_

```
Error: ENOENT: no such file or directory, open 'C:\Users\SHAMIM~1\AppData\Local\Temp\claude-query-258f147e179f-zbTSXK\generated-docs\specs\api-smoke-test.sh'
    at Object.readFileSync (node:fs:440:20)
    at Object.read (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\temp-project.ts:108:35)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\run-smoke-test.test.ts:94:30
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:5
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:11)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ run-smoke-test.js — credential safety PASS: a credential echoed back in the response body is redacted
_Area: Helper tools work correctly_

```
SyntaxError: Unexpected end of JSON input
    at JSON.parse (<anonymous>)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\run-smoke-test.test.ts:118:24
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:5
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:11)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:126:11
```

### ❌ run-smoke-test.js — error shapes FAIL: a refused connection is categorised (result failure / connection_refused), not a crash
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\run-smoke-test.test.ts:147:18
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:5
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:11)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:126:11
    at withEnv (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:90:5)
```

### ❌ run-smoke-test.js — error shapes FAIL: a missing --config exits non-zero with a status:error payload
_Area: Helper tools work correctly_

```
SyntaxError: Unexpected end of JSON input
    at JSON.parse (<anonymous>)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\run-smoke-test.test.ts:162:17
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:5
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:11)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:126:11
    at withEnv (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/vitest/dist/chunks/runBaseTests.3qpJUEJM.js:90:5)
```

### ❌ scan-doc.js — plain markdown file PASS: reports correct line count and text type
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\scan-doc.test.ts:25:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ scan-doc.js — binary file detection PASS: flags a buffer with null bytes as binary
_Area: Helper tools work correctly_

```
AssertionError: expected undefined to be true // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\scan-doc.test.ts:50:26
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ scan-doc.js — keyword counting PASS: counts requested keywords case-insensitively
_Area: Helper tools work correctly_

```
TypeError: actual value must be number or bigint, received "undefined"
    at assertTypes (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/utils/dist/helpers.js:20:11)
    at Proxy.<anonymous> (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/expect/dist/index.js:1245:5)
    at Proxy.<anonymous> (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/expect/dist/index.js:972:17)
    at Proxy.methodWrapper (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/chai/index.js:1686:25)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\scan-doc.test.ts:76:33
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
```

### ❌ scan-doc.js — keyword counting FAIL: keywords not present yield zero, not undefined/crash
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\scan-doc.test.ts:84:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ summarize-playwright.js PASS: a clean run reports result "pass" (exit 0)
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\summarize-playwright.test.ts:66:34
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ summarize-playwright.js FAIL: a failing spec is reported and mapped to its story number (exit 1)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\summarize-playwright.test.ts:82:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ summarize-playwright.js FAIL: a run-level error with zero failing specs is still a fail (broken-run guard)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/summarize-playwright.js:34:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\summarize-playwright.test.ts:98:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ summarize-playwright.js FAIL: an unparseable / wrong-shape report exits 2 (treat as a run failure)
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\summarize-playwright.test.ts:106:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ validate-generated-doc-names.js PASS: a correctly-named tree reports "ok" with zero drift (exit 0)
_Area: Helper tools work correctly_

```
AssertionError: file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/validate-generated-doc-names.js:25
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/validate-generated-doc-names.js:25:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0
: expected 1 to be +0 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\validate-generated-doc-names.test.ts:41:34
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

### ❌ validate-generated-doc-names.js FAIL: a drift-named epic file is reported (status "drift", exit 1)
_Area: Helper tools work correctly_

```
Error: Script output was not JSON.
stdout:

stderr:
file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/validate-generated-doc-names.js:25
const fs = require('fs');
           ^

ReferenceError: require is not defined in ES module scope, you can use import instead
This file is being treated as an ES module because it has a '.js' file extension and 'C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\package.json' contains "type": "module". To treat it as a CommonJS script, rename it to use the '.cjs' file extension.
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/.targets/dev-v1.2.0/.claude/scripts/validate-generated-doc-names.js:25:12
    at ModuleJob.run (node:internal/modules/esm/module_job:377:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:691:26)
    at async asyncRunEntryPointWithESMLoader (node:internal/modules/run_main:101:5)

Node.js v24.11.0

    at Object.json (C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\helpers\run-script.ts:78:15)
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\validate-generated-doc-names.test.ts:55:20
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
```

### ❌ validate-generated-doc-names.js FAIL: a missing conventions schema exits 2 (can't audit without the source of truth)
_Area: Helper tools work correctly_

```
AssertionError: expected 1 to be 2 // Object.is equality
    at C:\AI\Stadium8-AI-tests-DO_NOT_DELETE\AI-tests\tier-1-unit\scripts\validate-generated-doc-names.test.ts:66:24
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:146:14
    at file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:533:11
    at runWithTimeout (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:39:7)
    at runTest (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1056:17)
    at processTicksAndRejections (node:internal/process/task_queues:105:5)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runSuite (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1205:15)
    at runFiles (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1262:5)
    at startTests (file:///C:/AI/Stadium8-AI-tests-DO_NOT_DELETE/AI-tests/node_modules/@vitest/runner/dist/index.js:1271:3)
```

## Every check we ran

The full list, in case you want the detail. ✅ passed · ❌ needs attention · ⏭️ not run.

| Check | Area | Result | Time |
|---|---|:--:|--:|
| TG-31 rule — findInventedPaths FAIL: flags a path not in the spec | Project files follow the rules | ✅ | 5ms |
| TG-31 rule — findInventedPaths PASS: accepts an exact spec match | Project files follow the rules | ✅ | 1ms |
| TG-31 rule — findInventedPaths PASS: matches a parameterised path by shape | Project files follow the rules | ✅ | 1ms |
| TG-31 rule — findInventedPaths PASS: ignores strings that are not /api paths | Project files follow the rules | ✅ | 0ms |
| TG-31 regression — real spec + endpoints every code path matches the spec | Project files follow the rules | ⏭️ | — |
| TG-33 rule — findSuppressions FAIL: flags a @ts-ignore | Project files follow the rules | ✅ | 5ms |
| TG-33 rule — findSuppressions FAIL: flags an eslint-disable-next-line | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions FAIL: flags every directive variant | Project files follow the rules | ✅ | 1ms |
| TG-33 rule — findSuppressions PASS: clean code has no suppressions | Project files follow the rules | ✅ | 0ms |
| TG-33 regression — real web/src/ has no suppression directives in any source file | Project files follow the rules | ✅ | 22ms |
| TG-34 rule — findJargon FAIL: flags engineering jargon | Project files follow the rules | ✅ | 3ms |
| TG-34 rule — findJargon FAIL: flags a gate reference | Project files follow the rules | ✅ | 2ms |
| TG-34 rule — findJargon PASS: allows plain-language phrasing | Project files follow the rules | ✅ | 0ms |
| TG-34 rule — extractManualChecklist PASS: extracts only the manual-test section (not the dev metadata around it) | Project files follow the rules | ✅ | 1ms |
| TG-34 rule — extractManualChecklist FAIL: a jargon-laden manual-test line is caught in the extracted section | Project files follow the rules | ✅ | 0ms |
| TG-34 rule — extractManualChecklist PASS: returns empty string when there is no manual-test section | Project files follow the rules | ✅ | 0ms |
| TG-34 regression — real manual-test checklists (in story files) contain no engineering jargon | Project files follow the rules | ⏭️ | — |
| TG-38 rule — extractRole / roleViolation PASS: extracts a standard role and reports no violation | Project files follow the rules | ✅ | 3ms |
| TG-38 rule — extractRole / roleViolation PASS: "All authenticated users" is a valid non-restricted role | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts a plain metadata-table row, singular or plural | Project files follow the rules | ✅ | 1ms |
| TG-38 rule — extractRole / roleViolation PASS: accepts the bold plural marker | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags an empty table-row role | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags an empty role | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags "N/A" as empty/ambiguous | Project files follow the rules | ✅ | 0ms |
| TG-38 rule — extractRole / roleViolation FAIL: flags a story with no Role field at all | Project files follow the rules | ✅ | 0ms |
| TG-38 regression — real story files every story file has a valid Role | Project files follow the rules | ⏭️ | — |
| TG-32 rule — findNonShadcnUiImports FAIL: flags a hand-crafted Button import | Project files follow the rules | ✅ | 5ms |
| TG-32 rule — findNonShadcnUiImports PASS: accepts a Shadcn Button import | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports PASS: ignores non-UI imports | Project files follow the rules | ✅ | 1ms |
| TG-32 rule — findNonShadcnUiImports FAIL: flags one offender even when mixed with a valid import | Project files follow the rules | ✅ | 1ms |
| TG-32 regression — real web/src/ all UI-primitive imports come from @/components/ui/ | Project files follow the rules | ✅ | 15ms |
| agent frontmatter — every agent has required fields PASS: api-connectivity-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 28ms |
| agent frontmatter — every agent has required fields PASS: code-review-runner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 12ms |
| agent frontmatter — every agent has required fields PASS: design-api-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — every agent has required fields PASS: design-style-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — every agent has required fields PASS: developer.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — every agent has required fields PASS: feature-planner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 3ms |
| agent frontmatter — every agent has required fields PASS: intake-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 17ms |
| agent frontmatter — every agent has required fields PASS: mock-setup-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 8ms |
| agent frontmatter — every agent has required fields PASS: playwright-runner.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 24ms |
| agent frontmatter — every agent has required fields PASS: test-generator.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — every agent has required fields PASS: type-generator-agent.md has valid frontmatter with name + description | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — name matches filename PASS: name in api-connectivity-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 3ms |
| agent frontmatter — name matches filename PASS: name in code-review-runner.md matches the filename stem | Everything lines up and is consistent | ✅ | 4ms |
| agent frontmatter — name matches filename PASS: name in design-api-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — name matches filename PASS: name in design-style-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 12ms |
| agent frontmatter — name matches filename PASS: name in developer.md matches the filename stem | Everything lines up and is consistent | ✅ | 48ms |
| agent frontmatter — name matches filename PASS: name in feature-planner.md matches the filename stem | Everything lines up and is consistent | ✅ | 6ms |
| agent frontmatter — name matches filename PASS: name in intake-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 15ms |
| agent frontmatter — name matches filename PASS: name in mock-setup-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — name matches filename PASS: name in playwright-runner.md matches the filename stem | Everything lines up and is consistent | ✅ | 33ms |
| agent frontmatter — name matches filename PASS: name in test-generator.md matches the filename stem | Everything lines up and is consistent | ✅ | 34ms |
| agent frontmatter — name matches filename PASS: name in type-generator-agent.md matches the filename stem | Everything lines up and is consistent | ✅ | 26ms |
| agent README consistency PASS: every agent file has a matching entry in README.md | Everything lines up and is consistent | ✅ | 4ms |
| agent README consistency FAIL: README does not list phantom agents that don't exist on disk | Everything lines up and is consistent | ✅ | 15ms |
| agent frontmatter — model / tools / color are well-formed PASS: api-connectivity-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 10ms |
| agent frontmatter — model / tools / color are well-formed PASS: code-review-runner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 3ms |
| agent frontmatter — model / tools / color are well-formed PASS: design-api-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — model / tools / color are well-formed PASS: design-style-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — model / tools / color are well-formed PASS: developer.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 2ms |
| agent frontmatter — model / tools / color are well-formed PASS: feature-planner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — model / tools / color are well-formed PASS: intake-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 51ms |
| agent frontmatter — model / tools / color are well-formed PASS: mock-setup-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 19ms |
| agent frontmatter — model / tools / color are well-formed PASS: playwright-runner.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 17ms |
| agent frontmatter — model / tools / color are well-formed PASS: test-generator.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 9ms |
| agent frontmatter — model / tools / color are well-formed PASS: type-generator-agent.md has a valid model, non-empty tools, and a colour | Everything lines up and is consistent | ✅ | 6ms |
| agent README — referenced scripts exist on disk PASS: every backticked *.js script named in README.md resolves under .claude/scripts/ | Everything lines up and is consistent | ✅ | 7ms |
| command frontmatter PASS: /api-go-live has a non-empty description | Everything lines up and is consistent | ✅ | 12ms |
| command frontmatter PASS: /api-mock-refresh has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /api-status has a non-empty description | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter PASS: /build-report has a non-empty description | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter PASS: /continue has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /dashboard has a non-empty description | Everything lines up and is consistent | ✅ | 5ms |
| command frontmatter PASS: /migrate-legacy has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /plan has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /quality-check has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /release has a non-empty description | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter PASS: /start has a non-empty description | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter PASS: /status has a non-empty description | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter PASS: /upgrade has a non-empty description | Everything lines up and is consistent | ✅ | 5ms |
| command frontmatter — model field valid PASS: api-go-live.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: api-mock-refresh.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: api-status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: build-report.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| command frontmatter — model field valid PASS: continue.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: dashboard.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 14ms |
| command frontmatter — model field valid PASS: migrate-legacy.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 3ms |
| command frontmatter — model field valid PASS: plan.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 9ms |
| command frontmatter — model field valid PASS: quality-check.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter — model field valid PASS: release.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 4ms |
| command frontmatter — model field valid PASS: start.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: status.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 2ms |
| command frontmatter — model field valid PASS: upgrade.md either omits model or uses a known value | Everything lines up and is consistent | ✅ | 1ms |
| CLAUDE.md → commands cross-reference PASS: every /command referenced in CLAUDE.md exists under .claude/commands/ | Everything lines up and is consistent | ✅ | 3ms |
| orchestrator-rules.md → agent files PASS: every agent mentioned by name in orchestrator-rules.md exists | Everything lines up and is consistent | ✅ | 5ms |
| agents/README.md agent catalog PASS: .claude/agents/README.md references every real agent at least once | Everything lines up and is consistent | ✅ | 2ms |
| CLAUDE.md → policies/ files PASS: every policy file referenced in CLAUDE.md exists | Everything lines up and is consistent | ✅ | 2ms |
| generated-doc-conventions.json — shape PASS: contains exactly the six expected conventions | Everything lines up and is consistent | ✅ | 5ms |
| generated-doc-conventions.json — shape PASS: every convention has the required fields | Everything lines up and is consistent | ✅ | 4ms |
| generated-doc-conventions.json — self-consistency PASS: each convention's example matches its filenamePattern | Everything lines up and is consistent | ✅ | 2ms |
| generated-doc-conventions.json — self-consistency FAIL-shape: each counterexample is drift — matches badPattern but NOT filenamePattern | Everything lines up and is consistent | ✅ | 2ms |
| generated-doc-conventions.json — agreement with consumers + mirror PASS: naming-conventions.md documents every convention (by example filename) | Everything lines up and is consistent | ✅ | 2ms |
| generated-doc-conventions.json — agreement with consumers + mirror PASS: both the hook and the validator read generated-doc-conventions.json | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — check-off page is generated PASS: continue.md § B7.1 generates the manual-tests.html check-off page | Everything lines up and is consistent | ✅ | 4ms |
| manual-test approval — check-off page is generated PASS: approval-pattern.md documents the Manual-Test Check-off Page and its results payload | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — results are persisted PASS: continue.md persists the handed-back results to state.json.epic.manualTestResults | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — results are persisted — failure-path coverage FAIL: a tampered continue.md that never persists results is detected | Everything lines up and is consistent | ✅ | 116ms |
| manual-test approval — fix-cycle re-display PASS: continue.md re-displays the approval carrying previously-passed ticks forward | Everything lines up and is consistent | ✅ | 4ms |
| manual-test approval — fix-cycle re-display PASS: only the affected tests come back unchecked after a fix | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — fix-cycle re-display PASS: the manual-test fix loop is capped at 3 cycles | Everything lines up and is consistent | ✅ | 3ms |
| manual-test approval — fix-cycle re-display PASS: the check-off page pre-ticks from prior results (approval-pattern.md) | Everything lines up and is consistent | ✅ | 5ms |
| manual-test approval — fix-cycle re-display — failure-path coverage FAIL: a tampered continue.md that re-asks the whole list from scratch is detected | Everything lines up and is consistent | ✅ | 106ms |
| manual-test approval — free-text issue handling PASS: continue.md captures a free-text failure and classifies it before fixing | Everything lines up and is consistent | ✅ | 4ms |
| manual-test approval — free-text issue handling PASS: continue.md re-presents the manual-test approval after the fix (never advances silently) | Everything lines up and is consistent | ✅ | 2ms |
| manual-test approval — content shown before the question PASS: approval-pattern.md requires the summary/content before calling AskUserQuestion | Everything lines up and is consistent | ✅ | 1ms |
| manual-test approval — free-text handling — failure-path coverage FAIL: a tampered continue.md that never captures/classifies a free-text issue is detected | Everything lines up and is consistent | ✅ | 103ms |
| settings.json structural validity PASS: parses as valid JSON | Everything lines up and is consistent | ✅ | 7ms |
| settings.json structural validity PASS: has expected top-level sections | Everything lines up and is consistent | ✅ | 1ms |
| settings.json structural validity FAIL: deny list is not empty (security invariant) | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/workflow-guard.ps1 | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-phase-context.ps1 | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/inject-agent-context.ps1 | Everything lines up and is consistent | ✅ | 1ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/bash-permission-checker.js | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook files exist PASS: hook file referenced in settings.json exists: .claude/hooks/enforce-generated-doc-names.js | Everything lines up and is consistent | ✅ | 0ms |
| settings.json hook timeouts are reasonable PASS: no hook declares a timeout over 60 seconds | Everything lines up and is consistent | ✅ | 2ms |
| shared/ + policies/ — no orphans PASS: there are shared and policy docs to check (sanity) | Everything lines up and is consistent | ✅ | 2ms |
| shared/ + policies/ — no orphans PASS: shared/agent-autonomy.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/agent-startup.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/approval-pattern.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/epic-picker.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/generated-doc-conventions.json is referenced by at least one other file | Everything lines up and is consistent | ✅ | 1ms |
| shared/ + policies/ — no orphans PASS: shared/naming-conventions.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/orchestrator-rules.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: shared/roles-snippets.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/authentication-intake.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/bff-auth-pattern.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/compliance-intake.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/epic-branch-concurrency.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/file-operations.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/styling-centralisation.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — no orphans PASS: policies/testing-policy.md is referenced by at least one other file | Everything lines up and is consistent | ✅ | 0ms |
| shared/ + policies/ — every reference resolves PASS: no reference points at a missing shared/policy file | Everything lines up and is consistent | ✅ | 238ms |
| shared/ + policies/ — the detectors work (good/broken) PASS: extractSharedPolicyRefs finds refs with and without a prefix | Everything lines up and is consistent | ✅ | 3ms |
| shared/ + policies/ — the detectors work (good/broken) FAIL: an orphan (unreferenced basename) is detectable in a synthetic corpus | Everything lines up and is consistent | ✅ | 1ms |
| parseChangelog — good input PASS: returns released versions newest-first, skipping Unreleased | Flexibility | ✅ | 5ms |
| parseChangelog — good input PASS: parses the date and typed entries of a version | Flexibility | ✅ | 1ms |
| parseChangelog — broken/edge input PASS: a malformed/typo heading is ignored, not fatal (parser never throws) | Flexibility | ✅ | 3ms |
| parseChangelog — broken/edge input PASS: empty / null input yields an empty list, not an error | Flexibility | ✅ | 1ms |
| entriesBetween PASS: (1.0.0, 1.2.0] returns only the 1.1.0 and 1.2.0 entries | Flexibility | ✅ | 1ms |
| entriesBetween PASS: tolerates a leading "v" on the bounds | Flexibility | ✅ | 0ms |
| entriesBetween BROKEN-RANGE: a reversed or equal range yields [] (no gap), not an error | Flexibility | ✅ | 0ms |
| findExplaining — attribution PASS: a symbol named in the changelog is explained (incl. kebab/spaced variants) | Flexibility | ✅ | 1ms |
| findExplaining — attribution BROKEN: a symbol NOT in any entry is unexplained (returns null) | Flexibility | ✅ | 1ms |
| compareVersions / normaliseVersion PASS: orders versions numerically and strips a leading v | Flexibility | ✅ | 1ms |
| compareVersions / normaliseVersion PASS: a pre-release sorts before its plain release | Flexibility | ✅ | 0ms |
| diffLive PASS: identical templates produce no differences | Flexibility | ✅ | 4ms |
| diffLive PASS: a value only on one side is reported with the correct side | Flexibility | ✅ | 1ms |
| diffLive PASS: an order-only change on an ordered list is flagged | Flexibility | ✅ | 1ms |
| verdict — the three-way rule GREEN: no differences | Flexibility | ✅ | 1ms |
| verdict — the three-way rule AMBER: differences that are ALL explained by the changelog (pending promotion) | Flexibility | ✅ | 1ms |
| verdict — the three-way rule RED: a difference with NO changelog entry behind it is unexplained | Flexibility | ✅ | 3ms |
| verdict — the three-way rule RED: an order-only change is treated as needing review (unexplained) | Flexibility | ✅ | 0ms |
| channel resolution — good case PASS: dev and release resolve to their repo URL + contract | Flexibility | ✅ | 4ms |
| channel resolution — good case PASS: the real targets.json lists dev and release, each with a repo + contract | Flexibility | ✅ | 5ms |
| channel resolution — broken case BROKEN: an unknown target name throws a clear error listing the known ones (no silent default) | Flexibility | ✅ | 3ms |
| channel resolution — broken case PASS: loadTargets rejects a targets file with no targets | Flexibility | ✅ | 1ms |
| suiteVersion PASS: reads the suite baseline from the VERSION file | Flexibility | ✅ | 5ms |
| templateVersion — good case PASS: reads templateRef from a valid template-version.json | Flexibility | ✅ | 5ms |
| templateVersion — broken/absent marker BROKEN: a malformed marker does not crash — reports unknown (no git tag here) | Flexibility | ✅ | 127ms |
| templateVersion — broken/absent marker PASS: a missing marker reports unknown, not an error | Flexibility | ✅ | 149ms |
| versionGap — direction PASS: equal versions read as in-sync | Flexibility | ✅ | 5ms |
| versionGap — direction PASS: an older template reads as template-ahead=false (suite-ahead) | Flexibility | ✅ | 4ms |
| versionGap — direction PASS: a newer template reads as template-ahead | Flexibility | ✅ | 7ms |
| versionGap — direction BROKEN: an unreadable template version reads as unknown gap, never throws | Flexibility | ✅ | 70ms |
| git-machinery — epic lifecycle: branch → merge → complete → merged on the dashboard PASS: after merge + mark-epic-complete, the epic shows as merged (COMPLETE), not in-flight | Git machinery | ❌ | 2.6s |
| git-machinery — auto-combine vs. conflict substrate PASS: two epics adding different tokens combine on their own (clean merge) | Git machinery | ✅ | 3.3s |
| git-machinery — auto-combine vs. conflict substrate FAIL: two epics changing the SAME token line conflict (the workflow's halt trigger) | Git machinery | ✅ | 3.7s |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf / — deny path | Built-in safety checks | ❌ | 211ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): rm -rf /* — deny path with wildcard | Built-in safety checks | ❌ | 168ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat ~/.ssh/id_rsa — ssh private key | Built-in safety checks | ❌ | 202ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat /root/.ssh/id_rsa — ssh private key absolute | Built-in safety checks | ❌ | 304ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): type id_rsa.pem — ssh key via Windows type | Built-in safety checks | ❌ | 309ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): Get-Content id_rsa — ssh key via PowerShell Get-Content | Built-in safety checks | ❌ | 329ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): cat mykey.pem — .pem via cat | Built-in safety checks | ❌ | 231ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): sed -n 1p credentials — credentials via sed | Built-in safety checks | ❌ | 234ms |
| bash-permission-checker — deny matrix FAIL safely (must deny): grep password credentials.json — credentials file | Built-in safety checks | ❌ | 248ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/transition-phase.js --show — node running a claude script | Built-in safety checks | ✅ | 257ms |
| bash-permission-checker — allow matrix PASS: allow node .claude/scripts/copy-with-header.js --from a --to b — copy-with-header | Built-in safety checks | ✅ | 171ms |
| bash-permission-checker — allow matrix PASS: allow git pull — git pull is always auto-approved | Built-in safety checks | ✅ | 181ms |
| bash-permission-checker — allow matrix PASS: allow git add generated-docs/ — git add scoped to generated-docs | Built-in safety checks | ✅ | 158ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf / outright | Built-in safety checks | ✅ | 316ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm  -rf  / outright | Built-in safety checks | ✅ | 163ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -r -f / outright | Built-in safety checks | ✅ | 206ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm --recursive --force / outright | Built-in safety checks | ✅ | 209ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf ~ outright | Built-in safety checks | ✅ | 208ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW rm -rf $HOME outright | Built-in safety checks | ✅ | 207ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW /bin/rm -rf / outright | Built-in safety checks | ✅ | 214ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW sudo rm -rf / outright | Built-in safety checks | ✅ | 280ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW bash -c "rm -rf /" outright | Built-in safety checks | ✅ | 309ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW eval "rm -rf /" outright | Built-in safety checks | ✅ | 239ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW  rm -rf / outright | Built-in safety checks | ✅ | 216ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW cat ~/.ssh/id_rsa && true outright | Built-in safety checks | ✅ | 191ms |
| bash-permission-checker — fuzz (adversarial input) FAIL: must not ALLOW true \|\| cat /etc/shadow outright | Built-in safety checks | ✅ | 202ms |
| bash-permission-checker — fallthrough for ordinary commands PASS: falls through (no decision) for a benign unrelated command | Built-in safety checks | ✅ | 214ms |
| bash-permission-checker — fallthrough for ordinary commands FAIL: does not crash or exit non-zero for empty input | Built-in safety checks | ❌ | 229ms |
| enforce-generated-doc-names.js — the six conventions PASS: [project-facts] a correctly-named new file is allowed (project.md) | Built-in safety checks | ❌ | 316ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [project-facts] a drift-named new file is blocked (project-facts.md) | Built-in safety checks | ❌ | 280ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-brief] a correctly-named new file is allowed (brief.md) | Built-in safety checks | ❌ | 329ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-brief] a drift-named new file is blocked (epic-brief.md) | Built-in safety checks | ❌ | 326ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-state] a correctly-named new file is allowed (state.json) | Built-in safety checks | ❌ | 348ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-state] a drift-named new file is blocked (epic-state.json) | Built-in safety checks | ❌ | 406ms |
| enforce-generated-doc-names.js — the six conventions PASS: [epic-journal] a correctly-named new file is allowed (journal.md) | Built-in safety checks | ❌ | 498ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [epic-journal] a drift-named new file is blocked (epic-journal.md) | Built-in safety checks | ❌ | 642ms |
| enforce-generated-doc-names.js — the six conventions PASS: [story-file] a correctly-named new file is allowed (story-3-nav.md) | Built-in safety checks | ❌ | 743ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [story-file] a drift-named new file is blocked (story-3.md) | Built-in safety checks | ❌ | 768ms |
| enforce-generated-doc-names.js — the six conventions PASS: [e2e-spec] a correctly-named new file is allowed (epic-task-browsing-story-3-nav.spec.ts) | Built-in safety checks | ❌ | 788ms |
| enforce-generated-doc-names.js — the six conventions FAIL: [e2e-spec] a drift-named new file is blocked (story-3-nav.spec.ts) | Built-in safety checks | ❌ | 559ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: a non-gated tool (Read) falls through | Built-in safety checks | ❌ | 685ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: an ungoverned filename under a governed dir falls through | Built-in safety checks | ❌ | 573ms |
| enforce-generated-doc-names.js — fall-through and guards PASS: a drift name is grandfathered when the file already exists on disk | Built-in safety checks | ❌ | 494ms |
| enforce-generated-doc-names.js — fall-through and guards FAIL: the write-location guard blocks an artifact path nested under web/ | Built-in safety checks | ❌ | 278ms |
| intake-manifest.json schema PASS: default manifest (Team Task Manager) validates | Saved data has the right shape | ✅ | 204ms |
| intake-manifest.json schema PASS: BFF variant overlay validates | Saved data has the right shape | ✅ | 120ms |
| intake-manifest.json schema FAIL: invalid dataSource value is rejected | Saved data has the right shape | ✅ | 1ms |
| intake-manifest.json schema FAIL: artifact entry without `generate` boolean is rejected | Saved data has the right shape | ✅ | 0ms |
| intake-manifest.json schema FAIL: invalid authMethod is rejected | Saved data has the right shape | ✅ | 0ms |
| collect-dashboard-data.js — status detection PASS: returns "no_project" when nothing has started | Helper tools work correctly | ❌ | 341ms |
| collect-dashboard-data.js — status detection FAIL: does NOT report "ok" or crash when only legacy state exists | Helper tools work correctly | ❌ | 393ms |
| collect-dashboard-data.js — the plan and its readiness PASS: with project.md + epic-plan.md, returns "ok" with the plan and derived readiness | Helper tools work correctly | ❌ | 332ms |
| collect-dashboard-data.js — the plan and its readiness FAIL: does not mark a dependent epic "ready" while its dependency is unmet | Helper tools work correctly | ❌ | 293ms |
| collect-dashboard-data.js — an in-flight epic on its branch PASS: an epic/<slug> branch with a state.json surfaces as in-flight with its phase and story counts | Helper tools work correctly | ❌ | 1.9s |
| collect-dashboard-data.js — an in-flight epic on its branch FAIL: a branch whose slug is not a valid epic/<kebab-slug> is surfaced, not silently dropped | Helper tools work correctly | ❌ | 2.1s |
| collect-dashboard-data.js — --format=text PASS: text format is human-readable and names the project and its plan | Helper tools work correctly | ❌ | 475ms |
| collect-dashboard-data.js — --format=text FAIL: text format does not leak raw JSON braces into user-facing output | Helper tools work correctly | ✅ | 415ms |
| generate-dashboard-html.js PASS: writes dashboard.html with an auto-refresh meta tag when a project exists | Helper tools work correctly | ❌ | 281ms |
| generate-dashboard-html.js FAIL: still writes usable HTML (never a half-written/empty file) with no project at all | Helper tools work correctly | ❌ | 302ms |
| generate-dashboard-html.js — snapshot (stable HTML) PASS: produces deterministic HTML for a fixed state (after normalising timestamps) | Helper tools work correctly | ❌ | 359ms |
| generate-dashboard-html.js — snapshot (stable HTML) FAIL: different states produce different HTML (proves the normaliser isn't stripping signal) | Helper tools work correctly | ❌ | 297ms |
| generate-test-report — buildModel PASS: tallies counts, groups by layer, and keeps the failure message | Helper tools work correctly | ✅ | 26ms |
| generate-test-report — buildModel FAIL: does not count a skipped test as passed | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — fmtDuration PASS: formats sub-second, seconds, and minutes | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — fmtDuration FAIL: returns a placeholder for a missing duration rather than NaN | Helper tools work correctly | ✅ | 0ms |
| generate-test-report — render PASS: emits the plain-language sections and a "needs attention" block with the failure detail | Helper tools work correctly | ✅ | 3ms |
| generate-test-report — render FAIL: an all-pass run is not reported as needing attention | Helper tools work correctly | ✅ | 1ms |
| generate-test-report — render PASS: shows a lines-of-code section when that data is supplied | Helper tools work correctly | ✅ | 86ms |
| generate-test-report — friendlyArea PASS: maps a known layer to plain language and tidies an unknown one | Helper tools work correctly | ✅ | 1ms |
| import-prototype.js — genesis layout PASS: copies genesis marker files into documentation/ when genesis.md is present | Helper tools work correctly | ❌ | 384ms |
| import-prototype.js — genesis layout FAIL: returns status=error when --from path does not exist | Helper tools work correctly | ❌ | 392ms |
| init-preferences.js — initial write PASS: writes .claude/preferences.json with the given flags | Helper tools work correctly | ❌ | 366ms |
| init-preferences.js — initial write FAIL: rejects non-boolean flag values | Helper tools work correctly | ❌ | 340ms |
| init-preferences.js — idempotency PASS: second invocation without --force skips (reports "skipped" or similar) | Helper tools work correctly | ❌ | 764ms |
| init-preferences.js — idempotency FAIL: --force overwrites, proving idempotency can be bypassed deliberately | Helper tools work correctly | ❌ | 937ms |
| mark-epic-complete.js — valid finalisation PASS: flips COMPLETE-ON-BRANCH → COMPLETE and refreshes lastUpdated | Helper tools work correctly | ❌ | 268ms |
| mark-epic-complete.js — valid finalisation PASS: also finalises from EPIC-END and MANUAL-TEST (uncommitted-tip recovery) | Helper tools work correctly | ❌ | 309ms |
| mark-epic-complete.js — valid finalisation PASS: is idempotent — a second run stays COMPLETE and reports "already complete" | Helper tools work correctly | ❌ | 454ms |
| mark-epic-complete.js — refuses invalid input FAIL: refuses a premature phase (BUILD) and leaves the state untouched | Helper tools work correctly | ❌ | 280ms |
| mark-epic-complete.js — refuses invalid input FAIL: errors when the epic has no state.json | Helper tools work correctly | ❌ | 295ms |
| mark-epic-complete.js — refuses invalid input FAIL: rejects a path-traversal slug rather than resolving outside generated-docs/epics | Helper tools work correctly | ❌ | 270ms |
| mark-epic-complete.js — refuses invalid input FAIL: missing --slug prints usage and exits non-zero | Helper tools work correctly | ✅ | 502ms |
| migrate-legacy-state.js — detection detects legacy currentPhase (DESIGN → state-rewrite) | Helper tools work correctly | ❌ | 260ms |
| migrate-legacy-state.js — detection detects legacy story phases (REALIGN/QA) | Helper tools work correctly | ❌ | 219ms |
| migrate-legacy-state.js — detection detects FRS without brief (spec-copy) | Helper tools work correctly | ❌ | 288ms |
| migrate-legacy-state.js — detection reports no_legacy when nothing exists | Helper tools work correctly | ❌ | 290ms |
| migrate-legacy-state.js — detection reports no_migration_needed for an already-migrated state | Helper tools work correctly | ❌ | 325ms |
| migrate-legacy-state.js — fixture-driven migration output run-12: REALIGN currentPhase → BUILD, in-progress story → PENDING | Helper tools work correctly | ❌ | 240ms |
| migrate-legacy-state.js — fixture-driven migration output run-12: completed stories get synthesized e2e/manual fields with warnings | Helper tools work correctly | ❌ | 261ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: QA currentPhase → BUILD, completed stories preserve fields | Helper tools work correctly | ❌ | 246ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: design and designArtifacts blocks are dropped with warnings | Helper tools work correctly | ❌ | 317ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: intake.frsExists renamed to briefExists | Helper tools work correctly | ❌ | 216ms |
| migrate-legacy-state.js — fixture-driven migration output run-23: epic.phase STORIES → PENDING | Helper tools work correctly | ❌ | 200ms |
| migrate-legacy-state.js — fixture-driven migration output run-24-intake: SCOPE currentPhase → PLAN | Helper tools work correctly | ❌ | 332ms |
| migrate-legacy-state.js — fixture-driven migration output run-24-playwright: round-trip apply → restore | Helper tools work correctly | ❌ | 236ms |
| migrate-legacy-state.js — spec copy --apply copies FRS to brief with a migration header | Helper tools work correctly | ❌ | 230ms |
| migrate-legacy-state.js — spec copy --apply skips FRS copy if brief already exists, with a warning | Helper tools work correctly | ❌ | 224ms |
| migrate-legacy-state.js — spec copy --restore removes only a migration-header brief, leaving a user-edited brief | Helper tools work correctly | ❌ | 590ms |
| migrate-legacy-state.js — edge cases --restore with no backup exits 1 | Helper tools work correctly | ✅ | 268ms |
| migrate-legacy-state.js — edge cases warns on an existing backup during a second apply | Helper tools work correctly | ❌ | 630ms |
| migrate-legacy-state.js — edge cases a second apply over an existing backup reports status "skipped", not "applied" | Helper tools work correctly | ❌ | 412ms |
| migrate-legacy-state.js — edge cases integration tests are counted once, not double-counted | Helper tools work correctly | ❌ | 267ms |
| migrate-legacy-state.js — edge cases a present-but-falsy completion field (e2eStatus: "") is preserved, not synthesized over | Helper tools work correctly | ❌ | 288ms |
| migrate-legacy-state.js — edge cases AC count is synthesized from the story file when available | Helper tools work correctly | ❌ | 243ms |
| project-root.js — default anchor getProjectRoot() returns the target repo root that contains .claude | Helper tools work correctly | ✅ | 3ms |
| project-root.js — walk-up resolution walks up to the nearest ancestor containing .claude | Helper tools work correctly | ✅ | 10ms |
| project-root.js — walk-up resolution recognises .git as a fallback marker | Helper tools work correctly | ✅ | 9ms |
| project-root.js — walk-up resolution recognises .git when it is a file (git worktree layout) | Helper tools work correctly | ✅ | 6ms |
| project-root.js — walk-up resolution stops at the nearest marker, not a farther one (nested-repo safety) | Helper tools work correctly | ✅ | 10ms |
| project-root.js — walk-up resolution returns the start dir itself when it holds the marker | Helper tools work correctly | ✅ | 4ms |
| quality-gates.js — JSON shape PASS: always outputs a parseable JSON object with a gates array | Helper tools work correctly | ✅ | 407ms |
| quality-gates.js — JSON shape FAIL: does not return a "conditional pass" marker anywhere in its JSON output | Helper tools work correctly | ✅ | 516ms |
| resolve-state-path.js — epic branch PASS: epic/<slug> resolves to the per-epic state.json path | Helper tools work correctly | ❌ | 516ms |
| resolve-state-path.js — epic branch PASS: reports exists:true once the state.json is present | Helper tools work correctly | ❌ | 431ms |
| resolve-state-path.js — non-epic and invalid PASS: on main it resolves to kind:none with no path | Helper tools work correctly | ❌ | 428ms |
| resolve-state-path.js — non-epic and invalid FAIL: an invalid (non-kebab) epic slug is an error (exit 1) | Helper tools work correctly | ❌ | 351ms |
| resolve-state-path.js — non-epic and invalid FAIL: legacy workflow-state.json is NOT treated as a valid state source | Helper tools work correctly | ❌ | 607ms |
| run-smoke-test.js — credential safety PASS: reports credentials_missing (without printing the value) when an env var is unset | Helper tools work correctly | ❌ | 326ms |
| run-smoke-test.js — credential safety PASS: the .sh artifact carries an env-var REFERENCE, never the credential value | Helper tools work correctly | ❌ | 425ms |
| run-smoke-test.js — credential safety PASS: a credential echoed back in the response body is redacted | Helper tools work correctly | ❌ | 313ms |
| run-smoke-test.js — error shapes FAIL: a refused connection is categorised (result failure / connection_refused), not a crash | Helper tools work correctly | ❌ | 333ms |
| run-smoke-test.js — error shapes FAIL: a missing --config exits non-zero with a status:error payload | Helper tools work correctly | ❌ | 358ms |
| scan-doc.js — plain markdown file PASS: reports correct line count and text type | Helper tools work correctly | ❌ | 318ms |
| scan-doc.js — plain markdown file FAIL: does not claim a text file is binary | Helper tools work correctly | ✅ | 286ms |
| scan-doc.js — binary file detection PASS: flags a buffer with null bytes as binary | Helper tools work correctly | ❌ | 285ms |
| scan-doc.js — binary file detection FAIL: does not attempt to count lines in a binary buffer as if it were text | Helper tools work correctly | ✅ | 312ms |
| scan-doc.js — keyword counting PASS: counts requested keywords case-insensitively | Helper tools work correctly | ❌ | 450ms |
| scan-doc.js — keyword counting FAIL: keywords not present yield zero, not undefined/crash | Helper tools work correctly | ❌ | 331ms |
| summarize-playwright.js PASS: a clean run reports result "pass" (exit 0) | Helper tools work correctly | ❌ | 284ms |
| summarize-playwright.js FAIL: a failing spec is reported and mapped to its story number (exit 1) | Helper tools work correctly | ❌ | 272ms |
| summarize-playwright.js FAIL: a run-level error with zero failing specs is still a fail (broken-run guard) | Helper tools work correctly | ❌ | 318ms |
| summarize-playwright.js FAIL: an unparseable / wrong-shape report exits 2 (treat as a run failure) | Helper tools work correctly | ❌ | 272ms |
| validate-generated-doc-names.js PASS: a correctly-named tree reports "ok" with zero drift (exit 0) | Helper tools work correctly | ❌ | 612ms |
| validate-generated-doc-names.js FAIL: a drift-named epic file is reported (status "drift", exit 1) | Helper tools work correctly | ❌ | 517ms |
| validate-generated-doc-names.js FAIL: a missing conventions schema exits 2 (can't audit without the source of truth) | Helper tools work correctly | ❌ | 414ms |

---

<sub>Generated 2026-08-03 07:08:32 · QA suite version 0.1.0 · code version n/a on branch n/a · Node v24.11.0, Vitest 2.1.9. Time taken is the real wall-clock time; checks run side by side, so it is shorter than adding up each one.</sub>
