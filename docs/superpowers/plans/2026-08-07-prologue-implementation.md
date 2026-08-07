# Borrowed Fortune — Prologue Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a working, testable Chapter 0 (Prologue) of *Borrowed Fortune*, playable end-to-end in Godot, with the core engine systems (ledger/economy, per-faction reputation, dialogue, save/load, the diegetic glossary "Margin") implemented as tested, pure GDScript and wired to real Prologue content.

**Architecture:** Engine/content split, mirroring the sibling project `vigil`: `engine/` holds pure, `RefCounted`-based, unit-tested GDScript classes with zero scene-tree dependencies; `content/` holds plain JSON data (dialogue trees, glossary entries) that content authors edit without touching engine code; `scenes/` holds the Godot scenes/scripts that orchestrate engine + content into something playable. Chapters 1–7 are explicitly out of scope — this plan stops at a complete, playable Prologue.

**Tech Stack:** Godot 4.3 (GDScript), GUT (Godot Unit Test, github.com/bitwes/Gut) for automated testing, plain JSON for content data.

## Global Constraints

- **Godot version floor: 4.3.** All API usage in this plan (`FileAccess`, `JSON.stringify`/`JSON.parse_string`, typed arrays) targets Godot 4.x; do not use Godot 3 APIs (`File`, `JSON.parse`).
- **No combat system.** Per spec Section 1 — nothing in this plan implements piloted combat of any kind.
- **Engine layer purity.** Every file under `engine/` extends `RefCounted` (never `Node`), so it can be unit-tested with GUT without instancing a scene tree. Scene-tree/UI code lives only under `scenes/`.
- **Money is dirham-equivalent internally.** All monetary math uses a single `float` unit ("dirham-equivalent"); gold dinar coins convert to this unit via a fixed exchange constant on `Ledger` (`GOLD_TO_SILVER_VALUE_RATIO`). This matches spec Section 6 ("coins are weighed, not counted").
- **Factions are plain strings, not an enum**, so future chapters can introduce new factions via content data without an engine change. This plan's known faction ids: `"ghaznavid_officials"`, `"trading_families"`, `"hidden_network"`, `"townsfolk"` (spec Section 6).
- **Content is plain JSON, not compiled Resources.** Dialogue trees and glossary entries live under `content/` as `.json` files loaded at runtime via `FileAccess`/`JSON.parse_string`. Content authors must never need to open a `.gd` file to add a line of dialogue or a glossary entry.
- **Naming idiom override.** This plan uses GDScript's own idiom — `snake_case` for variables/functions, `PascalCase` for `class_name` types — rather than the general camelCase preference in the user's global coding-style rules. This is a deliberate exception: matching the target language's own convention is what "readable, well-named" code means in the Godot ecosystem, and camelCase GDScript reads as foreign to Godot's own tooling, docs, and any future contributor.
- **Coverage measurement gap, flagged honestly.** GDScript has no mature line-coverage tool equivalent to `pytest-cov`. This plan satisfies the *intent* of the global 80%-coverage rule by giving every public method on every engine class its own passing + edge-case test, rather than a measured percentage — noted here rather than silently claimed.
- **Commit after every task**, per the repo's established single-file-then-commit pattern from the spec commit.
- **JSON numbers deserialize as `float`, never `int`.** Godot's `JSON.parse_string` does not preserve the int/float distinction — every number from parsed content or save data comes back as `float`. Any typed-`int` parameter fed from JSON-sourced data (e.g. `ReputationTracker.adjust_reputation`'s `delta: int`) must be explicitly wrapped in `int(...)` at the call site — see Task 13.

---

## File Structure

```
borrowed-fortune/
├── project.godot
├── .gitignore
├── addons/gut/                              (vendored third-party test framework)
├── engine/
│   ├── ledger/
│   │   ├── Coin.gd
│   │   ├── Debt.gd
│   │   ├── Ledger.gd
│   │   ├── MudarabaPartnership.gd
│   │   └── Suftaja.gd
│   ├── reputation/
│   │   └── ReputationTracker.gd
│   ├── margin/
│   │   ├── MarginGlossary.gd
│   │   └── GlossedTextParser.gd
│   ├── dialogue/
│   │   └── DialogueEngine.gd
│   └── save/
│       ├── GameState.gd
│       └── SaveManager.gd
├── content/
│   ├── glossary/
│   │   └── prologue_terms.json
│   └── chapters/
│       └── chapter_00_prologue/
│           └── prologue.json
├── scenes/
│   ├── main/
│   │   ├── Main.tscn
│   │   └── Main.gd
│   ├── chapter_view/
│   │   ├── ChapterView.tscn
│   │   └── ChapterView.gd
│   └── margin_popup/
│       ├── MarginPopup.tscn
│       └── MarginPopup.gd
└── tests/unit/
    ├── test_coin.gd
    ├── test_debt.gd
    ├── test_ledger.gd
    ├── test_mudaraba_and_suftaja.gd
    ├── test_reputation_tracker.gd
    ├── test_margin_glossary.gd
    ├── test_glossed_text_parser.gd
    ├── test_dialogue_engine.gd
    ├── test_save_manager.gd
    ├── test_prologue_glossary_content.gd
    ├── test_prologue_dialogue_content.gd
    └── test_chapter_view.gd
```

---

