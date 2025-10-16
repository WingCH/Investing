# Repository Guidelines

## Project Structure & Module Organization
Each investment tool lives in its own top-level folder (e.g., `JT_EA/`). Keep strategy code, configs, datasets, and notes inside that directory, following a predictable layout such as `lib/`, `signals/`, `backtests/`, and `notes.md`. Include a `README.md`, `metadata.yaml` (or `.json`), and a `PRINCIPLES.md` derived from `TOOL_PRINCIPLES_TEMPLATE.md` to capture the tool’s rationale. Create `shared/` for reusable components, and maintain a root-level catalog (e.g., `CATALOG.md`) that lists active tools with owners and status.

## Architecture & Context Practices
The folder-per-strategy model isolates changes, making git diffs and performance tracking straightforward while preventing cross-strategy regressions. Standard names (`signals/`, `backtests/`, `context.md`, `PRINCIPLES.md`) let automation collect performance stats or feed AI summaries without per-tool adjustments. Keep short context files updated so retrieval systems and agents can load summaries quickly; store larger research artifacts under predictable subfolders to support indexing.

## Coding Style & Naming Conventions
Respect platform defaults: Dart files use lower_snake_case, Swift types and files use UpperCamelCase. Indent Dart with two spaces, Swift with four. Name strategy folders with concise identifiers (`FX_Arbitrage`, `JT_EA`) and reuse established metadata field names to keep automation interoperable.

## Testing Guidelines
Ship tests with new logic. Mirror production file names (`portfolio_service_test.dart`) and suffix Swift test classes with `Tests`. Cover entry, exit, and risk-control paths at minimum. Store fixtures or mocks under `test/fixtures/` and prefer `mocktail` for Flutter mocks.

## Commit & Pull Request Guidelines
Write imperative commits (“Add RSI signal evaluator”) and keep unrelated work split. Pull requests must describe the change, list touched strategies, link issues, and show passing results (`flutter test`, `swift test`). Provide screenshots or logs for UI or reporting updates so reviewers can validate behavior efficiently.
