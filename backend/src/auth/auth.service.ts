import argon2 from "argon2";
import jwt from "jsonwebtoken";
import { env } from "../lib/env.js";
import { HttpError } from "../lib/http.js";
import { prisma } from "../lib/prisma.js";

function accessToken(userId: string) {
  return jwt.sign(
    { sub: userId },
    env.JWT_SECRET,
    { expiresIn: env.ACCESS_TOKEN_TTL as jwt.SignOptions["expiresIn"] }
  );
}

async function createRefreshToken(userId: string) {
  const token = crypto.randomUUID() + "." + crypto.randomUUID();
  const tokenHash = await argon2.hash(token);
  const expiresAt = new Date(Date.now() + env.REFRESH_TOKEN_DAYS * 24 * 60 * 60 * 1000);
  await prisma.refreshToken.create({ data: { userId, tokenHash, expiresAt } });
  return token;
}

export async function signup(input: { email: string; password: string; displayName?: string }) {
  const passwordHash = await argon2.hash(input.password, { type: argon2.argon2id });
  try {
    const user = await prisma.user.create({
      data: { email: input.email, passwordHash, displayName: input.displayName },
      select: { id: true, email: true, displayName: true }
    });
    return { accessToken: accessToken(user.id), refreshToken: await createRefreshToken(user.id), user };
  } catch (error: any) {
    if (error.code === "P2002") {
      throw new HttpError(409, "EMAIL_EXISTS", "This email is already registered.");
    }
    throw error;
  }
}

export async function login(input: { email: string; password: string }) {
  const user = await prisma.user.findUnique({ where: { email: input.email } });
  if (!user || !(await argon2.verify(user.passwordHash, input.password))) {
    throw new HttpError(401, "INVALID_CREDENTIALS", "Email or password is incorrect.");
  }
  return {
    accessToken: accessToken(user.id),
    refreshToken: await createRefreshToken(user.id),
    user: { id: user.id, email: user.email, displayName: user.displayName }
  };
}

export async function refresh() {
  return { accessToken: "todo", refreshToken: "todo" };
}

export async function logout() {
  return { success: true };
}

export async function me(authHeader?: string) {
  if (!authHeader?.startsWith("Bearer ")) {
    throw new HttpError(401, "UNAUTHORIZED", "Missing or invalid token.");
  }
  const token = authHeader.substring(7);
  try {
    const payload = jwt.verify(token, env.JWT_SECRET) as { sub: string };
    const user = await prisma.user.findUnique({
      where: { id: payload.sub },
      select: { id: true, email: true, displayName: true }
    });
    if (!user) throw new Error();
    return user;
  } catch (err) {
    throw new HttpError(401, "UNAUTHORIZED", "Invalid token.");
  }
}
