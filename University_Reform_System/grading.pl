/* ==========================================================================
   FILE: grading.pl     (MODULE F - Difficulty-Adjusted, Standards-Based Grading)

   1. WHAT THIS FILE DOES
      Applies difficulty-adjusted, standards-based grade thresholds approved
      by the central examination team for each examination session, without
      any bell curve, ranking, quota, or class-average calculation.

   2. IMPORTANT PREDICATES
      - grade_sequence/1        : grade_sequence([a, b, c, d, f])
      - thresholds_complete/1   : thresholds_complete(Session)
      - strictly_decreasing/1   : strictly_decreasing(MinMarkList)
      - thresholds_valid/1      : thresholds_valid(Session)
      - mark_to_grade/3         : mark_to_grade(Session, Mark, Grade)
      - student_grade/3         : student_grade(Student, Session, Grade)
      - grade_count/3           : grade_count(Session, Grade, Count)
      - grading_issue/3         : grading_issue(Session, IssueId, Text)
      - report_grading/0        : prints Menu Option 7 report

   3. FACTS VERSUS RULES
      - Facts in `knowledge_base.pl` (`difficulty_review/3`, `grade_threshold/3`,
        `exam_mark/3`) store the examination team's approved difficulty review,
        the approved minimum marks for `[a, b, c, d, f]`, and raw student marks.
      - Rules validate the thresholds and map each student's mark to a grade.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `strictly_decreasing/1` uses list recursion (`[First, Second | Rest]`)
        to verify `A > B > C > D > F`.
      - `first_grade_met/4` walks down `[a, b, c, d, f]` and assigns the first
        grade whose approved `Minimum` satisfies `Mark >= Minimum`.

   5. LOGIC IN PLAIN ENGLISH
      - Prolog does NOT invent or guess exam difficulty from class averages.
        Instead, the examination team's review and thresholds are stored as
        configurable input facts (`grade_threshold/3`).
      - `mark_to_grade(Session, Mark, Grade)` takes ONLY `Session` and `Mark`.
        It never inspects any other student's mark. Therefore:
          * Every student in `Session` is judged against identical boundaries.
          * There is no bell curve or rank limit: if 80 of 100 (or 100 of 100)
            students meet the A threshold, all of them receive an `a`.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- mark_to_grade(cn301_fall2020, 78, G2020),
           mark_to_grade(cn301_fall2021, 78, G2021).
      Expected Output:
        G2020 = b,
        G2021 = a.

      Query 2:
        ?- grade_count(cn301_fall2020, a, CountA).
      Expected Output:
        CountA = 4.   % 4 out of 5 students (80%) received an A

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How can you prove your grading rule never applies a bell curve or
          relative ranking?
      A1: Look at `mark_to_grade(Session, Mark, Grade)`: it only reads
          `grade_threshold(Session, Candidate, Minimum)` and compares
          `Mark >= Minimum`. It never calls `exam_mark/3` for other students.
          In `tests.pl` (Test R08), we assert 4 new students with marks 96-99
          and prove that not a single existing student's grade changes.
      Q2: Why does a mark of 78 get a B in `cn301_fall2020` but an A in
          `cn301_fall2021`?
      A2: Because the 2020 exam was reviewed as relatively easy (A threshold 85)
          whereas the 2021 exam was reviewed as relatively difficult (A
          threshold 75).
   ========================================================================== */

% Grades from best to worst.  F has threshold 0 so every mark gets a grade.
grade_sequence([a, b, c, d, f]).

% thresholds_complete(+Session): every grade has an approved threshold.
thresholds_complete(Session) :-
    exam_session(Session, _, _, _),
    grade_sequence(Grades),
    forall(member(Grade, Grades), grade_threshold(Session, Grade, _)).

% threshold_list(+Session, -Minimums): thresholds in grade order.
threshold_list(Session, Minimums) :-
    grade_sequence(Grades),
    findall(Min, ( member(Grade, Grades), grade_threshold(Session, Grade, Min) ), Minimums).

% strictly_decreasing(+List) - recursion over a list.
strictly_decreasing([]).
strictly_decreasing([_]).
strictly_decreasing([First, Second | Rest]) :-
    First > Second,
    strictly_decreasing([Second | Rest]).

