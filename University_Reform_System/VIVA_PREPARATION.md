# Viva Preparation Guide — University Education Reform Expert System for Pakistan

**Project Team:**
1. **Syed Hanzala Ali** — `24K0025` — Project Lead
2. **Rafay Siddiqui** — `24K0009`
3. **Azan Naveed** — `24K5638`

This guide is written in beginner-friendly English so that every team member can explain the project, the Prolog concepts, and every single module during the viva examination.

---

## 1. The Whole Project in Plain English (60-Second Elevator Pitch)

> *"Our project is a rule-based **Expert System** built in **SWI-Prolog** that does two things: first, it **diagnoses weaknesses** in conventional university policies (`conventional_uni`), and second, it **demonstrates a complete alternative university operating model** (`reform_uni`).*
>
> *We separated our system into a **Knowledge Base** (`knowledge_base.pl`), which holds fictional facts about two universities, courses, teachers, sections, students, exams, and budgets, and **ten reasoning modules (Modules A to J)** that apply logical rules to those facts. We also built a 14-option command-line menu (`main.pl`) and 65 automated test cases (`tests.pl`)."*

### Suggested Division of Modules Among the Three Team Members
*(Note: Every member should read the entire guide, because examiners can ask anyone about any file!)*

- **Syed Hanzala Ali (`24K0025` — Project Lead):** System Architecture (`main.pl`, `knowledge_base.pl`, `recommendations.pl`, `tests.pl`), Module E (Centralized Examination System), and Module F (Difficulty-Adjusted Standards-Based Grading).
- **Rafay Siddiqui (`24K0009`):** Module A (Attendance & Learning), Module B (Teacher Recruitment), Module C (Teacher Course Specialization), and Module D (Teacher & Assistant Responsibilities).
- **Azan Naveed (`24K5638`):** Module G (Modular & Linear Exam Scheduling & Deferred Eligibility), Module H (Student Teacher Selection & Confidential Feedback), Module I (Enrollment-Based Compensation), and Module J (Governance & Financial Transparency).

---

## 2. Beginner-Friendly SWI-Prolog & KRR Crash Course

If the examiner asks *"Explain the Prolog constructs in your code"*, use this table:

| Concept | Syntax in Our Code | Plain-English Meaning |
|---------|--------------------|-----------------------|
| **Fact** | `course(cn301, 'Computer Networks').` | Something we state is unconditionally true in our fictional dataset. Ends with a full stop `.` and has no `:-`. |
| **Rule** | `Head :- Goal1, Goal2.` | "`Head` is true **IF** `Goal1` **AND** `Goal2` are both true." The symbol `:-` is read as **"IF"**. |
| **Predicate & Arity** | `section/6` | The name of a fact/rule (`section`) followed by `/` and how many arguments it takes (`6`). `section/6` and `section/2` would be two completely different predicates. |
| **Atom (Constant)** | `cn301`, `fall`, `'2025-26'` | Starts with a **lowercase** letter (or is enclosed in single quotes `'...'`). Represents a specific object or value. |
| **Variable** | `Student`, `Course`, `Mark` | Starts with an **UPPERCASE** letter (or `_`). Represents an unknown placeholder that Prolog fills in by matching facts. |
| **Anonymous Variable** | `_` or `_Route` | Means *"I don't care what value is in this position."* Each `_` is independent. |
| **Conjunction (AND)** | `,` (comma) | Both goals must succeed: `module_choice(S, C, M, modular), exam_missed(S, C, M)`. |
| **Disjunction (OR)** | `;` (semicolon) or multiple clauses | Either branch can succeed. Writing 3 separate clauses for `scheduled_exam/6` means an exam is scheduled if it is modular **OR** linear **OR** deferred. |
| **If-Then-Else** | `( Cond -> Then ; Else )` | **If** `Cond` succeeds, run `Then`; **else** run `Else`. Used in `candidate_decision/2` and `selection_decision/6`. |
| **Negation as Failure** | `\+ Goal` | Succeeds if `Goal` **cannot be proven** from the current knowledge base. Example: `\+ academic_issue(Uni, _, _)`. |
| **Arithmetic Evaluation** | `Seats is Capacity - Count` | In Prolog, `4 - 4` is just a tree expression until you use `is`, which calculates the number `0`. |
| **Arithmetic Comparison** | `>=`, `=<`, `>`, `<`, `=:=`, `=\=` | Compare numeric values (`=:=` means numerically equal; `=\=` means numerically not equal). |
| **Term Inequality** | `Actual \= Expected` | Succeeds if two terms do **not** unify (are different). |
| **List (`[Head \| Tail]`)** | `[First, Second \| Rest]` | Splits a list into its first element(s) and the remaining list `Rest`. Used for recursion in `grading.pl` and `utilities.pl`. |
| **`findall/3`** | `findall(X, Goal, List)` | Finds **all** values of `X` that make `Goal` true and puts them into `List`. Returns `[]` if none exist. |
| **`sort/2`** | `sort(List, UniqueSorted)` | Sorts `List` **and removes duplicate elements**. |
| **`aggregate_all/3`** | `aggregate_all(count, Goal, N)` | Counts how many times `Goal` succeeds and stores the count in `N`. |
| **`forall/2`** | `forall(Condition, Action)` | For every solution of `Condition`, checks or runs `Action`. |
| **`assertz/1` & `retract/1`** | `assertz(enrolled(s07, cn301_c))` | Adds (`assertz`) or removes (`retract`) a dynamic fact from memory at runtime. |

