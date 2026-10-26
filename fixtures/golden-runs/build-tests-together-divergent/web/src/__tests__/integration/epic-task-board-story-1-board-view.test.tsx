// Story 1 — MATCHING pair (both files agree on every control).
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { Board } from '@/components/Board';

describe('Epic task-board, Story 1: board view', () => {
  // AC-1 (vitest)
  it('renders the board heading and New Task button', () => {
    render(<Board />);
    expect(screen.getByRole('heading', { name: 'Task Board' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'New Task' })).toBeEnabled();
  });
});
