/* ==========================================================================
   FILE: governance_finance.pl   (MODULE J - Financial Transparency & Governance)

   1. WHAT THIS FILE DOES
      1. Governance: checks that all 7 university governance duties (teaching,
         curriculum coordination, examination administration, student records,
         financial management, laboratory maintenance, student complaints) have
         exactly ONE clear responsible office.
      2. Financial Transparency: checks whether approved budget allocations,
         actual expenditures, and supporting documentation exist across all 7
         categories (faculty salaries, administration, laboratories, research,
         libraries, student facilities, infrastructure), compares approved vs.
         actual figures, and flags missing data as UNKNOWN without ever
         inferring corruption or misconduct.

   2. IMPORTANT PREDICATES
      - governance_duty/1       : lists the 7 required governance duties
      - budget_category/1       : lists the 7 financial categories
      - duty_owners/3           : duty_owners(Uni, Duty, SortedOwners)
      - governance_issue/3      : governance_issue(Uni, IssueId, Text)
      - governance_compliant/1  : governance_compliant(Uni)
      - budget_available/2      : budget_available(Uni, Year)
      - finance_status/4        : finance_status(Uni, Year, Category, Status)
      - documentation_status/4  : documentation_status(Uni, Year, Category, Status)
      - finance_issue/3         : finance_issue(Uni, IssueId, Text)
      - report_governance/0     : prints Module J section of Menu Option 12
      - report_finance/0        : prints Menu Option 13 report

   3. FACTS VERSUS RULES
      - Facts here (`governance_duty/1`, `budget_category/1`, `missing_status/1`)
        define the categories to audit.
      - Facts in `knowledge_base.pl` (`duty_owner/3`, `approved_allocation/4`,
        `actual_expenditure/4`, `expenditure_documented/4`,
        `variance_review_percent/1`) hold the fictional records.
      - Rules classify each duty and budget category.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `duty_owners/3` collects all offices assigned to a duty into a list:
          * Empty list `[]` -> `unassigned_duty(Duty)`.
          * Length `N > 1`  -> `unclear_responsibility(Duty, Owners)`.
      - `finance_status/4` checks whether `approved_allocation/4` and
        `actual_expenditure/4` exist; if both exist, `variance_status/3`
        computes `Percent is round((Actual - Approved) * 100 / Approved)`.

   5. LOGIC IN PLAIN ENGLISH
      - Sound Epistemic Reasoning: In KRR, absence of a record is NOT proof of
        wrongdoing. When `actual_expenditure` for `research` is missing at
        `reform_uni`, the rule produces `unknown_actual_expenditure` and states
        "information gap, NOT evidence of misconduct". When `administration`
        spending is 25% above budget (> 10% threshold), it requests an
        explanation rather than alleging misconduct.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- governance_issue(conventional_uni, Id, Text).
      Expected Output:
        Id = unassigned_duty(curriculum_coordination), ... ;
        Id = unassigned_duty(laboratory_maintenance), ... ;
        Id = unassigned_duty(student_complaints), ... ;
        Id = unclear_responsibility(examination_administration, [faculty, registrar_office]), ...

      Query 2:
        ?- finance_status(reform_uni, '2025-26', research, S1),
           finance_status(reform_uni, '2025-26', administration, S2).
      Expected Output:
        S1 = unknown_actual_expenditure,
        S2 = review_required(120, 150, 25).

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Why doesn't the system infer corruption when actual expenditure is
          missing or exceeds the approved allocation?
      A1: Because missing records or budget variances can occur due to delayed
          reporting, emergency purchases, or accounting timing. Sound KRR only
          infers what is logically entailed: an information gap (`unknown`) or
          a variance requiring explanation (`review_required`).
      Q2: How does the system detect unclear governance responsibility?
      A2: `duty_owners/3` collects all owners for a duty using `findall/3` and
          `sort/2`. If `length(Owners, N)` has `N > 1` (like
          `examination_administration` at `conventional_uni`, owned by both
          `faculty` and `registrar_office`), Rule J2 flags it as unclear.
   ========================================================================== */

governance_duty(teaching).
governance_duty(curriculum_coordination).
governance_duty(examination_administration).
governance_duty(student_records).
governance_duty(financial_management).
governance_duty(laboratory_maintenance).
governance_duty(student_complaints).

budget_category(faculty_salaries).
budget_category(administration).
budget_category(laboratories).
budget_category(research).
budget_category(libraries).
budget_category(student_facilities).
budget_category(infrastructure).

/* --------------------------------------------------------------------------
   Governance
   -------------------------------------------------------------------------- */
duty_owners(Uni, Duty, Owners) :-
    findall(Owner, duty_owner(Uni, Duty, Owner), AllOwners),
    sort(AllOwners, Owners).

governance_issue(Uni, unassigned_duty(Duty), Text) :-
    university(Uni, _),
    governance_duty(Duty),
    duty_owners(Uni, Duty, []),
    format(atom(Text), "No owner is assigned for '~w'.", [Duty]).

