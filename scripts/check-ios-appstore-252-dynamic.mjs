#!/usr/bin/env node
/**
 * App Store guideline 2.5.2 guard: fail when iOS Swift sources build
 * selector or class names at runtime (interpolation, variables, loops).
 *
 * Static lookups via string literals or enum static member refs are allowed.
 *
 * Usage:
 *   node scripts/check-ios-appstore-252-dynamic.mjs
 *   node scripts/check-ios-appstore-252-dynamic.mjs --dir path
 */

import fs from "node:fs";
import path from "node:path";

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

const EXACT_STRING_LITERAL = /^"([^"\\]|\\.)*"$/;
const STATIC_MEMBER_REF = /^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$/;

function isExactStringLiteral(arg) {
  return EXACT_STRING_LITERAL.test(arg.trim());
}

function isStaticMemberRef(arg) {
  const t = arg.trim();
  if (!STATIC_MEMBER_REF.test(t)) return false;
  if (t.includes("(") || t.includes("+")) return false;
  return true;
}

function isAllowedLookupArg(arg) {
  const t = arg.trim();
  if (isExactStringLiteral(t)) return true;
  if (isStaticMemberRef(t)) return true;
  return false;
}

function extractParenArg(line, calleePattern) {
  const re = new RegExp(`${calleePattern}\\s*\\(\\s*([^)]+)\\)`, "g");
  const args = [];
  let m;
  while ((m = re.exec(line)) !== null) {
    args.push(m[1].trim());
  }
  return args;
}

function lineHasDynamicSymbolSyntax(line) {
  if (!/NSSelectorFromString|NSClassFromString|(?<![A-Za-z0-9_])Selector\s*\(|#selector\s*\(/.test(line)) {
    return false;
  }
  if (/\\\([^)]*\)/.test(line)) return true;
  if (/\.appending\s*\(/.test(line)) return true;
  if (/"\s*\+|'\s*\+|\+\s*"/.test(line)) return true;
  return false;
}

/** @type {{ id: string, test: (line: string) => boolean }[]} */
const LINE_RULES = [
  {
    id: "dynamic-symbol-syntax",
    test: (line) => lineHasDynamicSymbolSyntax(line),
  },
  {
    id: "nss-selector-non-static",
    test: (line) => {
      if (!line.includes("NSSelectorFromString")) return false;
      const args = extractParenArg(line, "NSSelectorFromString");
      if (!args.length) return true;
      return args.some((arg) => !isAllowedLookupArg(arg));
    },
  },
  {
    id: "nsclass-non-static",
    test: (line) => {
      if (!line.includes("NSClassFromString")) return false;
      const args = extractParenArg(line, "NSClassFromString");
      if (!args.length) return true;
      return args.some((arg) => !isAllowedLookupArg(arg));
    },
  },
  {
    id: "selector-non-static",
    test: (line) => {
      if (!/(?<![A-Za-z0-9_])Selector\s*\(/.test(line)) return false;
      const stripped = line.replace(/#selector\s*\([^)]*\)/g, "");
      if (!/(?<![A-Za-z0-9_])Selector\s*\(/.test(stripped)) return false;
      const args = extractParenArg(stripped, "(?<![A-Za-z0-9_])Selector");
      if (!args.length) return false;
      return args.some((arg) => !isAllowedLookupArg(arg));
    },
  },
];

function readText(p) {
  try {
    return fs.readFileSync(p, "utf8");
  } catch (e) {
    throw new Error(`cannot read ${p}: ${e?.message || e}`);
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

function pluginExpectsIos(pluginDir) {
  const pkgPath = path.join(pluginDir, "package.json");
  if (!exists(pkgPath)) return false;
  try {
    const pkg = JSON.parse(readText(pkgPath));
    const cap = typeof pkg.capacitor === "object" && pkg.capacitor ? pkg.capacitor : {};
    return Boolean(cap.ios);
  } catch {
    return false;
  }
}

function walkSwiftFiles(rootDir) {
  const out = [];
  const stack = [rootDir];
  while (stack.length) {
    const dir = stack.pop();
    let entries;
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true });
    } catch (e) {
      throw new Error(`cannot read directory ${dir}: ${e?.message || e}`);
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

/**
 * @returns {{ violations: object[], fatal: string[] }}
 */
function scanPluginDir(pluginDir) {
  const iosSources = path.join(pluginDir, "ios", "Sources");
  const fatal = [];

  if (!exists(iosSources)) {
    if (pluginExpectsIos(pluginDir)) {
      fatal.push(`missing ios/Sources under ${pluginDir}`);
    }
    return { violations: [], fatal };
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
  return { violations, fatal };
}

const args = parseArgs(process.argv);
const pluginDir = args.dir;

let scanResult;
try {
  scanResult = scanPluginDir(pluginDir);
} catch (e) {
  console.error(`[appstore-252-dynamic] ERROR: ${e?.message || e}`);
  process.exit(1);
}

const relDir = path.relative(process.cwd(), pluginDir) || ".";

if (scanResult.fatal.length) {
  console.error(`[appstore-252-dynamic] FAIL in ${relDir}`);
  for (const msg of scanResult.fatal) {
    console.error(`- fatal: ${msg}`);
  }
  process.exit(1);
}

if (scanResult.violations.length) {
  console.error(`[appstore-252-dynamic] FAIL in ${relDir}`);
  for (const v of scanResult.violations) {
    console.error(`- ${v.rule}: ${v.file}:${v.line}: ${v.text}`);
  }
  process.exit(1);
}

console.log("[appstore-252-dynamic] OK");
process.exit(0);
