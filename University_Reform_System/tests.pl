/* ==========================================================================
   FILE: tests.pl     (Automated tests for every module)

   1. WHAT THIS FILE DOES
      Defines and runs 65 automated test cases covering all 16 mandatory
      testing scenarios (labelled R01..R16), plus additional unit, edge-case,
      and full-system integration tests across Modules A through J.

   2. IMPORTANT PREDICATES
      - test_case/2            : test_case(TestName, GoalToVerify)
      - run_all_tests/0        : runs every test_case/2 and prints PASS/FAIL
      - run_test/2             : executes one test goal inside catch/3
      - with_temporary_facts/2 : asserts temporary facts, runs Goal, retracts them
      - without_facts/2        : retracts facts temporarily, runs Goal, restores them
      - quietly/1              : suppresses console output while testing reports

   3. FACTS VERSUS RULES
      - Each `test_case(Name, Goal)` is a fact whose second argument is an
        executable Prolog goal (conjunction, negation, arithmetic check, etc.).
      - `run_all_tests/0` and the helper predicates are rules that execute
        those goals and tally `test_result(Name, pass | fail)`.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - Standard tests query `knowledge_base.pl` directly via the module rules.
      - Edge-case tests use `with_temporary_facts/2` and `without_facts/2` to
        temporarily modify the dynamic knowledge base (`assertz/1` / `retract/1`)
        and automatically restore it afterwards so the demo data stays intact.

   5. LOGIC IN PLAIN ENGLISH
      `run_all_tests/0` clears old results, runs every `test_case(Name, Goal)`,
      prints `PASS` if `Goal` succeeds or `FAIL` if it fails, counts total
      passes and failures, and exits with status code 1 if any test failed.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1 (from command line):
        swipl -g run_all_tests -t halt tests.pl
      Query 2 (interactive):
        ?- [tests].
        ?- run_all_tests.
      Expected Output:
        Prints `PASS` for all 65 test cases and concludes:
        `RESULT: 65 / 65 tests passed, 0 failed.`

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How do you test edge cases (like 100% of students getting an A or an
          invalid grade threshold order) without polluting the sample dataset?
      A1: `with_temporary_facts(Facts, Goal)` asserts the temporary facts,
          runs `Goal`, and then retracts every temporary fact before returning.
      Q2: How does Test R08 prove there is no bell curve in the grading module?
      A2: It records all grades in `cn301_fall2020` (`Before`), temporarily
          adds four extra students with marks 99, 98, 97, and 96, re-computes
          the original students' grades (`After`), and verifies `After == Before`.
   ========================================================================== */

:- ensure_loaded(main).

:- dynamic test_result/2.

/* --------------------------------------------------------------------------
   Test helpers
   -------------------------------------------------------------------------- */
with_temporary_facts(Facts, Goal) :-
    forall(member(Fact, Facts), assertz(Fact)),
    (   catch(Goal, _, fail) -> Result = passed ; Result = failed ),
    forall(member(Fact, Facts), retract(Fact)),
    Result == passed.

without_facts(Facts, Goal) :-
    forall(member(Fact, Facts), retract(Fact)),
    (   catch(Goal, _, fail) -> Result = passed ; Result = failed ),
    forall(member(Fact, Facts), assertz(Fact)),
    Result == passed.

% Silences report output when a test only checks that it runs.
quietly(Goal) :-
    with_output_to(string(_), Goal).

all_grades(Session, Pairs) :-
    findall(Student-Grade, student_grade(Student, Session, Grade), Pairs0),
    sort(Pairs0, Pairs).

/* --------------------------------------------------------------------------
   TEST CASES
   -------------------------------------------------------------------------- */

% ---------- Module A: attendance and learning ----------
test_case('R01 A: compulsory lecture attendance is diagnosed',
    academic_issue(conventional_uni, compulsory_attendance(lecture), _)).
test_case('A: minimum attendance percentage is diagnosed',
    academic_issue(conventional_uni, minimum_attendance_percentage, _)).
