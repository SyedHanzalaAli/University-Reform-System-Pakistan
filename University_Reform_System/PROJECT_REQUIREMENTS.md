# Formal Requirements Specification — University Education Reform Expert System

**Project Title:** University Education Reform Expert System for Pakistan  
**Project Team:** Syed Hanzala Ali (`24K0025`, Project Lead), Rafay Siddiqui (`24K0009`), Azan Naveed (`24K5638`)  
**Technology:** SWI-Prolog

---

## 1. System Objectives

The expert system must perform two primary functions through rule-based Knowledge Representation and Reasoning (KRR):

1. **Diagnose Weaknesses in Conventional University Policies:** Identify violations of the proposed reform policies across attendance, assessment, teacher recruitment, teacher course specialization, teaching/examination duties, centralized exams, grading, scheduling, governance, and financial transparency.
2. **Demonstrate the Alternative University Operating Model:** Show how a university operating under the proposed reform model functions in practice (standards-based grading, modular/linear exam mixing, deferred modular exam eligibility, student teacher selection with capacity checks, enrollment-based teacher compensation, and actionable reform recommendations).

---

## 2. Formal Module Specifications (Modules A–J)

### Module A — Attendance and Learning (`academic_policy.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **A.1** | Eliminate compulsory attendance requirements for all lectures. Do not allow compulsory lecture attendance to be reintroduced under another name (e.g., tutorial/seminar). | `academic_issue(Uni, compulsory_attendance(SessionType), Text)` where `SessionType \= practical` |
| **A.2** | Abolish minimum attendance percentages (e.g., 75%). | `academic_issue(Uni, minimum_attendance_percentage, Text)` |
| **A.3** | Missing lectures must never automatically reduce marks or make students ineligible for examinations. | `academic_issue(Uni, attendance_reduces_marks, Text)` & `academic_issue(Uni, attendance_blocks_exams, Text)` |
| **A.4** | Students must be free to learn through university lectures, textbooks, YouTube, ChatGPT, or other learning resources. | `academic_issue(Uni, restricted_learning_resources, Text)` |
| **A.5** | Completely remove homework assignments, random quizzes, unannounced tests, and routine take-home assessments. | `prohibited_assessment/1` & `academic_issue(Uni, prohibited_assessment(Type), Text)` |
| **A.6** | Replace removed assessments with scheduled, supervised physical examinations. | `academic_issue(Uni, no_scheduled_supervised_exams, Text)` |
| **A.7** | Practical/lab components, if relevant, must be represented separately (`practical_component/3`) and never used to reintroduce compulsory lecture attendance. | `practical_component(Uni, Course, Description)` |

### Module B — Teacher Recruitment (`teacher_recruitment.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **B.1** | Hiring must evaluate both subject expertise and actual teaching ability: (1) relevant academic qualifications, (2) subject knowledge test, (3) demonstration lecture, (4) teaching ability & communication, and (5) relevant practical experience where appropriate. | `required_hiring_criterion/1`, `criterion_required/2` |
| **B.2** | Diagnose a recruitment process that checks qualifications but ignores teaching ability (`demonstration_lecture` and `teaching_communication`). | `recruitment_issue(Process, qualifications_only, Text)` |
| **B.3** | Identify any missing required criterion in a recruitment process and recommend improvements. | `recruitment_issue(Process, missing_criterion(C), Text)` |
| **B.4** | Evaluate individual candidates across all required criteria and classify them as `recommended`, `not_recommended`, or `incomplete_information`. | `candidate_check/3`, `candidate_decision/2` |

### Module C — Teacher Course Specialization (`teacher_specialization.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **C.1** | Each teacher is assigned exactly TWO courses per academic year: one in Fall and one in Spring. | `assigned_course(Teacher, Course, Term)`, Rules C1–C3 |
| **C.2** | The teacher continues teaching the same two assigned courses in subsequent academic years; Summer sessions may repeat batches of those same assigned courses. | Rules C4–C5 allow `summer` and any `AcademicYear` for assigned courses |
| **C.3** | Identify teachers assigned unrelated courses or teaching an assigned course in the wrong regular term. | `specialization_issue(Teacher, unrelated_course(C,T,Y), Text)` & `wrong_term(C,T,Y)` |
| **C.4** | Teaching multiple sections or batches of an assigned course must count as ONE course, not a violation. | `teaching_records/2` collapses multiple sections via `sort/2` |

### Module D — Teacher Responsibilities and Assistants (`responsibilities.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **D.1** | Teachers deliver lectures and provide academic guidance only. | `approved_role(deliver_lectures, teacher)`, `approved_role(academic_guidance, teacher)` |
| **D.2** | Central examination team prepares exam papers; examination assistants handle invigilation and exam logistics; central marking assistants mark answer scripts; academic oversight handles moderation, quality assurance, and academic appeals. | `approved_role/2`, `responsibility_issue/3` |
| **D.3** | Flag any duty assigned to the wrong role (e.g., teachers preparing or marking their own section exams) or left unassigned. | `responsibility_issue(Uni, wrong_role(Task, Actual, Expected), Text)` & `unassigned_task(Task)` |

