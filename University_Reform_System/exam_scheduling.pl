/* ==========================================================================
   FILE: exam_scheduling.pl     (MODULE G - Modular and Linear Examination System)

   1. WHAT THIS FILE DOES
      Implements the 20-week modular academic calendar (4 modules x [4 teaching
      weeks + 1 exam week] = 16 teaching + 4 exam weeks) plus Weeks 21-24 for
      linear and deferred modular examinations. Supports per-module mixing of
      `modular` and `linear` choices, distinguishes missed modular exams from
      attempted-but-below-standard exams, and detects timetable clashes and
      extended-period capacity overflows.

   2. IMPORTANT PREDICATES
      - module_plan/4            : module_plan(ModNo, FirstTeachWk, LastTeachWk, ExamWk)
      - calendar_valid/0         : verifies 16 teaching + 4 exam weeks & weeks 21-24
      - deferred_eligible/3      : deferred_eligible(Student, Course, Module)
      - scheduled_exam/6         : scheduled_exam(Student, Course, Mod, Week, Day, Route)
      - module_status/4          : module_status(Student, Course, Module, Status)
      - exam_clash/5             : exam_clash(Student, Exam1, Exam2, Week, Day)
      - extended_week_load/2     : extended_week_load(Week, SittingCount)
      - scheduling_issue/3       : scheduling_issue(Subject, IssueId, Text)
      - student_schedule/2       : student_schedule(Student, SortedSlots)
      - report_student_routes/0  : prints Menu Option 8 report
      - report_exam_schedule/0   : prints Menu Option 9 report
      - report_deferred/0        : prints Menu Option 10 report

   3. FACTS VERSUS RULES
      - Structural facts here (`module_plan/4`, `extended_period/2`, `valid_route/1`)
        define the approved 20+4 week calendar.
      - Facts in `knowledge_base.pl` (`module_choice/4`, `exam_attempted/4`,
        `exam_missed/3`, `course_exam_day/2`, `linear_exam_week/2`,
        `extended_period_capacity/2`) store student choices and outcomes.
      - Rules infer timetables, deferred eligibility, clashes, and statuses.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `scheduled_exam/6` has 3 clauses (DISJUNCTION):
          1. Modular choice -> scheduled in `ExamWeek` (5, 10, 15, or 20).
          2. Linear choice  -> scheduled in `linear_exam_week(Module, Week)` (21-24).
          3. Deferred exam  -> if `deferred_eligible/3` holds, also scheduled in
             `linear_exam_week(Module, Week)` (21-24) with route `deferred`.
      - `exam_clash/5` finds two scheduled exams for the same student in the
        same `(Week, Day)` and uses term ordering (`@<`) so each clash is
        reported once.

   5. LOGIC IN PLAIN ENGLISH
      - A student can mix `modular` and `linear` across modules 1..4 of the
        same course because `module_choice/4` stores the choice per module.
      - Missing a modular exam (`exam_missed/3`) NEVER records a fail. It makes
        `deferred_eligible(Student, Course, Module)` true and schedules a
        `deferred` sitting in Weeks 21-24.
      - Attempting an exam (`exam_attempted/4`) is stored in a completely
        different predicate from `exam_missed/3`, so a missed exam and an
        attempted-but-below-standard exam can never be confused.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- deferred_eligible(s02, cn301, Mod),
           module_status(s02, cn301, 2, S2),
           module_status(s02, cn301, 3, S3).
      Expected Output:
        Mod = 2,
        S2 = missed_deferred_exam_eligible,
        S3 = attempted_below_standard(38).

      Query 2:
        ?- exam_clash(Student, Exam1, Exam2, Week, Day).
      Expected Output:
        Student = s01,
        Exam1 = exam(db201, 1, modular), Exam2 = exam(os302, 1, modular),
        Week = 5, Day = tuesday ;
        Student = s10,
        Exam1 = exam(db201, 2, deferred), Exam2 = exam(os302, 2, linear),
        Week = 22, Day = tuesday.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: In your knowledge base, student `s02` missed Module 2 of `cn301` and
          scored 38 in Module 3. Why does `s02` get a deferred exam for Module 2
          but NOT for Module 3?
      A1: Because `deferred_eligible/3` requires `module_choice(S, C, M, modular)`
          AND `exam_missed(S, C, M)`. Module 2 was missed (`exam_missed`), whereas
          Module 3 was attempted (`exam_attempted(s02, cn301, 3, 38)`). Resits for
          attempted-but-below-standard exams are not invented; they are flagged
          as requiring university approval.
      Q2: Why does student `s10` have an exam clash in Week 22?
      A2: Because `s10` missed the modular exam for `db201` Module 2 (creating a
          deferred exam in Week 22 on Tuesday) and also chose the `linear` route
          for `os302` Module 2 (scheduled in Week 22 on Tuesday).
   ========================================================================== */