test_case('A: homework, random quizzes and unannounced tests are all diagnosed',
    ( academic_issue(conventional_uni, prohibited_assessment(homework_assignment), _),
      academic_issue(conventional_uni, prohibited_assessment(random_quiz), _),
      academic_issue(conventional_uni, prohibited_assessment(unannounced_test), _) )).
test_case('A: reform university fully complies',
    academic_policy_compliant(reform_uni)).
test_case('A edge: compulsory attendance under another name (tutorial) is caught',
    with_temporary_facts([attendance_rule(reform_uni, tutorial, compulsory)],
        academic_issue(reform_uni, compulsory_attendance(tutorial), _))).
test_case('A edge: a practical rule is NOT treated as lecture attendance',
    with_temporary_facts([attendance_rule(reform_uni, practical, compulsory)],
        \+ academic_issue(reform_uni, compulsory_attendance(_), _))).
test_case('A edge: a university with no recorded policy is unknown, not compliant',
    with_temporary_facts([university(empty_uni, 'Empty demo')],
        ( academic_policy_unknown(empty_uni, minimum_attendance_percent),
          \+ academic_policy_compliant(empty_uni) ))).

% ---------- Module B: recruitment ----------
test_case('R02 B: qualifications-only recruitment is diagnosed',
    recruitment_issue(conv_hiring, qualifications_only, _)).
test_case('B: conventional process is missing the demonstration lecture',
    recruitment_issue(conv_hiring, missing_criterion(demonstration_lecture), _)).
test_case('B: reform recruitment process is compliant',
    recruitment_compliant(reform_hiring)).
test_case('B: strong teacher (Sana) is recommended',
    candidate_decision(c_sana, recommended)).
test_case('B: high qualification but weak demo lecture (Kamran) is not recommended',
    ( candidate_decision(c_kamran, not_recommended),
      candidate_check(c_kamran, demonstration_lecture, failed) )).
test_case('B edge: missing demo score gives incomplete information, not a fail',
    candidate_decision(c_imran, incomplete_information)).

% ---------- Module C: specialization ----------
test_case('R03 C: teacher with an unrelated course is identified',
    specialization_issue(t_usman, unrelated_course(db201, fall, '2025-26'), _)).
test_case('C: assigned course taught in the wrong term is identified',
    specialization_issue(t_usman, wrong_term(os302, spring, '2025-26'), _)).
test_case('C: summer repeat and next-year continuation are allowed',
    specialization_compliant(t_ahmed)).
test_case('C edge: several sections of the same course count as one course',
    with_temporary_facts([section(cn301_extra, cn301, t_ahmed, fall, '2025-26', 30)],
        specialization_compliant(t_ahmed))).
test_case('C edge: a third assigned course is flagged',
    with_temporary_facts([assigned_course(t_bilal, db201, fall)],
        ( specialization_issue(t_bilal, wrong_number_of_assigned_courses(3), _),
          specialization_issue(t_bilal, several_courses_in_term(fall), _) ))).

% ---------- Module D: responsibilities ----------
test_case('D: teacher preparing papers is flagged as the wrong role',
    responsibility_issue(conventional_uni, wrong_role(prepare_exam_papers, teacher, central_exam_team), _)).
test_case('D: missing moderation owner is flagged',
    responsibility_issue(conventional_uni, unassigned_task(moderation), _)).
test_case('D: reform university duties are compliant',
    responsibilities_compliant(reform_uni)).

% ---------- Module E: central examinations and marking ----------
test_case('R04 E: different papers for sections of the same course are detected',
    exam_arrangement_issue(db201_fall2025, multiple_papers([db_paper_ayesha, db_paper_usman]), _)).
test_case('E: common central paper for Computer Networks is verified',
    ( centralized_exam_verified(cn301_fall2025),
      papers_used(cn301_fall2025, [cn_paper_2025]) )).
test_case('R05 E: common central marking scheme is verified',
    ( central_marking_verified(cn301_fall2025),
      schemes_used(cn301_fall2025, [cn_scheme_2025]),
      scheme_total_marks(cn_scheme_2025, 100) )).
