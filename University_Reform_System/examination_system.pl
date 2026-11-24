/* ==========================================================================
   FILE: examination_system.pl       (MODULE E - Centralized Examination System)

   1. WHAT THIS FILE DOES
      Verifies that every section of a course in a given examination session
      receives ONE common examination paper prepared by the central examination
      team, is marked with ONE common marking scheme (with question-level
      marks, expected answers, and partial-credit rules), is marked centrally
      by central marking assistants rather than individual section teachers,
      and undergoes moderation.

   2. IMPORTANT PREDICATES
      - session_section/2           : session_section(Session, Section)
      - papers_used/2               : papers_used(Session, DistinctPapers)
      - schemes_used/2              : schemes_used(Session, DistinctSchemes)
      - exam_arrangement_issue/3    : exam_arrangement_issue(Session, IssueId, Text)
      - centralized_exam_verified/1 : centralized_exam_verified(Session)
      - marking_issue/3             : marking_issue(Session, IssueId, Text)
      - central_marking_verified/1  : central_marking_verified(Session)
      - scheme_total_marks/2        : scheme_total_marks(Scheme, TotalMarks)
      - report_central_exams/0      : prints Menu Option 5 report
      - report_marking/0            : prints Menu Option 6 report

   3. FACTS VERSUS RULES
      - Policy facts here (`central_preparer/1`, `central_marker/1`) name the
        approved central roles.
      - Facts in `knowledge_base.pl` (`exam_session/4`, `section_exam_paper/3`,
        `paper_prepared_by/2`, `section_marking_scheme/3`, `scheme_question/5`,
        `scripts_marked_by/3`, `moderation_record/2`) record each session.
      - Rules E1-E4 check paper arrangements; Rules M1-M7 check marking schemes,
        central marking, and moderation.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `session_section(Session, Section)` joins `exam_session(Session, Course, Term, Year)`
        with `section(Section, Course, _, Term, Year, _)` by unifying `Course`,
        `Term`, and `Year`. That ensures different examination sessions and
        different academic years are always treated separately.
      - `papers_used/2` and `schemes_used/2` use `findall/3` + `sort/2` to collect
        unique papers/schemes used across sections of a session.

   5. LOGIC IN PLAIN ENGLISH
      - If `length(Papers, N)` with `N > 1`, different sections received
        different exam papers -> violation (`multiple_papers(Papers)`).
      - If any paper or scheme was prepared by a teacher instead of
        `central_exam_team`, or marked by a teacher instead of
        `central_marking_assistants`, a violation is reported.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- papers_used(cn301_fall2025, P1), papers_used(db201_fall2025, P2).
      Expected Output:
        P1 = [cn_paper_2025],
        P2 = [db_paper_ayesha, db_paper_usman].

      Query 2:
        ?- centralized_exam_verified(cn301_fall2025),
           central_marking_verified(cn301_fall2025).
      Expected Output:
        true.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How does your system prevent the 2020 Computer Networks paper from
          conflicting with the 2025 Computer Networks paper?
      A1: `session_section/2` unifies `Course`, `Term`, AND `AcademicYear` from
          `exam_session/4` and `section/6`. Every rule takes `Session` as its
          first argument, isolating each session and academic year.
      Q2: Why does `db201_fall2025` fail both Menu Option 5 and Menu Option 6?
      A2: Because `db201_a` and `db201_b` use two different papers prepared by
          their respective teachers (`t_ayesha` and `t_usman`), two different
          marking schemes (`db_scheme_usman` has no question breakdown), are
          marked locally by the teachers, and have no moderation record.
   ========================================================================== */

% The role that must prepare papers and schemes, and the role that must mark.
central_preparer(central_exam_team).
central_marker(central_marking_assistants).

% session_section(?Session, ?Section)
% A section sits a session if it is the same course, term and academic year.
session_section(Session, Section) :-
    exam_session(Session, Course, Term, Year),
    section(Section, Course, _, Term, Year, _).

session_has_sections(Session) :-
    exam_session(Session, _, _, _),
    once(session_section(Session, _)).

