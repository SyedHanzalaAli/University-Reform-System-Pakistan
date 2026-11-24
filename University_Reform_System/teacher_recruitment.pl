/* ==========================================================================
   FILE: teacher_recruitment.pl         (MODULE B - Teacher Recruitment)

   1. WHAT THIS FILE DOES
      1. Diagnoses whether a university RECRUITMENT PROCESS evaluates both
         subject expertise and actual teaching ability (not qualifications alone).
      2. Evaluates individual CANDIDATES against the 5 approved criteria:
         (1) relevant academic qualification, (2) subject knowledge test,
         (3) demonstration lecture, (4) teaching ability & communication, and
         (5) practical experience where appropriate.

   2. IMPORTANT PREDICATES
      - criterion_required/2      : criterion_required(Process, Criterion)
      - missing_criterion/2       : missing_criterion(Process, Criterion)
      - recruitment_issue/3       : recruitment_issue(Process, IssueId, Text)
      - recruitment_compliant/1   : recruitment_compliant(Process)
      - candidate_check/3         : candidate_check(Candidate, Criterion, Result)
      - candidate_decision/2      : candidate_decision(Candidate, Decision)
      - report_recruitment/0      : prints Menu Option 2 report

   3. FACTS VERSUS RULES
      - Policy facts here (`required_hiring_criterion/1`,
        `teaching_ability_criterion/1`) define what every hiring process needs.
      - Facts in `knowledge_base.pl` (`recruitment_process/2`,
        `recruitment_criterion/2`, `candidate/3`, `candidate_score/3`, etc.)
        store the processes and candidate records.
      - Rules infer process weaknesses and candidate hiring decisions.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `criterion_required/2` uses two clauses (Prolog DISJUNCTION) so that
        `practical_experience` is required only when
        `process_requires_experience(Process, MinYears)` exists in the KB.
      - `candidate_decision/2` uses an if-then-else chain (`-> ;`) to classify
        a candidate into `not_recommended`, `incomplete_information`, or
        `recommended`.

   5. LOGIC IN PLAIN ENGLISH
      - A recruitment process has the `qualifications_only` issue if it checks
        `academic_qualification` but does NOT check any teaching-ability
        criterion (`demonstration_lecture` or `teaching_communication`).
      - A candidate is `recommended` only if every required criterion passes.
        If any criterion fails (e.g., Dr. Kamran's demo lecture is 4/10 < 6),
        the candidate is `not_recommended`. If no criterion fails but a score
        is missing (e.g., Mr. Imran), the result is `incomplete_information`.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- recruitment_issue(conv_hiring, qualifications_only, Text).
      Expected Output:
        Text = 'Evaluates academic qualifications but ignores teaching ability.'

      Query 2:
        ?- candidate_decision(c_sana, D1), candidate_decision(c_kamran, D2),
           candidate_decision(c_imran, D3).
      Expected Output:
        D1 = recommended,
        D2 = not_recommended,
        D3 = incomplete_information.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Why is Dr. Kamran not recommended even though he has a PhD and 9/10
          on the subject knowledge test?
      A1: Because his demonstration lecture (4/10) and teaching communication
          (5/10) are below the configurable pass mark (6/10), and his 1 year
          of practical experience is below the required 2 years.
      Q2: How did you represent "relevant professional or practical experience
          where appropriate"?
      A2: Using two clauses for `criterion_required/2`: practical experience is
          only required if `process_requires_experience(Process, MinYears)` is
          asserted for that recruitment process.
   ========================================================================== */

% Criteria every process must contain.
required_hiring_criterion(academic_qualification).
required_hiring_criterion(subject_knowledge_test).
required_hiring_criterion(demonstration_lecture).
required_hiring_criterion(teaching_communication).

% Criteria that measure TEACHING ABILITY.
teaching_ability_criterion(demonstration_lecture).
teaching_ability_criterion(teaching_communication).

% criterion_required(?Process, ?Criterion)
% Disjunction expressed as two clauses: a criterion is required if it is a
% general requirement OR it is practical experience for a process that needs it.
criterion_required(Process, Criterion) :-
    recruitment_process(Process, _),
    required_hiring_criterion(Criterion).
criterion_required(Process, practical_experience) :-
    process_requires_experience(Process, _).

