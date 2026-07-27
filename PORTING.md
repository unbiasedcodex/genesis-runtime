# Geb Engine Porting Checklist

Single source of truth for porting the Geb browser engine to the glc
freestanding dialect. Update the checkboxes as work lands (one commit per
item or small group; check only after CI confirms). Resume from the first
unchecked item.

**Verification loop**: push to `ci` -> `engine-check.yml` probes each module
standalone and publishes logs to the `ci-logs` branch (`summary.txt` +
per-module logs). System boot test lives in genesis-kernel's workflow.

**Probe status (2026-07-26, after phase 2 parser pack)**: net OK.
Parse phase now CLEAN for css, tls, image (they reach codegen and hit the
const-array panic -> phase 3). crypto parses but fails LLVM verification
("Function return type does not match operand type of return inst").
layout: `matches!` (fixed in parser, pending probe). html: `ref` keyword
(fixed, pending probe). browser/js: attributes and `use` in STATEMENT
position inside fn bodies (new gap, see 2.11) plus raw strings (2.10).

---

## Phase 1 — Mechanical rewrites in the engine (no compiler changes)

- [x] 1.1 crypto: replace `static mut RNG_STATE`/`RNG_INITIALIZED`
      (src/crypto/mod.gl:24-25) with state threaded via context struct
      param (glc has no statics; freestanding.md:184). Update all users
      in src/crypto/.
- [x] 1.2 layout: `mut self` receiver -> `&mut self` (src/layout/inline.gl:69).
- [x] 1.3 html: `mut self` receiver -> `&mut self` (src/html/treebuilder.gl:422).
- [x] 1.4 layout: `0.0_f64` -> `0.0` (src/layout/block.gl:485).
- [x] 1.5 css: remove `<'a>` fn generic params, elide lifetimes
      (src/css/parser.gl:865, src/css/mod.gl:497).
- [x] 1.6 closure param patterns `|&x|` / `|(a,b)|` (~20 sites, e.g.
      src/css/mod.gl:312 `.position(|&x| ...)`, src/html/treebuilder.gl:251
      `.retain(|&x| ...)`): rewrite as plain-param closures or explicit
      loops. DECIDED (checked reference.md:618-643): stdlib has NO
      .position/.retain — VecIter offers find/any/all/map/filter only,
      in Vec::iter()/VecIter::* function style. Rewrite these sites as
      explicit while loops. Wave-2 risk noted: engine uses method-call
      sugar on Vec/String everywhere; html passed typeck so sugar seems
      accepted, but stdlib method NAMES not in reference.md will surface
      as errors in Phase 4.
- [x] 1.7 css: `F: FnMut(...)` bounds -> `fn(...)` pointer params
      (src/css/cascade.gl:1356 + grep for more).
- [x] 1.8 tls: remove `core::mem::transmute` x2 (src/tls/mod.gl:796,864);
      store callbacks as typed `fn(...)` fields (needs Phase 2.2 to parse).
- [ ] 1.9 MOVED TO 2.10: there are 7 raw-string sites (6 in browser/mod.gl:
      318,370,395,434,458,523 + tab.gl:469), multi-line HTML/CSS bodies with
      embedded quotes — a glc lexer feature is cheaper than rewriting them.
- [x] 1.10 browser: `Key::Char('1') ..= Key::Char('9')` -> binding + guard
      (src/browser/main.gl:663).

## Phase 2 — glc parser/lexer pack (genesis-lang repo)

Phase 1 complete except 1.9 (moved to 2.10). Phase 2 items unblock the rest.

- [x] 2.1 Ignore unknown attributes (e.g. `#[test]`) and SKIP items annotated
      `#[cfg(test)]` via token-level balanced-brace skipping
      (parser.rs:362-368 whitelist is repr/derive only). Kills ~half of
      html/js/browser error volume incl. `use super::*` and test raw strings.
- [x] 2.2 `fn(...) -> T` pointer TYPES in parse_type (parser.rs:3188).
      AST TypeKind::FnPtr (ast.rs:548), typeck (infer.rs:3775) and IR
      (lower.rs:1448) already wired. Unblocks tls entirely.
- [x] 2.3 Keywords as method/field names after `.` (`.join` fails; join/spawn
      are keywords, token.rs:150). Scope to post-dot position.
- [x] 2.4 Float literal suffixes `0.0_f64` in lexer (token.rs:42). (Optional
      once 1.4 lands; still worth accepting.)
- [x] 2.5 Unicode char escapes `'\u{...}'` (token.rs:55 char regex; 54 sites
      in html/css tokenizers).
- [x] 2.6 Char/int range patterns `'0'..='9'` in match (PatternKind::Range
      exists ast.rs:891; parser hookup missing; check exhaustiveness
      handles Range or require wildcard arm).
- [x] 2.7 `ref` / `ref mut` in struct-pattern fields (parser.rs:3584;
      PatternKind::Ref exists; verify downstream semantics safe under HARC).
