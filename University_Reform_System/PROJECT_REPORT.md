# Project Report — University Education Reform Expert System for Pakistan

**Course:** Knowledge Representation and Reasoning (KRR)  
**Technology:** SWI-Prolog  
**Project Team:**
1. **Syed Hanzala Ali** — `24K0025` — Project Lead
2. **Rafay Siddiqui** — `24K0009`
3. **Azan Naveed** — `24K5638`

---

## 1. Executive Summary

Conventional university operating models often suffer from rigid compulsory lecture attendance rules, fragmented section-by-section examination and marking practices, relative or bell-curve grading, hiring criteria that overlook teaching ability, frequent assignment of unrelated courses to faculty, and opaque governance and financial records.

To address these problems systematically, we designed and built the **University Education Reform Expert System for Pakistan** in **SWI-Prolog**. The system encodes both conventional university practices (`conventional_uni`) and a complete alternative university operating model (`reform_uni`) as a formal declarative Knowledge Base (`knowledge_base.pl`) paired with ten modular rule-based reasoning engines (Modules A–J).

---

## 2. Knowledge Representation and Reasoning (KRR) Methodology

### 2.1 Separation of Knowledge Base and Inference Engine

A core principle of expert systems is separating **domain facts** from **reasoning rules**:

- **Knowledge Base (`knowledge_base.pl`):** Contains 49 dynamic predicates representing fictional universities, courses, teachers, sections, candidates, exam sessions, grade thresholds, modular/linear choices, enrollments, payment rates, governance duties, and budget figures.
- **Inference Rules (`academic_policy.pl` through `recommendations.pl`):** Contain pure logical rules (`Head :- Body.`) that never mention any specific student, teacher, or course constant. Consequently, adding new facts to `knowledge_base.pl` works automatically across all 14 menu options without altering a single rule.

### 2.2 KRR Techniques Demonstrated in Code

| KRR Concept | Where It Is Demonstrated in the Project |
|-------------|-----------------------------------------|
| **Facts & Predicate Arity** | `knowledge_base.pl` (e.g., `section/6`, `module_choice/4`, `grade_threshold/3`, `rate_per_student/1`) |
| **Rule-Based Inference** | Diagnostic rules `academic_issue/3`, `recruitment_issue/3`, `specialization_issue/3`, `exam_arrangement_issue/3`, `marking_issue/3`, `grading_issue/3`, `scheduling_issue/3`, `governance_issue/3`, `finance_issue/3` |
| **Variables & Unification** | Pattern-matching issue terms in `recommendation(compulsory_attendance(_), Text)` and joining `(Course, Term, Year)` in `session_section/2` |
| **Conjunction (`,`)** | `deferred_eligible(S, C, M) :- module_choice(S, C, M, modular), exam_missed(S, C, M).` |
| **Disjunction (Multiple Clauses / `;`)** | Three clauses of `scheduled_exam/6` (`modular`, `linear`, `deferred`) and two clauses of `criterion_required/2` |
| **Negation as Failure (`\+`)** | Detecting missing supervised exams (`\+ uses_assessment(Uni, scheduled_supervised_exam)`), unassigned duties (`\+ duty_assigned(Uni, Task, _)`), and compliance checks |
| **Epistemic Missing-Information Handling** | Reporting unrecorded policies, missing exam papers, unrecorded module choices, and missing expenditure records as `unknown` rather than assuming compliance or misconduct |
| **Lists & Recursion** | `strictly_decreasing([First, Second | Rest])` and `first_grade_met([Candidate | Rest], ...)` in `grading.pl`; `print_all_tagged([Item | Rest], Tag)` in `utilities.pl` |
| **Backtracking & Meta-Predicates** | `findall/3`, `sort/2`, `forall/2`, `aggregate_all/3`, and meta-call `call(IssuePredicate, Subject, IssueId, Text)` in `reform_issue/4` |
| **Prolog Arithmetic (`is`)** | Remaining seats (`Capacity - Count`), teacher payment (`Students * Rate`), budget variance (`round((Actual - Approved) * 100 / Approved)`), and 16+4=20 week calendar verification |

