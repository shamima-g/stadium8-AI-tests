# Test plan — /pack includes the shared API contract in the packaged backend (v1.6)

**Branch:** `version-1.6` (AI-tests repo, for the plan doc). **Where the tests live:** the **.NET
Linx8-QATests** suite (`C:\AI\Linx8-QATests-DO-NOT-DELETE\QATests`), **not** the frontend AI-tests vitest
tiers — Linx8 and Stadium 8 are fusing, and that suite already black-box-tests the `stadium-builder` `/pack`
→ `.t57` → `docker build` machinery this feature changes. See memory **[[linx8-stadium8-fusion-backend-tests]]**.

> **Reuse recommendation (the question asked): yes — extend, don't rebuild.** Every mechanic this feature needs
> already exists in Linx8-QATests: a fast Docker-free package-contents tier, an opt-in `docker build`-from-
> package tier with daemon gating + cleanup, a scaffold-then-overlay reference host, and an nswag-codegen test.
> The three ACs are new **tests + fixtures** added to that suite's existing files, reusing its helpers verbatim.
> Do **not** port these into the frontend vitest repo — they are xUnit/.NET and depend on the Linx8 fixtures;
> porting would orphan them. If one estate is wanted, bring the Linx8 `QATests` project into the fused repo
> (it is deliberately black-box and "can be lifted into its own repo unchanged" per its `.csproj`).

> **v2 — council-hardened** (claim-accuracy · falsifiability · adversarial/vacuous-green · feasibility). The
> reuse map checked out **verbatim** against the real suite. Three fixes applied: **(1, load-bearing)** the
> plan's **core premise — that a *missing* contract breaks the packaged `docker build` — is UNVERIFIED**: the
> real `dockerfile-template` runs only `COPY src src` + `dotnet publish` (no build-time nswag codegen) and
> `pack.cs` excludes `*.g.cs`, so a missing spec fails the build **only if** the Stadium backend csproj consumes
> it at publish time — which no available file confirms. **This must be pinned before T-L5a is worth writing**
> (see *Core premise* below). **(2)** `docs/docker-guide.md` **does not exist** in this suite — AC3's target is
> a file the fix must *ship*; the current package-contents prose is `.claude/commands/pack.md`. **(3)** the AC's
> `docker build -t demo-app - < DemoApp.t57` stdin form is **not implementable** with `Helpers\Cli.cs` (no
> stdin redirection, `UseShellExecute=false`) — use `Tarball.Extract` + `Docker.Build(dir)`. See **What the
> council changed**.

---

## ⚠ Core premise — verify before building T-L5a (council finding #1)

The whole "builds from its package" proof rests on one causal claim: **packing `api-spec.yaml` is what makes the
packaged `docker build` succeed, and omitting it makes it fail.** The council verified this is **not**
established by any file on hand:

- The real `dockerfile-template` (Linx8 cached host) does **only** `COPY src src` then `RUN dotnet publish …
  src/{{projectName}}` — **no nswag/codegen at build time**.
- `pack.cs` **excludes `*.g.cs`** — the generated controller/client is not in the package.

So a missing contract breaks the in-container `dotnet publish` **only if** the Stadium backend's `.csproj`
consumes the spec at publish time (an `<EmbeddedResource Include="…api-spec.yaml"/>` at a packable path, **or**
an MSBuild target that runs nswag during build). If it does **not**, `docker build` **succeeds without the
contract** and T-L5a's negative control is **vacuous** (and the feature's own premise is questionable).

**The feature's AC1 asserts the pre-fix package "fails to build" — so the feature author is asserting this
dependency exists.** The test must therefore:
1. **Pin the mechanism against the real `stadium-builder` backend scaffold** (not available in these roots — it's
   the fused CLI; confirm with the backend repo / feature author): *how* does the packaged build consume
   `generated-docs/specs/api-spec.yaml`? That answer fixes **both** the in-package path T-L1a asserts **and**
   why T-L5a's negative control reds.
