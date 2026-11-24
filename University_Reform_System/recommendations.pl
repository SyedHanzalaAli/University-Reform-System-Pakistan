/* ==========================================================================
   FILE: recommendations.pl    (Reform recommendations + comprehensive report)

   1. WHAT THIS FILE DOES
      1. Maps every diagnosed issue ID across Modules A-J to an actionable
         reform recommendation via `recommendation(IssuePattern, Text)`.
      2. Provides a single unified inference rule `reform_issue(Area, Subject, Id, Text)`
         that queries every module's diagnostic rules across the entire KB.
      3. Explicitly lists policy decisions NOT specified by the approved model
         (`open_policy_decision/1`) so the system never invents policy.
      4. Generates the Comprehensive Reform Report (Menu Option 14).

   2. IMPORTANT PREDICATES
      - recommendation/2             : recommendation(IssuePattern, AdviceText)
      - print_recommendations_for/2  : print_recommendations_for(Subject, IssuePred)
      - reform_area/3                : reform_area(AreaId, IssuePredicate, Title)
      - reform_issue/4               : reform_issue(Area, Subject, IssueId, Text)
      - open_policy_decision/1       : open_policy_decision(Description)
      - report_comprehensive/0       : prints Menu Option 14 report

   3. FACTS VERSUS RULES
      - `recommendation/2`, `reform_area/3`, and `open_policy_decision/1` are
        facts that structure the expert system's advice and meta-knowledge.
      - `reform_issue/4` and `print_recommendations_for/2` are meta-rules that
        use `call/4` to invoke each module's diagnostic predicate dynamically.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `recommendation/2` uses anonymous variables (`_`) in compound terms,
        such as `recommendation(compulsory_attendance(_), '...')`. When Prolog
        unifies `compulsory_attendance(lecture)` or `compulsory_attendance(tutorial)`
        with `compulsory_attendance(_)`, unification succeeds for any session type.
      - `reform_issue/4` iterates over `reform_area(Area, IssuePredicate, _)`
        and calls `call(IssuePredicate, Subject, IssueId, Text)`.

   5. LOGIC IN PLAIN ENGLISH
      - Whenever any module diagnoses an issue `IssueId`, `recommendation(IssueId, Text)`
        looks up the corresponding reform action.
      - `print_recommendations_for/2` collects all matching recommendations
        with `findall/3`, removes duplicates with `sort/2`, and prints each one.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- recommendation(qualifications_only, Advice).
      Expected Output:
        Advice = 'Add a demonstration lecture and a teaching/communication evaluation to hiring.'

      Query 2:
        ?- aggregate_all(count, reform_issue(_, _, _, _), TotalIssues).
      Expected Output:
        TotalIssues = 42.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How does `recommendation(compulsory_attendance(_), Text)` match
          `compulsory_attendance(lecture)`?
      A1: Through Prolog UNIFICATION: the anonymous variable `_` inside the
          compound term unifies with any atom (`lecture`, `tutorial`, etc.).
      Q2: Why did you include `open_policy_decision/1`?
      A2: Because an expert system must not silently invent policies that were
          not approved (such as resit rules for attempted-but-failed exams).
          Instead, it flags them as decisions requiring university approval.
   ========================================================================== */

/* --------------------------------------------------------------------------
   recommendation(IssuePattern, RecommendationText)
   -------------------------------------------------------------------------- */