---

## 3. File-by-File & Predicate-by-Predicate Guide

### 3.1 `knowledge_base.pl` — The Fact Database
- **What it does:** Declares 49 predicates as `:- dynamic` and stores all fictional demonstration facts for `conventional_uni` and `reform_uni`.
- **Why `:- dynamic`?** It lets us add facts at runtime (`assertz/1`), and if a predicate has zero facts for a query, Prolog fails cleanly instead of throwing an error.

### 3.2 `academic_policy.pl` — Module A (Attendance & Learning)
- `academic_issue(Uni, IssueId, Text)`: Has 7 clauses (Rules A1–A7) that detect compulsory lecture attendance (`SessionType \= practical`), minimum attendance percentages, attendance mark deductions, attendance exam bars, restricted learning resources, prohibited assessments (`homework_assignment`, `random_quiz`, `unannounced_test`, `take_home_assessment`), and missing scheduled supervised exams.
- `academic_policy_unknown(Uni, Key)`: Detects when a required policy fact is missing from the KB.
- `academic_policy_compliant(Uni)`: Succeeds only when `\+ academic_issue(Uni, _, _)` **and** `\+ academic_policy_unknown(Uni, _)`.

### 3.3 `teacher_recruitment.pl` — Module B (Teacher Recruitment)
- `criterion_required(Process, Criterion)`: Requires `academic_qualification`, `subject_knowledge_test`, `demonstration_lecture`, and `teaching_communication` for every process, plus `practical_experience` when `process_requires_experience(Process, MinYears)` is present.
- `recruitment_issue(Process, IssueId, Text)`: Flags `qualifications_only` (when qualifications are checked but neither `demonstration_lecture` nor `teaching_communication` is checked) and `missing_criterion(Criterion)`.
- `candidate_check(Candidate, Criterion, Result)`: Evaluates one criterion for a candidate (`passed`, `failed`, or `unknown`).
- `candidate_decision(Candidate, Decision)`: Returns `not_recommended` if any criterion failed, `incomplete_information` if any criterion is unknown, or `recommended` if all passed.

### 3.4 `teacher_specialization.pl` — Module C (Teacher Course Specialization)
- `assigned_courses(Teacher, Courses)`: Returns the sorted list of distinct courses assigned to `Teacher`.
- `teaching_records(Teacher, Records)`: Uses `findall/3` and `sort/2` to turn `section/6` facts into distinct `record(Course, Term, Year)` entries so multiple sections of the same course count as one course.
- `specialization_issue(Teacher, IssueId, Text)`: Flags `wrong_number_of_assigned_courses(N)` (`N =\= 2`), `missing_term_assignment(Term)`, `several_courses_in_term(Term)`, `unrelated_course(Course, Term, Year)`, and `wrong_term(Course, Term, Year)`.

### 3.5 `responsibilities.pl` — Module D (Teachers vs. Assistants)
- `approved_role(Task, Role)`: Maps each task to its approved owner (`teacher`, `central_exam_team`, `exam_assistants`, `central_marking_assistants`, `academic_oversight`).
- `responsibility_issue(Uni, IssueId, Text)`: Flags `unassigned_task(Task)`, `wrong_role(Task, Actual, Expected)`, and `task_not_in_policy(Task)`.

