import { z } from "zod";

export const credentialsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1).max(100).optional()
});

export const loginSchema = credentialsSchema.omit({ displayName: true });
