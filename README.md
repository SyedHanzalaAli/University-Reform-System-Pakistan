# University Education Reform Expert System for Pakistan

A rule-based **Knowledge Representation and Reasoning (KRR)** expert system developed in **SWI-Prolog** that diagnoses weaknesses in conventional university education policies and demonstrates an alternative university operating model.

---

## 1. Project Information

- **Project Title:** University Education Reform Expert System for Pakistan
- **Technology:** SWI-Prolog (Pure Logical Rule-Based Reasoning Engine)
- **Project Type:** Undergraduate KRR Rule-Based Expert System

### Project Team

| # | Name | Roll Number | Role |
|---|------|-------------|------|
| 1 | **Syed Hanzala Ali** | `24K0025` | Project Lead |
| 2 | **Rafay Siddiqui** | `24K0009` | Team Member |
| 3 | **Azan Naveed** | `24K5638` | Team Member |

> **Important Notice on Sample Data:** All university names, teacher names, student names, marks, grade thresholds, enrollment numbers, rupee compensation rates, and budget allocations in `knowledge_base.pl` are **fictional demonstration data** created strictly to illustrate the logical rules of the expert system.

---

## 2. Project Structure

```text
University_Reform_System/
│
├── main.pl                     % Entry point and 14-option interactive CLI menu
├── utilities.pl                % Reusable console output & list-printing helpers
├── knowledge_base.pl           % All fictional university facts (dynamic predicates)
├── academic_policy.pl          % Module A: Attendance and learning policy diagnosis
├── teacher_recruitment.pl      % Module B: Teacher recruitment process & candidate evaluation
├── teacher_specialization.pl   % Module C: Two-course teacher specialization check
├── responsibilities.pl         % Module D: Teacher vs. assistant responsibility check
├── student_selection.pl        % Module H: Teacher availability, student selection, transfers & feedback
├── examination_system.pl       % Module E: Centralized exam papers, common marking schemes & moderation
├── grading.pl                  % Module F: Difficulty-adjusted, standards-based grading (no bell curve)
├── exam_scheduling.pl          % Module G: 16+4 modular & Weeks 21-24 linear/deferred exam scheduling
├── compensation.pl             % Module I: Enrollment-based teacher compensation calculation
├── governance_finance.pl       % Module J: University governance ownership & financial transparency
├── recommendations.pl          % Reform recommendation engine & comprehensive report (Option 14)
├── tests.pl                    % 65 automated Prolog unit, edge-case & integration tests
├── run_menu.bat                % One-click Windows launcher for the 14-option interactive menu
├── run_tests.bat               % One-click Windows launcher for all 65 automated tests
├── run_demo_all.bat            % One-click Windows launcher to print all 14 menu reports
├── swipl.bat                   % Portable SWI-Prolog wrapper script
├── README.md                   % Installation, setup and execution guide
├── PROJECT_REQUIREMENTS.md     % Phase 1 formal requirements specification & traceability matrix
├── SYSTEM_DESIGN.md            % System architecture, predicate reference & inference engine design
├── PROJECT_REPORT.md           % Complete KRR project report with example queries & outputs
└── VIVA_PREPARATION.md         % Beginner-friendly viva guide, 45 Q&As & live demonstration script
```

---

## 3. Prerequisites & Installation

### Installing SWI-Prolog