### 3.6 `examination_system.pl` — Module E (Centralized Examinations & Marking)
- `session_section(Session, Section)`: Connects an `exam_session(Session, Course, Term, Year)` to all `section(Section, Course, _, Term, Year, _)` in that same course, term, and academic year.
- `papers_used(Session, Papers)` & `schemes_used(Session, Schemes)`: Collect distinct papers and marking schemes used across sections of `Session`.
- `exam_arrangement_issue(Session, IssueId, Text)`: Flags `multiple_papers(Papers)` (when `length(Papers, N), N > 1`), `section_without_paper(Section)`, `paper_not_central(Paper, Preparer)`, and `paper_preparer_unknown(Paper)`.
- `marking_issue(Session, IssueId, Text)`: Flags `multiple_schemes(Schemes)`, `section_without_scheme(Section)`, `scheme_not_central(Scheme, Preparer)`, `scheme_incomplete(Scheme)` (no `scheme_question/5` facts), `local_marking(Section, Marker)`, `marker_unknown(Section)`, and `no_moderation_record`.

### 3.7 `grading.pl` — Module F (Difficulty-Adjusted Standards-Based Grading)
- `thresholds_valid(Session)`: Checks that all 5 grades `[a, b, c, d, f]` have thresholds and that they are strictly decreasing (`A > B > C > D > F`) via recursive predicate `strictly_decreasing/1`.
- `mark_to_grade(Session, Mark, Grade)`: Walks `[a, b, c, d, f]` via `first_grade_met/4` and returns the first grade whose approved minimum is `<= Mark`.
- `student_grade(Student, Session, Grade)`: Looks up `exam_mark(Student, Session, Mark)` and calls `mark_to_grade/3`.

### 3.8 `exam_scheduling.pl` — Module G (Modular & Linear Exam Scheduling)
- `module_plan(ModuleNo, FirstTeachWeek, LastTeachWeek, ExamWeek)`: Encodes the 4 modules (Weeks 1–4 + 5, 6–9 + 10, 11–14 + 15, 16–19 + 20 = 16 teaching + 4 exam = 20 weeks).
- `deferred_eligible(Student, Course, Module)`: True when `module_choice(Student, Course, Module, modular)` **and** `exam_missed(Student, Course, Module)`.
- `scheduled_exam(Student, Course, Module, Week, Day, Route)`: Has 3 clauses (`modular` in Weeks 5/10/15/20; `linear` in Weeks 21–24; `deferred` in Weeks 21–24).
- `module_status(Student, Course, Module, Status)`: Distinguishes `attempted_met_standard(Mark)`, `attempted_below_standard(Mark)`, `missed_deferred_exam_eligible`, and `awaiting_exam`.
- `exam_clash(Student, Exam1, Exam2, Week, Day)`: Detects two exams for the same student in the same week and day.

### 3.9 `student_selection.pl` — Module H (Student Teacher Selection)
- `enrolled_count(Section, Count)` & `seats_remaining(Section, Seats)`: Compute current enrollment and remaining capacity (`Seats is Capacity - Count`).
- `selection_decision(Student, Course, Teacher, Status, Section, Reason)`: Evaluates a student's teacher preference (`approved`, `waitlisted`, or `rejected`).
- `transfer_decision(Student, From, To, Status, Reason)`: Evaluates a teacher-change request against the administrative procedure.
- `teacher_feedback_summary(Teacher, Count, Average)`: Computes average rating from anonymous `confidential_feedback(Section, Rating, Comment)` facts.

### 3.10 `compensation.pl` — Module I (Enrollment-Based Compensation)
- `payment_for_enrollment(Students, Payment)`: Computes `Payment is Students * Rate` using configurable `rate_per_student(Rate)`.
- `section_payment(Section, Teacher, Students, Payment)` & `teacher_term_payment(Teacher, Term, Year, Total)`: Compute per-section and total term compensation for a teacher.
- `adjusted_section_payment(Section, Adjusted)`: Keeps optional course weighting separate (disabled by default).

### 3.11 `governance_finance.pl` — Module J (Governance & Financial Transparency)
- `governance_issue(Uni, IssueId, Text)`: Flags `unassigned_duty(Duty)` (0 owners) and `unclear_responsibility(Duty, Owners)` (> 1 owner).
- `finance_status(Uni, Year, Category, Status)`: Returns `compared(Approved, Actual, Percent)`, `review_required(Approved, Actual, Percent)` (when `abs(Percent) > 10`), or `unknown_*` when figures are missing.
- `finance_issue(Uni, IssueId, Text)`: Reports missing budgets, missing figures, variances > 10%, and undocumented expenditures while explicitly stating that missing data is **not** evidence of misconduct.

