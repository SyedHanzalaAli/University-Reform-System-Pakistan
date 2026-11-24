# System Architecture & Design — University Education Reform Expert System

**Project Title:** University Education Reform Expert System for Pakistan  
**Project Team:** Syed Hanzala Ali (`24K0025`, Project Lead), Rafay Siddiqui (`24K0009`), Azan Naveed (`24K5638`)  
**Technology:** SWI-Prolog

---

## 1. High-Level Expert System Architecture

The application follows the classical four-layer **Rule-Based Expert System** architecture:

```text
+-----------------------------------------------------------------------+
| 1. USER INTERFACE LAYER (main.pl, utilities.pl)                       |
|    - 14-option interactive text menu (start/0, menu_loop/0)           |
|    - Non-interactive batch runners (run_choice/1, demo_all/0)         |
|    - Reusable formatted console helpers (print_heading/1, etc.)       |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
| 2. META-REASONING & RECOMMENDATION ENGINE (recommendations.pl)        |
|    - Unified cross-module query engine (reform_issue/4)               |
|    - Pattern-matched reform recommendations (recommendation/2)        |
|    - Explicit open policy decision register (open_policy_decision/1)  |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
| 3. DOMAIN INFERENCE MODULES (Modules A - J)                           |
|    - academic_policy.pl        (Module A: Attendance & Learning)      |
|    - teacher_recruitment.pl    (Module B: Hiring & Candidates)        |
|    - teacher_specialization.pl (Module C: Two-Course Specialization)  |
|    - responsibilities.pl       (Module D: Teachers vs. Assistants)    |
|    - examination_system.pl     (Module E: Central Papers & Marking)   |
|    - grading.pl                (Module F: Standards-Based Grading)    |
|    - exam_scheduling.pl        (Module G: 16+4 Modular/Linear/Defer)  |
|    - student_selection.pl      (Module H: Selection/Transfer/Rating)  |
|    - compensation.pl           (Module I: Enrollment Compensation)    |
|    - governance_finance.pl     (Module J: Governance & Transparency)  |
+-----------------------------------------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
| 4. DYNAMIC KNOWLEDGE BASE (knowledge_base.pl)                         |
|    - 49 dynamic fact predicates holding fictional demonstration data  |
|    - Zero hard-coded rules; extendable at runtime via assertz/1       |
+-----------------------------------------------------------------------+
```

### Load Order & Dependency Rules

`main.pl` loads the files via `:- ensure_loaded(...)` in a clean, linear hierarchy:

1. `utilities.pl` (no dependencies)
2. `knowledge_base.pl` (no dependencies; declares all 49 dynamic fact predicates)
3. Domain modules (`academic_policy.pl` through `governance_finance.pl`)
   - Note: `compensation.pl` calls `enrolled_count/2` defined in `student_selection.pl`, and each report calls `print_recommendations_for/2` defined in `recommendations.pl`. In Prolog, predicates are resolved at query time, so there are **zero circular load dependencies** and **zero duplicated facts**.
4. `recommendations.pl` (aggregates issues across all domain modules)
5. `tests.pl` (loads `main.pl` and runs 51 automated test cases)

---

## 2. How the Prolog Inference Engine Works

Our system relies entirely on SWI-Prolog's built-in **backward-chaining SLD resolution** engine:

1. **Facts vs. Rules:**
   - **Facts** (`knowledge_base.pl`) represent base propositions known to be true in the fictional dataset (e.g., `enrolled(s01, cn301_a).`).
   - **Rules** (`Head :- Body.`) represent conditional knowledge: `Head` is inferred to be true if every sub-goal in `Body` can be proven.
2. **Unification:**
   - Two terms unify if their functors and arities match and their arguments can be made identical by binding variables.
   - Example: `recommendation(compulsory_attendance(_), Advice)` uses the anonymous variable `_` to unify with `compulsory_attendance(lecture)`, `compulsory_attendance(tutorial)`, or any other session type.
