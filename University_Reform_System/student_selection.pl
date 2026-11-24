/* ==========================================================================
   FILE: student_selection.pl        (MODULE H - Student Teacher Selection)

   1. WHAT THIS FILE DOES
      Allows students to view available teachers for a course, select their
      preferred teacher, request a section transfer following an
      administratively defined procedure, and submit confidential teaching
      feedback while respecting class capacity.

   2. IMPORTANT PREDICATES
      - enrolled_count/2            : enrolled_count(Section, Count)
      - seats_remaining/2           : seats_remaining(Section, Seats)
      - available_teacher/4         : available_teacher(Course, Teacher, Section, Seats)
      - selection_decision/6        : selection_decision(Student, Course, Teacher, Status, Sec, Reason)
      - transfer_decision/5         : transfer_decision(Student, From, To, Status, Reason)
      - apply_transfer/3            : apply_transfer(Student, From, To)
      - teacher_feedback_summary/3  : teacher_feedback_summary(Teacher, Count, Avg)
      - report_student_selection/0  : prints Menu Option 4 report

   3. FACTS VERSUS RULES
      - Facts in `knowledge_base.pl`: `section/6`, `enrolled/2`,
        `selection_request/3`, `transfer_request/3`, `transfer_window/3`,
        `transfer_procedure_step/2`, and `confidential_feedback/3`.
      - Rules compute remaining seats using arithmetic (`Seats is Capacity - Count`)
        and evaluate selection and transfer requests step by step.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `enrolled_count/2` uses `aggregate_all(count, enrolled(_, Section), Count)`
        to count how many `enrolled/2` facts match `Section`.
      - `teacher_feedback_summary/3` uses `findall/3`, `length/2`, and
        `sum_list/2` to average ratings across all sections taught by a teacher.

   5. LOGIC IN PLAIN ENGLISH
      - Initial Selection: If the student is already enrolled in the course,
        they are told to use the transfer procedure. Otherwise, if their
        preferred teacher's section has `Seats > 0`, it is `approved`; if full
        (`Seats = 0`), it is `waitlisted` and alternative teachers with open
        seats are listed.
      - Transfer Procedure: Approved only if (1) student is in `From`,
        (2) `From` and `To` are the same course/term, (3) the transfer window
        is `open`, and (4) `To` has `Seats > 0`.
      - Confidential Feedback: `confidential_feedback(Section, Rating, Comment)`
        has no student-ID argument, guaranteeing anonymity by design.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- seats_remaining(cn301_a, S1), seats_remaining(cn301_c, S2).
      Expected Output:
        S1 = 0, S2 = 3.

      Query 2:
        ?- selection_decision(s10, cn301, t_ahmed, Status1, Sec1, _),
           selection_decision(s11, cn301, t_bilal, Status2, Sec2, _).
      Expected Output:
        Status1 = waitlisted, Sec1 = cn301_a,
        Status2 = approved,   Sec2 = cn301_c.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How is student feedback kept confidential in Prolog?
      A1: The predicate `confidential_feedback(SectionId, Rating, Comment)` has
          arity 3 and omits any StudentId argument. Because the student's ID is
          never stored in the fact, it can never be queried or leaked.
      Q2: Why is student `s09`'s transfer from `cn301_c` to `cn301_a` rejected?
      A2: Because `cn301_a` has capacity 4 and already has 4 enrolled students
          (`s01`-`s04`), so `seats_remaining(cn301_a, 0)` fails `section_has_space/1`.
   ========================================================================== */

% enrolled_count(?Section, -Count)
enrolled_count(Section, Count) :-
    section(Section, _, _, _, _, _),
    aggregate_all(count, enrolled(_, Section), Count).

% seats_remaining(?Section, -Seats)   Arithmetic: Seats is Capacity - Count.
seats_remaining(Section, Seats) :-
    section(Section, _, _, _, _, Capacity),
    enrolled_count(Section, Count),
    Seats is Capacity - Count.

section_has_space(Section) :-
    seats_remaining(Section, Seats),
    Seats > 0.

% available_teacher(?Course, ?Teacher, ?Section, -Seats)
% Teachers offering Course in the CURRENT term.
available_teacher(Course, Teacher, Section, Seats) :-
    current_term(Term, Year),
    section(Section, Course, Teacher, Term, Year, _),
    seats_remaining(Section, Seats).

% student_course_section(?Student, ?Course, ?Section) - current-term enrollment.
student_course_section(Student, Course, Section) :-
    current_term(Term, Year),
    enrolled(Student, Section),
    section(Section, Course, _, Term, Year, _).

/* --------------------------------------------------------------------------
   Initial teacher selection
   selection_decision(?Student, ?Course, ?Teacher, -Status, -Section, -Reason)
   -------------------------------------------------------------------------- */
selection_decision(Student, Course, Teacher, Status, Section, Reason) :-
    selection_request(Student, Course, Teacher),
    current_term(Term, Year),
    (   student_course_section(Student, Course, Existing)
    ->  Status = rejected, Section = Existing,
        Reason = 'already enrolled in this course - use the transfer procedure'
    ;   section(Found, Course, Teacher, Term, Year, _)
    ->  Section = Found,
        (   section_has_space(Found)
        ->  Status = approved,   Reason = 'seat available'
        ;   Status = waitlisted, Reason = 'section is full (capacity reached)'
        )
    ;   Status = rejected, Section = none,
        Reason = 'teacher has no section of this course in the current term'
    ).