### Task 1: Project scaffolding + GUT test framework

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `addons/gut/` (vendored from https://github.com/bitwes/Gut, default branch)
- Create: `tests/unit/test_bootstrap.gd`

**Interfaces:**
- Consumes: nothing (first task).
- Produces: a working `godot --headless ... -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` command every later task's tests run through.

- [ ] **Step 1: Create the Godot project file**

Create `project.godot`:

```ini
; Engine configuration file.
config_version=5

[application]

config/name="Borrowed Fortune"
run/main_scene="res://scenes/main/Main.tscn"
config/features=PackedStringArray("4.3", "Forward Plus")

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

Note: `run/main_scene` points at a scene that doesn't exist until Task 13. That's expected — the project will open and run tests fine before then; only launching the game itself requires Task 13.

- [ ] **Step 2: Create `.gitignore`**

```
.godot/
*.tmp
export.cfg
export_presets.cfg
```

- [ ] **Step 3: Vendor the GUT addon**

```bash
git clone --depth 1 https://github.com/bitwes/Gut.git /tmp/gut_vendor_clone
mkdir -p addons
cp -r /tmp/gut_vendor_clone/addons/gut addons/gut
rm -rf /tmp/gut_vendor_clone
```

- [ ] **Step 4: Write a bootstrap smoke test**

Create `tests/unit/test_bootstrap.gd`:

```gdscript
extends GutTest

func test_gut_pipeline_runs():
	assert_eq(1 + 1, 2, "sanity check that the GUT test runner executes at all")
```

- [ ] **Step 5: Run the suite and verify it passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: 1 test, 1 pass, 0 fail. If Godot reports it can't find `addons/gut/plugin.cfg`, re-check Step 3 copied the `addons/gut` directory (not `Gut/addons/gut` nested one level too deep).

- [ ] **Step 6: Commit**

```bash
git add project.godot .gitignore addons/ tests/
git commit -m "chore: scaffold Godot project and vendor GUT test framework"
```

---

### Task 2: `Coin` value object

**Files:**
- Create: `engine/ledger/Coin.gd`
- Test: `tests/unit/test_coin.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `Coin.new(metal: int, actual_weight_grams: float, purity: float)`, `Coin.Metal.GOLD` / `Coin.Metal.SILVER`, `coin.pure_metal_grams() -> float`, `coin.to_dict() -> Dictionary`, `Coin.from_dict(data: Dictionary) -> Coin`, `Coin.minted_dinar(purity: float = 1.0) -> Coin`, `Coin.minted_dirham(purity: float = 1.0) -> Coin`. Used by `Ledger` (Task 4) and `GameState`/`SaveManager` (Task 9).

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_coin.gd`:

```gdscript
extends GutTest

func test_pure_metal_grams_multiplies_weight_by_purity():
	var coin := Coin.new(Coin.Metal.SILVER, 3.0, 0.9)
	assert_almost_eq(coin.pure_metal_grams(), 2.7, 0.0001)

func test_minted_dinar_uses_standard_gold_weight_at_full_purity():
	var dinar := Coin.minted_dinar()
	assert_eq(dinar.metal, Coin.Metal.GOLD)
	assert_almost_eq(dinar.actual_weight_grams, 4.25, 0.0001)
	assert_almost_eq(dinar.purity, 1.0, 0.0001)

func test_minted_dirham_uses_standard_silver_weight():
	var dirham := Coin.minted_dirham(0.85)
	assert_eq(dirham.metal, Coin.Metal.SILVER)
	assert_almost_eq(dirham.actual_weight_grams, 2.97, 0.0001)
	assert_almost_eq(dirham.purity, 0.85, 0.0001)

func test_to_dict_and_from_dict_round_trip():
	var original := Coin.new(Coin.Metal.GOLD, 4.1, 0.92)
	var restored := Coin.from_dict(original.to_dict())
	assert_eq(restored.metal, original.metal)
	assert_almost_eq(restored.actual_weight_grams, original.actual_weight_grams, 0.0001)
	assert_almost_eq(restored.purity, original.purity, 0.0001)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_coin.gd -gexit`
Expected: FAIL — `Coin` does not exist yet.

- [ ] **Step 3: Implement `Coin`**

Create `engine/ledger/Coin.gd`:

```gdscript
extends RefCounted
class_name Coin

enum Metal { GOLD, SILVER }

const DINAR_NOMINAL_WEIGHT_GRAMS := 4.25
const DIRHAM_NOMINAL_WEIGHT_GRAMS := 2.97

var metal: int
var actual_weight_grams: float
var purity: float

func _init(p_metal: int, p_actual_weight_grams: float, p_purity: float) -> void:
	metal = p_metal
	actual_weight_grams = p_actual_weight_grams
	purity = p_purity

func pure_metal_grams() -> float:
	return actual_weight_grams * purity

func to_dict() -> Dictionary:
	return {
		"metal": metal,
		"actual_weight_grams": actual_weight_grams,
		"purity": purity,
	}

static func from_dict(data: Dictionary) -> Coin:
	return Coin.new(data["metal"], data["actual_weight_grams"], data["purity"])

static func minted_dinar(purity: float = 1.0) -> Coin:
	return Coin.new(Coin.Metal.GOLD, DINAR_NOMINAL_WEIGHT_GRAMS, purity)

static func minted_dirham(purity: float = 1.0) -> Coin:
	return Coin.new(Coin.Metal.SILVER, DIRHAM_NOMINAL_WEIGHT_GRAMS, purity)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_coin.gd -gexit`
Expected: 4 tests, 4 pass.

- [ ] **Step 5: Commit**

```bash
git add engine/ledger/Coin.gd tests/unit/test_coin.gd
git commit -m "feat: add Coin value object with weight/purity and JSON round-trip"
```

---

### Task 3: `Debt` value object

**Files:**
- Create: `engine/ledger/Debt.gd`
- Test: `tests/unit/test_debt.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `Debt.new(creditor_name: String, amount_dirham_equivalent: float, is_guaranteed_by_kafala: bool = false)`, `debt.to_dict() -> Dictionary`, `Debt.from_dict(data: Dictionary) -> Debt`. Used by `Ledger` (Task 4).

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_debt.gd`:

```gdscript
extends GutTest

func test_constructor_defaults_kafala_flag_to_false():
	var debt := Debt.new("Ibrahim al-Sarraf", 100.0)
	assert_eq(debt.creditor_name, "Ibrahim al-Sarraf")
	assert_almost_eq(debt.amount_dirham_equivalent, 100.0, 0.0001)
	assert_false(debt.is_guaranteed_by_kafala)

func test_constructor_accepts_explicit_kafala_flag():
	var debt := Debt.new("Rukn ibn Faramarz", 50.0, true)
	assert_true(debt.is_guaranteed_by_kafala)

func test_to_dict_and_from_dict_round_trip():
	var original := Debt.new("Nasuh", 60.0, true)
	var restored := Debt.from_dict(original.to_dict())
	assert_eq(restored.creditor_name, original.creditor_name)
	assert_almost_eq(restored.amount_dirham_equivalent, original.amount_dirham_equivalent, 0.0001)
	assert_eq(restored.is_guaranteed_by_kafala, original.is_guaranteed_by_kafala)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_debt.gd -gexit`
Expected: FAIL — `Debt` does not exist yet.

- [ ] **Step 3: Implement `Debt`**

Create `engine/ledger/Debt.gd`:

```gdscript
extends RefCounted
class_name Debt

var creditor_name: String
var amount_dirham_equivalent: float
var is_guaranteed_by_kafala: bool

func _init(p_creditor_name: String, p_amount_dirham_equivalent: float, p_is_guaranteed_by_kafala: bool = false) -> void:
	creditor_name = p_creditor_name
	amount_dirham_equivalent = p_amount_dirham_equivalent
	is_guaranteed_by_kafala = p_is_guaranteed_by_kafala

func to_dict() -> Dictionary:
	return {
		"creditor_name": creditor_name,
		"amount_dirham_equivalent": amount_dirham_equivalent,
		"is_guaranteed_by_kafala": is_guaranteed_by_kafala,
	}

static func from_dict(data: Dictionary) -> Debt:
	return Debt.new(data["creditor_name"], data["amount_dirham_equivalent"], data["is_guaranteed_by_kafala"])
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_debt.gd -gexit`
Expected: 3 tests, 3 pass.

- [ ] **Step 5: Commit**

```bash
git add engine/ledger/Debt.gd tests/unit/test_debt.gd
git commit -m "feat: add Debt value object with JSON round-trip"
```

---

### Task 4: `Ledger` core — purse, debts, kafāla, zakāt, 'ushr

**Files:**
- Create: `engine/ledger/Ledger.gd`
- Test: `tests/unit/test_ledger.gd`

**Interfaces:**
- Consumes: `Coin` (Task 2), `Debt` (Task 3).
- Produces: `Ledger.new()`, `ledger.add_coin(coin: Coin)`, `ledger.total_wealth_dirham_equivalent() -> float`, `ledger.guarantee_debt_via_kafala(creditor_name: String, amount_dirham_equivalent: float) -> Debt`, `ledger.total_debt_owed() -> float`, `ledger.pay_debt(debt: Debt, amount_dirham_equivalent: float) -> void`, `ledger.calculate_zakat(threshold_dirham_equivalent: float) -> float`, `ledger.calculate_ushr(goods_value_dirham_equivalent: float, is_muslim_trader: bool) -> float`, `ledger.to_dict() -> Dictionary`, `ledger.load_from_dict(data: Dictionary) -> void`. `purse: Array[Coin]` and `debts: Array[Debt]` are public properties. Used by `GameState`/`SaveManager` (Task 9) and `ChapterView` (Task 13).

- [ ] **Step 1: Write failing tests for purse & wealth**

Create `tests/unit/test_ledger.gd`:

```gdscript
extends GutTest

func test_total_wealth_sums_silver_coins_directly():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 3.0, 1.0))
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 2.0, 0.5))
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 4.0, 0.0001)

func test_total_wealth_converts_gold_via_exchange_rate():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.GOLD, 1.0, 1.0))
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), Ledger.GOLD_TO_SILVER_VALUE_RATIO, 0.0001)

func test_empty_purse_has_zero_wealth():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.total_wealth_dirham_equivalent(), 0.0, 0.0001)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: FAIL — `Ledger` does not exist yet.

- [ ] **Step 3: Implement purse & wealth**

Create `engine/ledger/Ledger.gd`:

```gdscript
extends RefCounted
class_name Ledger

const GOLD_TO_SILVER_VALUE_RATIO := 14.2
const ZAKAT_RATE := 0.025
const USHR_RATE_FOR_MUSLIM_TRADER := 0.05
const USHR_RATE_FOR_NON_MUSLIM_TRADER := 0.10

var purse: Array[Coin] = []
var debts: Array[Debt] = []

func add_coin(coin: Coin) -> void:
	purse.append(coin)

func total_wealth_dirham_equivalent() -> float:
	var total := 0.0
	for coin in purse:
		if coin.metal == Coin.Metal.GOLD:
			total += coin.pure_metal_grams() * GOLD_TO_SILVER_VALUE_RATIO
		else:
			total += coin.pure_metal_grams()
	return total
```

- [ ] **Step 4: Run to verify the purse/wealth tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: 3 tests, 3 pass.

- [ ] **Step 5: Write failing tests for debts & kafāla**

Append to `tests/unit/test_ledger.gd`:

```gdscript
func test_guarantee_debt_via_kafala_creates_a_flagged_debt():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)
	assert_true(debt.is_guaranteed_by_kafala)
	assert_eq(ledger.debts.size(), 1)
	assert_eq(ledger.debts[0], debt)

func test_total_debt_owed_sums_all_debts():
	var ledger := Ledger.new()
	ledger.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)
	ledger.guarantee_debt_via_kafala("Rukn ibn Faramarz", 210.0)
	assert_almost_eq(ledger.total_debt_owed(), 550.0, 0.0001)

func test_pay_debt_reduces_remaining_amount():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Nasuh", 60.0)
	ledger.pay_debt(debt, 20.0)
	assert_almost_eq(debt.amount_dirham_equivalent, 40.0, 0.0001)
	assert_eq(ledger.debts.size(), 1)

func test_pay_debt_in_full_removes_it_from_the_ledger():
	var ledger := Ledger.new()
	var debt := ledger.guarantee_debt_via_kafala("Nasuh", 60.0)
	ledger.pay_debt(debt, 60.0)
	assert_eq(ledger.debts.size(), 0)
```

- [ ] **Step 6: Run to verify failure, then implement debts & kafāla**

Run the same `-gtest` command as Step 2 and confirm the four new tests fail, then add to `engine/ledger/Ledger.gd`:

```gdscript
func guarantee_debt_via_kafala(creditor_name: String, amount_dirham_equivalent: float) -> Debt:
	var debt := Debt.new(creditor_name, amount_dirham_equivalent, true)
	debts.append(debt)
	return debt

func total_debt_owed() -> float:
	var total := 0.0
	for debt in debts:
		total += debt.amount_dirham_equivalent
	return total

func pay_debt(debt: Debt, amount_dirham_equivalent: float) -> void:
	debt.amount_dirham_equivalent -= amount_dirham_equivalent
	if debt.amount_dirham_equivalent <= 0.0:
		debts.erase(debt)
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: 7 tests, 7 pass.

- [ ] **Step 7: Write failing tests for zakāt & 'ushr**

Append to `tests/unit/test_ledger.gd`:

```gdscript
func test_zakat_is_zero_below_threshold():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 10.0, 1.0))
	assert_almost_eq(ledger.calculate_zakat(50.0), 0.0, 0.0001)

func test_zakat_is_two_and_a_half_percent_above_threshold():
	var ledger := Ledger.new()
	ledger.add_coin(Coin.new(Coin.Metal.SILVER, 100.0, 1.0))
	assert_almost_eq(ledger.calculate_zakat(50.0), 2.5, 0.0001)

func test_ushr_for_muslim_trader_is_five_percent():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.calculate_ushr(200.0, true), 10.0, 0.0001)

func test_ushr_for_non_muslim_trader_is_ten_percent():
	var ledger := Ledger.new()
	assert_almost_eq(ledger.calculate_ushr(200.0, false), 20.0, 0.0001)
```

- [ ] **Step 8: Run to verify failure, then implement zakāt & 'ushr**

Confirm the four new tests fail, then add to `engine/ledger/Ledger.gd`:

```gdscript
func calculate_zakat(threshold_dirham_equivalent: float) -> float:
	var wealth := total_wealth_dirham_equivalent()
	if wealth <= threshold_dirham_equivalent:
		return 0.0
	return wealth * ZAKAT_RATE