### Module E — Centralized Examination System (`examination_system.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **E.1** | For a given course and examination session, the central examination team prepares ONE common examination paper for all sections. | `papers_used/2`, `exam_arrangement_issue/3`, `centralized_exam_verified/1` |
| **E.2** | The central team prepares ONE common marking scheme specifying question marks, expected answers, and partial-credit criteria. | `schemes_used/2`, `scheme_question/5`, `marking_issue/3` |
| **E.3** | Answer scripts from all sections are marked centrally by `central_marking_assistants` and moderated by `academic_oversight`. | `scripts_marked_by/3`, `moderation_record/2`, `central_marking_verified/1` |
| **E.4** | Different examination sessions and academic years must be treated separately. | `session_section/2` joins on `(Course, Term, AcademicYear)` |

### Module F — Difficulty-Adjusted, Standards-Based Grading (`grading.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **F.1** | Grading is standards-based, NOT relative grading and NOT a bell curve. | `mark_to_grade(Session, Mark, Grade)` depends only on `Session` and `Mark` |
| **F.2** | The examination team reviews exam difficulty and approves configurable grade thresholds (`grade_threshold(Session, Grade, MinMark)`) separately for each session. Prolog treats the approved thresholds as input facts and does not guess difficulty from class averages. | `difficulty_review/3`, `grade_threshold/3`, `thresholds_valid/1` |
| **F.3** | Identical grade boundaries apply to every student in the same examination session. There is no cap or quota on A, B, or C grades (if 80/100 or 100/100 meet the A threshold, all get an A). | `student_grade/3`, `grade_count/3` |

### Module G — Modular and Linear Examination System (`exam_scheduling.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **G.1** | Academic structure has 4 modules: Module 1 (Weeks 1–4 teaching, Week 5 exam), Module 2 (Weeks 6–9 teaching, Week 10 exam), Module 3 (Weeks 11–14 teaching, Week 15 exam), Module 4 (Weeks 16–19 teaching, Week 20 exam) = 16 teaching + 4 exam = 20 weeks. | `module_plan/4`, `teaching_weeks_total/1`, `exam_weeks_total/1`, `calendar_valid/0` |
| **G.2** | Weeks 21–24 are reserved for linear examinations and deferred modular examinations. | `extended_period(21, 24)`, `linear_exam_week/2`, `extended_period_capacity/2` |
| **G.3** | For each module independently (1..4), a student may choose `modular` or `linear` assessment (mixing allowed within the same course). | `module_choice(Student, Course, Module, Route)` |
| **G.4** | If a student selects `modular` assessment and misses the exam (`exam_missed/3`), they do NOT automatically fail; they become eligible for a deferred exam in Weeks 21–24 (`deferred_eligible/3`). | `deferred_eligible/3`, `scheduled_exam/6` (3rd clause) |
| **G.5** | A missed modular exam (`exam_missed/3`) must never be confused with an attempted exam (`exam_attempted/4`) where the student scored below the standard. | `module_status/4` produces `missed_deferred_exam_eligible` vs. `attempted_below_standard(Mark)` |
| **G.6** | Detect student timetable clashes (same week and day) and extended-period seating capacity overflows. | `exam_clash/5`, `extended_week_load/2`, `scheduling_issue/3` |

### Module H — Student Teacher Selection (`student_selection.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **H.1** | Students can view available teachers for a course in the current term along with section capacities and remaining seats. | `available_teacher/4`, `seats_remaining/2` |
| **H.2** | Students can request their preferred teacher (`selection_request/3`) or request a teacher transfer (`transfer_request/3`) subject to class capacity and an administrative procedure (`transfer_procedure_step/2`, `transfer_window/3`). | `selection_decision/6`, `transfer_decision/5`, `apply_transfer/3` |
| **H.3** | Students can provide confidential teaching feedback (stored without student IDs) aggregated by teacher. | `confidential_feedback/3`, `teacher_feedback_summary/3` |

### Module I — Enrollment-Based Teacher Compensation (`compensation.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **I.1** | `Teacher Payment = Number of Enrolled Students * Configured Rate Per Student`, using a configurable fictional demonstration rate (`rate_per_student(1000)`). | `payment_for_enrollment/2`, `section_payment/4`, `teacher_term_payment/4` |
| **I.2** | Optional course weighting (`course_weight/2`) must be clearly separated and disabled by default (`optional_feature(course_weighting, disabled)`) so it never replaces the core formula. | `adjusted_section_payment/2` |

### Module J — Financial Transparency and University Governance (`governance_finance.pl`)