governance_issue(Uni, unclear_responsibility(Duty, Owners), Text) :-
    university(Uni, _),
    governance_duty(Duty),
    duty_owners(Uni, Duty, Owners),
    length(Owners, N),
    N > 1,
    format(atom(Text), "Responsibility for '~w' is unclear - shared by ~w.", [Duty, Owners]).

governance_compliant(Uni) :-
    university(Uni, _),
    \+ governance_issue(Uni, _, _).

/* --------------------------------------------------------------------------
   Finance
   -------------------------------------------------------------------------- */
budget_available(Uni, Year) :-
    once(approved_allocation(Uni, Year, _, _)).

% finance_status(?Uni, ?Year, ?Category, -Status)
% Status is one of:
%   unknown_allocation_and_expenditure, unknown_allocation,
%   unknown_actual_expenditure, compared(Approved, Actual, Percent),
%   review_required(Approved, Actual, Percent)
finance_status(Uni, Year, Category, Status) :-
    university(Uni, _),
    reporting_year(Year),
    budget_category(Category),
    (   approved_allocation(Uni, Year, Category, Approved)
    ->  (   actual_expenditure(Uni, Year, Category, Actual)
        ->  variance_status(Approved, Actual, Status)
        ;   Status = unknown_actual_expenditure
        )
    ;   (   actual_expenditure(Uni, Year, Category, _)
        ->  Status = unknown_allocation
        ;   Status = unknown_allocation_and_expenditure
        )
    ).

% variance_status(+Approved, +Actual, -Status)   arithmetic
variance_status(Approved, Actual, Status) :-
    Percent is round((Actual - Approved) * 100 / Approved),
    variance_review_percent(Limit),
    (   abs(Percent) > Limit
    ->  Status = review_required(Approved, Actual, Percent)
    ;   Status = compared(Approved, Actual, Percent)
    ).

% documentation_status(+Uni, +Year, +Category, -Status)  yes | no | unknown
documentation_status(Uni, Year, Category, Status) :-
    (   expenditure_documented(Uni, Year, Category, Value)
    ->  Status = Value
    ;   Status = unknown
    ).

finance_issue(Uni, no_budget_information(Year), Text) :-
    university(Uni, _),
    reporting_year(Year),
    \+ budget_available(Uni, Year),
    format(atom(Text), "No approved budget information for ~w (information gap).", [Year]).

finance_issue(Uni, missing_information(Category, Status), Text) :-
    finance_status(Uni, _Year, Category, Status),
    missing_status(Status),
    format(atom(Text), "~w: ~w - information gap, NOT evidence of misconduct.", [Category, Status]).

finance_issue(Uni, variance_needs_explanation(Category, Percent), Text) :-
    finance_status(Uni, _Year, Category, review_required(_, _, Percent)),
    format(atom(Text), "~w: actual differs from approved by ~w% - explanation requested (not a finding of misconduct).", [Category, Percent]).

finance_issue(Uni, undocumented_expenditure(Category, Status), Text) :-
    reporting_year(Year),
    actual_expenditure(Uni, Year, Category, _),
    documentation_status(Uni, Year, Category, Status),
    Status \= yes,
    format(atom(Text), "~w: expenditure documentation is '~w' - supporting records should be published.", [Category, Status]).

missing_status(unknown_allocation_and_expenditure).
missing_status(unknown_allocation).
missing_status(unknown_actual_expenditure).

/* --------------------------------------------------------------------------
   REPORTS
   -------------------------------------------------------------------------- */

% Part of menu option 12.
report_governance :-
    print_heading('MODULE J - University Governance Responsibilities'),
    demo_data_notice,
    forall(university(Uni, Name),
           (   print_subheading(Name),
               forall(governance_duty(Duty),
                      (   duty_owners(Uni, Duty, Owners),
                          format("  ~w: ~w~n", [Duty, Owners])
                      )),
               findall(Text, governance_issue(Uni, _, Text), Issues),
               print_list_or_none(Issues, 'ISSUE', 'Every duty has exactly one clear owner.'),
               print_recommendations_for(Uni, governance_issue)
           )).

% Menu option 13.
report_finance :-
    print_heading('MODULE J - Financial Transparency Check'),
    demo_data_notice,
    print_bullet('Figures in Rs. millions (FICTIONAL). Missing data = UNKNOWN, never evidence of misconduct.'),
    reporting_year(Year),
    forall(university(Uni, Name), report_finance_for(Uni, Name, Year)).

report_finance_for(Uni, Name, Year) :-
    format(atom(Title), "~w - ~w", [Name, Year]),
    print_subheading(Title),
    (   budget_available(Uni, Year)
    ->  print_bullet('Budget information: AVAILABLE')
    ;   print_bullet('Budget information: NOT AVAILABLE (unknown)')
    ),
    forall(finance_status(Uni, Year, Category, Status),
           (   documentation_status(Uni, Year, Category, Documented),
               format("  ~w: ~w | documented: ~w~n", [Category, Status, Documented])
           )),
    findall(Text, finance_issue(Uni, _, Text), Issues),
    print_list_or_none(Issues, 'TRANSPARENCY', 'All categories reported, comparable and documented.'),
    print_recommendations_for(Uni, finance_issue).
