// GOOD calibration — the two files agree on every shared control (same role + name + strategy).
// A story's single test-generator wrote both; this is what a conforming BUILD looks like.
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { StatusFilter } from '@/components/StatusFilter';

describe('Epic task-board, Story 2: status filter', () => {
  // AC-1 (vitest): the Status control is a radio group with the three states
  it('renders the Status radio group', () => {
    render(<StatusFilter />);
    expect(screen.getByRole('radiogroup', { name: 'Status' })).toBeInTheDocument();
    expect(screen.getByRole('radio', { name: 'Open' })).toBeInTheDocument();
  });

  // AC-3 (vitest): Save button present
  it('shows the Save changes button', () => {
    render(<StatusFilter />);
    expect(screen.getByRole('button', { name: /save changes/i })).toBeEnabled();
  });
});