% papers_used(+Session, -Papers): distinct papers given to the sections.
papers_used(Session, Papers) :-
    findall(Paper,
            ( session_section(Session, Section),
              section_exam_paper(Session, Section, Paper) ),
            AllPapers),
    sort(AllPapers, Papers).

% schemes_used(+Session, -Schemes): distinct marking schemes used.
schemes_used(Session, Schemes) :-
    findall(Scheme,
            ( session_section(Session, Section),
              section_marking_scheme(Session, Section, Scheme) ),
            AllSchemes),
    sort(AllSchemes, Schemes).

/* --------------------------------------------------------------------------
   Examination paper arrangement (menu option 5)
   -------------------------------------------------------------------------- */

% Rule E1: different sections of the same course received different papers.
exam_arrangement_issue(Session, multiple_papers(Papers), Text) :-
    session_has_sections(Session),
    papers_used(Session, Papers),
    length(Papers, N),
    N > 1,
    format(atom(Text), "~w different papers used across sections: ~w.", [N, Papers]).

% Rule E2: a section has no paper recorded (missing information).
exam_arrangement_issue(Session, section_without_paper(Section), Text) :-
    session_section(Session, Section),
    \+ section_exam_paper(Session, Section, _),
    format(atom(Text), "No examination paper recorded for section ~w (unknown).", [Section]).

% Rule E3: a paper was prepared by someone other than the central team.
exam_arrangement_issue(Session, paper_not_central(Paper, Preparer), Text) :-
    papers_used(Session, Papers),
    member(Paper, Papers),
    paper_prepared_by(Paper, Preparer),
    \+ central_preparer(Preparer),
    format(atom(Text), "Paper ~w was prepared by ~w, not the central examination team.", [Paper, Preparer]).

% Rule E4: preparer of a paper is unknown.
exam_arrangement_issue(Session, paper_preparer_unknown(Paper), Text) :-
    papers_used(Session, Papers),
    member(Paper, Papers),
    \+ paper_prepared_by(Paper, _),
    format(atom(Text), "Preparer of paper ~w is not recorded (unknown).", [Paper]).

centralized_exam_verified(Session) :-
    session_has_sections(Session),
    \+ exam_arrangement_issue(Session, _, _).

/* --------------------------------------------------------------------------
   Marking consistency (menu option 6)
   -------------------------------------------------------------------------- */

% Rule M1: more than one marking scheme for the same session.
marking_issue(Session, multiple_schemes(Schemes), Text) :-
    session_has_sections(Session),
    schemes_used(Session, Schemes),
    length(Schemes, N),
    N > 1,
    format(atom(Text), "~w different marking schemes used: ~w.", [N, Schemes]).

% Rule M2: a section has no marking scheme recorded.
marking_issue(Session, section_without_scheme(Section), Text) :-
    session_section(Session, Section),
    \+ section_marking_scheme(Session, Section, _),
    format(atom(Text), "No marking scheme recorded for section ~w (unknown).", [Section]).

% Rule M3: scheme not prepared by the central examination team.
marking_issue(Session, scheme_not_central(Scheme, Preparer), Text) :-
    schemes_used(Session, Schemes),
    member(Scheme, Schemes),
    scheme_prepared_by(Scheme, Preparer),
    \+ central_preparer(Preparer),
    format(atom(Text), "Marking scheme ~w was prepared by ~w, not the central team.", [Scheme, Preparer]).

% Rule M4: scheme has no question-level marks / expected answers recorded.
marking_issue(Session, scheme_incomplete(Scheme), Text) :-
    schemes_used(Session, Schemes),
    member(Scheme, Schemes),
    \+ scheme_question(Scheme, _, _, _, _),
    format(atom(Text), "Marking scheme ~w has no question marks, expected answers or partial-credit rules.", [Scheme]).

% Rule M5: scripts marked by someone other than central marking assistants.
marking_issue(Session, local_marking(Section, Marker), Text) :-
    session_section(Session, Section),
    scripts_marked_by(Session, Section, Marker),
    \+ central_marker(Marker),
    format(atom(Text), "Scripts of section ~w were marked by ~w instead of central marking assistants.", [Section, Marker]).