test_case('E: local marking by teachers is detected',
    marking_issue(db201_fall2025, local_marking(db201_b, t_usman), _)).
test_case('E: different marking schemes are detected',
    marking_issue(db201_fall2025, multiple_schemes(_), _)).
test_case('E edge: a different session/year with another paper does not affect 2025',
    with_temporary_facts(
        [ exam_session(cn301_fall2026, cn301, fall, '2026-27'),
          section_exam_paper(cn301_fall2026, cn301_a27, cn_paper_2026),
          paper_prepared_by(cn_paper_2026, central_exam_team) ],
        ( centralized_exam_verified(cn301_fall2025),
          papers_used(cn301_fall2026, [cn_paper_2026]) ))).
test_case('E edge: a section with no recorded paper is reported as unknown',
    without_facts([section_exam_paper(cn301_fall2025, cn301_c, cn_paper_2025)],
        exam_arrangement_issue(cn301_fall2025, section_without_paper(cn301_c), _))).

% ---------- Module F: standards-based grading ----------
test_case('R06 F: different sessions use different approved thresholds',
    ( grade_threshold(cn301_fall2020, a, A2020),
      grade_threshold(cn301_fall2021, a, A2021),
      A2020 =\= A2021 )).
test_case('F: the same mark earns different grades in easy vs difficult sessions',
    ( mark_to_grade(cn301_fall2020, 78, b),
      mark_to_grade(cn301_fall2021, 78, a) )).
test_case('R07 F: every student in one session gets the same thresholds (equal marks -> equal grade)',
    with_temporary_facts([exam_mark(test_student, cn301_fall2021, 62)],
        ( student_grade(test_student, cn301_fall2021, Grade),
          student_grade(s21_3, cn301_fall2021, Grade) ))).
test_case('R08 F: no bell curve - adding many high scorers does not change existing grades',
    ( all_grades(cn301_fall2020, Before),
      with_temporary_facts(
          [ exam_mark(extra1, cn301_fall2020, 99), exam_mark(extra2, cn301_fall2020, 98),
            exam_mark(extra3, cn301_fall2020, 97), exam_mark(extra4, cn301_fall2020, 96) ],
          ( findall(S-G, ( member(S-_, Before), student_grade(S, cn301_fall2020, G) ), After0),
            sort(After0, After),
            After == Before )) )).
test_case('R09 F: all students meeting the A standard receive an A (no quota)',
    ( aggregate_all(count, ( exam_mark(_, cn301_fall2020, M), M >= 85 ), Meeting),
      grade_count(cn301_fall2020, a, Meeting),
      Meeting =:= 4 )).
test_case('F edge: 100% of a class can receive an A',
    with_temporary_facts(
        [ exam_session(t_sess, cn301, fall, '2030-31'),
          grade_threshold(t_sess, a, 80), grade_threshold(t_sess, b, 65),
          grade_threshold(t_sess, c, 50), grade_threshold(t_sess, d, 40),
          grade_threshold(t_sess, f, 0),
          exam_mark(x1, t_sess, 81), exam_mark(x2, t_sess, 90), exam_mark(x3, t_sess, 100) ],
        ( grade_count(t_sess, a, 3), \+ student_grade(_, t_sess, b) ))).
test_case('F edge: mark exactly on the boundary gets that grade',
    mark_to_grade(cn301_fall2020, 85, a)).
test_case('F edge: session without approved thresholds cannot be graded',
    with_temporary_facts([exam_mark(y1, cn301_fall2025, 70)],
        ( \+ student_grade(y1, cn301_fall2025, _),
          grading_issue(cn301_fall2025, thresholds_not_approved, _) ))).
