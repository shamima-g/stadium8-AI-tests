// GOOD calibration (Playwright side). Same controls as the .test.tsx: 'Status' → radiogroup,
// 'Save changes' → button. Note the Playwright AC ids differ from the Vitest ones (coverage is a
// single tag per AC, so the files cover DISJOINT ACs) — controls are matched by name, not AC id.
import { test, expect } from '@playwright/test';

test.describe('Epic task-board, Story 2: status filter', () => {
  // AC-2 (playwright): filtering by status updates the list
  test('filters the list by Status', async ({ page }) => {
    await page.goto('/board');
    await page.getByRole('radiogroup', { name: 'Status' }).getByRole('radio', { name: 'Open' }).check();
    await expect(page.getByRole('button', { name: /save changes/i })).toBeEnabled();
  });
});
