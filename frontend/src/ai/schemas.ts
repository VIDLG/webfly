import { z } from 'zod';

/**
 * Common schemas shared across AI tools to avoid duplication.
 */

/** Schema for UI elements */
export const elementSchema = z.object({
  type: z.string(),
  props: z.record(z.string(), z.unknown()).optional(),
  children: z.array(z.string()).optional(),
});

/** Schema for effect code modification requests */
export const effectCodeSchema = z.object({
  code: z.string(),
  description: z.string().optional(),
});