test_case('F edge: thresholds in the wrong order are rejected',
    with_temporary_facts(
        [ exam_session(bad_sess, cn301, fall, '2031-32'),
          grade_threshold(bad_sess, a, 50), grade_threshold(bad_sess, b, 70),
          grade_threshold(bad_sess, c, 40), grade_threshold(bad_sess, d, 30),
          grade_threshold(bad_sess, f, 0), difficulty_review(bad_sess, x, x) ],
        ( grading_issue(bad_sess, invalid_threshold_order, _),
          \+ mark_to_grade(bad_sess, 60, _) ))).

% ---------- Module G: modular / linear scheduling ----------
test_case('G: calendar is 16 teaching + 4 exam weeks = 20, linear weeks within 21-24',
    ( teaching_weeks_total(16), exam_weeks_total(4), calendar_valid )).
test_case('R10 G: one student mixes modular and linear modules',
    ( module_choice(s01, cn301, 1, modular), module_choice(s01, cn301, 2, linear),
      module_choice(s01, cn301, 3, modular), module_choice(s01, cn301, 4, linear),
      scheduled_exam(s01, cn301, 1, 5, monday, modular),
      scheduled_exam(s01, cn301, 2, 22, monday, linear) )).
test_case('R11 G: student missing a modular exam is eligible for a deferred exam',
    ( deferred_eligible(s02, cn301, 2),
      scheduled_exam(s02, cn301, 2, Week, _, deferred),
      Week >= 21, Week =< 24 )).
test_case('R12 G: missed exam is not confused with an attempted-but-below-standard exam',
    ( module_status(s02, cn301, 2, missed_deferred_exam_eligible),
      module_status(s02, cn301, 3, attempted_below_standard(38)),
      \+ deferred_eligible(s02, cn301, 3),
      \+ exam_attempted(s02, cn301, 2, _) )).
test_case('G: modular exam clash (same week and day) is detected',
    exam_clash(s01, exam(db201, 1, modular), exam(os302, 1, modular), 5, tuesday)).
test_case('G: deferred exam clashing with a linear exam is detected',
    exam_clash(s10, _, _, 22, tuesday)).
test_case('G: missing module choices are reported as unknown',
    scheduling_issue(s02, missing_choice(db201, [1, 2, 3, 4]), _)).
test_case('G edge: extended-period capacity overflow is detected',
    without_facts([extended_period_capacity(21, 30)],
        with_temporary_facts([extended_period_capacity(21, 1)],
            scheduling_issue(21, over_capacity(_, 1), _)))).
test_case('G edge: a missed LINEAR exam does not create a deferred modular exam',
    with_temporary_facts([exam_missed(s03, cn301, 1)],
        ( \+ deferred_eligible(s03, cn301, 1),
          module_status(s03, cn301, 1, missed_linear_exam_policy_requires_approval) ))).

% ---------- Module H: student teacher selection ----------
test_case('R13 H: selection respects class capacity (full section -> waitlisted)',
    ( seats_remaining(cn301_a, 0),
      selection_decision(s10, cn301, t_ahmed, waitlisted, cn301_a, _) )).
test_case('H: selection with free seats is approved',
    selection_decision(s11, cn301, t_bilal, approved, cn301_c, _)).
test_case('H: already-enrolled student must use the transfer procedure',
    selection_decision(s01, cn301, t_fatima, rejected, cn301_a, _)).
test_case('H: valid transfer approved, transfer into a full section rejected',
    ( transfer_decision(s07, cn301_b, cn301_c, approved, _),
      transfer_decision(s09, cn301_c, cn301_a, rejected, _),
      transfer_decision(s05, cn301_b, db201_b, rejected, _) )).
test_case('H edge: closed transfer window rejects transfers',
    without_facts([transfer_window(fall, '2025-26', open)],
        transfer_decision(s07, cn301_b, cn301_c, rejected, 'transfer window is not open'))).
test_case('H edge: apply_transfer updates enrollment (then restored)',
    ( apply_transfer(s07, cn301_b, cn301_c),
      enrolled(s07, cn301_c),
      retract(enrolled(s07, cn301_c)),
      assertz(enrolled(s07, cn301_b)) )).