1. **Windows:**
   - Download the 64-bit installer from [https://www.swi-prolog.org/download/stable](https://www.swi-prolog.org/download/stable) or run in an Administrator PowerShell/Command Prompt:
     ```powershell
     winget install --id SWI-Prolog.SWI-Prolog -e
     ```
   - Ensure `swipl` is added to your system `PATH` (default location: `C:\Program Files\swipl\bin\swipl.exe`).
2. **Linux (Ubuntu/Debian):**
   ```bash
   sudo apt update && sudo apt install swi-prolog
   ```
3. **macOS (Homebrew):**
   ```bash
   brew install swi-prolog
   ```

Verify the installation by opening a terminal and running:

```bash
swipl --version
```

---

## 4. How to Run the Application

Open a terminal inside the `University_Reform_System` directory.

### Mode 1: Interactive Text Menu (Recommended for Viva)

```bash
swipl main.pl
```

At the SWI-Prolog `?-` prompt, start the menu by typing:

```prolog
?- start.
```

*(Note: Once inside the menu, simply type a number `0` to `14` and press **Enter**—you do not need to type a period `.` for menu choices.)*

Or launch directly into the interactive menu from your shell:

```bash
swipl -g start -t halt main.pl
```

### Mode 2: Run a Single Menu Option Directly

You can run any menu option (`1` through `14`) from the command line:

```bash
swipl -g "run_choice(1)" -t halt main.pl
swipl -g "run_choice(7)" -t halt main.pl
swipl -g "run_choice(14)" -t halt main.pl
```

### Mode 3: Run All 14 Menu Options Sequentially

To print the complete output of all 14 menu options in one pass:

```bash
swipl -g demo_all -t halt main.pl
```

### Mode 4: Run the Automated Test Suite (`tests.pl`)

To execute all 51 automated test cases (including the 16 mandatory requirements `R01`–`R16` and edge cases):

```bash
swipl -g run_all_tests -t halt tests.pl
```

Or interactively inside SWI-Prolog:

```prolog
?- [tests].
?- run_all_tests.
```

---

## 5. Overview of the 14 Menu Options

| Option | Title | Module | Primary Predicate Called |
|--------|-------|--------|--------------------------|
| **1** | Diagnose existing academic policies | Module A | `report_academic_policy/0` |
| **2** | Evaluate teacher recruitment practices | Module B | `report_recruitment/0` |
| **3** | Check teacher course specialization | Module C | `report_specialization/0` |
| **4** | View teacher availability and student selection | Module H | `report_student_selection/0` |
| **5** | Check centralized examination arrangements | Module E | `report_central_exams/0` |
| **6** | Check examination marking consistency | Module E | `report_marking/0` |
| **7** | Apply difficulty-adjusted grade thresholds | Module F | `report_grading/0` |
| **8** | View individual student examination routes | Module G | `report_student_routes/0` |
| **9** | Generate modular and linear examination schedules | Module G | `report_exam_schedule/0` |
| **10** | Identify deferred examination eligibility | Module G | `report_deferred/0` |
| **11** | Calculate teacher compensation | Module I | `report_compensation/0` |
| **12** | Check staff responsibilities | Modules D & J | `report_responsibilities/0`, `report_governance/0` |
| **13** | Check financial transparency | Module J | `report_finance/0` |
| **14** | Generate a comprehensive reform report | All Modules | `report_comprehensive/0` |
| **0** | Exit | — | Terminates `menu_loop/0` |

---

## 6. Extending the Knowledge Base Without Rewriting Rules

All facts live in `knowledge_base.pl` and all predicates are declared `:- dynamic`. No reasoning rule in any module hard-codes specific student, teacher, or course names.

You can add new facts either by editing `knowledge_base.pl` or live during your viva at the `?-` prompt:

```prolog
% Example 1: Add a new student and enroll them in Mr. Bilal's Computer Networks section
?- assertz(student(s12, 'Zainab Tariq')),
   assertz(enrolled(s12, cn301_c)).

% Verify seats remaining and updated teacher compensation for Mr. Bilal:
?- seats_remaining(cn301_c, Seats),
   teacher_term_payment(t_bilal, fall, '2025-26', Payment).
% Output: Seats = 2, Payment = 3000.
```

---

## 7. Verification Status Note

- **SWI-Prolog Portable / System Support:** The included launcher scripts (`swipl.bat`, `run_menu.bat`, `run_tests.bat`, `run_demo_all.bat`) automatically use either a portable `..\swipl\bin\swipl.exe` folder or a standard system `swipl` installation.
- **Runtime Test Suite Verified (65 / 65 Passed):** Every test case in `tests.pl` (covering all 16 mandatory verification scenarios `R01`–`R16`, edge cases, and all 14 menu options) was executed in SWI-Prolog 11.0.0 and passed (`RESULT: 65 / 65 tests passed, 0 failed`).
- **One-Click Launchers Included:** You can double-click `run_menu.bat`, `run_tests.bat`, or `run_demo_all.bat` directly in Windows File Explorer, or run `swipl -g start -t halt main.pl` from any terminal.