### 3.12 `recommendations.pl`, `main.pl`, `utilities.pl`, `tests.pl`
- `recommendation(IssuePattern, AdviceText)`: Pattern-matches any `IssueId` to its reform recommendation.
- `reform_issue(Area, Subject, IssueId, Text)`: Uses `call/4` to query all 10 diagnostic predicates across the system.
- `start/0` & `run_choice/1` (`main.pl`): Run the 14-option CLI menu.
- `run_all_tests/0` (`tests.pl`): Runs all 65 automated test cases.

---

## 4. 45 Likely Viva Questions and Model Answers

### Part A — KRR & SWI-Prolog Concepts (Q1–Q12)

**Q1: Why is SWI-Prolog suitable for building a university policy reform expert system?**  
**A1:** Because university policies are naturally expressed as declarative logical rules (*"An exam arrangement is inconsistent IF two sections of the same course in the same session use different papers"*). Prolog's built-in backward-chaining inference engine, unification, and backtracking automatically test these rules against any dataset without requiring procedural loops.

**Q2: What is the difference between a Fact and a Rule in your project?**  
**A2:** A **fact** (in `knowledge_base.pl`) states unconditional data, like `enrolled(s01, cn301_a).`. A **rule** (in the module files) states conditional knowledge using `:-` ("IF"), like `section_has_space(Section) :- seats_remaining(Section, Seats), Seats > 0.`.

**Q3: What is Predicate Arity? Give an example from your code.**  
**A3:** Arity is the number of arguments a predicate takes, written as `Name/Arity`. For example, `section/6` takes 6 arguments: `(SectionId, CourseId, TeacherId, Term, AcademicYear, Capacity)`.

**Q4: How does Unification work in your recommendation engine?**  
**A4:** In `recommendations.pl`, we wrote `recommendation(compulsory_attendance(_), 'Remove compulsory attendance...')`. When `academic_issue/3` outputs `compulsory_attendance(lecture)` or `compulsory_attendance(tutorial)`, Prolog unifies that compound term with `compulsory_attendance(_)` by matching the anonymous variable `_` to `lecture` or `tutorial`.

**Q5: How does Backtracking work when Menu Option 1 runs?**  
**A5:** `academic_issue/3` has 7 clauses (Rules A1–A7). When `findall(Text, academic_issue(conventional_uni, _, Text), Issues)` runs, Prolog tries clause A1, records the issue, then **backtracks** to try A2, A3, A4, A5, A6 (which itself backtracks across all 4 prohibited assessments), and A7 until every solution is collected.

**Q6: What is Negation as Failure (`\+`), and where do you use it?**  
**A6:** `\+ Goal` succeeds if `Goal` cannot be proven from the current facts. For example, in `academic_policy.pl`, `\+ uses_assessment(Uni, scheduled_supervised_exam)` detects that a university does not use scheduled supervised examinations.

**Q7: What is the Closed-World Assumption (CWA), and why can it be dangerous if misused?**  
**A7:** Under CWA, anything not currently proven true is treated as false. If we simply wrote `compliant(Uni) :- \+ issue(Uni)`, then an empty university with zero facts in the database would be declared "compliant"! We prevented that by also checking `\+ unknown(Uni)`, so missing facts are reported as `UNKNOWN` rather than compliant.

**Q8: Where did you use explicit List Recursion in your code?**  
**A8:** In three places:
1. `strictly_decreasing([First, Second | Rest])` in `grading.pl` to check `A > B > C > D > F`.
2. `first_grade_met([Candidate | Rest], Session, Mark, Grade)` in `grading.pl` to walk down the grade thresholds.
3. `print_all_tagged([Item | Rest], Tag)` in `utilities.pl` to print every item in a list.

**Q9: Why can't we write `Seats = Capacity - Count` in Prolog? Why must we write `Seats is Capacity - Count`?**  
**A9:** In Prolog, `=` is unification, so `Seats = 4 - 4` binds `Seats` to the unevaluated structure `4 - 4`. The `is` operator forces Prolog to evaluate the arithmetic expression on the right-hand side and bind `Seats` to `0`.