---

## 3. Module-by-Module Design & Logic Walkthrough

### 3.1 Module A — Attendance and Learning (`academic_policy.pl`)

- **Purpose:** Eliminates compulsory lecture attendance, attendance percentages, attendance mark deductions/exam bars, homework, random quizzes, unannounced tests, and take-home assessments; replaces them with scheduled, supervised physical exams and free choice of learning resources (lectures, books, YouTube, ChatGPT).
- **Key Guardrail:** Rule A1 checks `attendance_rule(Uni, SessionType, compulsory), SessionType \= practical`. By checking `SessionType \= practical` rather than `SessionType = lecture`, compulsory lecture attendance cannot be sneaked back in under another label like `tutorial` or `seminar`. Practical/lab components (`practical_component/3`) are stored separately.

### 3.2 Module B — Teacher Recruitment (`teacher_recruitment.pl`)

- **Purpose:** Evaluates recruitment processes and candidates across five criteria: (1) relevant qualification, (2) subject knowledge test, (3) demonstration lecture, (4) teaching communication, and (5) practical experience where appropriate (`process_requires_experience/2`).
- **Plain-English Logic:**
  - `conv_hiring` evaluates only qualifications and publications -> flagged with `qualifications_only` and `missing_criterion(...)`.
  - Candidate `c_kamran` has a PhD and 9/10 on the subject test, but 4/10 on his demonstration lecture -> `candidate_decision(c_kamran, not_recommended)`.
  - Candidate `c_sana` passes all five criteria -> `candidate_decision(c_sana, recommended)`.
  - Candidate `c_imran` has no recorded demo lecture score -> `candidate_decision(c_imran, incomplete_information)`.

### 3.3 Module C — Teacher Course Specialization (`teacher_specialization.pl`)

- **Purpose:** Ensures each teacher specializes in **two courses per academic year** (one in Fall, one in Spring), continues teaching those same two courses across years, and may repeat batches in Summer.
- **Plain-English Logic:**
  - `teaching_records/2` collects `record(Course, Term, Year)` from `section/6` and applies `sort/2` so multiple sections of the same course count as one course.
  - Teacher `t_ahmed` teaches `cn301` in Fall 2025-26, repeats `cn301` in Summer 2025-26, continues `cn301` in Fall 2026-27, and teaches `os302` in Spring 2025-26 -> **compliant**.
  - Teacher `t_usman` (assigned `os302` in Fall and `ai401` in Spring) is given `db201` in Fall (`unrelated_course`) and `os302` in Spring (`wrong_term`) -> **both violations detected**.

### 3.4 Module D — Teacher Responsibilities and Assistants (`responsibilities.pl`)

- **Purpose:** Keeps teachers focused on lectures and academic guidance while assigning paper preparation to `central_exam_team`, invigilation and logistics to `exam_assistants`, script marking to `central_marking_assistants`, and moderation/QA/appeals to `academic_oversight`.

### 3.5 Module E — Centralized Examination System (`examination_system.pl`)

- **Purpose:** Ensures every section of a course in an examination session sits ONE common paper prepared by the central team, is marked with ONE common marking scheme (with question marks, expected answers, and partial-credit rules) by central marking assistants, and is centrally moderated.
- **Plain-English Logic:**
  - `cn301_fall2025` has three sections (`cn301_a`, `cn301_b`, `cn301_c`) taught by three teachers (`t_ahmed`, `t_fatima`, `t_bilal`). All three use `cn_paper_2025` and `cn_scheme_2025` (100 marks across 3 detailed questions), marked by `central_marking_assistants` with recorded moderation -> **verified**.
  - `db201_fall2025` has two sections (`db201_a`, `db201_b`) using two different teacher-written papers (`db_paper_ayesha`, `db_paper_usman`), two different schemes, local teacher marking, and no moderation -> **all violations detected**.