func calculate_ushr(goods_value_dirham_equivalent: float, is_muslim_trader: bool) -> float:
	var rate := USHR_RATE_FOR_MUSLIM_TRADER if is_muslim_trader else USHR_RATE_FOR_NON_MUSLIM_TRADER
	return goods_value_dirham_equivalent * rate
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: 11 tests, 11 pass.

- [ ] **Step 9: Write failing tests for serialization**

Append to `tests/unit/test_ledger.gd`:

```gdscript
func test_to_dict_and_from_dict_round_trip_purse_and_debts():
	var original := Ledger.new()
	original.add_coin(Coin.new(Coin.Metal.SILVER, 3.0, 0.9))
	original.guarantee_debt_via_kafala("Ibrahim al-Sarraf", 340.0)

	var restored := Ledger.new()
	restored.load_from_dict(original.to_dict())

	assert_eq(restored.purse.size(), 1)
	assert_almost_eq(restored.purse[0].actual_weight_grams, 3.0, 0.0001)
	assert_eq(restored.debts.size(), 1)
	assert_eq(restored.debts[0].creditor_name, "Ibrahim al-Sarraf")
	assert_almost_eq(restored.debts[0].amount_dirham_equivalent, 340.0, 0.0001)
```

- [ ] **Step 10: Run to verify failure, then implement serialization**

Confirm the new test fails, then add to `engine/ledger/Ledger.gd`:

```gdscript
func to_dict() -> Dictionary:
	var purse_data: Array = []
	for coin in purse:
		purse_data.append(coin.to_dict())
	var debts_data: Array = []
	for debt in debts:
		debts_data.append(debt.to_dict())
	return {"purse": purse_data, "debts": debts_data}

func load_from_dict(data: Dictionary) -> void:
	purse.clear()
	for coin_data in data.get("purse", []):
		purse.append(Coin.from_dict(coin_data))
	debts.clear()
	for debt_data in data.get("debts", []):
		debts.append(Debt.from_dict(debt_data))
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_ledger.gd -gexit`
Expected: 12 tests, 12 pass.

- [ ] **Step 11: Commit**

```bash
git add engine/ledger/Ledger.gd tests/unit/test_ledger.gd
git commit -m "feat: add Ledger core (purse, debts, kafala, zakat, ushr, serialization)"
```

---

### Task 5: `MudarabaPartnership` & `Suftaja` instruments

**Files:**
- Create: `engine/ledger/MudarabaPartnership.gd`
- Create: `engine/ledger/Suftaja.gd`
- Test: `tests/unit/test_mudaraba_and_suftaja.gd`

**Interfaces:**
- Consumes: nothing (standalone value objects).
- Produces: `MudarabaPartnership.new(financier_name: String, agent_name: String, capital_dirham_equivalent: float, agent_profit_share: float)`, `partnership.settle(outcome_value_dirham_equivalent: float, agent_was_negligent: bool) -> Dictionary` (returns `{"financier_result": float, "agent_result": float}`); `Suftaja.new(issuing_city: String, redeeming_city: String, face_value_dirham_equivalent: float)`, `suftaja.redeem() -> float`, `suftaja.is_redeemed: bool`.
- **Scope note:** these two instruments are not yet part of `Ledger.to_dict()`/`load_from_dict()` — no Prologue content in this plan creates one, so persistence is deferred until a future chapter actually exercises them. This is a deliberate scope decision, not an oversight.

- [ ] **Step 1: Write failing tests for `MudarabaPartnership`**

Create `tests/unit/test_mudaraba_and_suftaja.gd`:

```gdscript
extends GutTest

func test_settle_splits_profit_by_agreed_share():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(150.0, false)
	# profit = 50; agent gets 30% of profit = 15; financier gets capital + rest = 135
	assert_almost_eq(result["agent_result"], 15.0, 0.0001)
	assert_almost_eq(result["financier_result"], 135.0, 0.0001)

func test_settle_on_loss_without_negligence_puts_loss_on_financier_alone():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(60.0, false)
	assert_almost_eq(result["financier_result"], 60.0, 0.0001)
	assert_almost_eq(result["agent_result"], 0.0, 0.0001)

func test_settle_on_loss_with_negligence_shifts_loss_to_agent():
	var partnership := MudarabaPartnership.new("financier", "agent", 100.0, 0.3)
	var result := partnership.settle(60.0, true)
	assert_almost_eq(result["financier_result"], 100.0, 0.0001)
	assert_almost_eq(result["agent_result"], -40.0, 0.0001)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_mudaraba_and_suftaja.gd -gexit`
Expected: FAIL — `MudarabaPartnership` does not exist yet.

- [ ] **Step 3: Implement `MudarabaPartnership`**

Create `engine/ledger/MudarabaPartnership.gd`:

```gdscript
extends RefCounted
class_name MudarabaPartnership

var financier_name: String
var agent_name: String
var capital_dirham_equivalent: float
var agent_profit_share: float

func _init(p_financier_name: String, p_agent_name: String, p_capital_dirham_equivalent: float, p_agent_profit_share: float) -> void:
	financier_name = p_financier_name
	agent_name = p_agent_name
	capital_dirham_equivalent = p_capital_dirham_equivalent
	agent_profit_share = p_agent_profit_share

func settle(outcome_value_dirham_equivalent: float, agent_was_negligent: bool) -> Dictionary:
	var profit := outcome_value_dirham_equivalent - capital_dirham_equivalent
	if profit >= 0.0:
		var agent_share := profit * agent_profit_share
		return {
			"financier_result": capital_dirham_equivalent + (profit - agent_share),
			"agent_result": agent_share,
		}
	if agent_was_negligent:
		return {"financier_result": capital_dirham_equivalent, "agent_result": profit}
	return {"financier_result": outcome_value_dirham_equivalent, "agent_result": 0.0}
```

- [ ] **Step 4: Run to verify the `MudarabaPartnership` tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_mudaraba_and_suftaja.gd -gexit`
Expected: 3 tests, 3 pass.

- [ ] **Step 5: Write failing tests for `Suftaja`**

Append to `tests/unit/test_mudaraba_and_suftaja.gd`:

```gdscript
func test_suftaja_starts_unredeemed():
	var suftaja := Suftaja.new("Ghazni", "Rayy", 340.0)
	assert_false(suftaja.is_redeemed)

func test_redeem_returns_face_value_and_marks_redeemed():
	var suftaja := Suftaja.new("Ghazni", "Rayy", 340.0)
	var paid_out := suftaja.redeem()
	assert_almost_eq(paid_out, 340.0, 0.0001)
	assert_true(suftaja.is_redeemed)
```

- [ ] **Step 6: Run to verify failure, then implement `Suftaja`**

Confirm the two new tests fail, then create `engine/ledger/Suftaja.gd`:

```gdscript
extends RefCounted
class_name Suftaja

var issuing_city: String
var redeeming_city: String
var face_value_dirham_equivalent: float
var is_redeemed: bool = false

func _init(p_issuing_city: String, p_redeeming_city: String, p_face_value_dirham_equivalent: float) -> void:
	issuing_city = p_issuing_city
	redeeming_city = p_redeeming_city
	face_value_dirham_equivalent = p_face_value_dirham_equivalent

func redeem() -> float:
	is_redeemed = true
	return face_value_dirham_equivalent
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_mudaraba_and_suftaja.gd -gexit`
Expected: 5 tests, 5 pass.

- [ ] **Step 7: Commit**

```bash
git add engine/ledger/MudarabaPartnership.gd engine/ledger/Suftaja.gd tests/unit/test_mudaraba_and_suftaja.gd
git commit -m "feat: add MudarabaPartnership settlement math and Suftaja instrument"
```

---

### Task 6: `ReputationTracker`

**Files:**
- Create: `engine/reputation/ReputationTracker.gd`
- Test: `tests/unit/test_reputation_tracker.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `ReputationTracker.new()`, `tracker.get_reputation(faction_id: String) -> int`, `tracker.adjust_reputation(faction_id: String, delta: int) -> void`, `tracker.meets_threshold(faction_id: String, threshold: int) -> bool`, `tracker.to_dict() -> Dictionary`, `tracker.load_from_dict(data: Dictionary) -> void`. Used by `GameState`/`SaveManager` (Task 9) and `ChapterView` (Task 13).

- [ ] **Step 1: Write the failing tests**

Create `tests/unit/test_reputation_tracker.gd`:

```gdscript
extends GutTest

func test_unknown_faction_starts_at_zero():
	var tracker := ReputationTracker.new()
	assert_eq(tracker.get_reputation("trading_families"), 0)

func test_adjust_reputation_accumulates():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("trading_families", 2)
	tracker.adjust_reputation("trading_families", 1)
	assert_eq(tracker.get_reputation("trading_families"), 3)

func test_adjust_reputation_can_go_negative():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("ghaznavid_officials", -3)
	assert_eq(tracker.get_reputation("ghaznavid_officials"), -3)

func test_meets_threshold_true_when_score_at_or_above():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("townsfolk", 5)
	assert_true(tracker.meets_threshold("townsfolk", 5))
	assert_true(tracker.meets_threshold("townsfolk", 3))

func test_meets_threshold_false_when_score_below():
	var tracker := ReputationTracker.new()
	tracker.adjust_reputation("townsfolk", 2)
	assert_false(tracker.meets_threshold("townsfolk", 5))

func test_to_dict_and_load_from_dict_round_trip():
	var original := ReputationTracker.new()
	original.adjust_reputation("hidden_network", -1)
	var restored := ReputationTracker.new()
	restored.load_from_dict(original.to_dict())
	assert_eq(restored.get_reputation("hidden_network"), -1)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_reputation_tracker.gd -gexit`
Expected: FAIL — `ReputationTracker` does not exist yet.

- [ ] **Step 3: Implement `ReputationTracker`**