3. **Conjunction and Disjunction:**
   - **Conjunction (AND `,`):** Used inside rule bodies when several conditions must hold together (e.g., in `deferred_eligible/3`: the student chose `modular` **AND** missed the exam).
   - **Disjunction (OR `;` and multiple clauses):** Used when there are multiple ways to prove a goal. For example, `scheduled_exam/6` has three clauses: one for `modular` exams (Weeks 5, 10, 15, 20), one for `linear` exams (Weeks 21–24), and one for `deferred` exams (Weeks 21–24).
4. **Backtracking:**
   - When a query can be satisfied in multiple ways (such as `academic_issue(conventional_uni, Id, Text)`), Prolog finds the first matching clause/fact, and upon backtracking (`;`, `forall/2`, or `findall/3`), systematically explores all remaining branches.
5. **Negation as Failure (`\+`) and Epistemic Missing-Information Handling:**
   - Under Prolog's Closed-World Assumption, `\+ Goal` succeeds when `Goal` cannot be proven from the current knowledge base.
   - Instead of equating missing facts with compliance or misconduct, we write explicit missing-information rules (e.g., `academic_policy_unknown/2`, `section_without_paper/1`, `missing_module_choice/3`, `unknown_actual_expenditure`). A university is only declared compliant when `\+ Issue` **AND** `\+ Unknown`.
6. **Lists, Recursion, and Aggregation:**
   - **Explicit List Recursion:**
     - `print_all_tagged([Item | Rest], Tag)` in `utilities.pl`
     - `strictly_decreasing([First, Second | Rest])` in `grading.pl`
     - `first_grade_met([Candidate | Rest], Session, Mark, Grade)` in `grading.pl`
   - **List Aggregation & Sorting:**
     - `findall(Template, Goal, Bag)` collects all solutions into a list.
     - `sort(Bag, UniqueSorted)` sorts and removes duplicates (crucial in Module C so teaching multiple sections of `cn301` counts as one course, and in Module E to count distinct papers/schemes across sections).
     - `aggregate_all(count, Goal, Count)` counts matching solutions.
     - `sum_list(List, Total)` sums marks, teaching weeks, and payments.
7. **Arithmetic:**
   - Evaluated via `is/2` and compared with `>=`, `=<`, `>`, `<`, `=:=`, `=\=`:
     - Remaining seats: `Seats is Capacity - Count`
     - Compensation: `Payment is Students * Rate`
     - Budget variance: `Percent is round((Actual - Approved) * 100 / Approved)`
     - Calendar verification: `Last - First + 1 =:= 4`

---

## 3. Complete Predicate Catalog

### 3.1 Knowledge Base Fact Predicates (`knowledge_base.pl`)