**Q10: Why did you use `sort/2` after `findall/3` in `papers_used/2` and `teaching_records/2`?**  
**A10:** Because `findall/3` keeps duplicates (e.g., if 3 sections all use `cn_paper_2025`, `findall/3` produces `[cn_paper_2025, cn_paper_2025, cn_paper_2025]`). Calling `sort/2` sorts the list and removes duplicates, giving `[cn_paper_2025]` of length 1.

**Q11: What does `:- dynamic` do at the top of `knowledge_base.pl`?**  
**A11:** It tells SWI-Prolog that those predicates can be modified at runtime using `assertz/1` and `retract/1` (used in `apply_transfer/3` and in `tests.pl`), and prevents an existence error if a predicate currently has no facts.

**Q12: How does `reform_issue/4` in `recommendations.pl` query all 10 modules with a single rule?**  
**A12:** It looks up `reform_area(Area, IssuePredicate, _)` and uses the meta-predicate `call(IssuePredicate, Subject, IssueId, Text)` to dynamically invoke `academic_issue/3`, `recruitment_issue/3`, `specialization_issue/3`, and so on.

---

### Part B — Module A: Attendance and Learning (Q13–Q16)

**Q13: What is the reform policy on lecture attendance?**  
**A13:** Eliminate compulsory lecture attendance completely. There are no minimum attendance percentages, and missing lectures never reduces marks or bars a student from sitting examinations. Students pay fees and may learn from lectures, textbooks, YouTube, ChatGPT, or any other resource.

**Q14: What if a university renames lectures to "tutorials" or "seminars" and makes those compulsory? Does your code catch it?**  
**A14:** Yes! Rule A1 checks `attendance_rule(Uni, SessionType, compulsory), SessionType \= practical`. Any compulsory non-practical session—whatever it is named—is caught and tested in `tests.pl`.

**Q15: How are practical/laboratory components handled?**  
**A15:** They are stored in a separate predicate, `practical_component(Uni, Course, Description)`, and are explicitly excluded from lecture attendance rules so they can never be used as a backdoor to reintroduce compulsory lecture attendance.

**Q16: Which assessment methods are removed by Module A, and what replaces them?**  
**A16:** Homework assignments, random quizzes, unannounced tests, and routine take-home assessments are completely removed (`prohibited_assessment/1`) and replaced with scheduled, supervised physical examinations (`scheduled_supervised_exam`).

---

### Part C — Module B: Teacher Recruitment (Q17–Q19)

**Q17: What five criteria does Module B check when hiring teachers?**  
**A17:** (1) Relevant academic qualifications, (2) subject knowledge assessment, (3) demonstration lecture, (4) teaching ability and communication, and (5) relevant practical/professional experience where appropriate.

**Q18: How does the system detect a conventional hiring process that ignores teaching ability?**  
**A18:** Rule B1 (`qualifications_only`) checks if `recruitment_criterion(Process, academic_qualification)` holds while `\+ (teaching_ability_criterion(C), recruitment_criterion(Process, C))` holds.

**Q19: In your sample data, why is Dr. Kamran (`c_kamran`) not recommended even though he has a PhD and scored 9/10 on the subject knowledge test?**  
**A19:** Because he scored 4/10 on the demonstration lecture and 5/10 on teaching communication (both below the configurable pass mark of 6/10), and has only 1 year of practical experience (below the required 2 years). Meanwhile, Ms. Sana (`c_sana`) passes all five criteria and is recommended.

---

### Part D — Module C: Teacher Course Specialization (Q20–Q22)

**Q20: What is the two-course teacher specialization policy?**  
**A20:** Each teacher is assigned exactly two courses per academic year—one taught in Fall and one taught in Spring—and continues teaching those same two courses in subsequent years (with optional Summer repeat batches) to build deep specialization.

**Q21: If Mr. Ahmed teaches three sections of `cn301` in Fall, does the system think he is teaching three different courses?**  
**A21:** No. `teaching_records/2` ignores the section ID (`_`) and sorts `record(Course, Term, Year)` with `sort/2`, so three sections of `cn301` collapse into a single course record.

**Q22: Which violations are detected for Mr. Usman (`t_usman`) in Module C?**  
**A22:** Two violations: (1) he is assigned `os302` (Fall) and `ai401` (Spring), yet he is teaching `db201` in Fall 2025-26 (`unrelated_course`), and (2) he is teaching `os302` in Spring 2025-26 even though `os302` is his Fall course (`wrong_term`).

---

### Part E — Module D: Teacher Responsibilities and Assistants (Q23–Q25)

