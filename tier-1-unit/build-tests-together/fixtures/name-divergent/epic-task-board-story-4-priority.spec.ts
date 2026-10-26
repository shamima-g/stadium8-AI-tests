// NAME-DIVERGENT calibration (Playwright side). Same combobox role, but the accessible name is
// 'Priority level' vs 'Priority' in the .test.tsx. No shared name → nothing to compare → the names
// appear in uncompared.{vitestOnly, playwrightOnly} for human review.
import { test, expect } from '@playwright/test';

test.describe('Epic task-board, Story 4: priority', () => {
  // AC-2 (playwright)
  test('sets the priority', async ({ page }) => {
    await page.goto('/board');
    await page.getByRole('combobox', { name: 'Priority level' }).selectOption('High');
  });
});
