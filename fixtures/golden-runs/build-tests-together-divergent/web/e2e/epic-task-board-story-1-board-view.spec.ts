// Story 1 — MATCHING pair (Playwright side): same 'Task Board' heading + 'New Task' button.
import { test, expect } from '@playwright/test';

test.describe('Epic task-board, Story 1: board view', () => {
  // AC-2 (playwright)
  test('opens the board and starts a new task', async ({ page }) => {
    await page.goto('/board');
    await expect(page.getByRole('heading', { name: 'Task Board' })).toBeVisible();
    await page.getByRole('button', { name: 'New Task' }).click();
  });
});