**Q23: According to Module D, what should teachers be responsible for, and who handles exam work?**  
**A23:** Teachers focus on delivering lectures and providing academic guidance. The central examination team prepares papers, exam assistants handle invigilation and exam logistics, central marking assistants mark scripts, and academic oversight handles moderation, quality assurance, and appeals.

**Q24: What issues does Module D find at `conventional_uni`?**  
**A24:** At `conventional_uni`, teachers are assigned `prepare_exam_papers`, `invigilation`, and `mark_answer_scripts` (`wrong_role`), while `moderation`, `quality_assurance`, and `academic_appeals` have no assigned owner (`unassigned_task`).

**Q25: Why is it harmful for each section teacher to write and mark their own exams?**  
**A25:** Because different sections of the same course get unequal difficulty and inconsistent grading standards, and teachers are overburdened with administrative work instead of teaching.

---

### Part F — Module E: Centralized Examination System (Q26–Q29)

**Q26: Explain the Computer Networks example in Module E.**  
**A26:** In session `cn301_fall2025`, Computer Networks is taught across multiple sections (`cn301_a`, `cn301_b`, `cn301_c`) by three different teachers (`t_ahmed`, `t_fatima`, `t_bilal`). All three sections receive the exact same paper (`cn_paper_2025`) prepared by `central_exam_team`, are graded with the exact same marking scheme (`cn_scheme_2025`, totalling 100 marks with partial-credit rules) by `central_marking_assistants`, and have a recorded moderation check.

**Q27: How does Module E detect an inconsistent examination arrangement?**  
**A27:** In `db201_fall2025`, sections `db201_a` and `db201_b` use two different papers (`db_paper_ayesha` and `db_paper_usman`). `papers_used(db201_fall2025, Papers)` returns a list of length 2 (`N > 1`), triggering `exam_arrangement_issue(db201_fall2025, multiple_papers(...), Text)`.

**Q28: What elements must a valid centralized marking scheme contain?**  
**A28:** As represented in `scheme_question(SchemeId, QuestionNo, Marks, ExpectedAnswer, PartialCredit)`, it must specify the marks allocated to each question, the expected answer, and partial-credit criteria.

**Q29: How does your code make sure different examination sessions and academic years are treated separately?**  
**A29:** `session_section(Session, Section)` unifies `Course`, `Term`, and `AcademicYear` between `exam_session/4` and `section/6`, and every rule in `examination_system.pl` takes `Session` as its first argument.

---

### Part G — Module F: Difficulty-Adjusted, Standards-Based Grading (Q30–Q33)

**Q30: How does difficulty-adjusted standards-based grading differ from relative (bell-curve) grading?**  
**A30:** In relative/bell-curve grading, students are ranked against classmates and only a fixed percentage can get an A. In our standards-based system, the examination team reviews the difficulty of each session's paper and approves minimum mark thresholds for `a, b, c, d, f`. Every student who meets the approved threshold receives that grade—even if 80% or 100% of the class earns an A.

**Q31: Does your Prolog system automatically compute exam difficulty from class averages?**  
**A31:** **No.** High or low class averages can reflect cohort preparation rather than paper difficulty. The examination team's difficulty review (`difficulty_review/3`) and approved thresholds (`grade_threshold/3`) are stored as configurable input facts, and Prolog applies those approved thresholds equally to all students in the session.

**Q32: Walk through the 2020 vs. 2021 Computer Networks grading example in your Knowledge Base.**  
**A32:** In `cn301_fall2020` (hypothetical relatively easy paper), the approved A threshold is `85` and B is `70`. Four out of five students score 85 or above (92, 88, 86, 85), and all four get an `a`. In `cn301_fall2021` (hypothetical relatively difficult paper), the approved A threshold is `75` and B is `60`. Thus, a raw mark of `78` gets a `b` in 2020 but an `a` in 2021.

**Q33: How does Test R08 in `tests.pl` mathematically prove there is no bell curve?**  
**A33:** It records every student's grade in `cn301_fall2020`, temporarily asserts four new students with marks 99, 98, 97, and 96, re-queries the original students' grades, and verifies that not a single original student's grade changed.

---

### Part H — Module G: Modular and Linear Examination System (Q34–Q38)

