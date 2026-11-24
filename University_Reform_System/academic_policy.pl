/* ==========================================================================
   FILE: academic_policy.pl            (MODULE A - Attendance and Learning)

   1. WHAT THIS FILE DOES
      Diagnoses a university's attendance and assessment policies against the
      proposed reform model:
        - NO compulsory attendance for lectures (under any name),
        - NO minimum attendance percentage,
        - missing lectures never reduces marks or blocks examinations,
        - students may learn from any resource (lectures, books, YouTube, ChatGPT),
        - NO homework, random quizzes, unannounced tests or take-home assessments,
        - assessment by SCHEDULED, SUPERVISED physical examinations.

   2. IMPORTANT PREDICATES
      - prohibited_assessment/1      : prohibited_assessment(AssessmentType)
      - required_policy_key/1        : required_policy_key(PolicyKey)
      - academic_issue/3             : academic_issue(Uni, IssueId, Explanation)
      - academic_policy_unknown/2    : academic_policy_unknown(Uni, Key)
      - academic_policy_compliant/1  : academic_policy_compliant(Uni)
      - report_academic_policy/0     : prints Menu Option 1 report

   3. FACTS VERSUS RULES
      - Facts in this file (`prohibited_assessment/1`, `required_policy_key/1`)
        define the approved reform standard.
      - Facts in `knowledge_base.pl` (`attendance_rule/3`, `policy/3`,
        `uses_assessment/2`, `practical_component/3`) describe each university.
      - Rules (`academic_issue/3`, `academic_policy_compliant/1`) infer
        policy violations by matching university facts against the standard.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      `academic_issue/3` has 7 separate clauses (Rules A1-A7). When queried,
      Prolog uses BACKTRACKING to test every clause against the facts in
      `knowledge_base.pl` and uses NEGATION AS FAILURE (`\+`) to detect when
      scheduled supervised exams or required policy records are missing.

   5. LOGIC IN PLAIN ENGLISH
      - Rule A1 checks `SessionType \= practical` instead of `SessionType = lecture`
        so a university cannot re-introduce compulsory lecture attendance under
        another name like `tutorial` or `seminar`.
      - Practical/lab components (`practical_component/3`) are stored separately
        and never trigger lecture attendance requirements.
      - A university is `academic_policy_compliant(Uni)` IF AND ONLY IF it has
        NO `academic_issue` AND NO `academic_policy_unknown`.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- academic_issue(conventional_uni, Id, Text).
      Expected Output:
        Id = compulsory_attendance(lecture),
        Text = 'Attendance is compulsory for lecture sessions.' ;
        Id = minimum_attendance_percentage,
        Text = 'A minimum attendance of 75% is required.' ;
        Id = attendance_reduces_marks,
        Text = 'Missing lectures automatically reduces marks.' ;
        ... (7 issues in total)

      Query 2:
        ?- academic_policy_compliant(reform_uni).
      Expected Output:
        true.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How do you prevent compulsory lecture attendance from being
          re-introduced under another name like "tutorial"?
      A1: Rule A1 checks `attendance_rule(Uni, SessionType, compulsory)` with
          `SessionType \= practical`. Any non-practical compulsory session is
          flagged immediately.
      Q2: Why does `academic_policy_compliant/1` check both `\+ academic_issue`
          and `\+ academic_policy_unknown`?
      A2: Because a university with zero recorded facts would have no issues
          detected, yet its policies are unknown rather than compliant.
   ========================================================================== */

% Assessment types removed by the reform (approved policy).
prohibited_assessment(homework_assignment).
prohibited_assessment(random_quiz).
prohibited_assessment(unannounced_test).
prohibited_assessment(take_home_assessment).

% Policy keys that must be recorded before we can call a university compliant.
required_policy_key(minimum_attendance_percent).
required_policy_key(attendance_affects_marks).
required_policy_key(attendance_affects_exam_eligibility).
required_policy_key(external_learning_resources).

/* --------------------------------------------------------------------------
   academic_issue(?University, ?IssueId, ?Explanation)
   Each clause below is ONE diagnostic rule.  Prolog tries every clause, so
   backtracking finds ALL issues for a university.
   -------------------------------------------------------------------------- */