% Module A
recommendation(compulsory_attendance(_),       'Remove compulsory attendance for all lectures; students decide whether to attend.').
recommendation(minimum_attendance_percentage,  'Abolish minimum attendance percentages.').
recommendation(attendance_reduces_marks,       'Stop deducting marks for missed lectures.').
recommendation(attendance_blocks_exams,        'Never bar students from examinations because of attendance.').
recommendation(restricted_learning_resources,  'Allow students to learn from any resource: lectures, textbooks, YouTube, ChatGPT, etc.').
recommendation(prohibited_assessment(_),       'Remove homework, random quizzes, unannounced tests and take-home assessments.').
recommendation(no_scheduled_supervised_exams,  'Assess through scheduled, supervised physical examinations.').
% Module B
recommendation(qualifications_only,            'Add a demonstration lecture and a teaching/communication evaluation to hiring.').
recommendation(missing_criterion(_),           'Include every approved hiring criterion: qualification, subject test, demo lecture, communication (and experience where appropriate).').
% Module C
recommendation(wrong_number_of_assigned_courses(_), 'Give each teacher exactly two assigned courses (one Fall, one Spring).').
recommendation(missing_term_assignment(_),     'Assign one course for Fall and one course for Spring.').
recommendation(several_courses_in_term(_),     'Keep only one assigned course per regular term.').
recommendation(unrelated_course(_, _, _),      'Reassign unrelated courses to teachers who specialise in them.').
recommendation(wrong_term(_, _, _),            'Teach each assigned course in its assigned term (summer repeats allowed).').
% Module D
recommendation(unassigned_task(_),             'Assign the task to its approved role (assistants / academic oversight).').
recommendation(wrong_role(_, _, _),            'Move examination and administrative work from teachers to dedicated assistants.').
recommendation(task_not_in_policy(_),          'Ask the university to decide who owns this task.').
% Module E
recommendation(multiple_papers(_),             'Use ONE common paper prepared by the central examination team for every section.').
recommendation(section_without_paper(_),       'Record which paper every section sat.').
recommendation(paper_not_central(_, _),        'Papers must be prepared by the central examination team, not individual teachers.').
recommendation(paper_preparer_unknown(_),      'Record who prepared each examination paper.').
recommendation(multiple_schemes(_),            'Use ONE common marking scheme for every script in the session.').
recommendation(section_without_scheme(_),      'Record the marking scheme used for every section.').
recommendation(scheme_not_central(_, _),       'Marking schemes must be prepared by the central examination team.').
recommendation(scheme_incomplete(_),           'Marking schemes must state marks per question, expected answers and partial-credit criteria.').
recommendation(local_marking(_, _),            'Mark scripts centrally using central marking assistants.').
recommendation(marker_unknown(_),              'Record who marked each section''s scripts.').
recommendation(no_moderation_record,           'Carry out and record moderation by academic oversight.').
% Module F
recommendation(thresholds_not_approved,        'The examination team must approve grade thresholds for this session before grading.').
recommendation(invalid_threshold_order,        'Correct the thresholds so that A > B > C > D > F.').
recommendation(difficulty_review_missing,      'Record the examination team''s difficulty review that justifies the thresholds.').
% Module G
recommendation(exam_clash(_, _, _, _),         'Move one of the clashing exams to a different day or slot.').
recommendation(invalid_route(_, _, _),         'Record each module choice as either modular or linear.').
recommendation(over_capacity(_, _),            'Increase capacity or spread linear/deferred exams across more slots.').
recommendation(capacity_unknown,               'Record the seating capacity of each extended-period week.').
recommendation(missing_choice(_, _),           'Collect each student''s modular/linear choice for every module.').
% Module J
recommendation(unassigned_duty(_),             'Assign a single responsible office for the duty.').
recommendation(unclear_responsibility(_, _),   'Name ONE accountable owner; others may support.').
recommendation(no_budget_information(_),       'Publish the approved budget.').
recommendation(missing_information(_, _),      'Publish the missing allocation or expenditure figure.').
recommendation(variance_needs_explanation(_, _), 'Publish an explanation for the difference between approved and actual spending.').
recommendation(undocumented_expenditure(_, _), 'Publish supporting documentation for the expenditure.').

% print_recommendations_for(+Subject, +IssuePredicate)
% call/4 calls e.g. academic_issue(Subject, Id, _) and collects matching advice.
print_recommendations_for(Subject, IssuePredicate) :-
    findall(Text,
            ( call(IssuePredicate, Subject, IssueId, _),
              recommendation(IssueId, Text) ),
            AllTexts),
    sort(AllTexts, Texts),
    print_all_tagged(Texts, 'RECOMMEND').

/* --------------------------------------------------------------------------
   One entry point for every issue in the system.
   reform_area(AreaId, IssuePredicate, Title)
   -------------------------------------------------------------------------- */