% alternative_section(+Course, +Teacher, -OtherTeacher, -Section, -Seats)
% Other teachers of the same course who still have seats.
alternative_section(Course, Teacher, OtherTeacher, Section, Seats) :-
    available_teacher(Course, OtherTeacher, Section, Seats),
    OtherTeacher \= Teacher,
    Seats > 0.

/* --------------------------------------------------------------------------
   Teacher change (transfer)
   transfer_decision(?Student, ?From, ?To, -Status, -Reason)
   Conditions are checked in the order of the administrative procedure.
   -------------------------------------------------------------------------- */
transfer_decision(Student, From, To, Status, Reason) :-
    transfer_request(Student, From, To),
    (   \+ enrolled(Student, From)
    ->  Status = rejected, Reason = 'student is not enrolled in the source section'
    ;   \+ same_course(From, To)
    ->  Status = rejected, Reason = 'sections belong to different courses'
    ;   \+ transfer_window_open_for(From)
    ->  Status = rejected, Reason = 'transfer window is not open'
    ;   \+ section_has_space(To)
    ->  Status = rejected, Reason = 'destination section is full (capacity reached)'
    ;   Status = approved, Reason = 'all procedure conditions satisfied - awaiting office update'
    ).

same_course(SectionA, SectionB) :-
    section(SectionA, Course, _, Term, Year, _),
    section(SectionB, Course, _, Term, Year, _).

transfer_window_open_for(Section) :-
    section(Section, _, _, Term, Year, _),
    transfer_window(Term, Year, open).

% apply_transfer(+Student, +From, +To)
% OPTIONAL demo of a dynamic knowledge base: if approved, the enrollment fact
% is replaced.  (Not called by the menu, so the demo data stays unchanged.)
apply_transfer(Student, From, To) :-
    transfer_decision(Student, From, To, approved, _),
    retract(enrolled(Student, From)),
    assertz(enrolled(Student, To)).

/* --------------------------------------------------------------------------
   Confidential feedback summary (no student identities involved)
   -------------------------------------------------------------------------- */
teacher_feedback_summary(Teacher, Count, Average) :-
    teacher(Teacher, _),
    findall(Rating,
            ( section(Section, _, Teacher, _, _, _),
              confidential_feedback(Section, Rating, _) ),
            Ratings),
    length(Ratings, Count),
    Count > 0,
    sum_list(Ratings, Total),
    Average is float(Total) / Count.

/* --------------------------------------------------------------------------
   REPORT (menu option 4)
   -------------------------------------------------------------------------- */
report_student_selection :-
    print_heading('MODULE H - Teacher Availability and Student Selection'),
    demo_data_notice,
    current_term(Term, Year),
    format("  Current term: ~w ~w~n", [Term, Year]),
    print_subheading('Available teachers per course (current term)'),
    forall(course(Course, Title), report_course_availability(Course, Title)),
    print_subheading('Teacher selection requests'),
    forall(selection_decision(Student, Course, Teacher, Status, Section, Reason),
           report_selection(Student, Course, Teacher, Status, Section, Reason)),
    print_subheading('Transfer (teacher change) procedure'),
    forall(transfer_procedure_step(N, Step), format("  Step ~w: ~w~n", [N, Step])),
    print_subheading('Transfer requests'),
    forall(transfer_decision(Student, From, To, Status, Reason),
           format("  ~w: ~w -> ~w : ~w (~w)~n", [Student, From, To, Status, Reason])),
    print_subheading('Confidential teaching feedback (aggregated, anonymous)'),
    forall(teacher(Teacher, Name),
           (   teacher_feedback_summary(Teacher, Count, Average)
           ->  format("  ~w: ~w response(s), average rating ~2f / 5~n", [Name, Count, Average])
           ;   format("  ~w: no feedback recorded~n", [Name])
           )).

report_course_availability(Course, Title) :-
    findall(Teacher-Section-Seats, available_teacher(Course, Teacher, Section, Seats), Options),
    (   Options == []
    ->  format("  ~w (~w): no sections this term~n", [Title, Course])
    ;   format("  ~w (~w):~n", [Title, Course]),
        forall(member(Teacher-Section-Seats, Options),
               (   teacher(Teacher, Name),
                   section(Section, _, _, _, _, Capacity),
                   format("      ~w  section ~w  capacity ~w  seats left ~w~n",
                          [Name, Section, Capacity, Seats])
               ))
    ).

report_selection(Student, Course, Teacher, Status, Section, Reason) :-
    student(Student, Name),
    format("  ~w (~w) wants ~w for ~w -> ~w [~w] (~w)~n",
           [Name, Student, Teacher, Course, Status, Section, Reason]),
    (   Status == waitlisted
    ->  forall(alternative_section(Course, Teacher, Other, OtherSection, Seats),
               format("      Alternative: ~w, section ~w, ~w seat(s) left~n", [Other, OtherSection, Seats]))
    ;   true
    ).
