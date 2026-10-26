// NAME-DIVERGENT calibration — the residual the check CANNOT catch statically: the same control is
// named 'Priority' here and 'Priority level' in the spec. Nothing ties the two names to one control,
// so this is NOT a mismatch — it surfaces as UNCOMPARED (status 'skipped-no-overlap') for a human to
// eyeball in PROOF.md. This fixture proves the limitation is SURFACED, never silently green.
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { PriorityPicker } from '@/components/PriorityPicker';

describe('Epic task-board, Story 4: priority', () => {
  // AC-1 (vitest)
  it('renders the Priority dropdown', () => {
    render(<PriorityPicker />);
    expect(screen.getByRole('combobox', { name: 'Priority' })).toBeInTheDocument();
  });
});
