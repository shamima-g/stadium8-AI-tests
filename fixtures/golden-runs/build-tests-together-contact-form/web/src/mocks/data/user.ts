import type { Role, User } from '@/types/api-generated';

/** Password shared by every seeded account (project.md §Authentication). Mock-only — never a real credential. */
export const SEEDED_PASSWORD = 'Test123';

export const createUser = (overrides: Partial<User> = {}): User => ({
  id: 1,
  email: 'visitor@example.com',
  firstName: 'Vera',
  lastName: 'Visitor',
  role: 'Visitor',
  ...overrides,
});

/** The three seeded accounts, one per role (brief §Seeded data). */
export const seededUsers: readonly User[] = [
  createUser({ id: 1, email: 'visitor@example.com', firstName: 'Vera', lastName: 'Visitor', role: 'Visitor' }),
  createUser({ id: 2, email: 'agent@example.com', firstName: 'Sam', lastName: 'Agent', role: 'Support Agent' }),
  createUser({ id: 3, email: 'admin@example.com', firstName: 'Alex', lastName: 'Admin', role: 'Admin' }),
];

export const seededUserFor = (role: Role): User => {
  const seededUser = seededUsers.find((user) => user.role === role);
  if (!seededUser) {
    throw new Error(`No seeded user for role "${role}"`);
  }
  return seededUser;
};
