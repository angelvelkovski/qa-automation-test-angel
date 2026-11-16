# QA Automation Task: Playwright + TypeScript

UI tests for https://www.saucedemo.com and API tests for https://jsonplaceholder.typicode.com.

## Setup

Requirements: Node 22.5+ (the SQL check uses Node's built-in SQLite), and Java 11+ only if you want the Allure report.

```bash
npm install
npx playwright install chromium
```

`.env` is created from `.env.example` automatically on the first `npm test`
(or run `cp .env.example .env`). It holds base URLs, the public demo credentials and the tax rate.

## Run

| Goal | Command |
| --- | --- |
| Whole suite | `npm test` |
| UI tests only | `npm run test:ui` |
| API tests only | `npm run test:api` |
| One file | `npx playwright test tests/ui/checkout.spec.ts` |
| One test by title | `npx playwright test -g "item total"` |
| One user / project | `npx playwright test --project=ui-problem` |
| See the browser | `npx playwright test --headed --workers=1` |
| Slow motion | `SLOWMO=800 npx playwright test --headed --workers=1 --project=ui-standard` |
| Debug / UI mode | `npx playwright test --ui` |
| Postman collection (Part 2) | `npm run test:postman` |
| SQL queries check (Part 3) | `npm run test:sql` |
| Everything (typecheck, Playwright, Postman, SQL) | `npm run test:all` |
| Type check | `npm run typecheck` |

Running a UI project automatically runs the `setup` project first (it logs in and saves the session).

## Reports

- **Playwright HTML report**: `npm run report`
- **Allure report** (grouped by epic/feature, with step timeline and descriptions): run the tests, then `npm run allure`
  (`allure:generate` builds it, `allure:open` serves it).

`ui-problem` is **expected to show as failed (✘)** in the list output. That is the known defect, not a broken suite (see below).
The overall result still counts as passed.

## Project layout

```
tests/        specs only (ui/, api/, setup/auth.setup.ts)
src/pages/        page objects (one per screen) + BasePage
src/components/   reusable pieces (header, line items, order summary)
src/api/          typed clients (BaseApiClient, Users, Posts) + schemas/
src/fixtures/     wires pages and clients into tests
src/test-data/    users, products, data builders, known defects
postman/           Postman collection + environment (Part 2)
sql/              queries.sql, sample data and local check (Part 3)
src/utils/        money math, schema validation, auth paths, report metadata
src/config/env.ts the only place that reads process.env
```

## Design decisions

1. **Layers:** specs contain no selectors and no URLs. Pages and components own locators (`data-test` attributes via `getByTestId`); typed API clients own URLs and requests; fixtures wire both into tests.
2. **Auth once:** a `setup` project logs in per user and saves `storageState`; UI projects depend on it, so tests start logged in and stay independent and parallel-safe.
3. **Config and secrets:** base URLs, credentials and tax rate come from environment variables through one typed `env` module (`.env` locally, pipeline secrets/variables in CI; see *Security and secrets*). Nothing is hardcoded in code or `playwright.config.ts`.
4. **Expected values are computed**, not hardcoded: item prices are read from the page, then item total, tax and total are calculated in integer cents (`utils/money`) and compared with the overview.
5. **problem_user (known defect):** the same test runs for both users. For problem_user it is marked `test.fail` with a description. It stays visible in the report as an expected failure instead of being skipped or deleted, and turns red the day the defect is fixed, so the marker gets removed. (Its checkout form drops the last name, so it never reaches the overview.)
6. **Non-persisting POST:** jsonplaceholder acknowledges a POST (201 and an id) but stores nothing, so the follow-up GET returns 404. The tests assert the create contract, and the read-back asserts 404 by default, switchable via `API_PERSISTS_DATA=true` for a real backend. The test documents the behaviour instead of pretending persistence exists.
7. **Contract test:** `GET /users/{id}` is validated against a JSON schema (Ajv), not field by field.
8. **No hard waits:** Playwright auto-waiting only. The app is a SPA (URL changes before the DOM re-renders), so components look rows up by product name instead of counting rows. A 5s `actionTimeout` makes a missing element fail fast as an ordinary error, which `test.fail` can recognise.
9. **Deliberately skipped:** CI workflow, data-driven login tests, tags, API-seeded cart. They are not required, and each would add code without adding evidence for the required scenarios.
10. **At 500 tests / five engineers:** group specs by feature folder, add a lint/format check and CI sharding, move test data creation to API calls, add Allure history, and put a CODEOWNERS file on `src/pages` and `src/api`.

## Assumptions

- The saucedemo demo accounts (`standard_user`, `problem_user`) and the 8% sales tax are public and stable; tax is configurable via `TAX_RATE`.
- "Two items" means Sauce Labs Backpack and Sauce Labs Bike Light.
- Rounding: tax is rounded to the nearest cent, as the site displays it.
- Tests run on Chromium only.
- jsonplaceholder returns 201 for POST and 404 for a post that was never really stored.

## Security and secrets

**What is in this repo:** only saucedemo's *public demo* accounts (`standard_user` / `problem_user`, published on the saucedemo login page) and public API URLs. They are not real secrets, but the repo is built as if they were:

- **Nothing sensitive in code or config.** `playwright.config.ts` and the sources contain no credentials or URLs. Everything is read from environment variables in one place (`src/config/env.ts`). A missing variable stops the run with a clear error, so there are no silent hardcoded fallbacks.
- **`.env` is git-ignored**, together with `.auth/` (saved login sessions, which are as sensitive as a password) and the test reports. Only `.env.example` is committed, and it holds demo values and placeholders, never real ones.
- **Reports can leak data.** Traces and screenshots are only kept on failure, and the report folders are not committed. For a system with real data, publish reports only to access-controlled storage.

**In a CI/CD pipeline, values come from the pipeline, not from files.** Nothing is committed; the pipeline injects the same variable names the code already reads:

| Kind | Examples | Where it lives (GitHub Actions) |
| --- | --- | --- |
| **Secrets** (sensitive, masked in logs) | `STANDARD_USER`, `STANDARD_PASSWORD`, `PROBLEM_USER`, `PROBLEM_PASSWORD`, any API token | Repository/Environment **Secrets** (Settings, Secrets and variables, Actions) |
| **Variables** (not sensitive, can differ per environment) | `UI_BASE_URL`, `API_BASE_URL`, `TAX_RATE`, `API_PERSISTS_DATA` | Repository/Environment **Variables** |

```yaml
- run: npm test
  env:
    UI_BASE_URL: ${{ vars.UI_BASE_URL }}
    API_BASE_URL: ${{ vars.API_BASE_URL }}
    TAX_RATE: ${{ vars.TAX_RATE }}
    API_PERSISTS_DATA: ${{ vars.API_PERSISTS_DATA }}
    STANDARD_USER: ${{ secrets.STANDARD_USER }}
    STANDARD_PASSWORD: ${{ secrets.STANDARD_PASSWORD }}
    PROBLEM_USER: ${{ secrets.PROBLEM_USER }}
    PROBLEM_PASSWORD: ${{ secrets.PROBLEM_PASSWORD }}
```

Pipeline practices that go with it: use separate **Environments** (e.g. staging, production) with their own secrets and required reviewers; give the workflow the least permissions it needs (`permissions: contents: read`); never print secrets or upload `.env` / `.auth/` as artifacts; do not expose secrets to pull requests from forks; rotate credentials on a schedule and immediately if one leaks; and add secret scanning (GitHub secret scanning or gitleaks) so a committed secret is caught early.

> [!NOTE]
> **Example CI workflow.** This repo does not ship a workflow file; this is how it would be wired up in GitHub Actions
> (save as `.github/workflows/tests.yml`, and create the secrets and variables first under
> Settings → Secrets and variables → Actions). `ui-problem` is an expected failure, so the job still ends green.
> After a run, download the report artifacts from the run's summary page (Artifacts section).
>
> ```yaml
> name: tests
> on: [push, pull_request]
>
> permissions:
>   contents: read          # least privilege: the job only needs to read the code
>
> jobs:
>   test:
>     runs-on: ubuntu-latest
>     env:
>       # Variables: not sensitive, may differ per environment
>       UI_BASE_URL: ${{ vars.UI_BASE_URL }}
>       API_BASE_URL: ${{ vars.API_BASE_URL }}
>       TAX_RATE: ${{ vars.TAX_RATE }}
>       API_PERSISTS_DATA: ${{ vars.API_PERSISTS_DATA }}
>       # Secrets: masked in logs, never committed
>       STANDARD_USER: ${{ secrets.STANDARD_USER }}
>       STANDARD_PASSWORD: ${{ secrets.STANDARD_PASSWORD }}
>       PROBLEM_USER: ${{ secrets.PROBLEM_USER }}
>       PROBLEM_PASSWORD: ${{ secrets.PROBLEM_PASSWORD }}
>     steps:
>       - uses: actions/checkout@v4
>       - uses: actions/setup-node@v4
>         with: { node-version: 22, cache: npm }
>       - uses: actions/setup-java@v4          # only needed to build the Allure report
>         with: { distribution: temurin, java-version: 17 }
>       - run: npm ci
>       - run: npx playwright install --with-deps chromium
>       - run: npm run test:all
>       - run: npm run allure:generate
>         if: always()                        # build the Allure report even when tests fail
>
>       # Artifacts: upload with `if: always()` so they exist exactly when something failed.
>       # Only report output is uploaded, never .env or .auth/ (saved login sessions).
>       - uses: actions/upload-artifact@v4
>         if: always()
>         with:
>           name: allure-report                # open locally: npx allure open <downloaded folder>
>           path: allure-report
>           retention-days: 14
>       - uses: actions/upload-artifact@v4
>         if: always()
>         with:
>           name: allure-results               # raw data, lets you rebuild the report or keep Allure history
>           path: allure-results
>           retention-days: 14
>       - uses: actions/upload-artifact@v4
>         if: always()
>         with:
>           name: playwright-report            # open locally: npx playwright show-report <downloaded folder>
>           path: playwright-report
>           retention-days: 14
>       - uses: actions/upload-artifact@v4
>         if: failure()
>         with:
>           name: failure-traces-and-screenshots
>           path: test-results                 # traces/screenshots are kept only for failed tests
>           retention-days: 7
> ```

## Parts 2 and 3

- **Postman** (`/postman`): collection plus environment, with shared tests at collection level. See [postman/README.md](postman/README.md). Run: `npm run test:postman`.
- **SQL** (`/sql/queries.sql`): the two queries, with an explanation and a local logic check. See [sql/README.md](sql/README.md). Run: `npm run test:sql`. Paste the queries into the W3Schools playground for the real data.
