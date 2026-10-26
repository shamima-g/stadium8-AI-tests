// Story 2 — DIVERGENT: Vitest treats 'Status' as a radio group...
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
