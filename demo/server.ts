import { bunTranspiler } from "@hono/bun-transpiler";
import { Hono } from "hono";
import { serveStatic } from "hono/bun";

const app = new Hono();

app.get("/:scriptName{.+.tsx?}", bunTranspiler());
app.get("/*", serveStatic({ root: "./" }));

export default app;