thresholds_valid(Session) :-
    thresholds_complete(Session),
    threshold_list(Session, Minimums),
    strictly_decreasing(Minimums).

% mark_to_grade(+Session, +Mark, -Grade)
% Walk down the grade list and return the FIRST grade whose minimum is met.
mark_to_grade(Session, Mark, Grade) :-
    thresholds_valid(Session),
    grade_sequence(Grades),
    first_grade_met(Grades, Session, Mark, Grade).

first_grade_met([Candidate | Rest], Session, Mark, Grade) :-
    grade_threshold(Session, Candidate, Minimum),
    (   Mark >= Minimum
    ->  Grade = Candidate
    ;   first_grade_met(Rest, Session, Mark, Grade)
    ).

% student_grade(?Student, ?Session, -Grade)
student_grade(Student, Session, Grade) :-
    exam_mark(Student, Session, Mark),
    mark_to_grade(Session, Mark, Grade).

% grade_count(+Session, +Grade, -Count)  - reporting only, NOT used to grade.
grade_count(Session, Grade, Count) :-
    aggregate_all(count, student_grade(_, Session, Grade), Count).

% session_has_marks(+Session)
session_has_marks(Session) :-
    once(exam_mark(_, Session, _)).

/* --------------------------------------------------------------------------
   grading_issue(?Session, ?IssueId, ?Text)
   -------------------------------------------------------------------------- */

% Rule F1: marks exist, but no complete set of approved thresholds.
grading_issue(Session, thresholds_not_approved,
              'Marks exist but a complete set of approved grade thresholds is missing - students cannot be graded yet.') :-
    session_has_marks(Session),
    \+ thresholds_complete(Session).

% Rule F2: thresholds exist but are not in strictly decreasing order.
grading_issue(Session, invalid_threshold_order,
              'Approved thresholds are not strictly decreasing from A to F - please correct the input.') :-
    thresholds_complete(Session),
    \+ thresholds_valid(Session).

% Rule F3: thresholds exist without a recorded difficulty review.
grading_issue(Session, difficulty_review_missing,
              'Thresholds are recorded but the examination team''s difficulty review is not recorded.') :-
    exam_session(Session, _, _, _),
    once(grade_threshold(Session, _, _)),
    \+ difficulty_review(Session, _, _).

/* --------------------------------------------------------------------------
   REPORT (menu option 7)
   -------------------------------------------------------------------------- */
report_grading :-
    print_heading('MODULE F - Difficulty-Adjusted, Standards-Based Grading'),
    demo_data_notice,
    print_bullet('Grades depend ONLY on the approved thresholds of the session and the student''s own mark.'),
    print_bullet('No bell curve, no ranking, no class averages, no limit on the number of any grade.'),
    forall(exam_session(Session, Course, Term, Year),
           report_session_grading(Session, Course, Term, Year)).

report_session_grading(Session, Course, Term, Year) :-
    format(atom(Title), "Session ~w (~w, ~w ~w)", [Session, Course, Term, Year]),
    print_subheading(Title),
    (   difficulty_review(Session, Assessment, Notes)
    ->  format("  Approved difficulty review: ~w~n  Notes: ~w~n", [Assessment, Notes])
    ;   format("  Approved difficulty review: NOT RECORDED~n")
    ),
    (   thresholds_valid(Session)
    ->  grade_sequence(Grades),
        findall(Grade-Min, ( member(Grade, Grades), grade_threshold(Session, Grade, Min) ), Pairs),
        format("  Approved thresholds (minimum mark): ~w~n", [Pairs]),
        forall(student_grade(Student, Session, Grade),
               (   exam_mark(Student, Session, Mark),
                   format("      ~w  mark ~w  -> grade ~w~n", [Student, Mark, Grade])
               )),
        findall(Grade-Count, ( member(Grade, Grades), grade_count(Session, Grade, Count) ), Counts),
        format("  Grade totals (for information only): ~w~n", [Counts])
    ;   print_bullet('No valid approved thresholds - grading not possible for this session yet.')
    ),
    findall(Text, grading_issue(Session, _, Text), Issues),
    print_all_tagged(Issues, 'ISSUE').
