import { Router } from "express";
import { ok } from "../lib/http.js";
import { credentialsSchema, loginSchema } from "./auth.validation.js";
import * as authService from "./auth.service.js";

export const authRouter = Router();

authRouter.post("/signup", async (request, response, next) => {
  try {
    const input = credentialsSchema.parse(request.body);
    ok(response, await authService.signup(input));
  } catch (error) {
    next(error);
  }
});

authRouter.post("/login", async (request, response, next) => {
  try {
    const input = loginSchema.parse(request.body);
    ok(response, await authService.login(input));
  } catch (error) {
    next(error);
  }
});

authRouter.post("/refresh", async (_request, response) => {
  ok(response, await authService.refresh());
});

authRouter.post("/logout", async (_request, response) => {
  ok(response, await authService.logout());
});

authRouter.get("/me", async (request, response, next) => {
  try {
    ok(response, await authService.me(request.headers.authorization));
  } catch (error) {
    next(error);
  }
});