test_case('H: confidential feedback is aggregated per teacher',
    ( teacher_feedback_summary(t_ahmed, 2, Average), Average =:= 4.5 )).

% ---------- Module I: compensation ----------
test_case('R14 I: teacher compensation is correctly calculated',
    ( teacher_term_payment(t_ahmed, fall, '2025-26', 4000),
      teacher_term_payment(t_usman, fall, '2025-26', 5000),
      payment_for_enrollment(20, 20000),
      payment_for_enrollment(40, 40000),
      payment_for_enrollment(60, 60000) )).
test_case('I edge: changing the configurable rate changes the payment',
    without_facts([rate_per_student(1000)],
        with_temporary_facts([rate_per_student(1500)],
            teacher_term_payment(t_ahmed, fall, '2025-26', 6000)))).
test_case('I edge: optional weighting is off by default and separate when enabled',
    ( adjusted_section_payment(cn301_a, 4000),
      without_facts([optional_feature(course_weighting, disabled)],
          with_temporary_facts([optional_feature(course_weighting, enabled)],
              ( adjusted_section_payment(cn301_a, 4800),
                section_payment(cn301_a, t_ahmed, 4, 4000) ))) )).

% ---------- Module J: governance and finance ----------
test_case('R15 J: missing financial information is reported as unknown, not misconduct',
    ( finance_status(reform_uni, '2025-26', research, unknown_actual_expenditure),
      finance_issue(reform_uni, missing_information(research, unknown_actual_expenditure), Text),
      sub_atom(Text, _, _, _, 'NOT evidence of misconduct') )).
test_case('J: large variance gives review_required, not a misconduct finding',
    finance_status(reform_uni, '2025-26', administration, review_required(120, 150, 25))).
test_case('J edge: university with no budget is reported as an information gap',
    with_temporary_facts([university(empty_uni, 'Empty demo')],
        finance_issue(empty_uni, no_budget_information('2025-26'), _))).
test_case('R16 J: unassigned staff responsibilities are detected',
    ( governance_issue(conventional_uni, unassigned_duty(curriculum_coordination), _),
      governance_issue(conventional_uni, unassigned_duty(student_complaints), _) )).
test_case('J: a duty shared by two offices is reported as unclear',
    governance_issue(conventional_uni, unclear_responsibility(examination_administration, _), _)).
test_case('J: reform university governance is compliant',
    governance_compliant(reform_uni)).

% ---------- Integration ----------
test_case('INTEGRATION: every menu option 1-14 runs without error',
    forall(menu_item(Number, _), quietly(run_choice(Number)))).
test_case('INTEGRATION: comprehensive report finds issues in several areas',
    ( reform_issue(attendance_and_learning, _, _, _),
      reform_issue(central_examination, _, _, _),
      reform_issue(exam_scheduling, _, _, _),
      reform_issue(finance, _, _, _) )).
test_case('INTEGRATION: every diagnosed issue has a recommendation',
    forall(reform_issue(_, _, Id, _), once(recommendation(Id, _)))).

/* --------------------------------------------------------------------------
   Test runner
   -------------------------------------------------------------------------- */
run_test(Name, Goal) :-
    (   catch(Goal, Error, ( format("  ERROR in ~w: ~w~n", [Name, Error]), fail ))
    ->  assertz(test_result(Name, pass)),
        format("  PASS  ~w~n", [Name])
    ;   assertz(test_result(Name, fail)),
        format("  FAIL  ~w~n", [Name])
    ).

run_all_tests :-
    retractall(test_result(_, _)),
    print_heading('AUTOMATED TESTS - University Reform Expert System'),
    forall(test_case(Name, Goal), run_test(Name, Goal)),
    aggregate_all(count, test_result(_, pass), Passed),
    aggregate_all(count, test_result(_, fail), Failed),
    Total is Passed + Failed,
    format("~n  RESULT: ~w / ~w tests passed, ~w failed.~n", [Passed, Total, Failed]),
    (   Failed =:= 0 -> true ; halt(1) ).
