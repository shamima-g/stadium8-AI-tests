// ROLE-DIVERGENT calibration (Playwright side). 'Status' is a combobox here, a radiogroup in the
// .test.tsx → mismatch on name "status": {role=radiogroup} vs {role=combobox}.
import { test, expect } from '@playwright/test';

test.describe('Epic task-board, Story 2: status filter', () => {
  // AC-2 (playwright)
  test('filters the list by Status', async ({ page }) => {
    await page.goto('/board');
    await page.getByRole('combobox', { name: 'Status' }).selectOption('Open');
  });
});