Create `engine/reputation/ReputationTracker.gd`:

```gdscript
extends RefCounted
class_name ReputationTracker

var _scores: Dictionary = {}

func get_reputation(faction_id: String) -> int:
	return _scores.get(faction_id, 0)

func adjust_reputation(faction_id: String, delta: int) -> void:
	_scores[faction_id] = get_reputation(faction_id) + delta

func meets_threshold(faction_id: String, threshold: int) -> bool:
	return get_reputation(faction_id) >= threshold

func to_dict() -> Dictionary:
	return _scores.duplicate()

func load_from_dict(data: Dictionary) -> void:
	_scores = data.duplicate()
```

- [ ] **Step 4: Run to verify they pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_reputation_tracker.gd -gexit`
Expected: 6 tests, 6 pass.

- [ ] **Step 5: Commit**

```bash
git add engine/reputation/ReputationTracker.gd tests/unit/test_reputation_tracker.gd
git commit -m "feat: add per-faction ReputationTracker"
```

---

### Task 7: `MarginGlossary` & `GlossedTextParser`

**Files:**
- Create: `engine/margin/MarginGlossary.gd`
- Create: `engine/margin/GlossedTextParser.gd`
- Test: `tests/unit/test_margin_glossary.gd`
- Test: `tests/unit/test_glossed_text_parser.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `MarginGlossary.new()`, `glossary.load_entries(entries: Dictionary) -> void`, `glossary.has_entry(term_id: String) -> bool`, `glossary.get_entry(term_id: String) -> Dictionary`, `glossary.unlock(term_id: String) -> void`, `glossary.is_unlocked(term_id: String) -> bool`, `glossary.unlocked_term_ids() -> Array`. `GlossedTextParser.parse_to_bbcode(raw_text: String) -> String`, `GlossedTextParser.extract_term_ids(raw_text: String) -> Array`. Both used by `ChapterView` (Task 13); `MarginGlossary` also used by `GameState`/`SaveManager` (Task 9).
- **Inline gloss token format** (used throughout `content/`): `{{term_id|Displayed Text}}` for a single gloss, `{{term_id_a,term_id_b|Displayed Text}}` when one phrase should unlock more than one entry (e.g. an honorific + the naming convention it demonstrates).

- [ ] **Step 1: Write the failing tests for `MarginGlossary`**

Create `tests/unit/test_margin_glossary.gd`:

```gdscript
extends GutTest

func test_has_entry_false_before_loading():
	var glossary := MarginGlossary.new()
	assert_false(glossary.has_entry("khwaja"))

func test_load_entries_then_has_and_get_entry():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "A respectful address."}})
	assert_true(glossary.has_entry("khwaja"))
	assert_eq(glossary.get_entry("khwaja")["headword"], "Khwaja")

func test_get_entry_for_unknown_term_returns_empty_dict():
	var glossary := MarginGlossary.new()
	assert_eq(glossary.get_entry("nonexistent"), {})

func test_unlock_only_takes_effect_for_known_terms():
	var glossary := MarginGlossary.new()
	glossary.load_entries({"khwaja": {"headword": "Khwaja", "definition": "..."}})
	glossary.unlock("khwaja")
	glossary.unlock("nonexistent")
	assert_true(glossary.is_unlocked("khwaja"))
	assert_false(glossary.is_unlocked("nonexistent"))

func test_unlocked_term_ids_lists_only_unlocked_terms():
	var glossary := MarginGlossary.new()
	glossary.load_entries({
		"khwaja": {"headword": "Khwaja", "definition": "..."},
		"kunya": {"headword": "Kunya", "definition": "..."},
	})
	glossary.unlock("khwaja")
	assert_eq(glossary.unlocked_term_ids(), ["khwaja"])
```

- [ ] **Step 2: Run to verify failure, then implement `MarginGlossary`**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_margin_glossary.gd -gexit`
Expected: FAIL — `MarginGlossary` does not exist yet.

Create `engine/margin/MarginGlossary.gd`:

```gdscript
extends RefCounted
class_name MarginGlossary

var _entries: Dictionary = {}
var _unlocked: Dictionary = {}

func load_entries(entries: Dictionary) -> void:
	_entries = entries

func has_entry(term_id: String) -> bool:
	return _entries.has(term_id)

func get_entry(term_id: String) -> Dictionary:
	return _entries.get(term_id, {})

func unlock(term_id: String) -> void:
	if has_entry(term_id):
		_unlocked[term_id] = true

func is_unlocked(term_id: String) -> bool:
	return _unlocked.get(term_id, false)

func unlocked_term_ids() -> Array:
	return _unlocked.keys()
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_margin_glossary.gd -gexit`
Expected: 5 tests, 5 pass.

- [ ] **Step 3: Commit `MarginGlossary`**

```bash
git add engine/margin/MarginGlossary.gd tests/unit/test_margin_glossary.gd
git commit -m "feat: add MarginGlossary term lookup and unlock tracking"
```

- [ ] **Step 4: Write the failing tests for `GlossedTextParser`**

Create `tests/unit/test_glossed_text_parser.gd`:

```gdscript
extends GutTest

func test_parse_to_bbcode_wraps_a_single_gloss_token():
	var result := GlossedTextParser.parse_to_bbcode("Hello {{khwaja|Khwaja}} sir.")
	assert_eq(result, "Hello [url=khwaja]Khwaja[/url] sir.")

func test_parse_to_bbcode_handles_multiple_tokens_in_one_string():
	var result := GlossedTextParser.parse_to_bbcode("{{ghusl|Ghusl}} then {{kafan|kafan}}.")
	assert_eq(result, "[url=ghusl]Ghusl[/url] then [url=kafan]kafan[/url].")

func test_parse_to_bbcode_leaves_plain_text_untouched():
	var result := GlossedTextParser.parse_to_bbcode("No glosses here.")
	assert_eq(result, "No glosses here.")

func test_extract_term_ids_returns_all_ids_in_order_without_duplicates():
	var ids := GlossedTextParser.extract_term_ids("{{khwaja|Khwaja Abu Farrukh}} ... {{ghusl|ghusl}}")
	assert_eq(ids, ["khwaja", "ghusl"])

func test_extract_term_ids_splits_multi_id_tokens():
	var ids := GlossedTextParser.extract_term_ids("{{khwaja,kunya|Khwaja Abu Farrukh}}")
	assert_eq(ids, ["khwaja", "kunya"])
```

- [ ] **Step 5: Run to verify failure, then implement `GlossedTextParser`**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_glossed_text_parser.gd -gexit`
Expected: FAIL — `GlossedTextParser` does not exist yet.

Create `engine/margin/GlossedTextParser.gd`:

```gdscript
extends RefCounted
class_name GlossedTextParser

static func _token_regex() -> RegEx:
	var regex := RegEx.new()
	regex.compile("\\{\\{([\\w,]+)\\|([^}]+)\\}\\}")
	return regex

static func parse_to_bbcode(raw_text: String) -> String:
	var regex := _token_regex()
	var result := raw_text
	for match_result in regex.search_all(raw_text):
		var term_ids: String = match_result.get_string(1)
		var display_text: String = match_result.get_string(2)
		var token: String = match_result.get_string(0)
		result = result.replace(token, "[url=%s]%s[/url]" % [term_ids, display_text])
	return result

static func extract_term_ids(raw_text: String) -> Array:
	var regex := _token_regex()
	var ids: Array = []
	for match_result in regex.search_all(raw_text):
		for term_id in match_result.get_string(1).split(","):
			if not ids.has(term_id):
				ids.append(term_id)
	return ids
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_glossed_text_parser.gd -gexit`
Expected: 5 tests, 5 pass.

- [ ] **Step 6: Commit `GlossedTextParser`**

```bash
git add engine/margin/GlossedTextParser.gd tests/unit/test_glossed_text_parser.gd
git commit -m "feat: add GlossedTextParser for inline {{term|text}} gloss tokens"
```

---

### Task 8: `DialogueEngine`

**Files:**
- Create: `engine/dialogue/DialogueEngine.gd`
- Test: `tests/unit/test_dialogue_engine.gd`

**Interfaces:**
- Consumes: nothing (operates on plain `Array`/`Dictionary` node data — see node schema below).
- Produces: `DialogueEngine.new()`, `engine.load_tree(nodes: Array, start_id: String) -> void`, `engine.current_node() -> Dictionary`, `engine.available_choices() -> Array`, `engine.choose(choice_index: int) -> Dictionary`, `engine.is_chapter_end() -> bool`, `engine.flags: Dictionary` (public), `engine.current_node_id: String` (public). Used by `ChapterView` (Task 13) and content-integrity test (Task 11).

**Node schema** (plain `Dictionary`, as loaded from JSON content):
```json
{
  "id": "n01",
  "text": "Some narration with {{term_id|a gloss}}.",
  "choices": [
    {"text": "Continue.", "next_id": "n02", "effects": {}},
    {"text": "An alternate option.", "next_id": "n02b", "requires_flag": "some_flag", "effects": {"flags": ["chose_alt"]}}
  ]
}
```
A node with `"choices": []` (or no `choices` key) is the chapter's end.

- [ ] **Step 1: Write failing tests for tree loading and choices**

Create `tests/unit/test_dialogue_engine.gd`:

```gdscript
extends GutTest

func _sample_nodes() -> Array:
	return [
		{
			"id": "n1",
			"text": "Opening beat.",
			"choices": [{"text": "Continue.", "next_id": "n2", "effects": {}}],
		},
		{
			"id": "n2",
			"text": "A real fork.",
			"choices": [
				{"text": "Speak now.", "next_id": "n3a", "effects": {"flags": ["spoke_now"]}},
				{"text": "Wait.", "next_id": "n3b", "effects": {"flags": ["waited"]}},
			],
		},
		{"id": "n3a", "text": "You spoke.", "choices": [{"text": "Continue.", "next_id": "n4", "effects": {}}]},
		{"id": "n3b", "text": "You waited.", "choices": [{"text": "Continue.", "next_id": "n4", "effects": {}}]},
		{
			"id": "n4",
			"text": "A gated option.",
			"choices": [
				{"text": "Always available.", "next_id": "n5", "effects": {}},
				{"text": "Only if you spoke.", "next_id": "n5", "requires_flag": "spoke_now", "effects": {}},
			],
		},
		{"id": "n5", "text": "The end.", "choices": []},
	]

func test_load_tree_sets_current_node_to_start_id():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_eq(engine.current_node()["id"], "n1")

func test_available_choices_returns_all_ungated_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	assert_eq(engine.available_choices().size(), 2)

func test_choose_moves_to_the_chosen_next_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(0)
	assert_eq(engine.current_node()["id"], "n3a")

func test_choose_applies_flags_from_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(0)
	assert_true(engine.flags.get("spoke_now", false))

func test_choose_returns_the_chosen_effects():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	var effects := engine.choose(1)
	assert_eq(effects, {"flags": ["waited"]})

func test_choose_with_out_of_range_index_returns_empty_and_does_not_move():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	var effects := engine.choose(99)
	assert_eq(effects, {})
	assert_eq(engine.current_node()["id"], "n2")

func test_is_chapter_end_false_when_choices_exist():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n1")
	assert_false(engine.is_chapter_end())

func test_is_chapter_end_true_on_final_node():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n5")
	assert_true(engine.is_chapter_end())
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: FAIL — `DialogueEngine` does not exist yet.

- [ ] **Step 3: Implement tree loading, choices, and traversal**

Create `engine/dialogue/DialogueEngine.gd`:

```gdscript
extends RefCounted
class_name DialogueEngine

var current_node_id: String = ""
var flags: Dictionary = {}
var _nodes_by_id: Dictionary = {}

func load_tree(nodes: Array, start_id: String) -> void:
	_nodes_by_id.clear()
	for node in nodes:
		_nodes_by_id[node["id"]] = node
	current_node_id = start_id

func current_node() -> Dictionary:
	return _nodes_by_id.get(current_node_id, {})

func available_choices() -> Array:
	var result: Array = []
	for choice in current_node().get("choices", []):
		if _choice_is_available(choice):
			result.append(choice)
	return result

func choose(choice_index: int) -> Dictionary:
	var choices := available_choices()
	if choice_index < 0 or choice_index >= choices.size():
		return {}
	var choice: Dictionary = choices[choice_index]
	var effects: Dictionary = choice.get("effects", {})
	for flag_name in effects.get("flags", []):
		flags[flag_name] = true
	current_node_id = choice["next_id"]
	return effects

func is_chapter_end() -> bool:
	return available_choices().is_empty()

func _choice_is_available(choice: Dictionary) -> bool:
	var requires_flag = choice.get("requires_flag", null)
	if requires_flag == null:
		return true
	return flags.get(requires_flag, false)
```

- [ ] **Step 4: Run to verify all tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: 8 tests, 8 pass.

- [ ] **Step 5: Write failing test for flag-gated choices**

Append to `tests/unit/test_dialogue_engine.gd`:

```gdscript
func test_gated_choice_hidden_until_flag_is_set_then_appears():
	var engine := DialogueEngine.new()
	engine.load_tree(_sample_nodes(), "n2")
	engine.choose(1) # "Wait." -> sets "waited", not "spoke_now" -> n3b
	engine.choose(0) # n3b -> n4
	assert_eq(engine.available_choices().size(), 1) # gated option hidden

	var engine_via_speak := DialogueEngine.new()
	engine_via_speak.load_tree(_sample_nodes(), "n2")
	engine_via_speak.choose(0) # "Speak now." -> sets "spoke_now" -> n3a
	engine_via_speak.choose(0) # n3a -> n4
	assert_eq(engine_via_speak.available_choices().size(), 2) # gated option now visible
```

- [ ] **Step 6: Run to verify it already passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_dialogue_engine.gd -gexit`
Expected: 9 tests, 9 pass — this confirms the gating logic from Step 3 handles the full reconverge-then-gate scenario, not just the single-node case.

- [ ] **Step 7: Commit**

```bash
git add engine/dialogue/DialogueEngine.gd tests/unit/test_dialogue_engine.gd
git commit -m "feat: add DialogueEngine with flag-gated branching choices"
```

---

### Task 9: `GameState` & `SaveManager`

**Files:**
- Create: `engine/save/GameState.gd`
- Create: `engine/save/SaveManager.gd`
- Test: `tests/unit/test_save_manager.gd`

**Interfaces:**
- Consumes: plain `Dictionary`/`Array` shapes produced by `Ledger.to_dict()` (Task 4), `ReputationTracker.to_dict()` (Task 6), `MarginGlossary.unlocked_term_ids()` (Task 7), and `DialogueEngine.flags`/`current_node_id` (Task 8) — `GameState` itself has no dependency on those classes, only on the `Dictionary`/`Array` shapes they produce, so it can be tested with plain fixtures.
- Produces: `GameState.new()` with public fields `chapter_id: String`, `dialogue_node_id: String`, `dialogue_flags: Dictionary`, `reputation_data: Dictionary`, `unlocked_glossary_terms: Array`, `ledger_data: Dictionary`; `state.to_dict() -> Dictionary`; `GameState.from_dict(data: Dictionary) -> GameState`. `SaveManager.new()`, `manager.save(state: GameState, file_path: String) -> Error`, `manager.load(file_path: String) -> GameState` (returns `null` if the file doesn't exist or fails to parse). Used by `ChapterView` (Task 13).

- [ ] **Step 1: Write failing tests for `GameState`**

Create `tests/unit/test_save_manager.gd`:

```gdscript
extends GutTest

func _sample_state() -> GameState:
	var state := GameState.new()
	state.chapter_id = "chapter_00_prologue"
	state.dialogue_node_id = "n4"
	state.dialogue_flags = {"spoke_now": true}
	state.reputation_data = {"trading_families": 2}
	state.unlocked_glossary_terms = ["khwaja", "ghusl"]
	state.ledger_data = {"purse": [], "debts": [{"creditor_name": "Nasuh", "amount_dirham_equivalent": 60.0, "is_guaranteed_by_kafala": true}]}
	return state

func test_game_state_to_dict_and_from_dict_round_trip():
	var original := _sample_state()
	var restored := GameState.from_dict(original.to_dict())
	assert_eq(restored.chapter_id, original.chapter_id)
	assert_eq(restored.dialogue_node_id, original.dialogue_node_id)
	assert_eq(restored.dialogue_flags, original.dialogue_flags)
	assert_eq(restored.reputation_data, original.reputation_data)
	assert_eq(restored.unlocked_glossary_terms, original.unlocked_glossary_terms)
	assert_eq(restored.ledger_data, original.ledger_data)

func test_from_dict_on_empty_dict_uses_safe_defaults():
	var state := GameState.from_dict({})
	assert_eq(state.chapter_id, "")
	assert_eq(state.dialogue_flags, {})
	assert_eq(state.unlocked_glossary_terms, [])
```

- [ ] **Step 2: Run to verify failure, then implement `GameState`**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_save_manager.gd -gexit`
Expected: FAIL — `GameState` does not exist yet.

Create `engine/save/GameState.gd`:

```gdscript
extends RefCounted
class_name GameState

var chapter_id: String = ""
var dialogue_node_id: String = ""
var dialogue_flags: Dictionary = {}
var reputation_data: Dictionary = {}
var unlocked_glossary_terms: Array = []
var ledger_data: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"chapter_id": chapter_id,
		"dialogue_node_id": dialogue_node_id,
		"dialogue_flags": dialogue_flags,
		"reputation_data": reputation_data,
		"unlocked_glossary_terms": unlocked_glossary_terms,
		"ledger_data": ledger_data,
	}

static func from_dict(data: Dictionary) -> GameState:
	var state := GameState.new()
	state.chapter_id = data.get("chapter_id", "")
	state.dialogue_node_id = data.get("dialogue_node_id", "")
	state.dialogue_flags = data.get("dialogue_flags", {})
	state.reputation_data = data.get("reputation_data", {})
	state.unlocked_glossary_terms = data.get("unlocked_glossary_terms", [])
	state.ledger_data = data.get("ledger_data", {})
	return state
```

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_save_manager.gd -gexit`
Expected: 2 tests, 2 pass.

- [ ] **Step 3: Write failing tests for `SaveManager`**

Append to `tests/unit/test_save_manager.gd`:

```gdscript
func test_save_then_load_round_trips_through_a_real_file():
	var manager := SaveManager.new()
	var path := "user://test_save_round_trip.json"
	var original := _sample_state()

	var save_error := manager.save(original, path)
	assert_eq(save_error, OK)

	var restored := manager.load(path)
	assert_not_null(restored)
	assert_eq(restored.chapter_id, original.chapter_id)
	assert_eq(restored.dialogue_node_id, original.dialogue_node_id)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_load_returns_null_when_file_does_not_exist():
	var manager := SaveManager.new()
	var restored := manager.load("user://this_file_does_not_exist_12345.json")
	assert_null(restored)
```

- [ ] **Step 4: Run to verify failure, then implement `SaveManager`**