| Predicate / Arity | Arguments | Description |
|-------------------|-----------|-------------|
| `university/2` | `(UniId, DisplayName)` | Fictional universities (`conventional_uni`, `reform_uni`) |
| `attendance_rule/3` | `(UniId, SessionType, Rule)` | `compulsory` or `optional` attendance |
| `policy/3` | `(UniId, PolicyKey, Value)` | Attendance % and resource policies |
| `uses_assessment/2` | `(UniId, AssessmentType)` | Assessment types used by a university |
| `practical_component/3` | `(UniId, CourseId, Description)` | Lab component stored separately from lectures |
| `recruitment_process/2` | `(ProcessId, UniId)` | Hiring processes (`conv_hiring`, `reform_hiring`) |
| `recruitment_criterion/2` | `(ProcessId, Criterion)` | Criteria evaluated by a hiring process |
| `process_requires_experience/2` | `(ProcessId, MinYears)` | Practical experience requirement where appropriate |
| `hiring_pass_mark/2` | `(Criterion, PassMarkOutOf10)` | Configurable minimum score per hiring test |
| `candidate/3` | `(CandidateId, Name, ProcessId)` | Demonstration teacher candidates |
| `candidate_qualification/3` | `(CandidateId, Degree, Relevance)` | `relevant` or `not_relevant` |
| `candidate_score/3` | `(CandidateId, Criterion, Score)` | Candidate score out of 10 |
| `candidate_experience_years/2` | `(CandidateId, Years)` | Years of relevant practical experience |
| `teacher/2` | `(TeacherId, Name)` | Demonstration teachers (`t_ahmed`..`t_usman`) |
| `course/2` | `(CourseId, Title)` | Demonstration courses (`cn301`, `db201`, `os302`, `ai401`) |
| `assigned_course/3` | `(TeacherId, CourseId, Term)` | Approved 2-course specialization pair (`fall`/`spring`) |
| `current_term/2` | `(Term, AcademicYear)` | Current active term (`fall`, `'2025-26'`) |
| `section/6` | `(SectionId, CourseId, TeacherId, Term, Year, Cap)` | Course sections and capacities |
| `duty_assigned/3` | `(UniId, Task, Role)` | Teaching and examination duty assignments |
| `exam_session/4` | `(SessionId, CourseId, Term, Year)` | Examination sessions across courses and years |
| `section_exam_paper/3` | `(SessionId, SectionId, PaperId)` | Paper administered to each section |
| `paper_prepared_by/2` | `(PaperId, Preparer)` | Role or teacher who prepared the paper |
| `section_marking_scheme/3` | `(SessionId, SectionId, SchemeId)` | Marking scheme applied to each section |
| `scheme_prepared_by/2` | `(SchemeId, Preparer)` | Role or teacher who prepared the scheme |
| `scheme_question/5` | `(SchemeId, QNo, Marks, Expected, Partial)` | Question-level rubric breakdown |
| `scripts_marked_by/3` | `(SessionId, SectionId, Marker)` | Role or teacher who marked the section's scripts |
| `moderation_record/2` | `(SessionId, Description)` | Central moderation record |
| `difficulty_review/3` | `(SessionId, Assessment, Notes)` | Exam team's difficulty review (input fact) |
| `grade_threshold/3` | `(SessionId, Grade, MinimumMark)` | Approved minimum mark for grade `a`..`f` |
| `exam_mark/3` | `(StudentId, SessionId, Mark)` | Student's raw mark in a session |
| `student/2` | `(StudentId, Name)` | Demonstration students |
| `enrolled/2` | `(StudentId, SectionId)` | Student section enrollments |
| `module_choice/4` | `(StudentId, CourseId, ModNo, Route)` | Per-module `modular` or `linear` choice (1..4) |
| `exam_attempted/4` | `(StudentId, CourseId, ModNo, Mark)` | Record of an attempted modular exam |
| `exam_missed/3` | `(StudentId, CourseId, ModNo)` | Record of a missed exam (distinct from attempted) |
| `module_pass_mark/2` | `(CourseId, PassMark)` | Configured module pass mark (hypothetical 40) |
| `course_exam_day/2` | `(CourseId, DayOfWeek)` | Configured exam day for a course |
| `linear_exam_week/2` | `(ModNo, Week)` | Configured week (21–24) for linear/deferred exams |
| `extended_period_capacity/2` | `(Week, MaxSittings)` | Seating capacity in Weeks 21–24 |
| `selection_request/3` | `(StudentId, CourseId, TeacherId)` | Student request to select a preferred teacher |
| `transfer_request/3` | `(StudentId, FromSecId, ToSecId)` | Student request to change teacher/section |
| `transfer_window/3` | `(Term, AcademicYear, Status)` | `open` or `closed` |
| `transfer_procedure_step/2` | `(StepNo, Description)` | Administratively defined transfer steps |
| `confidential_feedback/3` | `(SectionId, Rating, Comment)` | Anonymous student feedback (no StudentId) |
| `rate_per_student/1` | `(Rupees)` | Configurable per-student payment rate (demo: `1000`) |
| `optional_feature/2` | `(FeatureName, Status)` | `course_weighting` is `disabled` by default |
| `course_weight/2` | `(CourseId, Multiplier)` | Optional multiplier if weighting is enabled |
| `duty_owner/3` | `(UniId, GovernanceDuty, Office)` | Responsible office for university governance duties |
| `reporting_year/1` | `(AcademicYear)` | Financial reporting year (`'2025-26'`) |
| `variance_review_percent/1` | `(Percent)` | Variance threshold requiring explanation (`10`) |
| `approved_allocation/4` | `(UniId, Year, Category, AmountM)` | Approved budget in fictional Rs. millions |
| `actual_expenditure/4` | `(UniId, Year, Category, AmountM)` | Actual expenditure in fictional Rs. millions |
| `expenditure_documented/4` | `(UniId, Year, Category, YesNo)` | Whether supporting documents are published |