% Rule A1: Compulsory attendance for any non-practical session type.
% Checking "SessionType \= practical" (instead of "= lecture") means
% compulsory attendance cannot be re-introduced under another name
% (e.g. "tutorial" or "seminar").
academic_issue(Uni, compulsory_attendance(SessionType), Text) :-
    attendance_rule(Uni, SessionType, compulsory),
    SessionType \= practical,
    format(atom(Text), "Attendance is compulsory for ~w sessions.", [SessionType]).

% Rule A2: A numeric minimum attendance percentage exists.
academic_issue(Uni, minimum_attendance_percentage, Text) :-
    policy(Uni, minimum_attendance_percent, Percent),
    number(Percent),
    format(atom(Text), "A minimum attendance of ~w% is required.", [Percent]).

% Rule A3: Missing lectures reduces marks.
academic_issue(Uni, attendance_reduces_marks,
               'Missing lectures automatically reduces marks.') :-
    policy(Uni, attendance_affects_marks, yes).

% Rule A4: Low attendance blocks examinations.
academic_issue(Uni, attendance_blocks_exams,
               'Low attendance can make a student ineligible for examinations.') :-
    policy(Uni, attendance_affects_exam_eligibility, yes).

% Rule A5: Learning resources are restricted.
academic_issue(Uni, restricted_learning_resources, Text) :-
    policy(Uni, external_learning_resources, Value),
    Value \= allowed,
    format(atom(Text), "External learning resources (books, YouTube, ChatGPT ...) are ~w.", [Value]).

% Rule A6: A prohibited assessment type is used.
academic_issue(Uni, prohibited_assessment(Type), Text) :-
    uses_assessment(Uni, Type),
    prohibited_assessment(Type),
    format(atom(Text), "Uses ~w, which the reform model removes.", [Type]).

% Rule A7: No scheduled supervised examinations (negation as failure).
academic_issue(Uni, no_scheduled_supervised_exams,
               'Does not assess through scheduled, supervised physical examinations.') :-
    university(Uni, _),
    \+ uses_assessment(Uni, scheduled_supervised_exam).

/* --------------------------------------------------------------------------
   Missing information: reported as UNKNOWN, never assumed good or bad.
   -------------------------------------------------------------------------- */
academic_policy_unknown(Uni, Key) :-
    university(Uni, _),
    required_policy_key(Key),
    \+ policy(Uni, Key, _).
academic_policy_unknown(Uni, lecture_attendance_rule) :-
    university(Uni, _),
    \+ attendance_rule(Uni, lecture, _).

% A university complies only if there is no issue AND nothing is unknown.
academic_policy_compliant(Uni) :-
    university(Uni, _),
    \+ academic_issue(Uni, _, _),
    \+ academic_policy_unknown(Uni, _).

/* --------------------------------------------------------------------------
   REPORT (menu option 1)
   -------------------------------------------------------------------------- */
report_academic_policy :-
    print_heading('MODULE A - Diagnosis of Attendance and Assessment Policies'),
    demo_data_notice,
    forall(university(Uni, Name), report_academic_policy_for(Uni, Name)).

report_academic_policy_for(Uni, Name) :-
    print_subheading(Name),
    findall(Text, academic_issue(Uni, _, Text), Issues),
    print_list_or_none(Issues, 'ISSUE', 'No attendance or assessment issues found.'),
    forall(academic_policy_unknown(Uni, Key),
           format("  [UNKNOWN] Policy '~w' is not recorded.~n", [Key])),
    forall(practical_component(Uni, Course, Description),
           format("  [NOTE] Practical component for ~w: ~w.~n         Stored separately; it is NOT a lecture attendance rule.~n         Any attendance rule for practicals requires university approval.~n",
                  [Course, Description])),
    (   academic_policy_compliant(Uni)
    ->  print_bullet('RESULT: Matches the proposed attendance and assessment model.')
    ;   print_bullet('RESULT: Does NOT fully match the proposed model.')
    ),
    print_recommendations_for(Uni, academic_issue).
