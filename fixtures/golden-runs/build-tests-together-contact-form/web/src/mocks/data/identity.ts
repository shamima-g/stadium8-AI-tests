import type { Role, SessionResponse } from '@/types/api-generated';

import { seededUserFor } from './user';

/** Role landing pages (brief BR2): Visitor → Contact form; Support Agent / Admin → Inbox. */
export const LANDING_PATH_BY_ROLE: Record<Role, string> = {
  Visitor: '/contact',
  'Support Agent': '/inbox',
  Admin: '/inbox',
};

/** Pages each role may open (brief R5 / project.md §Roles & Permissions). Anything else shows the permission-denied banner. */
export const PAGES_BY_ROLE: Record<Role, readonly string[]> = {
  Visitor: ['/contact', '/my-messages'],
  'Support Agent': ['/inbox'],
  Admin: ['/inbox'],
};

const IDLE_TIMEOUT_MS = 30 * 60 * 1000;
const ABSOLUTE_TIMEOUT_MS = 12 * 60 * 60 * 1000;

export interface MockUserInfo extends SessionResponse {
  /** Roles the signed-in user holds — the app gates on these. */
  Roles: Role[];
  /** Pages the signed-in user may open — the app gates navigation on these. */
  Pages: string[];
}

const isRole = (roleName: string): roleName is Role =>
  Object.prototype.hasOwnProperty.call(LANDING_PATH_BY_ROLE, roleName);

/**
 * The session/userinfo payload for a seeded role — the single identity contract
 * shared by Vitest, Playwright and any runtime mock handlers.
 */
export const userInfoFor = (roleName: string, signedInAt: Date = new Date()): MockUserInfo => {
  if (!isRole(roleName)) {
    throw new Error(`Unknown role "${roleName}" — expected Visitor, Support Agent or Admin`);
  }
  return {
    user: seededUserFor(roleName),
    landingPath: LANDING_PATH_BY_ROLE[roleName],
    idleExpiresAt: new Date(signedInAt.getTime() + IDLE_TIMEOUT_MS).toISOString(),
    absoluteExpiresAt: new Date(signedInAt.getTime() + ABSOLUTE_TIMEOUT_MS).toISOString(),
    Roles: [roleName],
    Pages: [...PAGES_BY_ROLE[roleName]],
  };
};