**Q34: Explain the 20-week + 4-week academic calendar structure.**  
**A34:** The course is divided into 4 modules. Each module has **4 teaching weeks + 1 examination week**:
- Module 1: Weeks 1–4 teaching, Week 5 exam
- Module 2: Weeks 6–9 teaching, Week 10 exam
- Module 3: Weeks 11–14 teaching, Week 15 exam
- Module 4: Weeks 16–19 teaching, Week 20 exam  
That totals **16 teaching weeks + 4 exam weeks = 20 weeks**. **Weeks 21–24** are reserved for linear examinations and deferred modular examinations.

**Q35: Must a student choose purely modular or purely linear for an entire course?**  
**A35:** No! A student chooses `modular` or `linear` for each module independently (`module_choice(Student, Course, ModuleNo, Route)`). For example, student `s01` in `cn301` chooses Module 1 `modular` (Week 5), Module 2 `linear` (Week 22), Module 3 `modular` (Week 15), and Module 4 `linear` (Week 24).

**Q36: What happens if a student chooses a modular exam and misses it?**  
**A36:** The student does **not** automatically fail. Rule `deferred_eligible(Student, Course, Module)` checks `module_choice(Student, Course, Module, modular), exam_missed(Student, Course, Module)`, making the student eligible for a deferred examination in Weeks 21–24.

**Q37: How does the system avoid confusing a missed exam with an attempted exam that the student failed?**  
**A37:** They are represented by two separate predicates: `exam_missed(Student, Course, Module)` (no mark exists because the student was absent) versus `exam_attempted(Student, Course, Module, Mark)` (the student sat the paper and earned `Mark`). For student `s02` in `cn301`, Module 2 was missed (`missed_deferred_exam_eligible`), whereas Module 3 was attempted with 38 marks (`attempted_below_standard(38)`, not eligible for a deferred modular exam).

**Q38: How does the system detect examination scheduling conflicts?**  
**A38:** `exam_clash/5` checks whether the same student has two different `scheduled_exam/6` sittings in the exact same `Week` and `Day` (for instance, `s01` has `db201` and `os302` modular exams both on Week 5 Tuesday, and `s10` has a deferred `db201` exam and a linear `os302` exam both on Week 22 Tuesday).

---

### Part I — Module H: Student Teacher Selection (Q39–Q41)

**Q39: How does the system handle a student choosing a teacher whose section is already full?**  
**A39:** `seats_remaining(Section, Seats)` calculates `Seats is Capacity - Count`. When student `s10` requests `t_ahmed` for `cn301`, section `cn301_a` has capacity 4 and 4 enrolled students (`0` seats remaining), so `selection_decision/6` returns `Status = waitlisted` and lists alternative teachers (`t_fatima` and `t_bilal`) who still have free seats.

**Q40: What conditions are checked before approving a teacher transfer request?**  
**A40:** `transfer_decision/5` checks four administrative conditions: (1) the student is currently enrolled in the source section, (2) the source and destination sections belong to the same course and term, (3) the transfer window is `open`, and (4) the destination section has available capacity (`Seats > 0`).

**Q41: How do you guarantee that student teaching feedback is confidential?**  
**A41:** The fact `confidential_feedback(SectionId, RatingOutOf5, Comment)` has no student ID argument. Because the student's identity is never stored in the knowledge base, it is impossible for any query to reveal who submitted a rating.

---

### Part J — Module I: Enrollment-Based Teacher Compensation (Q42–Q43)

**Q42: What is the formula for teacher compensation, and how is it configured?**  
**A42:** `Teacher Payment = Number of Enrolled Students * Configured Rate Per Student`. The rate is stored in the configurable fact `rate_per_student(1000)` (fictional demo figure). With Rs. 1,000 per student, 20 students = Rs. 20,000, 40 students = Rs. 40,000, and 60 students = Rs. 60,000.

**Q43: How did you handle optional course weighting without replacing the core enrollment-based formula?**  
**A43:** We added `optional_feature(course_weighting, disabled)` in `knowledge_base.pl` and kept the weighted calculation in a separate predicate `adjusted_section_payment/2`. By default, it is disabled so `section_payment/4` and `teacher_term_payment/4` always use the pure enrollment formula.

---

### Part K — Module J: Governance and Financial Transparency (Q44–Q45)

**Q44: How does Module J check university governance responsibilities?**  
**A44:** `duty_owners(Uni, Duty, Owners)` collects all offices assigned to each of the 7 governance duties. If `Owners` is empty `[]`, it reports `unassigned_duty(Duty)` (e.g., `curriculum_coordination`, `laboratory_maintenance`, and `student_complaints` at `conventional_uni`). If `Owners` has more than one office (`N > 1`), it reports `unclear_responsibility(Duty, Owners)` (e.g., `examination_administration` shared by `faculty` and `registrar_office` at `conventional_uni`).