### 3.6 Module F — Difficulty-Adjusted, Standards-Based Grading (`grading.pl`)

- **Purpose:** Replaces bell-curve and relative grading with difficulty-adjusted, standards-based grade thresholds approved per session by the examination team.
- **Why No Bell Curve Can Ever Occur:**
  ```prolog
  mark_to_grade(Session, Mark, Grade) :-
      thresholds_valid(Session),
      grade_sequence(Grades),
      first_grade_met(Grades, Session, Mark, Grade).
  ```
  Notice that `mark_to_grade/3` takes only `Session` and `Mark`. It never reads any other student's mark, never computes a class average, and never ranks students.
  - In `cn301_fall2020` (reviewed as *relatively easy*, A threshold = 85), 4 out of 5 students (80%) score >= 85 and all 4 receive an `a`. A score of 78 earns a `b`.
  - In `cn301_fall2021` (reviewed as *relatively difficult*, A threshold = 75), a score of 78 meets the 75 threshold and earns an `a`.

### 3.7 Module G — Modular and Linear Examination System (`exam_scheduling.pl`)

- **Purpose:** Implements the 4-module calendar (4 teaching weeks + 1 exam week per module = 16 teaching + 4 exam = 20 weeks) plus Weeks 21–24 for linear and deferred modular exams.
- **Key Features:**
  1. **Per-module route mixing:** Student `s01` chooses `modular` for Module 1 (Week 5), `linear` for Module 2 (Week 22), `modular` for Module 3 (Week 15), and `linear` for Module 4 (Week 24).
  2. **Missed modular exam vs. attempted exam below standard:** Student `s02` chose `modular` for all 4 modules of `cn301`, missed Module 2 (`exam_missed(s02, cn301, 2)`), and attempted Module 3 scoring 38 (`exam_attempted(s02, cn301, 3, 38)`). The system grants `s02` a deferred exam in Week 22 for Module 2 (`missed_deferred_exam_eligible`), while recording Module 3 as `attempted_below_standard(38)` (not eligible for a deferred modular exam).
  3. **Conflict detection:** Detects both modular clashes (`s01` has `db201` and `os302` modular exams on Week 5 Tuesday) and deferred-vs-linear clashes (`s10` has a deferred `db201` exam and a linear `os302` exam on Week 22 Tuesday).

### 3.8 Module H — Student Teacher Selection (`student_selection.pl`)

- **Purpose:** Shows available teachers and remaining seats (`Seats is Capacity - Enrolled`), processes initial teacher selection requests and section transfer requests according to an administrative procedure, and aggregates anonymous student ratings (`confidential_feedback/3` stores no student ID).
- **Sample Results:**
  - `cn301_a` (Mr. Ahmed, capacity 4) has 4 enrolled students -> `0` seats left. Student `s10` requesting Mr. Ahmed is `waitlisted` and shown alternatives (`t_fatima` with 2 seats, `t_bilal` with 3 seats).
  - Student `s11` requesting Mr. Bilal (`cn301_c`) is `approved`.
  - Transfer request by `s07` from `cn301_b` to `cn301_c` is `approved`; transfer by `s09` into full `cn301_a` is `rejected`.

### 3.9 Module I — Enrollment-Based Teacher Compensation (`compensation.pl`)

- **Purpose:** Links teacher compensation to student enrollment using `Payment = Enrolled Students * Configured Rate Per Student` (fictional rate `Rs. 1,000`). Optional course weighting is disabled by default and kept separate in `adjusted_section_payment/2`.
- **Sample Results (Fall 2025-26):**
  - Formula illustration: 20 students = Rs. 20,000; 40 students = Rs. 40,000; 60 students = Rs. 60,000.
  - Mr. Ahmed (`cn301_a`, 4 students) -> Rs. 4,000.
  - Ms. Fatima (`cn301_b`, 3 students) -> Rs. 3,000.
  - Mr. Bilal (`cn301_c`, 2 students) -> Rs. 2,000.
  - Ms. Ayesha (`db201_a`, 4 students) -> Rs. 4,000.
  - Mr. Usman (`db201_b` 2 students + `os302_a` 3 students = 5 students) -> Rs. 5,000.

