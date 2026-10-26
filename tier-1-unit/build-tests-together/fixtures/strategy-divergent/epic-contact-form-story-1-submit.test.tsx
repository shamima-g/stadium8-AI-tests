// STRATEGY-DIVERGENT calibration — same control 'Email', same intent, but found a DIFFERENT WAY:
// getByRole('textbox') here vs getByLabel in the spec. test-generator.md:296 requires both files to
// "find each control the same way", so this MUST be reported as a mismatch
// ({role=textbox} vs {label}) for name "email".
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { ContactForm } from '@/components/ContactForm';

describe('Epic contact-form, Story 1: submit', () => {
  // AC-1 (vitest)
  it('renders the email field and submit button', () => {
    render(<ContactForm />);
    expect(screen.getByRole('textbox', { name: 'Email' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Send' })).toBeEnabled();
  });
});
