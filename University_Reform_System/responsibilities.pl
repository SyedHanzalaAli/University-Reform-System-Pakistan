/* ==========================================================================
   FILE: responsibilities.pl     (MODULE D - Teacher Responsibilities & Assistants)

   1. WHAT THIS FILE DOES
      Verifies that teachers focus on teaching and academic guidance while
      dedicated assistant and oversight teams handle examination papers,
      invigilation, logistics, central script marking, moderation, quality
      assurance, and appeals.

   2. IMPORTANT PREDICATES
      - approved_role/2             : approved_role(Task, ExpectedRole)
      - responsibility_issue/3      : responsibility_issue(Uni, IssueId, Text)
      - responsibilities_compliant/1: responsibilities_compliant(Uni)
      - report_responsibilities/0   : prints Module D section of Menu Option 12

   3. FACTS VERSUS RULES
      - `approved_role/2` facts in this file encode the reform model's
        division of labour.
      - `duty_assigned/3` facts in `knowledge_base.pl` record who performs each
        task at a given university.
      - `responsibility_issue/3` rules compare actual vs. approved roles.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - Rule D1 uses negation as failure (`\+ duty_assigned(Uni, Task, _)`) to
        find tasks with no assigned role.
      - Rule D2 uses unification and inequality (`Actual \= Expected`) to catch
        tasks assigned to teachers instead of dedicated assistants.

   5. LOGIC IN PLAIN ENGLISH
      If a task is in `approved_role(Task, Expected)`:
        - If nobody is assigned to `Task` at `Uni`, report `unassigned_task(Task)`.
        - If `Actual` is assigned and `Actual \= Expected`, report
          `wrong_role(Task, Actual, Expected)`.
        - If a university assigns a task not in `approved_role/2`, report
          `task_not_in_policy(Task)` as requiring a university decision.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- responsibility_issue(conventional_uni, wrong_role(Task, Actual, Expected), _).
      Expected Output:
        Task = prepare_exam_papers, Actual = teacher, Expected = central_exam_team ;
        Task = invigilation,        Actual = teacher, Expected = exam_assistants ;
        Task = mark_answer_scripts, Actual = teacher, Expected = central_marking_assistants.

      Query 2:
        ?- responsibilities_compliant(reform_uni).
      Expected Output:
        true.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Why shouldn't teachers prepare and mark examinations for their own
          sections?
      A1: To prevent inconsistent exam standards across sections and let
          teachers focus on delivering lectures and academic guidance.
      Q2: What is the difference between `responsibilities.pl` (Module D) and
          `governance_finance.pl` (Module J)?
      A2: Module D checks teaching and examination roles (teachers, exam team,
          marking assistants, academic oversight), whereas Module J checks
          university-wide administrative offices (registrar, finance, labs,
          student affairs) and financial transparency.
   ========================================================================== */

% approved_role(Task, Role) - the approved owner of each task.
approved_role(deliver_lectures,    teacher).
approved_role(academic_guidance,   teacher).
approved_role(prepare_exam_papers, central_exam_team).
approved_role(invigilation,        exam_assistants).
approved_role(exam_logistics,      exam_assistants).
approved_role(mark_answer_scripts, central_marking_assistants).
approved_role(moderation,          academic_oversight).
approved_role(quality_assurance,   academic_oversight).
approved_role(academic_appeals,    academic_oversight).

% Rule D1: an approved task has nobody assigned.
responsibility_issue(Uni, unassigned_task(Task), Text) :-
    university(Uni, _),
    approved_role(Task, Expected),
    \+ duty_assigned(Uni, Task, _),
    format(atom(Text), "No one is assigned to '~w' (should be ~w).", [Task, Expected]).

% Rule D2: a task is assigned to the wrong role.
responsibility_issue(Uni, wrong_role(Task, Actual, Expected), Text) :-
    duty_assigned(Uni, Task, Actual),
    approved_role(Task, Expected),
    Actual \= Expected,
    format(atom(Text), "'~w' is done by ~w; the model assigns it to ~w.", [Task, Actual, Expected]).

% Rule D3: a task that the approved policy does not mention.
responsibility_issue(Uni, task_not_in_policy(Task), Text) :-
    duty_assigned(Uni, Task, Role),
    \+ approved_role(Task, _),
    format(atom(Text), "Task '~w' (by ~w) is not covered by the approved policy - requires university decision.", [Task, Role]).

responsibilities_compliant(Uni) :-
    university(Uni, _),
    \+ responsibility_issue(Uni, _, _).

/* --------------------------------------------------------------------------
   REPORT (part of menu option 12)
   -------------------------------------------------------------------------- */
report_responsibilities :-
    print_heading('MODULE D - Teacher and Assistant Responsibilities'),
    demo_data_notice,
    forall(university(Uni, Name),
           (   print_subheading(Name),
               findall(Text, responsibility_issue(Uni, _, Text), Issues),
               print_list_or_none(Issues, 'ISSUE', 'All teaching and examination duties are correctly assigned.'),
               print_recommendations_for(Uni, responsibility_issue)
           )).