**Q45: In `reform_uni`, the actual expenditure for `research` is missing and `administration` spending is 25% above the approved allocation. Does your expert system conclude financial corruption?**  
**A45:** **No, never.** Missing records are reported as `unknown_actual_expenditure` (*"information gap, NOT evidence of misconduct"*), and the +25% administration variance is reported as `review_required(120, 150, 25)` (*"explanation requested (not a finding of misconduct)"*). Sound KRR never jumps to unproven accusations from missing data or budget variances.

---

## 5. Practical Viva Demonstration Script (Step-by-Step Live Walkthrough)

Use this 5-step script on your laptop during the viva to impress the examiners.

### Step 1 — Run the Automated Test Suite (30 seconds)
Open a terminal in `University_Reform_System/` and run:
```bash
swipl -g run_all_tests -t halt tests.pl
```
Point out to the examiner: *"All 65 automated test cases—covering all 16 mandatory requirements R01 to R16 and edge cases—pass with 0 failures."*

### Step 2 — Launch the Interactive Menu and Show Key Reports (3 minutes)
```bash
swipl main.pl
```
At the `?-` prompt, type:
```prolog
?- start.
```
Now type these menu numbers (just the number + Enter):
- Type `1` (**Module A**): Show how `conventional_uni` is diagnosed for compulsory attendance, 75% minimum attendance, homework, random quizzes, and unannounced tests, while `reform_uni` is compliant.
- Type `5` and `6` (**Module E**): Show how Computer Networks (`cn301_fall2025`) uses one common paper (`cn_paper_2025`) and one common 100-mark scheme (`cn_scheme_2025`) across all 3 sections, whereas Database Systems (`db201_fall2025`) is caught using two different teacher-written papers and local marking.
- Type `7` (**Module F**): Show how `cn301_fall2020` (A >= 85) gives 4 out of 5 students an A (no bell curve!) and how a mark of 78 gets a B in easy 2020 but an A in difficult 2021 (A >= 75).
- Type `8`, `9`, and `10` (**Module G**): Show student `s01` mixing `modular` and `linear` exams, student `s02` getting a deferred exam in Week 22 for missed Module 2 (while attempted Module 3 with mark 38 is kept distinct), and the timetable clash detector catching `s01` (Week 5 Tuesday) and `s10` (Week 22 Tuesday).
- Type `11` (**Module I**) and `14` (**Comprehensive Report**): Show enrollment-based teacher compensation and the full reform summary.
- Type `0` to exit the menu back to the `?-` prompt.

### Step 3 — Run Live Prolog Queries at the `?-` Prompt (2 minutes)
Show the examiner that you understand how Prolog queries work under the hood:

```prolog
% 1. Show backtracking over specialization issues for Mr. Usman (press ; for next solution):
?- specialization_issue(t_usman, IssueId, Explanation).

% 2. Show standards-based grading for mark 78 across two sessions:
?- mark_to_grade(cn301_fall2020, 78, G2020),
   mark_to_grade(cn301_fall2021, 78, G2021).

% 3. Show missed exam vs. attempted-below-standard exam for Hira Khan (s02):
?- module_status(s02, cn301, 2, StatusMissed),
   module_status(s02, cn301, 3, StatusAttempted).
```

### Step 4 — Live Extension of the Knowledge Base in Front of the Examiner (1 minute)
Say: *"Because our rules are completely separated from our facts, we can add a new student enrollment right now without touching any rule, and watch capacity and teacher compensation update automatically:"*

```prolog
% Check Mr. Bilal's section (cn301_c) before adding a student:
?- seats_remaining(cn301_c, SeatsBefore),
   teacher_term_payment(t_bilal, fall, '2025-26', PayBefore).
% Output: SeatsBefore = 3, PayBefore = 2000.

% Dynamically assert a new student enrollment into cn301_c:
?- assertz(student(s12, 'Viva Demo Student')),
   assertz(enrolled(s12, cn301_c)).

% Re-run the exact same query:
?- seats_remaining(cn301_c, SeatsAfter),
   teacher_term_payment(t_bilal, fall, '2025-26', PayAfter).
% Output: SeatsAfter = 2, PayAfter = 3000.
```
*(Clean up if desired with `retract(enrolled(s12, cn301_c)), retract(student(s12, 'Viva Demo Student')).`)*
