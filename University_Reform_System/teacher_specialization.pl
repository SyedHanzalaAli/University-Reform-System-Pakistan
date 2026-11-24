/* ==========================================================================
   FILE: teacher_specialization.pl     (MODULE C - Teacher Course Specialization)

   1. WHAT THIS FILE DOES
      Enforces the two-course teacher specialization policy:
        - Each teacher is assigned TWO courses per year (1 Fall, 1 Spring).
        - The teacher continues teaching the same two courses across years.
        - Summer sessions may repeat batches of those same assigned courses.
        - Teachers must not be assigned unrelated courses.
        - Multiple sections/batches of an assigned course count as ONE course.

   2. IMPORTANT PREDICATES
      - assigned_courses/2        : assigned_courses(Teacher, DistinctCourseList)
      - teaching_records/2        : teaching_records(Teacher, DistinctRecords)
      - teaches_course/4          : teaches_course(Teacher, Course, Term, Year)
      - specialization_issue/3    : specialization_issue(Teacher, IssueId, Text)
      - specialization_compliant/1: specialization_compliant(Teacher)
      - section_count/5           : section_count(Teacher, Course, Term, Year, N)
      - report_specialization/0   : prints Menu Option 3 report

   3. FACTS VERSUS RULES
      - Facts in `knowledge_base.pl`: `teacher/2`, `assigned_course/3`, and
        `section/6`.
      - Rules in this file aggregate sections into distinct courses using
        `findall/3` and `sort/2`, and diagnose 5 types of policy violations
        (Rules C1-C5).

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      `teaching_records/2` collects `record(Course, Term, Year)` from all
      `section/6` facts for a teacher and calls `sort/2`, which removes
      duplicates. That way, teaching 3 sections of `cn301` in Fall produces
      only ONE `record(cn301, fall, '2025-26')`.

   5. LOGIC IN PLAIN ENGLISH
      - Rule C1 checks that a teacher has exactly 2 distinct assigned courses.
      - Rule C2 checks that both `fall` and `spring` have an assigned course.
      - Rule C3 checks that no regular term has more than 1 assigned course.
      - Rule C4 flags any taught course that is not in `assigned_course/3`.
      - Rule C5 flags an assigned course taught in the wrong regular term
        (e.g., a Fall course taught in Spring), while allowing `summer` repeats.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- specialization_issue(t_usman, Id, Text).
      Expected Output:
        Id = unrelated_course(db201, fall, '2025-26'),
        Text = 'Teaches unassigned course db201 in fall 2025-26.' ;
        Id = wrong_term(os302, spring, '2025-26'),
        Text = 'Teaches os302 in spring 2025-26, but it is assigned to the fall term.'

      Query 2:
        ?- specialization_compliant(t_ahmed).
      Expected Output:
        true.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How does your code make sure multiple sections of an assigned course
          do not count as a third course?
      A1: `teaching_records/2` projects out the section ID (`_`) and calls
          `sort/2` on `record(Course, Term, Year)`, collapsing all sections of
          the same course in a term into a single record.
      Q2: Why is Mr. Ahmed compliant even though he teaches `cn301` in Summer
          2025-26 and Fall 2026-27?
      A2: Because `cn301` is his assigned Fall course; repeating it in Summer
          and continuing it in subsequent academic years are explicitly allowed.
   ========================================================================== */

regular_term(fall).
regular_term(spring).

% assigned_courses(+Teacher, -Courses)
% findall collects every assigned course; sort/2 removes duplicates.
assigned_courses(Teacher, Courses) :-
    teacher(Teacher, _),
    findall(Course, assigned_course(Teacher, Course, _), AllCourses),
    sort(AllCourses, Courses).

% teaching_records(+Teacher, -Records)
% Turns many sections into distinct record(Course, Term, Year) terms, so
% several sections of the same course are NOT counted as different courses.
teaching_records(Teacher, Records) :-
    findall(record(Course, Term, Year),
            section(_, Course, Teacher, Term, Year, _),
            AllRecords),
    sort(AllRecords, Records).