Confirm both tests fail (`SaveManager` doesn't exist yet), then create `engine/save/SaveManager.gd`:

```gdscript
extends RefCounted
class_name SaveManager

func save(state: GameState, file_path: String) -> Error:
	var json_text := JSON.stringify(state.to_dict())
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(json_text)
	file.close()
	return OK

func load(file_path: String) -> GameState:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null:
		return null
	return GameState.from_dict(parsed)
```

- [ ] **Step 5: Run to verify all tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_save_manager.gd -gexit`
Expected: 4 tests, 4 pass.

- [ ] **Step 6: Commit**

```bash
git add engine/save/GameState.gd engine/save/SaveManager.gd tests/unit/test_save_manager.gd
git commit -m "feat: add GameState and SaveManager for JSON save/load"
```

---

### Task 10: Prologue glossary content

**Files:**
- Create: `content/glossary/prologue_terms.json`
- Test: `tests/unit/test_prologue_glossary_content.gd`

**Interfaces:**
- Consumes: `MarginGlossary` (Task 7).
- Produces: a loadable glossary content file at `res://content/glossary/prologue_terms.json` containing exactly the 12 terms the Prologue's dialogue (Task 11) glosses. Used by `ChapterView` (Task 13).

- [ ] **Step 1: Write the failing content-integrity test**

Create `tests/unit/test_prologue_glossary_content.gd`:

```gdscript
extends GutTest

const REQUIRED_TERM_IDS := [
	"khwaja", "kunya", "nasa", "ghusl", "kafan", "janaza",
	"tajir", "kafala", "taziya", "rahimahu_llah", "suftaja", "ostad",
]

func _load_glossary() -> MarginGlossary:
	var file := FileAccess.open("res://content/glossary/prologue_terms.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	var glossary := MarginGlossary.new()
	glossary.load_entries(data)
	return glossary

func test_every_required_term_is_present_with_headword_and_definition():
	var glossary := _load_glossary()
	for term_id in REQUIRED_TERM_IDS:
		assert_true(glossary.has_entry(term_id), "missing glossary entry: %s" % term_id)
		var entry := glossary.get_entry(term_id)
		assert_true(entry.get("headword", "").length() > 0, "%s has an empty headword" % term_id)
		assert_true(entry.get("definition", "").length() > 0, "%s has an empty definition" % term_id)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_prologue_glossary_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the glossary content**

Create `content/glossary/prologue_terms.json` (definitions drawn from spec Section 11 / the research the spec is built on):

```json
{
	"khwaja": {
		"headword": "Khwaja",
		"definition": "A respectful address for a learned or notable man - 'sir', 'master', 'my lord'. In this era it marks general high standing, not a merchant title specifically; that narrower sense would only develop centuries later."
	},
	"kunya": {
		"headword": "Kunya",
		"definition": "An adult man's honorific name, of the form 'Abu [child]' - 'father of [child]'. Conventionally taken from his firstborn son once one exists; an unmarried or childless man has none yet."
	},
	"nasa": {
		"headword": "Nasa",
		"definition": "A frontier fortress-town on the edge of Ghaznavid Khorasan. In 1035, Seljuk-led Oghuz Turkmen forces defeated a Ghaznavid garrison here - an early sign the empire's grip on this frontier was failing."
	},
	"ghusl": {
		"headword": "Ghusl",
		"definition": "The ritual washing of a body before burial, performed by same-sex relatives or community members, an odd number of times, the final rinse scented with camphor."
	},
	"kafan": {
		"headword": "Kafan",
		"definition": "The burial shroud: plain white cloth, unadorned regardless of the deceased's wealth, so that rich and poor are wrapped identically in death."
	},
	"janaza": {
		"headword": "Janaza",
		"definition": "The funeral prayer: a standing congregational rite, performed without the bowing or prostration of ordinary prayer, largely in silence."
	},
	"tajir": {
		"headword": "Tajir",
		"definition": "Merchant - a plain, classical Arabic term. The Persian equivalent is 'bazargan'."
	},
	"kafala": {
		"headword": "Kafala (also damān)",
		"definition": "A formal, voluntary suretyship: one person bindingly guarantees another's debt. A real instrument of Islamic law, not a metaphor - once invoked, it is enforceable like any other debt."
	},
	"taziya": {
		"headword": "Ta'ziya",
		"definition": "The customary three-day period of condolence-visiting after a death."
	},
	"rahimahu_llah": {
		"headword": "Rahimahu llah",
		"definition": "'God have mercy on him' - spoken of the dead."
	},
	"suftaja": {
		"headword": "Suftaja",
		"definition": "A written instrument letting a merchant move value between cities without physically carrying coin through dangerous country - the era's closest equivalent to a bill of exchange."
	},
	"ostad": {
		"headword": "Ostad",
		"definition": "'Master' - an honorific for a craftsman, scholar, or teacher, unrelated to trade specifically; rooted in pre-Islamic Persian guild culture."
	}
}
```

- [ ] **Step 4: Run to verify the test passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_prologue_glossary_content.gd -gexit`
Expected: 1 test, 1 pass.

- [ ] **Step 5: Commit**

```bash
git add content/glossary/prologue_terms.json tests/unit/test_prologue_glossary_content.gd
git commit -m "content: add Prologue glossary entries for The Margin"
```

---

### Task 11: Prologue dialogue content

**Files:**
- Create: `content/chapters/chapter_00_prologue/prologue.json`
- Test: `tests/unit/test_prologue_dialogue_content.gd`

**Interfaces:**
- Consumes: `DialogueEngine` (Task 8), `GlossedTextParser` (Task 7), the glossary content from Task 10 (its term ids must be a superset of every id used in this file's gloss tokens).
- Produces: a loadable dialogue tree at `res://content/chapters/chapter_00_prologue/prologue.json`, implementing the full Prologue scene from spec Section 10, starting at node id `"n01_naming"`, ending at `"n12_departure"`. Used by `ChapterView` (Task 13).

This file renders the spec's approved Prologue prose (Section 10), split into 12 nodes with two real, reconverging player choices: how Farrukh responds in the moment before the grave (`n04_grave_question`), and whether he reads Nasuh's unsigned letter in full (`n09_suftaja_letter_choice`). The kafāla vow itself (`n06_vow`) is preserved as written in the spec — both paths from the fork lead to the same vow; only the flavor text and a small reputation nudge differ.

- [ ] **Step 1: Write the failing content-integrity test**

Create `tests/unit/test_prologue_dialogue_content.gd`:

```gdscript
extends GutTest

func _load_nodes() -> Array:
	var file := FileAccess.open("res://content/chapters/chapter_00_prologue/prologue.json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	return data

func test_every_next_id_points_at_a_node_that_exists():
	var nodes := _load_nodes()
	var known_ids: Dictionary = {}
	for node in nodes:
		known_ids[node["id"]] = true
	for node in nodes:
		for choice in node.get("choices", []):
			assert_true(known_ids.has(choice["next_id"]), "%s -> next_id '%s' does not exist" % [node["id"], choice["next_id"]])

func test_exactly_one_node_has_no_choices_and_it_is_the_last_node():
	var nodes := _load_nodes()
	var end_node_ids: Array = []
	for node in nodes:
		if node.get("choices", []).is_empty():
			end_node_ids.append(node["id"])
	assert_eq(end_node_ids, ["n12_departure"])

func test_every_glossed_term_id_exists_in_the_prologue_glossary():
	var nodes := _load_nodes()
	var glossary_file := FileAccess.open("res://content/glossary/prologue_terms.json", FileAccess.READ)
	var glossary_data = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	for node in nodes:
		for term_id in GlossedTextParser.extract_term_ids(node["text"]):
			assert_true(glossary_data.has(term_id), "node %s glosses unknown term '%s'" % [node["id"], term_id])

func test_the_full_tree_is_walkable_from_start_to_end_via_first_choices():
	var engine := DialogueEngine.new()
	engine.load_tree(_load_nodes(), "n01_naming")
	var visited := 0
	while not engine.is_chapter_end() and visited < 100:
		engine.choose(0)
		visited += 1
	assert_true(engine.is_chapter_end())
	assert_eq(engine.current_node()["id"], "n12_departure")
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_prologue_dialogue_content.gd -gexit`
Expected: FAIL — the content file does not exist yet.

- [ ] **Step 3: Write the Prologue dialogue content**

Create `content/chapters/chapter_00_prologue/prologue.json`:

```json
[
	{
		"id": "n01_naming",
		"text": "Farrukh ibn Hasan al-Nishapuri had lived nineteen years without once hearing his father's own name spoken aloud. To the bazaar, to the mosque, to the tax-farmer's clerks, the man who raised him was {{khwaja,kunya|Khwaja Abu Farrukh}} - \"master, father of Farrukh\" - and that was enough of a name for a man to die under.",
		"choices": [{"text": "Continue.", "next_id": "n02_rumor_illness", "effects": {}}]
	},
	{
		"id": "n02_rumor_illness",
		"text": "It was a bad season to be caught grieving. Riders had come through the Chahar Su market three weeks running with the same unsettling murmur - Turkmen horsemen loose again on the Khorasan frontier, a garrison broken somewhere near {{nasa|Nasa}}, word passed caravan to caravan faster than any courier the Sultan employed. Farrukh had barely marked it. His father's cough had turned to fever on the same week the news arrived, as if the sickness in the empire's far edge had found its way, by some private road, into one merchant's chest in Ghazni.",
		"choices": [{"text": "Continue.", "next_id": "n03_death", "effects": {}}]
	},
	{
		"id": "n03_death",
		"text": "He died on a Thursday. His body was washed that same afternoon by his brother and two men from the mosque - {{ghusl|ghusl}}, three times over, the last water scented with camphor - and wrapped before evening in plain white cloth, three lengths of it, unmarked, unadorned. Farrukh had expected - he did not know what he had expected. Not this. Not a shroud identical, thread for thread, to the one they'd have wrapped a beggar in behind the grain market. {{kafan|Kafan}} made no distinction. That was the point of it, someone told him gently. He did not feel comforted.",
		"choices": [{"text": "Continue.", "next_id": "n04_grave_question", "effects": {}}]
	},
	{
		"id": "n04_grave_question",
		"text": "At the grave they said the {{janaza|janaza}} standing, no bowing, near-silent - and it was there, in front of half the merchants of the western bazaar, that the trouble surfaced into the open air. The imam did not begin. He turned, instead, to the men close by, and asked, plainly, the question the Prophet himself was remembered to have asked before he would pray over a man: is he in debt? Someone answered before Farrukh could. Yes. Considerably. To three houses, maybe four. Nobody was certain how much, because nobody - not the widow, not the clerks, not the dead man's own partner - had yet opened the ledger. The imam did not move to pray.",
		"choices": [
			{"text": "Step forward now, before anyone else decides for him.", "next_id": "n05a_speak_now", "effects": {"flags": ["spoke_now"], "reputation": {"trading_families": 1}}},
			{"text": "Wait - let an elder answer first.", "next_id": "n05b_waited", "effects": {"flags": ["waited"], "reputation": {"townsfolk": 1}}}
		]
	},
	{
		"id": "n05a_speak_now",
		"text": "Nobody among the assembled {{tajir|tajirs}} had stepped forward yet. Farrukh did not wait for one of them to. He was already moving before the silence had finished settling over the grave.",
		"choices": [{"text": "Continue.", "next_id": "n06_vow", "effects": {}}]
	},
	{
		"id": "n05b_waited",
		"text": "He waited one breath, then two, watching the older, richer men of the bazaar find reasons not to meet the imam's eyes. Nobody stepped forward. So Farrukh did.",
		"choices": [{"text": "Continue.", "next_id": "n06_vow", "effects": {}}]
	},
	{
		"id": "n06_vow",
		"text": "He said the words before he had decided to say them, the way a man's hand moves before his mind has finished arguing with it: that he would stand for his father's debt himself - all of it, whatever it proved to be - {{kafala|damān}}, his word as guarantee, in front of every man there to remember it. It was not required of him. No qadi, no creditor, no verse of the Book would have compelled a son to answer for a father's failed venture beyond whatever the estate itself could cover - a fact he did not yet know, and that would have changed nothing if he had. He said it because the alternative was standing silent while his father was refused a grave.",
		"choices": [{"text": "Continue.", "next_id": "n07_prayer_taziya", "effects": {
			"flags": ["vowed_kafala"],
			"reputation": {"trading_families": 2, "townsfolk": 1},
			"debts": [
				{"creditor_name": "the house of Ibrahim al-Sarraf", "amount_dirham_equivalent": 340.0},
				{"creditor_name": "the trading house of Rukn ibn Faramarz", "amount_dirham_equivalent": 210.0},
				{"creditor_name": "Nasuh's own back wages, unpaid four months", "amount_dirham_equivalent": 60.0}
			]
		}}]
	},
	{
		"id": "n07_prayer_taziya",
		"text": "The imam prayed. Grief afterward observed its three days of {{taziya|ta'ziya}} - visitors, murmured {{rahimahu_llah|rahimahu llah}}, trays of food from neighbors Farrukh could not later remember thanking.",
		"choices": [{"text": "Continue.", "next_id": "n08_nasuh_ledger", "effects": {}}]
	},
	{
		"id": "n08_nasuh_ledger",
		"text": "It was on the second of those three days that Nasuh - his father's old clerk, a quiet, ink-stained man who had kept the shop's accounts for eleven years - finally opened the ledger in front of him, and went very still reading it. The debts were real, and worse than the bazaar's rumor. But it was not the sums that troubled Nasuh. It was a {{suftaja|suftaja}} from a banking house in Rayy that Farrukh's father had never mentioned owning, promising a payment against goods that, by the manifest, did not match anything the shop had ever carried west - and a second paper, unsigned, in a hand Nasuh did not recognize, that used a word for the shipment's origin that made the old clerk fold it shut before Farrukh could finish reading it.",
		"choices": [{"text": "Continue.", "next_id": "n09_suftaja_letter_choice", "effects": {}}]
	},
	{
		"id": "n09_suftaja_letter_choice",
		"text": "\"Some accounts,\" Nasuh said, \"are better settled on the road than argued over in this house.\" His hand stayed on the folded paper. He had not put it away yet.",
		"choices": [
			{"text": "Ask to see the letter in full before it's put away.", "next_id": "n10a_read_letter", "effects": {"flags": ["read_unsigned_letter"]}},
			{"text": "Let Nasuh fold it away. Ask no more tonight.", "next_id": "n10b_let_it_go", "effects": {"flags": ["avoided_unsigned_letter"]}}
		]
	},
	{
		"id": "n10a_read_letter",
		"text": "Nasuh unfolded it again, reluctant, and Farrukh read it through to the end. He understood perhaps a third of it - enough to know the word that had stopped Nasuh cold was not a word either of them should be saying aloud in a house still receiving condolence visitors.",
		"choices": [{"text": "Continue.", "next_id": "n11_ostad_comfort", "effects": {}}]
	},
	{
		"id": "n10b_let_it_go",
		"text": "Nasuh folded it away without another word, visibly relieved not to have to say the word out loud a second time. Farrukh let him. There would be time on the road, he told himself, not quite believing it.",
		"choices": [{"text": "Continue.", "next_id": "n11_ostad_comfort", "effects": {}}]
	},
	{
		"id": "n11_ostad_comfort",
		"text": "That night, an old friend of his father's - a traveling letter-writer who called himself nothing grander than {{ostad|ostad}}, though he had read further than most qadis - sat with Farrukh outside the shuttered shop and offered the only comfort that didn't feel like a lie. They say the physicians in the west - Bukhara, Hamadan, wherever the man has run to now, the Sultan's men still asking after him - argue that a man stripped of every sense, every last touch of his own skin, would still know one thing for certain: that he is. That the self isn't the body at all. \"Whatever's under that shroud,\" the old man said, \"was never the whole of your father. Only what could be borrowed. The rest went somewhere law and ledgers don't reach.\"",
		"choices": [{"text": "Continue.", "next_id": "n12_departure", "effects": {}}]
	},
	{
		"id": "n12_departure",
		"text": "Farrukh did not know if he believed it. He packed the shop's remaining goods into two mules' worth of load, hired a caravan guide who knew the road past Teginabad, and set out from Ghazni's western gate before the week's mourning was fully spent - toward Nishapur, toward whatever his father had actually been carrying, and toward a frontier that the riders from Nasa said was already starting to come apart.",
		"choices": []
	}
]
```

- [ ] **Step 4: Run to verify the tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_prologue_dialogue_content.gd -gexit`
Expected: 4 tests, 4 pass.

- [ ] **Step 5: Commit**

```bash
git add content/chapters/chapter_00_prologue/prologue.json tests/unit/test_prologue_dialogue_content.gd
git commit -m "content: add Chapter 0 Prologue dialogue tree"
```

---

### Task 12: `MarginPopup` scene

**Files:**
- Create: `scenes/margin_popup/MarginPopup.tscn`
- Create: `scenes/margin_popup/MarginPopup.gd`
- Test: `tests/unit/test_chapter_view.gd` (shared with Task 13 — this task adds the popup-specific cases)

**Interfaces:**
- Consumes: nothing beyond plain `Dictionary` entry data (`{"headword": String, "definition": String}`).
- Produces: a `PanelContainer`-based scene, script `MarginPopup.gd`, with `func show_entries(entries: Array) -> void` (each element a `Dictionary` with `headword`/`definition`) and a `close_requested` signal. Used by `ChapterView` (Task 13).

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_chapter_view.gd` (this file grows further in Task 13):

```gdscript
extends GutTest

const MarginPopupScene := preload("res://scenes/margin_popup/MarginPopup.tscn")

func test_margin_popup_renders_headword_and_definition_for_each_entry():
	var popup = add_child_autofree(MarginPopupScene.instantiate())
	popup.show_entries([
		{"headword": "Khwaja", "definition": "A respectful address."},
		{"headword": "Kunya", "definition": "A father's honorific name."},
	])
	var rendered_text: String = popup.get_node("MarginRichTextLabel").text
	assert_true(rendered_text.contains("Khwaja"))
	assert_true(rendered_text.contains("A respectful address."))
	assert_true(rendered_text.contains("Kunya"))
	assert_true(rendered_text.contains("A father's honorific name."))
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — the scene does not exist yet.

- [ ] **Step 3: Build the scene**

Create `scenes/margin_popup/MarginPopup.gd`:

```gdscript
extends PanelContainer

signal close_requested

@onready var margin_rich_text_label: RichTextLabel = $MarginRichTextLabel

func show_entries(entries: Array) -> void:
	var lines: Array = []
	for entry in entries:
		lines.append("[b]%s[/b]\n%s" % [entry.get("headword", ""), entry.get("definition", "")])
	margin_rich_text_label.text = "\n\n".join(lines)
	visible = true

func _on_close_button_pressed() -> void:
	visible = false
	close_requested.emit()
```

Create `scenes/margin_popup/MarginPopup.tscn` (a `PanelContainer` root, sized `320x200`, positioned near the bottom-right of a `1280x720` viewport, with the script above attached) containing:
- `MarginRichTextLabel` (`RichTextLabel`, `bbcode_enabled = true`, anchored to fill the panel with an 8px margin)
- `CloseButton` (`Button`, text `"Close"`, docked bottom-right, `pressed` signal connected to `_on_close_button_pressed`)

Build this in the Godot editor (Scene > New Scene > `PanelContainer` root, add the two children, attach the script, connect the signal) rather than hand-writing the `.tscn` text — Godot's `.tscn` format is generated/maintained by the editor, and hand-authoring UUIDs/node paths by hand is error-prone. Save as `scenes/margin_popup/MarginPopup.tscn`.

- [ ] **Step 4: Run to verify the test passes**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: 1 test, 1 pass.

- [ ] **Step 5: Commit**

```bash
git add scenes/margin_popup/ tests/unit/test_chapter_view.gd
git commit -m "feat: add MarginPopup scene for glossary entry display"
```

---

### Task 13: `ChapterView` scene, `Main` bootstrap, and end-to-end wiring

**Files:**
- Create: `scenes/chapter_view/ChapterView.tscn`
- Create: `scenes/chapter_view/ChapterView.gd`
- Create: `scenes/main/Main.tscn`
- Create: `scenes/main/Main.gd`
- Test: `tests/unit/test_chapter_view.gd` (extended further)

**Interfaces:**
- Consumes: `DialogueEngine` (Task 8), `MarginGlossary` (Task 7), `GlossedTextParser` (Task 7), `Ledger` (Task 4), `ReputationTracker` (Task 6), `GameState`/`SaveManager` (Task 9), `MarginPopup` (Task 12), the Prologue content files (Tasks 10–11).
- Produces: a playable scene. `ChapterView.gd` exposes `func load_chapter(dialogue_path: String, glossary_path: String) -> void` and `func save_path() -> String` for the smoke test; `Main.tscn` is the project's `run/main_scene`, instancing `ChapterView` pointed at the Prologue content.

- [ ] **Step 1: Write the failing scene-wiring test**

Append to `tests/unit/test_chapter_view.gd`:

```gdscript
const ChapterViewScene := preload("res://scenes/chapter_view/ChapterView.tscn")

func test_chapter_view_renders_the_first_node_text_on_load():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	var narration_label: RichTextLabel = chapter_view.get_node("NarrationLabel")
	assert_true(narration_label.text.contains("Farrukh ibn Hasan al-Nishapuri"))

func test_chapter_view_choosing_an_option_advances_the_node_and_applies_effects():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	# Must go through _on_choice_pressed (not dialogue_engine.choose() directly) -
	# choose() only applies flags; _on_choice_pressed also routes reputation/debt
	# effects into _apply_effects(), which is what actually updates the ledger.
	# n01 -> n02 -> n03 -> n04 -> (pick "Step forward now...") -> n05a -> n06_vow
	for i in range(5):
		chapter_view._on_choice_pressed(0)
	# now sitting at n06_vow; one more press applies its kafala debts and flag
	chapter_view._on_choice_pressed(0)
	assert_almost_eq(chapter_view.ledger.total_debt_owed(), 610.0, 0.0001)
	assert_true(chapter_view.dialogue_engine.flags.get("vowed_kafala", false))

func test_chapter_view_clicking_a_glossed_term_unlocks_and_shows_it():
	var chapter_view = add_child_autofree(ChapterViewScene.instantiate())
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
	chapter_view._on_narration_meta_clicked("khwaja,kunya")
	assert_true(chapter_view.margin_glossary.is_unlocked("khwaja"))
	assert_true(chapter_view.margin_glossary.is_unlocked("kunya"))
	var popup = chapter_view.get_node("MarginPopup")
	assert_true(popup.visible)
```

- [ ] **Step 2: Run to verify failure**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: FAIL — `ChapterView` does not exist yet.

- [ ] **Step 3: Implement `ChapterView.gd`**

Create `scenes/chapter_view/ChapterView.gd`:

```gdscript
extends Control

@onready var narration_label: RichTextLabel = $NarrationLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var margin_popup = $MarginPopup

var dialogue_engine: DialogueEngine = DialogueEngine.new()
var margin_glossary: MarginGlossary = MarginGlossary.new()
var ledger: Ledger = Ledger.new()
var reputation_tracker: ReputationTracker = ReputationTracker.new()
var save_manager: SaveManager = SaveManager.new()
var chapter_id: String = "chapter_00_prologue"

func _ready() -> void:
	narration_label.meta_clicked.connect(_on_narration_meta_clicked)

func load_chapter(dialogue_path: String, glossary_path: String) -> void:
	var dialogue_file := FileAccess.open(dialogue_path, FileAccess.READ)
	var nodes = JSON.parse_string(dialogue_file.get_as_text())
	dialogue_file.close()

	var glossary_file := FileAccess.open(glossary_path, FileAccess.READ)
	var entries = JSON.parse_string(glossary_file.get_as_text())
	glossary_file.close()

	margin_glossary.load_entries(entries)
	dialogue_engine.load_tree(nodes, nodes[0]["id"])
	_render_current_node()

func save_path() -> String:
	return "user://borrowed_fortune_%s.json" % chapter_id

func _render_current_node() -> void:
	var node := dialogue_engine.current_node()
	narration_label.text = GlossedTextParser.parse_to_bbcode(node.get("text", ""))

	for child in choices_container.get_children():
		child.queue_free()

	var choices := dialogue_engine.available_choices()
	for i in range(choices.size()):
		var button := Button.new()
		button.text = choices[i]["text"]
		button.pressed.connect(_on_choice_pressed.bind(i))
		choices_container.add_child(button)

	if dialogue_engine.is_chapter_end():
		_save_and_finish()

func _on_choice_pressed(choice_index: int) -> void:
	var effects := dialogue_engine.choose(choice_index)
	_apply_effects(effects)
	_render_current_node()

func _apply_effects(effects: Dictionary) -> void:
	for faction_id in effects.get("reputation", {}):
		# effects come from JSON, where all numbers parse as float — cast
		# explicitly since adjust_reputation's delta parameter is typed int.
		reputation_tracker.adjust_reputation(faction_id, int(effects["reputation"][faction_id]))
	for debt_data in effects.get("debts", []):
		ledger.guarantee_debt_via_kafala(debt_data["creditor_name"], debt_data["amount_dirham_equivalent"])

func _on_narration_meta_clicked(meta) -> void:
	var term_ids: Array = str(meta).split(",")
	var entries: Array = []
	for term_id in term_ids:
		margin_glossary.unlock(term_id)
		entries.append(margin_glossary.get_entry(term_id))
	margin_popup.show_entries(entries)

func _save_and_finish() -> void:
	var state := GameState.new()
	state.chapter_id = chapter_id
	state.dialogue_node_id = dialogue_engine.current_node_id
	state.dialogue_flags = dialogue_engine.flags
	state.reputation_data = reputation_tracker.to_dict()
	state.unlocked_glossary_terms = margin_glossary.unlocked_term_ids()
	state.ledger_data = ledger.to_dict()
	save_manager.save(state, save_path())
```

Build `scenes/chapter_view/ChapterView.tscn` in the Godot editor: a `Control` root with the script above attached, containing:
- `NarrationLabel` (`RichTextLabel`, `bbcode_enabled = true`, anchored to the upper ~70% of the view)
- `ChoicesContainer` (`VBoxContainer`, anchored below `NarrationLabel`)
- `MarginPopup` (an instance of `res://scenes/margin_popup/MarginPopup.tscn`, initially `visible = false`, anchored bottom-right)

- [ ] **Step 4: Run to verify the `ChapterView` tests pass**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_chapter_view.gd -gexit`
Expected: 4 tests, 4 pass (the 1 from Task 12 plus the 3 above).

- [ ] **Step 5: Implement `Main.gd` and wire it as the run scene**

Create `scenes/main/Main.gd`:

```gdscript
extends Control

@onready var chapter_view = $ChapterView

func _ready() -> void:
	chapter_view.load_chapter(
		"res://content/chapters/chapter_00_prologue/prologue.json",
		"res://content/glossary/prologue_terms.json"
	)
```

Build `scenes/main/Main.tscn` in the Godot editor: a `Control` root (script above attached) that fills the viewport, containing one child `ChapterView` (an instance of `res://scenes/chapter_view/ChapterView.tscn`).

- [ ] **Step 6: Manual playtest**

Open the project in the Godot editor and press Play (F5). Confirm, by hand:
1. The opening line ("Farrukh ibn Hasan al-Nishapuri had lived nineteen years...") appears with `Khwaja Abu Farrukh` shown as a clickable link.
2. Clicking that link opens the Margin popup showing both the "Khwaja" and "Kunya" entries, and a Close button dismisses it.
3. Clicking "Continue." repeatedly advances through the narration in order.
4. At `n04_grave_question`, two distinct choice buttons appear; picking either eventually reaches the same `n06_vow` text.
5. After the final node (`n12_departure`), no choice buttons remain (chapter complete) and a save file appears at the path printed by `OS.get_user_data_dir()` (Godot prints this to the console on startup) under `borrowed_fortune_chapter_00_prologue.json`.

If any of these don't hold, fix the scene wiring before proceeding — this manual pass is the only check on how the chapter actually *feels* to play, which the automated tests can't judge.

- [ ] **Step 7: Commit**

```bash
git add scenes/chapter_view/ scenes/main/ tests/unit/test_chapter_view.gd
git commit -m "feat: wire ChapterView and Main scene for a playable Prologue"
```

---

### Task 14: Full-suite verification and close-out

**Files:** none created; this task only runs and verifies.

**Interfaces:**
- Consumes: everything from Tasks 1–13.
- Produces: confirmation that the entire test suite passes together (not just per-file, as run in each task above) and a final summary commit tag.

- [ ] **Step 1: Run the entire suite together**

Run: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`
Expected: all tests across every file pass (Tasks 2–13 total 12 test files; no cross-file interference). If a test that passed in isolation fails here, suspect shared state — GUT runs each `test_*` method fresh per `extends GutTest` script, but static-typed `class_name` singletons or `user://` file leftovers (Task 9's save test) can leak between runs; the `DirAccess.remove_absolute` cleanup in `test_save_manager.gd` Step 3 exists for exactly this reason.

- [ ] **Step 2: Re-run the Task 13 manual playtest once more, start to finish**

Confirm the whole Prologue — all 12 nodes, both branch points, the Margin popup, and the save file — still plays cleanly end to end after every task's changes.

- [ ] **Step 3: Tag the milestone**

```bash
git tag -a v0.1-prologue -m "Prologue (Chapter 0) playable end-to-end with core engine systems"
```

No further commit is needed — this task verifies and tags what Tasks 1–13 already committed.

---

## Post-Plan Note

Chapters 1–7 are not part of this plan. When that work begins, it will reuse every engine system built here unchanged (`Ledger`, `ReputationTracker`, `DialogueEngine`, `MarginGlossary`/`GlossedTextParser`, `GameState`/`SaveManager`, `ChapterView`) and add only new `content/chapters/chapter_0N_*/` JSON files plus their glossary entries — the same pattern Task 10/11 established for the Prologue. The `MudarabaPartnership` and `Suftaja` persistence gap noted in Task 5 should be closed the first time a future chapter actually creates one of those instruments.