| ID | Requirement Specification | Implementation Predicate |
|----|---------------------------|--------------------------|
| **J.1** | Check governance ownership across 7 duties (teaching, curriculum coordination, examination administration, student records, financial management, laboratory maintenance, student complaints) and identify unassigned or shared/unclear duties. | `governance_duty/1`, `duty_owners/3`, `governance_issue/3` |
| **J.2** | Check financial records across 7 budget categories (faculty salaries, administration, laboratories, research, libraries, student facilities, infrastructure): verify availability of approved allocations, actual expenditures, variance comparisons, and documentation. | `budget_category/1`, `finance_status/4`, `documentation_status/4`, `finance_issue/3` |
| **J.3** | Never automatically infer corruption or financial misconduct from missing records or budget variances; report missing data as `unknown` (information gap) and large variances as `review_required`. | `finance_status/4`, `finance_issue/3` |

---

## 3. Unspecified Policy Decisions (Explicitly Separated, Not Invented)

To strictly obey the requirement *"Do not invent unapproved policy decisions; represent any unspecified policy as configurable or identify it as a decision requiring university approval"*, the following points are catalogued in `open_policy_decision/1` (`recommendations.pl`) and printed in Menu Option 14:

1. **Resit policy for attempted-but-below-standard exams:** If a student sits a modular or linear exam and scores below the standard (e.g., `s02` scoring 38 in `cn301` Module 3), whether a resit is allowed is flagged as requiring university approval.
2. **Missing a linear or deferred exam:** If a student misses a linear exam in Weeks 21–24 (`missed_linear_exam_policy_requires_approval`), the policy requires university approval.
3. **Practical/lab component rules:** Practical components are stored separately (`practical_component/3`); any attendance rule for laboratories requires university approval and never applies to lectures.
4. **Weighting of the 4 modules toward the final course grade:** Configurable / requires university approval.
5. **Mapping of modules to specific days/weeks in Weeks 21–24:** Stored as configurable facts (`linear_exam_week/2`, `course_exam_day/2`, `extended_period_capacity/2`).

---

## 4. Requirement-to-Test Traceability Matrix (R01–R16)

| Req # | Mandatory Verification Scenario (Section 9) | Module File | Test Case in `tests.pl` |
|-------|---------------------------------------------|-------------|-------------------------|
| **R01** | A university with compulsory lecture attendance is diagnosed | `academic_policy.pl` | `'R01 A: compulsory lecture attendance is diagnosed'` |
| **R02** | A recruitment process that checks qualifications but not teaching ability is diagnosed | `teacher_recruitment.pl` | `'R02 B: qualifications-only recruitment is diagnosed'` |
| **R03** | A teacher assigned unrelated courses contrary to the specialization policy is identified | `teacher_specialization.pl` | `'R03 C: teacher with an unrelated course is identified'` |
| **R04** | Different sections of the same course using different examination papers are detected | `examination_system.pl` | `'R04 E: different papers for sections of the same course are detected'` |
| **R05** | A centralized common marking scheme is verified | `examination_system.pl` | `'R05 E: common central marking scheme is verified'` |
| **R06** | Different examination sessions can use different approved grade thresholds | `grading.pl` | `'R06 F: different sessions use different approved thresholds'` |
| **R07** | All students in one examination session receive the same thresholds | `grading.pl` | `'R07 F: every student in one session gets the same thresholds (equal marks -> equal grade)'` |
| **R08** | The system does not impose a bell curve or rank-based grading | `grading.pl` | `'R08 F: no bell curve - adding many high scorers does not change existing grades'` |
| **R09** | All students meeting the A-grade standard can receive an A | `grading.pl` | `'R09 F: all students meeting the A standard receive an A (no quota)'` |
| **R10** | One student can choose modular for some modules and linear for others | `exam_scheduling.pl` | `'R10 G: one student mixes modular and linear modules'` |
| **R11** | A student missing a modular exam becomes eligible for a deferred examination | `exam_scheduling.pl` | `'R11 G: student missing a modular exam is eligible for a deferred exam'` |
| **R12** | Missing an exam is not confused with failing an attempted exam | `exam_scheduling.pl` | `'R12 G: missed exam is not confused with an attempted-but-below-standard exam'` |
| **R13** | A student's teacher selection respects class capacity | `student_selection.pl` | `'R13 H: selection respects class capacity (full section -> waitlisted)'` |
| **R14** | Teacher compensation is correctly calculated | `compensation.pl` | `'R14 I: teacher compensation is correctly calculated'` |
| **R15** | Missing financial information is reported as unknown rather than evidence of misconduct | `governance_finance.pl` | `'R15 J: missing financial information is reported as unknown, not misconduct'` |
| **R16** | Unassigned staff responsibilities are detected | `governance_finance.pl` | `'R16 J: unassigned staff responsibilities are detected'` |