% missing_criterion(?Process, ?Criterion)
missing_criterion(Process, Criterion) :-
    criterion_required(Process, Criterion),
    \+ recruitment_criterion(Process, Criterion).

/* --------------------------------------------------------------------------
   Process diagnosis
   -------------------------------------------------------------------------- */

% Rule B1: qualifications are checked but NO teaching-ability criterion is.
recruitment_issue(Process, qualifications_only,
                  'Evaluates academic qualifications but ignores teaching ability.') :-
    recruitment_criterion(Process, academic_qualification),
    \+ ( teaching_ability_criterion(Criterion),
         recruitment_criterion(Process, Criterion) ).

% Rule B2: a required criterion is missing.
recruitment_issue(Process, missing_criterion(Criterion), Text) :-
    missing_criterion(Process, Criterion),
    format(atom(Text), "Required hiring criterion '~w' is not part of the process.", [Criterion]).

recruitment_compliant(Process) :-
    recruitment_process(Process, _),
    \+ recruitment_issue(Process, _, _).

/* --------------------------------------------------------------------------
   Candidate evaluation
   -------------------------------------------------------------------------- */

% candidate_check(?Candidate, ?Criterion, -Result)
candidate_check(Candidate, Criterion, Result) :-
    candidate(Candidate, _, Process),
    criterion_required(Process, Criterion),
    criterion_result(Candidate, Process, Criterion, Result).

% Qualification: relevant -> passed, not relevant -> failed, none -> unknown.
criterion_result(Candidate, _Process, academic_qualification, Result) :-
    (   candidate_qualification(Candidate, _, relevant)     -> Result = passed
    ;   candidate_qualification(Candidate, _, not_relevant) -> Result = failed
    ;   Result = unknown
    ).

% Scored criteria (subject test, demo lecture, communication) use pass marks.
criterion_result(Candidate, _Process, Criterion, Result) :-
    hiring_pass_mark(Criterion, PassMark),
    (   candidate_score(Candidate, Criterion, Score)
    ->  (   Score >= PassMark -> Result = passed ; Result = failed )
    ;   Result = unknown
    ).

% Practical experience: compared with the process minimum.
criterion_result(Candidate, Process, practical_experience, Result) :-
    process_requires_experience(Process, MinimumYears),
    (   candidate_experience_years(Candidate, Years)
    ->  (   Years >= MinimumYears -> Result = passed ; Result = failed )
    ;   Result = unknown
    ).

% candidate_decision(?Candidate, -Decision)
% If-then-else chain: any failure -> not recommended; otherwise any unknown ->
% incomplete information; otherwise recommended.
candidate_decision(Candidate, Decision) :-
    candidate(Candidate, _, _),
    (   candidate_check(Candidate, _, failed)  -> Decision = not_recommended
    ;   candidate_check(Candidate, _, unknown) -> Decision = incomplete_information
    ;   Decision = recommended
    ).

/* --------------------------------------------------------------------------
   REPORT (menu option 2)
   -------------------------------------------------------------------------- */
report_recruitment :-
    print_heading('MODULE B - Teacher Recruitment Evaluation'),
    demo_data_notice,
    forall(recruitment_process(Process, Uni), report_process(Process, Uni)),
    print_subheading('Candidate evaluation'),
    forall(candidate(Candidate, Name, Process), report_candidate(Candidate, Name, Process)).

report_process(Process, Uni) :-
    university(Uni, UniName),
    format(atom(Title), "Process ~w (~w)", [Process, UniName]),
    print_subheading(Title),
    findall(C, recruitment_criterion(Process, C), Criteria),
    format("  Criteria used: ~w~n", [Criteria]),
    findall(Text, recruitment_issue(Process, _, Text), Issues),
    print_list_or_none(Issues, 'ISSUE', 'Process evaluates both expertise and teaching ability.'),
    print_recommendations_for(Process, recruitment_issue).

report_candidate(Candidate, Name, Process) :-
    candidate_decision(Candidate, Decision),
    format("  ~w (process ~w) -> ~w~n", [Name, Process, Decision]),
    forall(candidate_check(Candidate, Criterion, Result),
           format("      ~w: ~w~n", [Criterion, Result])).
