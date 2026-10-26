// ROLE-DIVERGENT calibration — the exact reported bug. Vitest treats 'Status' as a radio group;
// the Playwright spec (sibling file) treats the same 'Status' control as a dropdown (combobox).
// Same accessible name, different role → the parity check MUST report a mismatch.
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { StatusFilter } from '@/components/StatusFilter';

describe('Epic task-board, Story 2: status filter', () => {
  // AC-1 (vitest)
  it('renders the Status radio group', () => {
    render(<StatusFilter />);
    expect(screen.getByRole('radiogroup', { name: 'Status' })).toBeInTheDocument();
  });
});