- [x] 2.8 CLOSED by 1.2/1.3 (call sites rewritten to &mut self instead).
- [ ] 2.10 Raw strings r#"..."# (multi-line) in the lexer — replaces 1.9.
- [x] 2.9b `matches!(value, pat [if guard])` desugared in the parser into a
      match expression (63 sites in the engine).
- [x] 2.9c `ref` accepted as a keyword token in binding and struct-field
      patterns (the first attempt only handled it as an identifier).
- [ ] 2.11 Attributes and `use` in STATEMENT position inside fn bodies
      (browser/mod.gl ~9474, js/mod.gl:414): skip `#[...]`-annotated
      statements and either support or skip in-body `use`.
- [ ] 2.12 crypto LLVM verification error: "Function return type does not
      match operand type of return inst" — find the offending function
      (likely a fixed-array or struct return) and fix lowering.
- [ ] 2.9 Tests for each item following tests/ conventions; `cargo test`
      green in lang CI.

## Phase 3 — glc codegen: global const arrays (genesis-lang repo)

- [ ] 3.1 lower.rs:2110 — type global const arrays properly (not I64).
- [ ] 3.2 llvm.rs declare_global (:208-210) — emit real LLVM constant-array
      initializers (elements u8..u64/i8..i64/f64; repeat `[v; N]` form).
- [ ] 3.3 llvm.rs:1705-1712 — const refs produce the global's POINTER
      (GlobalRef) so Load/GEP/indexing work (panic site was llvm.rs:912).
- [ ] 3.4 Const struct globals: implement if symmetric/small, else replace
      silent stub with a clear compile error.
- [ ] 3.5 Codegen tests (const table indexed in main; repeat-initializer;
      i64 case). Unblocks image, fixes silent miscompile in crypto.

## Phase 4 — Wave-2 audit after Phases 1-3

- [ ] 4.1 Re-run probe; update the status table above.
- [ ] 4.2 image: audit calls to std::mem::swap, sort_by, Peekable
      (png.gl:333, svg.gl:473,713) — not in glc stdlib; rewrite or add.
- [ ] 4.3 Sweep remaining per-module errors until probe shows all OK
      except js.

## Phase 5 — js module port (long pole; LAST)

- [ ] 5.1 Port src/js/ off Rc/RefCell (155 sites: builtins 41, dom 62,
      interpreter 45, mod 7) to arena/index style modeled on html's
      node_idx approach (which already typechecks).
- [ ] 5.2 Remove `use` in fn bodies, std::time, println!, env-capturing
      native closures (fn-ptr table instead), `@` bindings (~20) -> nested
      match, tuple closure params.
- [ ] 5.3 Probe: js OK.

## Phase 6 — Browser integration (first rendered page)

- [ ] 6.1 Fix src/browser/mod.gl API drift (with_config/browser.config,
      phantom re-exports TabBarItem/HitTestResult/Color).
- [ ] 6.2 Replace phantom HttpClient/HttpResponse/Url/TlsStream in
      src/browser/tab.gl with real net/http.gl (`http_get(addr)`) +
      TLS syscalls (wrappers copied into geb_rt.gl from shell runtime).
- [ ] 6.3 Enable engine mods in src/geb.gl compilation root; `make
      check-geb` green; boot CI green with geb running.
- [ ] 6.4 Wire browser::Browser into geb.gl event loop: scancode->Key
      translation, mouse polling, UICommand rasterizer via fb_* syscalls.
- [ ] 6.5 MILESTONE: fetch HTML over HTTP from CI listener, parse, style,
      layout, paint — screenshot of first rendered page.
- [ ] 6.6 HTTPS via kernel TLS syscalls (socat proxy already in CI).

## Loose ends (parallel-friendly, low priority)

- [ ] L.1 Shell tests GW8K/GOOG time out while kernel-level connect works
      (serial: SR=1 then TMO) — investigate shell net path.
- [ ] L.2 glc: fix tcp_debug_dec corruption for values > 999
      (tcp.gl:1893) — hampers debugging.
- [ ] L.3 glc bug upstream: inline asm with two outputs panics inkwell
      (single-output workaround in tcp_rdtsc); proper fix in llvm.rs asm
      lowering.
- [ ] L.4 RX ring: single consumer discipline (mod.gl/e1000.gl vs tcp.gl
      paths share RX_CUR with different RDT rules).

## Done (for context)

- [x] fb syscall arg offsets (R8/R9) + vga_putchar color — verified by screenshot.
- [x] TCP: TSC pacing, RDT trailing discipline, RST fast-fail — EST/RES=0 in CI.
- [x] TLS 1.2 vs amazon.com via socat: TLS OK in CI.
- [x] Geb skeleton as PID 5 at native base 0x5000000; RAMFS 32MB + reserve
      fix; 5th GRUB module; `geb` shell command execs it — screenshot.
- [x] net/mod.gl index + duplicate `mod url;` removed; engine probe workflow.