### 3.2 Reasoning & Inference Predicates (Modules A–J)

| File | Key Reasoning Predicates (`Name/Arity`) |
|------|-----------------------------------------|
| `academic_policy.pl` | `academic_issue/3`, `academic_policy_unknown/2`, `academic_policy_compliant/1`, `report_academic_policy/0` |
| `teacher_recruitment.pl` | `criterion_required/2`, `missing_criterion/2`, `recruitment_issue/3`, `recruitment_compliant/1`, `candidate_check/3`, `candidate_decision/2`, `report_recruitment/0` |
| `teacher_specialization.pl` | `assigned_courses/2`, `teaching_records/2`, `teaches_course/4`, `specialization_issue/3`, `specialization_compliant/1`, `section_count/5`, `report_specialization/0` |
| `responsibilities.pl` | `approved_role/2`, `responsibility_issue/3`, `responsibilities_compliant/1`, `report_responsibilities/0` |
| `examination_system.pl` | `session_section/2`, `papers_used/2`, `schemes_used/2`, `exam_arrangement_issue/3`, `centralized_exam_verified/1`, `marking_issue/3`, `central_marking_verified/1`, `scheme_total_marks/2`, `report_central_exams/0`, `report_marking/0` |
| `grading.pl` | `thresholds_complete/1`, `strictly_decreasing/1`, `thresholds_valid/1`, `mark_to_grade/3`, `student_grade/3`, `grade_count/3`, `grading_issue/3`, `report_grading/0` |
| `exam_scheduling.pl` | `module_plan/4`, `teaching_weeks_total/1`, `exam_weeks_total/1`, `calendar_valid/0`, `deferred_eligible/3`, `scheduled_exam/6`, `module_status/4`, `exam_clash/5`, `extended_week_load/2`, `missing_module_choice/3`, `scheduling_issue/3`, `student_schedule/2`, `report_student_routes/0`, `report_exam_schedule/0`, `report_deferred/0` |
| `student_selection.pl` | `enrolled_count/2`, `seats_remaining/2`, `section_has_space/1`, `available_teacher/4`, `selection_decision/6`, `alternative_section/5`, `transfer_decision/5`, `apply_transfer/3`, `teacher_feedback_summary/3`, `report_student_selection/0` |
| `compensation.pl` | `payment_for_enrollment/2`, `section_payment/4`, `teacher_term_payment/4`, `teacher_term_students/4`, `adjusted_section_payment/2`, `report_compensation/0` |
| `governance_finance.pl` | `duty_owners/3`, `governance_issue/3`, `governance_compliant/1`, `budget_available/2`, `finance_status/4`, `variance_status/3`, `documentation_status/4`, `finance_issue/3`, `report_governance/0`, `report_finance/0` |
| `recommendations.pl` | `recommendation/2`, `print_recommendations_for/2`, `reform_area/3`, `reform_issue/4`, `open_policy_decision/1`, `report_comprehensive/0` |
