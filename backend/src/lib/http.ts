import type { Request, Response, NextFunction } from "express";

export function ok<T>(response: Response, data: T, meta: Record<string, unknown> = {}) {
  return response.json({
    data,
    meta: {
      cachedAt: new Date().toISOString(),
      stale: false,
      ...meta
    }
  });
}

export class HttpError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export function errorHandler(error: unknown, _request: Request, response: Response, _next: NextFunction) {
  if (error instanceof HttpError) {
    return response.status(error.status).json({ error: { code: error.code, message: error.message } });
  }

  console.error(error);
  return response.status(500).json({ error: { code: "INTERNAL_ERROR", message: "Something went wrong." } });
}
