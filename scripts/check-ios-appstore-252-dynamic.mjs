#!/usr/bin/env node
/**
 * App Store guideline 2.5.2 guard: fail when iOS Swift sources build
 * selector or class names at runtime (interpolation, variables, loops).
 *
 * Static lookups via string literals or `static let` constants are allowed.
 *
 * Usage:
 *   node scripts/check-ios-appstore-252-dynamic.mjs
 *   node scripts/check-ios-appstore-252-dynamic.mjs --dir path
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const SKIP_DIRS = new Set([
  "node_modules",
  "dist",
  "build",
  ".build",
  ".gradle",
  "Pods",
  "DerivedData",
  ".swiftpm",
  ".git",
  "example-app",
  "Tests",
]);

const STRING_LITERAL = /^"([^"\\]|\\.)*"/;
const STATIC_MEMBER = /^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$/;

/** @type {{ id: string, test: (line: string) => boolean }[]} */
const LINE_RULES = [
  {
    id: "nss-selector-non-literal",
    test: (line) => {
      if (!line.includes("NSSelectorFromString")) return false;
      const m = line.match(/NSSelectorFromString\s*\(\s*([^)]+)\)/);
      if (!m) return true;
      const arg = m[1].trim();
      return !STRING_LITERAL.test(arg);
    },
  },
  {
    id: "nsclass-non-literal",
    test: (line) => {
      if (!line.includes("NSClassFromString")) return false;
      const m = line.match(/NSClassFromString\s*\(\s*([^)]+)\)/);
      if (!m) return true;
      const arg = m[1].trim();
      if (STRING_LITERAL.test(arg)) return false;
      if (STATIC_MEMBER.test(arg)) return false;
      return true;
    },
  },
  {
    id: "selector-string-interpolation",
    test: (line) =>
      (line.includes("NSSelectorFromString") || line.includes("NSClassFromString") || line.includes('Selector("')) &&
      /\\\(/.test(line),
  },
  {
    id: "selector-string-concat",
    test: (line) => {
      if (!line.includes("NSSelectorFromString") && !line.includes("NSClassFromString")) return false;
      return /"\s*\+|'\s*\+|\+\s*"/.test(line);
    },
  },
  {
    id: "selector-loop-variable",
    test: (line) => {
      if (!line.includes("NSSelectorFromString")) return false;
      const m = line.match(/NSSelectorFromString\s*\(\s*([a-z][A-Za-z0-9_]*)\s*\)/);
      return Boolean(m);
    },
  },
];

function readText(p) {
  try {
    return fs.readFileSync(p, "utf8");
  } catch {
    return "";
  }
}

function exists(p) {
  try {
    fs.accessSync(p);
    return true;
  } catch {
    return false;
  }
}

function parseArgs(argv) {
  const out = { dir: process.cwd() };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--dir" || a === "--pluginDir") {
      out.dir = path.resolve(argv[++i] || ".");
      continue;
    }
  }
  return out;
}

function walkSwiftFiles(rootDir) {
  const out = [];
  const stack = [rootDir];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch {
      continue;
    }
    for (const e of entries) {
      if (e.isDirectory()) {
        if (SKIP_DIRS.has(e.name)) continue;
        stack.push(path.join(dir, e.name));
        continue;
      }
      if (e.isFile() && e.name.endsWith(".swift")) {
        out.push(path.join(dir, e.name));
      }
    }
  }
  out.sort();
  return out;
}

function scanPluginDir(pluginDir) {
  const iosSources = path.join(pluginDir, "ios", "Sources");
  if (!exists(iosSources)) {
    return [];
  }

  const violations = [];
  for (const file of walkSwiftFiles(iosSources)) {
    const lines = readText(file).split(/\r?\n/);
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      for (const rule of LINE_RULES) {
        if (rule.test(line)) {
          violations.push({
            rule: rule.id,
            file: path.relative(pluginDir, file),
            line: i + 1,
            text: line.trim(),
          });
        }
      }
    }
  }
  return violations;
}

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const args = parseArgs(process.argv);
const pluginDir = args.dir;

const violations = scanPluginDir(pluginDir);
if (violations.length) {
  const relDir = path.relative(process.cwd(), pluginDir) || ".";
  console.error(`[appstore-252-dynamic] FAIL in ${relDir}`);
  for (const v of violations) {
    console.error(`- ${v.rule}: ${v.file}:${v.line}: ${v.text}`);
  }
  process.exit(1);
}

console.log("[appstore-252-dynamic] OK");
process.exit(0);
