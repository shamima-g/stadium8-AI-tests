/**
 * CLI entry for `review:status` (run via `npm run review:status [-- <goldenRunsRoot>]`). A dedicated entry
 * (like ingest-verdict-cli.ts) because argv[1] under vite-node is vite-node.mjs, so a self-invoke guard
 * never fires. The tests import `runStatusCli`/`slotStatus`/`formatStatusReport` from ./review-status.
 */
import { runStatusCli } from './review-status';

process.exit(runStatusCli(process.argv.slice(2)));