reform_area(attendance_and_learning, academic_issue,         'A. Attendance and learning').
reform_area(teacher_recruitment,     recruitment_issue,      'B. Teacher recruitment').
reform_area(course_specialization,   specialization_issue,   'C. Teacher course specialization').
reform_area(responsibilities,        responsibility_issue,   'D. Teacher and assistant responsibilities').
reform_area(central_examination,     exam_arrangement_issue, 'E. Centralized examination papers').
reform_area(marking_consistency,     marking_issue,          'E. Marking consistency').
reform_area(grading,                 grading_issue,          'F. Standards-based grading').
reform_area(exam_scheduling,         scheduling_issue,       'G. Modular/linear scheduling').
reform_area(governance,              governance_issue,       'J. Governance').
reform_area(finance,                 finance_issue,          'J. Financial transparency').

% reform_issue(?Area, ?Subject, ?IssueId, ?Text)
reform_issue(Area, Subject, IssueId, Text) :-
    reform_area(Area, IssuePredicate, _),
    call(IssuePredicate, Subject, IssueId, Text).

/* --------------------------------------------------------------------------
   Decisions NOT specified by the approved policy (never invented by us).
   -------------------------------------------------------------------------- */
open_policy_decision('Resit opportunity after an ATTEMPTED modular/linear exam that is below the standard.').
open_policy_decision('What happens if a student misses a linear exam or a deferred exam.').
open_policy_decision('Whether any attendance rule applies to practical/lab components (never to lectures).').
open_policy_decision('How the four module results combine into the final course grade.').
open_policy_decision('Exact linear/deferred week per module (default: module N in week 20+N, configurable).').
open_policy_decision('Real rate per student (demo uses a fictional Rs. 1,000) and whether course weighting is used.').
open_policy_decision('Real module pass standards (demo uses a hypothetical 40 marks).').

/* --------------------------------------------------------------------------
   REPORT (menu option 14)
   -------------------------------------------------------------------------- */
report_comprehensive :-
    print_heading('COMPREHENSIVE UNIVERSITY REFORM REPORT'),
    demo_data_notice,
    print_subheading('Issues found per area'),
    forall(reform_area(Area, _, Title),
           (   aggregate_all(count, reform_issue(Area, _, _, _), Count),
               format("  ~w: ~w issue(s)~n", [Title, Count])
           )),
    aggregate_all(count, reform_issue(_, _, _, _), Total),
    format("  TOTAL: ~w issue(s)~n", [Total]),
    print_subheading('Detailed findings'),
    forall(reform_area(Area, _, Title),
           (   findall(Subject-Text, reform_issue(Area, Subject, _, Text), Found),
               (   Found == []
               ->  true
               ;   format("  ~w~n", [Title]),
                   forall(member(Subject-Text, Found),
                          format("      [~w] ~w~n", [Subject, Text]))
               )
           )),
    print_subheading('Teacher selection (Module H) summary'),
    forall(selection_decision(Student, Course, Teacher, Status, _, Reason),
           format("  ~w -> ~w for ~w: ~w (~w)~n", [Student, Teacher, Course, Status, Reason])),
    print_subheading('Compensation (Module I) summary'),
    current_term(Term, Year),
    forall(teacher(Teacher, Name),
           (   teacher_term_payment(Teacher, Term, Year, Pay),
               format("  ~w: Rs. ~D (~w ~w, fictional rate)~n", [Name, Pay, Term, Year])
           )),
    print_subheading('Reform recommendations (unique)'),
    findall(Text, ( reform_issue(_, _, Id, _), recommendation(Id, Text) ), AllRecs),
    sort(AllRecs, Recs),
    print_all_tagged(Recs, 'RECOMMEND'),
    print_subheading('Model university (reform_uni) compliance'),
    report_compliance_line('Attendance and assessment', academic_policy_compliant(reform_uni)),
    report_compliance_line('Recruitment process', recruitment_compliant(reform_hiring)),
    report_compliance_line('Teacher/assistant duties', responsibilities_compliant(reform_uni)),
    report_compliance_line('Governance ownership', governance_compliant(reform_uni)),
    report_compliance_line('Central exam cn301_fall2025', centralized_exam_verified(cn301_fall2025)),
    report_compliance_line('Central marking cn301_fall2025', central_marking_verified(cn301_fall2025)),
    report_compliance_line('Academic calendar 16+4 weeks', calendar_valid),
    print_subheading('Decisions requiring university approval'),
    forall(open_policy_decision(Decision), print_bullet(Decision)).

report_compliance_line(Label, Goal) :-
    (   call(Goal) -> Result = 'YES' ; Result = 'NO' ),
    format("  ~w: ~w~n", [Label, Result]).
