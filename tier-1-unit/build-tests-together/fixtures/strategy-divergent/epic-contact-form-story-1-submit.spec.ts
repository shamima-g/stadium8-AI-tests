// STRATEGY-DIVERGENT calibration (Playwright side). 'Email' is reached via getByLabel (strategy
// 'label') while the .test.tsx used getByRole('textbox') (strategy 'role') → mismatch for "email".
// 'Send' is found the same way in both (button) → that one agrees.
import { test, expect } from '@playwright/test';

test.describe('Epic contact-form, Story 1: submit', () => {
  // AC-2 (playwright)
  test('submits the contact form', async ({ page }) => {
    await page.goto('/contact');
    await page.getByLabel('Email').fill('a@b.com');
    await page.getByRole('button', { name: 'Send' }).click();
  });
});
