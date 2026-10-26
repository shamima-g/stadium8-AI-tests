// Story 2 — DIVERGENT (Playwright side): ...but the spec treats the same 'Status' control as a dropdown
// (combobox). Same accessible name, different role → the parity check MUST flag a mismatch.
import { test, expect } from '@playwright/test';

test.describe('Epic task-board, Story 2: status filter', () => {
  // AC-2 (playwright)
  test('filters the list by Status', async ({ page }) => {
    await page.goto('/board');
    await page.getByRole('combobox', { name: 'Status' }).selectOption('Open');
  });
});