% module_plan(Module, FirstTeachingWeek, LastTeachingWeek, ExamWeek)
module_plan(1,  1,  4,  5).
module_plan(2,  6,  9, 10).
module_plan(3, 11, 14, 15).
module_plan(4, 16, 19, 20).

extended_period(21, 24).

valid_route(modular).
valid_route(linear).

/* --------------------------------------------------------------------------
   Calendar arithmetic (used to prove 16 + 4 = 20 weeks)
   -------------------------------------------------------------------------- */
teaching_weeks_total(Total) :-
    findall(Weeks, ( module_plan(_, First, Last, _), Weeks is Last - First + 1 ), WeekList),
    sum_list(WeekList, Total).

exam_weeks_total(Total) :-
    aggregate_all(count, module_plan(_, _, _, _), Total).

calendar_valid :-
    teaching_weeks_total(16),
    exam_weeks_total(4),
    forall(module_plan(_, First, Last, ExamWeek),
           ( Last - First + 1 =:= 4, ExamWeek =:= Last + 1 )),
    forall(linear_exam_week(_, Week),
           ( extended_period(Start, End), Week >= Start, Week =< End )).

/* --------------------------------------------------------------------------
   Scheduling rules
   -------------------------------------------------------------------------- */

% deferred_eligible(?Student, ?Course, ?Module)
% Chose MODULAR and MISSED it -> deferred exam opportunity.
deferred_eligible(Student, Course, Module) :-
    module_choice(Student, Course, Module, modular),
    exam_missed(Student, Course, Module).

% scheduled_exam(?Student, ?Course, ?Module, ?Week, ?Day, ?Route)
% Three clauses = three ways an exam can be scheduled (disjunction).
scheduled_exam(Student, Course, Module, Week, Day, modular) :-
    module_choice(Student, Course, Module, modular),
    module_plan(Module, _, _, Week),
    course_exam_day(Course, Day).
scheduled_exam(Student, Course, Module, Week, Day, linear) :-
    module_choice(Student, Course, Module, linear),
    linear_exam_week(Module, Week),
    course_exam_day(Course, Day).
scheduled_exam(Student, Course, Module, Week, Day, deferred) :-
    deferred_eligible(Student, Course, Module),
    linear_exam_week(Module, Week),
    course_exam_day(Course, Day).

% module_status(?Student, ?Course, ?Module, -Status)
module_status(Student, Course, Module, Status) :-
    module_choice(Student, Course, Module, Route),
    outcome_status(Student, Course, Module, Route, Status).

outcome_status(Student, Course, Module, _Route, Status) :-
    exam_attempted(Student, Course, Module, Mark),
    !,                                   % an attempt exists: use it
    attempted_status(Course, Mark, Status).
outcome_status(Student, Course, Module, modular, missed_deferred_exam_eligible) :-
    exam_missed(Student, Course, Module),
    !.
outcome_status(Student, Course, Module, linear, missed_linear_exam_policy_requires_approval) :-
    exam_missed(Student, Course, Module),
    !.
outcome_status(_Student, _Course, _Module, _Route, awaiting_exam).

attempted_status(Course, Mark, Status) :-
    (   module_pass_mark(Course, PassMark)
    ->  (   Mark >= PassMark
        ->  Status = attempted_met_standard(Mark)
        ;   Status = attempted_below_standard(Mark)
        )
    ;   Status = attempted_standard_not_configured(Mark)
    ).