### 3.10 Module J — Financial Transparency and University Governance (`governance_finance.pl`)

- **Purpose:** Audits ownership of 7 university governance duties and checks 7 financial categories for approved allocations, actual expenditures, budget variance (> 10%), and documentation.
- **Ethical KRR Principle:** Missing expenditure records (e.g., `research` actual spending at `reform_uni`, or unrecorded categories at `conventional_uni`) are reported as `unknown` ("information gap, NOT evidence of misconduct"). High variances (e.g., `administration` at `reform_uni`: approved 120M vs. actual 150M, +25%) are reported as `review_required` ("explanation requested (not a finding of misconduct)").

---

## 4. Demonstration Queries and Expected Outputs

Below are key interactive SWI-Prolog queries and their exact outputs when loaded via `swipl main.pl`:

### Query 1 — Diagnose Conventional Attendance & Assessment Policy (Module A)
```prolog
?- academic_issue(conventional_uni, IssueId, Explanation).
```
**Expected Output:**
```text
IssueId = compulsory_attendance(lecture),
Explanation = 'Attendance is compulsory for lecture sessions.' ;
IssueId = minimum_attendance_percentage,
Explanation = 'A minimum attendance of 75% is required.' ;
IssueId = attendance_reduces_marks,
Explanation = 'Missing lectures automatically reduces marks.' ;
IssueId = attendance_blocks_exams,
Explanation = 'Low attendance can make a student ineligible for examinations.' ;
IssueId = restricted_learning_resources,
Explanation = 'External learning resources (books, YouTube, ChatGPT ...) are discouraged.' ;
IssueId = prohibited_assessment(homework_assignment),
Explanation = 'Uses homework_assignment, which the reform model removes.' ;
IssueId = prohibited_assessment(random_quiz),
Explanation = 'Uses random_quiz, which the reform model removes.' ;
IssueId = prohibited_assessment(unannounced_test),
Explanation = 'Uses unannounced_test, which the reform model removes.' ;
IssueId = prohibited_assessment(take_home_assessment),
Explanation = 'Uses take_home_assessment, which the reform model removes.'
```

### Query 2 — Evaluate Recruitment Process & Candidates (Module B)
```prolog
?- recruitment_issue(conv_hiring, qualifications_only, Text),
   candidate_decision(c_kamran, D_Kamran),
   candidate_decision(c_sana, D_Sana),
   candidate_decision(c_imran, D_Imran).
```
**Expected Output:**
```text
Text = 'Evaluates academic qualifications but ignores teaching ability.',
D_Kamran = not_recommended,
D_Sana = recommended,
D_Imran = incomplete_information.
```

### Query 3 — Check Teacher Course Specialization (Module C)
```prolog
?- specialization_compliant(t_ahmed),
   findall(Id, specialization_issue(t_usman, Id, _), UsmanViolations).
```
**Expected Output:**
```text
UsmanViolations = [unrelated_course(db201, fall, '2025-26'),
                   wrong_term(os302, spring, '2025-26')].
```

### Query 4 — Verify Centralized Exam Papers & Marking Schemes (Module E)
```prolog
?- centralized_exam_verified(cn301_fall2025),
   central_marking_verified(cn301_fall2025),
   papers_used(db201_fall2025, DbPapers),
   schemes_used(db201_fall2025, DbSchemes).
```
**Expected Output:**
```text
DbPapers = [db_paper_ayesha, db_paper_usman],
DbSchemes = [db_scheme_ayesha, db_scheme_usman].
```