2. **Build `OrdersHost` from the real `stadium-builder init` output**, carrying whatever contract-consuming
   csproj/build-target the tool actually scaffolds — **not** Linx8's `Greeting` seed overlay (whose
   `<EmbeddedResource>Greeting.yaml` is a Linx8-specific mechanism that would *mask* or *substitute* the real
   dependency).

Until #1 is answered, mark the premise **UNVERIFIED** and treat T-L5a as blocked; T-L1a (contents) and T-L0
(guide) are still writable.

**Status: spec-ahead.** Like the backend-at-intake feature, the fix isn't shipped: today `/pack` packages only
the backend project + the backend's own `docs/` folder, so a backend that reads the **shared** contract at
`generated-docs/specs/api-spec.yaml` (which sits *outside* `app-backend/`, referenced via
`../../generated-docs/specs/api-spec.yaml`) is packaged **without** it and fails to build from the package. The
tests below go **red on the current tool** (contract missing from the `.t57` ⇒ in-package `docker build` fails)
and **green once `/pack` carries the shared contract** where the backend expects it.

---

## The layout nuance that is the whole feature

Linx8's reference app embeds its spec *inside* the backend (`app-backend/<App>/docs/<Service>.yaml`), and
`pack.cs` already sweeps `docs/ → src/docs` — so for Linx8 the spec rides along today. **Stadium's contract is
shared**: it lives at the project root (`generated-docs/specs/api-spec.yaml`, sibling of `app-backend/`) and
the backend's nswag codegen reads it by relative path (`../../generated-docs/specs/api-spec.yaml`). `/pack`'s
current "project + backend docs" copy set **misses the shared root contract**. The fix: `/pack` also includes
`generated-docs/specs/api-spec.yaml` **at the in-package path the backend resolves it from**, so the packaged
build's nswag/`dotnet publish` step finds it. (`pack.cs`, verified via Linx8's cached host:
`PackFolder(..., "src/docs", excludeGenerated:true)` for backend docs + `PackFolder(..., "src/<project>", …)`
for the project — the root `generated-docs/specs/` is in neither set today.)

**Acceptance criteria (as given):**
1. A backend that reads the shared contract **builds from its package** — the `.t57` carries the contract where
   the backend expects it; `docker build -t demo-app - < DemoApp.t57` finishes without error.
2. A backend with **no** shared contract packs **as it does today** — `plain-app` still builds from its package.
3. The **Docker guide** (`docs/docker-guide.md`) describes the package contents and **names the API contract**.
   *(Council: `docs/docker-guide.md` does not exist in the suite today — the current package-contents prose is
   `.claude/commands/pack.md`. The fix must **ship** `docs/docker-guide.md` naming the contract and add it to
   `TemplateInvariantsTests.RequiredTemplateFiles`; T-L0 asserts on it and is red-now because it's absent. If
   the fused repo keeps `pack.md` as the guide instead, retarget T-L0 there.)*

---

## Tiering (onto Linx8-QATests' existing trait tiers)