% Rule M6: who marked a section is unknown.
marking_issue(Session, marker_unknown(Section), Text) :-
    session_section(Session, Section),
    \+ scripts_marked_by(Session, Section, _),
    format(atom(Text), "Marker for section ~w is not recorded (unknown).", [Section]).

% Rule M7: no moderation record.
marking_issue(Session, no_moderation_record,
              'No moderation record found for this session.') :-
    session_has_sections(Session),
    \+ moderation_record(Session, _).

central_marking_verified(Session) :-
    session_has_sections(Session),
    \+ marking_issue(Session, _, _).

% scheme_has_questions(+Scheme) - succeeds ONCE if at least one question exists.
scheme_has_questions(Scheme) :-
    once(scheme_question(Scheme, _, _, _, _)).

% scheme_total_marks(+Scheme, -Total)   Arithmetic with sum_list.
scheme_total_marks(Scheme, Total) :-
    findall(Marks, scheme_question(Scheme, _, Marks, _, _), MarkList),
    sum_list(MarkList, Total).

/* --------------------------------------------------------------------------
   REPORTS
   -------------------------------------------------------------------------- */
report_central_exams :-
    print_heading('MODULE E - Centralized Examination Arrangements'),
    demo_data_notice,
    forall(exam_session(Session, Course, Term, Year),
           report_session_papers(Session, Course, Term, Year)).

report_session_papers(Session, Course, Term, Year) :-
    format(atom(Title), "Session ~w (~w, ~w ~w)", [Session, Course, Term, Year]),
    print_subheading(Title),
    (   session_has_sections(Session)
    ->  forall(session_section(Session, Section),
               (   section(Section, _, Teacher, _, _, _),
                   ( section_exam_paper(Session, Section, Paper) -> true ; Paper = 'NOT RECORDED' ),
                   format("  Section ~w (teacher ~w) -> paper ~w~n", [Section, Teacher, Paper])
               )),
        findall(Text, exam_arrangement_issue(Session, _, Text), Issues),
        print_list_or_none(Issues, 'ISSUE', 'ONE common paper prepared centrally for every section.'),
        print_recommendations_for(Session, exam_arrangement_issue)
    ;   print_bullet('No section records for this session - arrangement cannot be checked (unknown).')
    ).

report_marking :-
    print_heading('MODULE E - Examination Marking Consistency'),
    demo_data_notice,
    forall(exam_session(Session, Course, Term, Year),
           report_session_marking(Session, Course, Term, Year)).

report_session_marking(Session, Course, Term, Year) :-
    format(atom(Title), "Session ~w (~w, ~w ~w)", [Session, Course, Term, Year]),
    print_subheading(Title),
    (   session_has_sections(Session)
    ->  forall(session_section(Session, Section),
               (   ( section_marking_scheme(Session, Section, Scheme) -> true ; Scheme = 'NOT RECORDED' ),
                   ( scripts_marked_by(Session, Section, Marker) -> true ; Marker = 'NOT RECORDED' ),
                   format("  Section ~w -> scheme ~w, marked by ~w~n", [Section, Scheme, Marker])
               )),
        schemes_used(Session, Schemes),
        forall(( member(Scheme, Schemes), scheme_has_questions(Scheme) ),
               (   scheme_total_marks(Scheme, Total),
                   format("  Scheme ~w: total ~w marks~n", [Scheme, Total]),
                   forall(scheme_question(Scheme, Q, Marks, Expected, Partial),
                          format("      Q~w (~w marks) expected: ~w | partial credit: ~w~n",
                                 [Q, Marks, Expected, Partial]))
               )),
        findall(Text, marking_issue(Session, _, Text), Issues),
        print_list_or_none(Issues, 'ISSUE', 'Common scheme, central marking and moderation verified.'),
        print_recommendations_for(Session, marking_issue)
    ;   print_bullet('No section records for this session - marking cannot be checked (unknown).')
    ).