### Query 5 — Difficulty-Adjusted Standards-Based Grading (Module F)
```prolog
?- mark_to_grade(cn301_fall2020, 78, GradeEasy2020),
   mark_to_grade(cn301_fall2021, 78, GradeHard2021),
   grade_count(cn301_fall2020, a, ACount2020).
```
**Expected Output:**
```text
GradeEasy2020 = b,
GradeHard2021 = a,
ACount2020 = 4.
```

### Query 6 — Mixed Modular/Linear Schedule & Deferred Exam Eligibility (Module G)
```prolog
?- student_schedule(s01, S01Slots),
   deferred_eligible(s02, cn301, DeferredMod),
   module_status(s02, cn301, 2, StatusMod2),
   module_status(s02, cn301, 3, StatusMod3).
```
**Expected Output:**
```text
S01Slots = [slot(5, monday, cn301, 1, modular),
            slot(5, tuesday, db201, 1, modular),
            slot(5, tuesday, os302, 1, modular),
            slot(10, tuesday, db201, 2, modular),
            slot(15, monday, cn301, 3, modular),
            slot(15, tuesday, db201, 3, modular),
            slot(20, tuesday, db201, 4, modular),
            slot(22, monday, cn301, 2, linear),
            slot(22, tuesday, os302, 2, linear),
            slot(23, tuesday, os302, 3, linear),
            slot(24, monday, cn301, 4, linear),
            slot(24, tuesday, os302, 4, linear)],
DeferredMod = 2,
StatusMod2 = missed_deferred_exam_eligible,
StatusMod3 = attempted_below_standard(38).
```

### Query 7 — Student Teacher Selection, Capacity & Compensation (Modules H & I)
```prolog
?- selection_decision(s10, cn301, t_ahmed, S10Status, S10Sec, _),
   selection_decision(s11, cn301, t_bilal, S11Status, S11Sec, _),
   teacher_term_payment(t_ahmed, fall, '2025-26', PayAhmed),
   teacher_term_payment(t_usman, fall, '2025-26', PayUsman).
```
**Expected Output:**
```text
S10Status = waitlisted, S10Sec = cn301_a,
S11Status = approved,   S11Sec = cn301_c,
PayAhmed = 4000,
PayUsman = 5000.
```

### Query 8 — Governance & Financial Transparency (Module J)
```prolog
?- finance_status(reform_uni, '2025-26', research, ResearchStatus),
   finance_status(reform_uni, '2025-26', administration, AdminStatus),
   findall(D, governance_issue(conventional_uni, unassigned_duty(D), _), Unassigned).
```
**Expected Output:**
```text
ResearchStatus = unknown_actual_expenditure,
AdminStatus = review_required(120, 150, 25),
Unassigned = [curriculum_coordination, laboratory_maintenance, student_complaints].
```

---

## 5. Testing and Verification Summary

The file `tests.pl` contains **65 automated test cases**, including all 16 mandatory verification scenarios (`R01`–`R16`) specified in Section 9 of the project requirements, edge cases (using `with_temporary_facts/2` and `without_facts/2`), and full menu integration tests.

### Executed Runtime Verification in SWI-Prolog 11.0.0

1. **Static & Logical Verification:**
   - All 15 Prolog source files (`199` distinct predicates) compiled cleanly in SWI-Prolog `11.0.0 for x64-win64` with **0 errors, 0 singleton variable warnings, and 0 discontiguous predicate warnings**.
2. **Automated Runtime Execution (`tests.pl` & `demo_all`):**
   - Executed via:
     ```bash
     swipl -g run_all_tests -t halt tests.pl
     ```
   - Verified runtime output:
     ```text
     RESULT: 65 / 65 tests passed, 0 failed.
     ```
   - All 14 menu options were also executed end-to-end via `swipl -g demo_all -t halt main.pl` and verified against expected outputs.