% exam_clash(?Student, -Exam1, -Exam2, -Week, -Day)
% Two different exams for the same student in the same week on the same day.
% The @< comparison reports each pair only once.
exam_clash(Student, exam(Course1, Module1, Route1), exam(Course2, Module2, Route2), Week, Day) :-
    scheduled_exam(Student, Course1, Module1, Week, Day, Route1),
    scheduled_exam(Student, Course2, Module2, Week, Day, Route2),
    exam(Course1, Module1, Route1) @< exam(Course2, Module2, Route2).

% extended_week_load(?Week, -Count): linear + deferred exams in Weeks 21-24.
extended_week_load(Week, Count) :-
    extended_period(Start, End),
    between(Start, End, Week),
    aggregate_all(count,
                  ( scheduled_exam(_, _, _, Week, _, Route),
                    ( Route == linear ; Route == deferred ) ),
                  Count).

% missing_module_choice(?Student, ?Course, ?Module)
% Enrolled in a current-term course, but no choice recorded for a module.
missing_module_choice(Student, Course, Module) :-
    current_term(Term, Year),
    enrolled(Student, Section),
    section(Section, Course, _, Term, Year, _),
    module_plan(Module, _, _, _),
    \+ module_choice(Student, Course, Module, _).

/* --------------------------------------------------------------------------
   scheduling_issue(?Subject, ?IssueId, ?Text)
   -------------------------------------------------------------------------- */
scheduling_issue(Student, exam_clash(Exam1, Exam2, Week, Day), Text) :-
    exam_clash(Student, Exam1, Exam2, Week, Day),
    format(atom(Text), "~w has two exams in week ~w on ~w: ~w and ~w.", [Student, Week, Day, Exam1, Exam2]).

scheduling_issue(Student, invalid_route(Course, Module, Route), Text) :-
    module_choice(Student, Course, Module, Route),
    \+ valid_route(Route),
    format(atom(Text), "~w chose unknown route '~w' for ~w module ~w.", [Student, Route, Course, Module]).

scheduling_issue(Week, over_capacity(Count, Capacity), Text) :-
    extended_week_load(Week, Count),
    extended_period_capacity(Week, Capacity),
    Count > Capacity,
    format(atom(Text), "Week ~w has ~w linear/deferred exams but capacity is ~w.", [Week, Count, Capacity]).

scheduling_issue(Week, capacity_unknown, Text) :-
    extended_week_load(Week, Count),
    Count > 0,
    \+ extended_period_capacity(Week, _),
    format(atom(Text), "Capacity for week ~w is not recorded (unknown).", [Week]).

% One line per student and course, listing all modules without a choice.
scheduling_issue(Student, missing_choice(Course, Modules), Text) :-
    current_term(Term, Year),
    enrolled(Student, Section),
    section(Section, Course, _, Term, Year, _),
    findall(Module, missing_module_choice(Student, Course, Module), Modules),
    Modules \= [],
    format(atom(Text), "~w has no recorded modular/linear choice for ~w modules ~w (unknown).", [Student, Course, Modules]).

% student_schedule(+Student, -Slots): every exam, sorted by week.
student_schedule(Student, Slots) :-
    student(Student, _),
    findall(slot(Week, Day, Course, Module, Route),
            scheduled_exam(Student, Course, Module, Week, Day, Route),
            Unsorted),
    sort(Unsorted, Slots).

students_with_choices(Students) :-
    findall(Student, module_choice(Student, _, _, _), All),
    sort(All, Students).

/* --------------------------------------------------------------------------
   REPORTS
   -------------------------------------------------------------------------- */

% Menu option 8: individual examination routes.
report_student_routes :-
    print_heading('MODULE G - Individual Student Examination Routes'),
    demo_data_notice,
    students_with_choices(Students),
    forall(member(Student, Students), report_one_route(Student)),
    print_subheading('Missing information'),
    findall(Text, scheduling_issue(_, missing_choice(_, _), Text), Missing),
    print_list_or_none(Missing, 'UNKNOWN', 'Every enrolled student has a recorded choice for every module.').

