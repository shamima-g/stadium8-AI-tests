/**
 * CLI entry for `ingest-verdict` (run via `npm run ingest-verdict -- <slotReviewDir> [...]`).
 * A dedicated entry (instead of a self-invoke guard) because argv[1] differs across runners — under
 * vite-node it is vite-node.mjs, not this file — so a `process.argv[1]`-based guard never fires. This file
 * exists only to run the CLI; the tests import `runCli`/`ingestVerdict` from ./ingest-verdict directly.
 */
import { runCli } from './ingest-verdict';

process.exit(runCli(process.argv.slice(2)));