| AC | Linx8 tier (trait) | Spend/Docker | What it proves |
|---|---|---|---|
| 1 + 2 (structural core) | **`pack` (L1)** — fast, ~11s, no Docker | none | the `.t57` **contents** carry (AC1) / correctly omit (AC2) the shared contract at the expected in-package path |
| 1 + 2 (end-to-end) | **`docker` (L5)** — opt-in, skips when no daemon | Docker | the packaged backend **`docker build`s** (AC1 with contract, AC2 plain-app); the pre-fix package **fails** (negative control) — **conditional on the *Core premise* being pinned** |
| 3 | **`fast` / L0 invariant** — offline | none | the shipped **`docs/docker-guide.md`** (the fix's new file; else `.claude/commands/pack.md`) **names the contract** among package contents |

**No AI judge.** Every check is a deterministic tar-entry list, a `docker build` exit code, or a doc-content
assertion. Each gets a **Mutant FAIL twin** (Linx8's `Helpers\Mutant.cs` clone-then-mutate) so it is shown to
go red — matching the suite's existing PASS/FAIL-twin convention (`ScaffoldingContractTests`,
`ServiceConventionsTests`). An optional live-Claude end-to-end (AC "add an operation from the contract, pack,
build") can be added to the **`manual`** tier via `AgenticEndToEndTests.cs` + `Helpers\ClaudeCli.cs`, but is not
required for green.

---

## The reference fixture to add — `demo-app` with a shared Orders contract

Reuse the `Helpers\ReferenceHost.cs` **caching/scaffold pattern** (SHA-256 keyed temp cache, scaffold → flatten
→ relocate under `app-backend/`), but **drive it from the real `stadium-builder init` output, NOT the Linx8
`Greeting` seed overlay** — the Greeting seed embeds its spec via `<EmbeddedResource>Greeting.yaml`, a
Linx8-specific mechanism that would mask the Stadium backend's real (and as-yet-unverified) contract dependency
(see *Core premise*). `OrdersHost` reproduces the AC1 setup exactly, deterministically and offline:

1. `stadium-builder init demo-app` into a temp cache.
2. Write the **shared** contract `generated-docs/specs/api-spec.yaml` (the AC's Orders spec — `GET /orders`,
   `operationId: ListOrders`).
3. Run the AC's codegen step `dotnet run .claude/scripts/generate-nswag.cs -- app-backend/DemoApp DemoApp
   ../../generated-docs/specs/api-spec.yaml Orders`. **Verify the script accepts a *pathful* 3rd arg** —
   `GenerateNswagScriptTests.cs` documents it as a bare *spec-filename* (→ `NSwag/<spec>.nswag`); a relative
   path may resolve oddly. Confirm before relying on it, or pass the form the script actually wants.
4. Add `app-backend/DemoApp/Services/Orders/Controller.cs` (the AC's 501 stub implementing the generated
   `ListOrders`).
5. `dotnet build app-backend` → "Build succeeded" (the pre-pack sanity gate; the scaffold-builds-clean mechanic
   is `ScaffoldingContractTests.Scaffold_builds_clean`).

Cache keyed by a SHA-256 of the inputs (as `ReferenceHost.HashSeed` does) so reruns are offline/fast. A second,
contract-less fixture `plain-app` (`stadium-builder init plain-app`, no `generated-docs/specs/`) backs AC2.

---

## Tests to add

### T-L1a — package carries the shared contract (AC1 structural core) — `tier=pack`
In `Tests\PackScriptTests.cs` (new `Packs_the_shared_api_contract_into_the_tarball`). After `/pack` on
`OrdersHost`, read `Helpers\Tarball.ListEntries(pkg)` and assert the shared contract is present at the
**in-package path the backend resolves** (impl-defined by the fix — e.g. `src/generated-docs/specs/api-spec.yaml`
so the backend's `../../generated-docs/specs/api-spec.yaml` resolves inside `src/<App>/…`; pin to the fix's
chosen location). Mirror the existing `e.StartsWith("src/docs/")` assertion in
`Packs_a_valid_app_into_a_linx_tarball_with_expected_layout`. **FAIL twin:** a pre-fix pack (or a Mutant that
removes the shared-contract copy step from `pack.cs`) ⇒ entry absent ⇒ test reds.

### T-L1b — plain-app packs well-formed, no contract (AC2 structural) — `tier=pack`
In `Tests\PackScriptTests.cs` (`Plain_app_packs_without_a_contract`). `/pack` on `plain-app`; assert the `.t57`
has `Dockerfile` + `src/<App>/…` and **no** `generated-docs/specs/` entry, and bin/obj/`.g.cs` still excluded
(reuse the exclusion assertions from `Generated_controller_is_excluded_from_the_package`). Proves the no-contract
path is unchanged.

### T-L5a — with-contract package `docker build`s (AC1 end-to-end) — `tier=docker` — **blocked on *Core premise***
In `Tests\PackagingAcceptanceTests.cs` (`Packaged_backend_with_contract_builds_a_docker_image`). Gate
`if (!Docker.IsAvailable) Assert.Skip(Docker.UnavailableReason)`. Run `/pack` on `OrdersHost`, then
`Tarball.Extract` + `Docker.Build(dir)` (the existing idiom — **not** the AC's `docker build - < DemoApp.t57`
stdin form: `Helpers\Cli.cs` has no stdin redirection and runs `UseShellExecute=false`, so `<` is impossible;
the extract-then-build path is equivalent). Assert `build.Succeeded` (exit 0, not timed out); `finally` →
`Docker.RemoveImage` + `PruneDanglingImages`; 10-min timeout. **Negative control (the regression):** the
**pre-fix** package (shared contract absent) ⇒ `Assert.False(build.Succeeded)` — **but this only reds if the
Stadium backend consumes the contract at publish time** (*Core premise*, unverified). The real
`dockerfile-template` runs **no** build-time codegen, so if the publish doesn't need the spec the build
**succeeds without it** and this control is vacuous. (`ServiceConventionsTests`' `embedded-spec` rule is a
*static csproj text linter*, not a build — it does **not** prove a publish fails; don't cite it as evidence the
control reds.) **Do not write T-L5a until the premise is pinned and reproduced in `OrdersHost`.**

### T-L5b — plain-app package `docker build`s (AC2 end-to-end) — `tier=docker`
In `Tests\PackagingAcceptanceTests.cs` (`Packaged_plain_app_builds_a_docker_image`). Same gate/cleanup; `/pack`
on `plain-app`; assert `docker build` succeeds — unchanged-today behaviour.

### T-L0 — docker guide names the contract (AC3) — `tier=fast`
In `Tests\TemplateInvariantsTests.cs` (`Docker_guide_names_the_api_contract`). **Target the file the fix ships
the guide in** — AC3 names `docs/docker-guide.md`, which **does not exist today** (red-now); the fix must create
it and add it to `RequiredTemplateFiles`. (If the fused repo keeps the existing `.claude/commands/pack.md` as
the package-contents guide, retarget there.) Assert **the package-contents section** names the API contract
(the `api-spec.yaml` / `generated-docs/specs/` path) — **scope to that section**, not a whole-file grep (which
could match any incidental mention). **Mutant FAIL twin** strips the mention ⇒ test reds.

---

## Acceptance → test traceability

| AC clause | `fast`/L0 | `pack`/L1 | `docker`/L5 |
|---|---|---|---|
| 1 — package carries the contract where the backend expects it | — | **T-L1a** (+ FAIL twin) | T-L5a (precondition) |
| 1 — packaged backend `docker build`s (contract present) | — | — | **T-L5a** (extract+build; negative control **conditional on Core premise**) |
| 2 — plain-app packs as today | — | T-L1b | — |
| 2 — plain-app `docker build` succeeds | — | — | T-L5b |
| 3 — docker guide names the contract | **T-L0** (+ Mutant twin) | — | — |

---

## Reuse map (what to copy, by Linx8 path)

| Need | Reuse directly (path under `…\Linx8-QATests-DO-NOT-DELETE\QATests`) |
|---|---|
| Docker gating + build + cleanup | `Helpers\Docker.cs` (`IsAvailable` = `docker --version` **and** `docker info`; `Build`, `RemoveImage`, `PruneDanglingImages`) |
| `.t57` contents / extract | `Helpers\Tarball.cs` (`ListEntries`, `Extract`) |
| Package-contents assertions (present/excluded) | `Tests\PackScriptTests.cs` (`Packs_a_valid_app…expected_layout`, `Generated_controller_is_excluded…`) |
| `docker build` from package + negative control | `Tests\PackagingAcceptanceTests.cs` (`Packed_app_builds_a_docker_image`, `Tarball_without_app_sources_fails_to_build`) |
| Scaffold → overlay → embed-spec reference host | `Helpers\ReferenceHost.cs` + `setup\seed\app-backend\` + `setup\Setup-GreetingHost.ps1` |
| nswag codegen CLI | `Tests\GenerateNswagScriptTests.cs` |
| Required-template-file + valid-YAML invariants + Mutant twin | `Tests\TemplateInvariantsTests.cs`, `Helpers\Mutant.cs` |
| Scaffold caching/relocate pattern (NOT the Greeting seed overlay) | `Helpers\ReferenceHost.cs` (SHA-256 cache, scaffold→flatten→relocate) — drive from real `stadium-builder init`, see *Core premise* |
| csproj-embedding reference (Linx8's mechanism, for comparison only) | `Tests\ServiceConventionsTests.cs` `embedded-spec` (static linter — **not** a build), `ReferenceHost.PatchAppCsproj` |
| Process runner, temp isolation, portable discovery | `Helpers\Cli.cs`, `Helpers\TempDir.cs`, `Helpers\DirCopy.cs`, `Helpers\RepoLocator.cs`, `Fixtures\RepoFixture.cs` |
| Runner, tier flags, report + rule map | `Run-QATests.ps1` (`-IncludeDocker`), `[Trait("tier", …)]`, `Generate-Report.ps1` (add `PackSharedContractTests`/extend `PackScriptTests`,`PackagingAcceptanceTests` rows) |
| Optional live-Claude end-to-end | `Tests\AgenticEndToEndTests.cs` + `Helpers\ClaudeCli.cs` (`manual` tier) |

---

## Feasibility, gates, prerequisites

- **Spec-ahead:** the fix must land in the `stadium-builder` tool (`pack.cs` carries the shared contract;
  `docs/docker-guide.md` names it) for the tiers to go green. Until then **T-L1a** (contents) and **T-L0**
  (guide) red on the current tool — the meaningful regression proof; **T-L5a** is blocked until the *Core
  premise* is pinned. Pin the targeted tool version via Linx8's `workflow-baseline.txt` / `-WorkflowVersion`.
- **Prereqs:** .NET 10 SDK + the `stadium-builder` tool (both already required by Linx8); **Docker only for the
  `docker` tier** — absent ⇒ `Assert.Skip`, never a failure (`Docker.IsAvailable`). `BUILDER_CMD` override keeps
  it portable; the AC's `dotnet run --project <repo>/src/Bootstrapper.Cli --` form is a valid `BUILDER_CMD`.
- **In-package path + the publish-time dependency are set by the fix, not knowable here:** the exact `.t57`
  destination for the contract (so the backend resolves it) **and** whether/how a missing contract fails the
  publish both come from the real `stadium-builder` backend scaffold (*Core premise*). T-L1a asserts the path;
  T-L5a's negative control is only valid once the dependency is pinned. Resolve both with the implementer /
  backend repo before writing T-L5a.
- **Docker stdin form not implementable:** `Helpers\Cli.cs` has no stdin redirection and runs
  `UseShellExecute=false`, so the AC's `docker build - < DemoApp.t57` can't be driven as-is — use
  `Tarball.Extract` + `Docker.Build(dir)` (equivalent). Only add a stdin variant if `Cli.Run` is extended with a
  stdin-file arg.

## Suggested order

0. **Pin the *Core premise*** with the backend repo / feature author: how does the packaged `dotnet publish`
   consume `generated-docs/specs/api-spec.yaml`? This gates T-L5a and fixes T-L1a's asserted path.
1. **AC3 / T-L0** (`fast`) + Mutant twin — cheapest, offline, writable now; red because `docs/docker-guide.md`
   (or the contract mention) is absent today.
2. **Build the `OrdersHost` reference fixture** from the real `stadium-builder init` + **T-L1a / T-L1b**
   (`pack`) — fast, no Docker; prove the contents check reds on the pre-fix pack (T-L1a FAIL twin) and that
   plain-app is unchanged.
3. **T-L5a / T-L5b** (`docker`, opt-in) — **only after step 0**; end-to-end `docker build` via extract+build;
   include the (now-valid) pre-fix negative control. `-IncludeDocker` on a Docker host; skips cleanly elsewhere.
4. Record proof under Linx8 `TestResults/` (TRX + per-run Markdown + the built image tag log); extend
   `Generate-Report.ps1`'s rule map so a failure names the contract-packaging check.

## Appendix — evidence (paths under `C:\AI\Linx8-QATests-DO-NOT-DELETE\QATests`)

- `Tests\PackScriptTests.cs` — `src/docs/` present + bin/obj/`.g.cs` excluded; `Generated_controller_is_excluded…`.
- `Tests\PackagingAcceptanceTests.cs` — clone → `/pack` → extract → `Docker.Build` → `Assert.True(Succeeded)`;
  delete-sources negative control.
- `Helpers\Docker.cs` — two-stage `IsAvailable` (`docker --version` + `docker info`), `Build`/`RemoveImage`/
  `PruneDanglingImages`, 10-min timeout. `Helpers\Tarball.cs` — `ListEntries`/`Extract`.
- `Helpers\ReferenceHost.cs` (+ `setup\seed\app-backend\`, `setup\Setup-GreetingHost.ps1`) — scaffold+overlay+
  `PatchAppCsproj` embeds the spec; SHA-256 seed cache. `Tests\GenerateNswagScriptTests.cs` — nswag CLI.
- `Tests\TemplateInvariantsTests.cs` — `RequiredTemplateFiles` (incl. `.claude/scripts/dockerfile-template`),
  `Embedded_openapi_spec_is_valid_yaml` / `Corrupt_openapi_spec_is_detected`; `Helpers\Mutant.cs`.
- `Tests\ServiceConventionsTests.cs` — `embedded-spec` rule (removing `<EmbeddedResource …yaml/>` is flagged).
- `QATests.csproj` (xUnit v3, net10, black-box, liftable), `Run-QATests.ps1` (`-IncludeDocker`),
  `Generate-Report.ps1` (rule map: `PackScriptTests`, `PackagingAcceptanceTests`, `GenerateNswagScriptTests`,
  `SeedInvariantsTests`), `README.md` (tier table: `pack` L1, `docker` L5), `QATests\README.md`.
- `pack.cs` (cached): `docs → src/docs` + `project → src/<name>` (root `generated-docs/specs/` in neither today);
  `dockerfile-template`: `COPY src src` + `dotnet publish` (**no build-time nswag**). Optional live tier:
  `Tests\AgenticEndToEndTests.cs` + `Helpers\ClaudeCli.cs` (`manual`).

---

## What the council changed (this is v2)

1. **Core premise flagged UNVERIFIED (load-bearing).** The plan assumed a *missing* contract fails the packaged
   `docker build`. The real `dockerfile-template` runs only `COPY src src` + `dotnet publish` (no build-time
   codegen) and `pack.cs` excludes `*.g.cs`, so that only holds if the Stadium backend csproj consumes the spec
   at publish time — which **no available file confirms**. Added a **Core premise** section: pin the mechanism
   against the real `stadium-builder` backend scaffold before writing T-L5a; its negative control is otherwise
   vacuous. The feature's own AC1 asserts the dependency exists, so this is a "confirm & reproduce," not a
   "the feature is wrong."
2. **`OrdersHost` built from the real scaffold, not Linx8's Greeting seed.** Overlaying the Greeting seed would
   import its `<EmbeddedResource>Greeting.yaml` mechanism and *mask* the Stadium backend's real (unverified)
   dependency. Reuse only the caching/relocate pattern; drive from `stadium-builder init`.
3. **Two wrong anchors fixed.** `docs/docker-guide.md` **doesn't exist** in the suite — it's a file the fix must
   ship (T-L0 red-now, add to `RequiredTemplateFiles`); fallback target `.claude/commands/pack.md`. And the AC's
   `docker build - < DemoApp.t57` stdin form is **not implementable** with `Helpers\Cli.cs` — use
   `Tarball.Extract` + `Docker.Build(dir)`.
4. **Miscite corrected.** `ServiceConventionsTests`' `embedded-spec` is a static csproj-text linter, not a
   build — it cannot show a publish fails; removed as "evidence" the negative control reds.
5. **generate-nswag arg nuance.** The script documents a bare *spec-filename* 3rd arg; the AC passes a relative
   path. Flagged to verify before relying on it in `OrdersHost`.

**Reuse map verified verbatim.** Every other cited Linx8 test, helper, trait, and the `pack.cs`/
`dockerfile-template` snippets checked out against the real suite — the plan's grounding was accurate; its one
real hole was the causal premise, now surfaced.