report_one_route(Student) :-
    student(Student, Name),
    format(atom(Title), "~w (~w)", [Name, Student]),
    print_subheading(Title),
    findall(Course, module_choice(Student, Course, _, _), Courses0),
    sort(Courses0, Courses),
    forall(member(Course, Courses),
           (   format("  ~w:~n", [Course]),
               forall(module_choice(Student, Course, Module, Route),
                      (   module_status(Student, Course, Module, Status),
                          format("      Module ~w: ~w  -> ~w~n", [Module, Route, Status])
                      ))
           )).

% Menu option 9: modular and linear schedule.
report_exam_schedule :-
    print_heading('MODULE G - Modular and Linear Examination Schedule'),
    demo_data_notice,
    print_subheading('Academic calendar (approved structure)'),
    forall(module_plan(Module, First, Last, ExamWeek),
           format("  Module ~w: teaching weeks ~w-~w, modular exam week ~w~n", [Module, First, Last, ExamWeek])),
    extended_period(Start, End),
    teaching_weeks_total(Teaching),
    exam_weeks_total(ExamWeeks),
    Total is Teaching + ExamWeeks,
    format("  Totals: ~w teaching + ~w exam weeks = ~w weeks; weeks ~w-~w reserved for linear/deferred exams.~n",
           [Teaching, ExamWeeks, Total, Start, End]),
    forall(linear_exam_week(Module, Week),
           format("  Linear/deferred exam for module ~w: week ~w (configurable)~n", [Module, Week])),
    (   calendar_valid -> print_bullet('Calendar check: VALID') ; print_bullet('Calendar check: INVALID') ),
    print_subheading('Per-student timetable'),
    students_with_choices(Students),
    forall(member(Student, Students),
           (   student_schedule(Student, Slots),
               format("  ~w:~n", [Student]),
               forall(member(slot(Week, Day, Course, Module, Route), Slots),
                      (   ( Route == modular, exam_missed(Student, Course, Module) -> Note = ' (MISSED)' ; Note = '' ),
                          format("      Week ~w ~w: ~w module ~w [~w]~w~n", [Week, Day, Course, Module, Route, Note])
                      ))
           )),
    print_subheading('Extended period load (weeks 21-24)'),
    forall(extended_week_load(Week, Count),
           (   ( extended_period_capacity(Week, Capacity) -> true ; Capacity = unknown ),
               format("  Week ~w: ~w exam sitting(s), capacity ~w~n", [Week, Count, Capacity])
           )),
    print_subheading('Scheduling conflicts and capacity problems'),
    findall(Text, ( scheduling_issue(_, Id, Text), Id \= missing_choice(_, _) ), Issues),
    print_list_or_none(Issues, 'CONFLICT', 'No clashes or capacity problems.').

% Menu option 10: deferred eligibility.
report_deferred :-
    print_heading('MODULE G - Deferred Examination Eligibility'),
    demo_data_notice,
    print_bullet('A MISSED modular exam is NOT a fail. It gives a deferred exam in weeks 21-24.'),
    print_subheading('Students eligible for deferred exams'),
    findall(Student-Course-Module, deferred_eligible(Student, Course, Module), Eligible),
    (   Eligible == []
    ->  print_bullet('None.')
    ;   forall(member(Student-Course-Module, Eligible),
               (   student(Student, Name),
                   scheduled_exam(Student, Course, Module, Week, Day, deferred),
                   format("  ~w (~w): ~w module ~w -> deferred exam week ~w, ~w~n",
                          [Name, Student, Course, Module, Week, Day])
               ))
    ),
    print_subheading('Attempted but below the standard (NOT deferred - different case)'),
    findall(Student-Course-Module-Mark,
            module_status(Student, Course, Module, attempted_below_standard(Mark)),
            Below),
    (   Below == []
    ->  print_bullet('None.')
    ;   forall(member(Student-Course-Module-Mark, Below),
               format("  ~w: ~w module ~w attempted, mark ~w (below the configured standard)~n",
                      [Student, Course, Module, Mark]))
    ),
    print_bullet('Resit policy after an attempted-but-below-standard exam: NOT SPECIFIED - requires university approval.').