teaches_course(Teacher, Course, Term, Year) :-
    teacher(Teacher, _),
    teaching_records(Teacher, Records),
    member(record(Course, Term, Year), Records).

/* --------------------------------------------------------------------------
   specialization_issue(?Teacher, ?IssueId, ?Text)
   -------------------------------------------------------------------------- */

% Rule C1: the teacher does not have exactly two assigned courses.
specialization_issue(Teacher, wrong_number_of_assigned_courses(N), Text) :-
    assigned_courses(Teacher, Courses),
    length(Courses, N),
    N =\= 2,
    format(atom(Text), "Has ~w distinct assigned courses ~w; policy requires exactly 2.", [N, Courses]).

% Rule C2: no assigned course for Fall or for Spring.
specialization_issue(Teacher, missing_term_assignment(Term), Text) :-
    teacher(Teacher, _),
    regular_term(Term),
    \+ assigned_course(Teacher, _, Term),
    format(atom(Text), "No assigned course for the ~w term.", [Term]).

% Rule C3: more than one assigned course in the same regular term.
specialization_issue(Teacher, several_courses_in_term(Term), Text) :-
    teacher(Teacher, _),
    regular_term(Term),
    findall(Course, assigned_course(Teacher, Course, Term), Courses0),
    sort(Courses0, Courses),
    length(Courses, N),
    N > 1,
    format(atom(Text), "Has ~w courses assigned to ~w ~w; policy allows one per term.", [N, Term, Courses]).

% Rule C4: teaching a course that is not one of the two assigned courses
% (applies to fall, spring AND summer).
specialization_issue(Teacher, unrelated_course(Course, Term, Year), Text) :-
    teaches_course(Teacher, Course, Term, Year),
    \+ assigned_course(Teacher, Course, _),
    format(atom(Text), "Teaches unassigned course ~w in ~w ~w.", [Course, Term, Year]).

% Rule C5: teaching an assigned course in the wrong regular term
% (e.g. the Fall course taught in Spring).  Summer is exempt.
specialization_issue(Teacher, wrong_term(Course, Term, Year), Text) :-
    teaches_course(Teacher, Course, Term, Year),
    regular_term(Term),
    assigned_course(Teacher, Course, AssignedTerm),
    AssignedTerm \= Term,
    \+ assigned_course(Teacher, Course, Term),
    format(atom(Text), "Teaches ~w in ~w ~w, but it is assigned to the ~w term.",
           [Course, Term, Year, AssignedTerm]).

specialization_compliant(Teacher) :-
    teacher(Teacher, _),
    \+ specialization_issue(Teacher, _, _).

% section_count(+Teacher, +Course, +Term, +Year, -Count)
section_count(Teacher, Course, Term, Year, Count) :-
    aggregate_all(count, section(_, Course, Teacher, Term, Year, _), Count).

/* --------------------------------------------------------------------------
   REPORT (menu option 3)
   -------------------------------------------------------------------------- */
report_specialization :-
    print_heading('MODULE C - Teacher Course Specialization Check'),
    demo_data_notice,
    forall(teacher(Teacher, Name), report_teacher_specialization(Teacher, Name)).

report_teacher_specialization(Teacher, Name) :-
    print_subheading(Name),
    findall(Course-Term, assigned_course(Teacher, Course, Term), Assigned),
    format("  Assigned courses: ~w~n", [Assigned]),
    teaching_records(Teacher, Records),
    forall(member(record(Course, Term, Year), Records),
           (   section_count(Teacher, Course, Term, Year, Count),
               format("  Teaches ~w in ~w ~w (~w section(s))~n", [Course, Term, Year, Count])
           )),
    findall(Text, specialization_issue(Teacher, _, Text), Issues),
    print_list_or_none(Issues, 'VIOLATION', 'Compliant with the two-course specialization model.'),
    print_recommendations_for(Teacher, specialization_issue).
