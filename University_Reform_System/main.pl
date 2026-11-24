/* ==========================================================================
   FILE: main.pl     (ENTRY POINT - University Education Reform Expert System)

   Project : University Education Reform Expert System for Pakistan
   Team    : Syed Hanzala Ali (24K0025, Project Lead),
             Rafay Siddiqui   (24K0009),
             Azan Naveed      (24K5638)
   Language: SWI-Prolog

   1. WHAT THIS FILE DOES
      Serves as the main entry point of the expert system. It loads all 12
      project modules in a clean, non-circular order and runs the interactive
      14-option command-line menu (`start/0`) as well as single-option and
      full-demo convenience predicates (`run_choice/1` and `demo_all/0`).

   2. IMPORTANT PREDICATES
      - start/0       : prints the project banner and starts the menu loop
      - menu_loop/0   : recursive loop that reads a number (0-14) and runs it
      - show_menu/0   : prints all 14 menu options from `menu_item/2`
      - menu_item/2   : menu_item(OptionNumber, Label)
      - read_choice/1 : reads a line from user_input without needing a dot `.`
      - run_choice/1  : dispatches OptionNumber (1..14) to the module report
      - demo_all/0    : runs all 14 menu options sequentially

   3. FACTS VERSUS RULES
      - `menu_item/2` facts store the 14 menu numbers and titles.
      - `start/0`, `menu_loop/0`, `read_choice/1`, `run_choice/1`, and
        `demo_all/0` are rules that control interaction and dispatch.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      When a user selects option `N`, `run_choice(N)` calls the report
      predicate in the corresponding module, which in turn queries the facts in
      `knowledge_base.pl` and prints the diagnosis and recommendations.

   5. LOGIC IN PLAIN ENGLISH
      - `read_choice/1` uses `read_line_to_string(user_input, Line)` so the
        user can simply type `1` and press Enter (no trailing period `.`
        required, which prevents beginner input errors during a live viva).
      - `menu_loop/0` uses tail recursion: if `Choice == 0`, it prints
        `Goodbye.` and stops; otherwise it runs `run_choice(Choice)` and calls
        `menu_loop` again.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1 (Interactive Menu):
        ?- start.
      Expected Output:
        Prints the banner, displays options 1..14 and 0 (Exit), and prompts:
        `Enter your choice (0-14):`

      Query 2 (Run a single menu option directly):
        ?- run_choice(11).
      Expected Output:
        Prints MODULE I - Enrollment-Based Teacher Compensation report.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Why did you use `read_line_to_string/2` instead of `read/1` for the
          menu input?
      A1: `read/1` requires the user to end every input with a Prolog full stop
          (e.g. `1.`). `read_line_to_string/2` lets the user just type `1` and
          press Enter, and gracefully handles invalid input without crashing.
      Q2: Why are there cuts (`!`) in `run_choice/1`?
      A2: Because the final catch-all clause `run_choice(_)` handles invalid
          inputs. Once a valid choice `1..14` matches its clause, the cut `!`
          commits to that clause so backtracking never falls into `run_choice(_)`.
   ========================================================================== */

:- ensure_loaded(utilities).
:- ensure_loaded(knowledge_base).
:- ensure_loaded(academic_policy).
:- ensure_loaded(teacher_recruitment).
:- ensure_loaded(teacher_specialization).
:- ensure_loaded(responsibilities).
:- ensure_loaded(student_selection).
:- ensure_loaded(examination_system).
:- ensure_loaded(grading).
:- ensure_loaded(exam_scheduling).
:- ensure_loaded(compensation).
:- ensure_loaded(governance_finance).
:- ensure_loaded(recommendations).

:- initialization(format("~nUniversity Reform Expert System loaded. Type  start.  to open the menu.~n")).

% start - prints the banner and runs the menu loop.
start :-
    print_heading('UNIVERSITY EDUCATION REFORM EXPERT SYSTEM FOR PAKISTAN'),
    format("  Team: Syed Hanzala Ali (24K0025, Lead), Rafay Siddiqui (24K0009), Azan Naveed (24K5638)~n"),
    demo_data_notice,
    menu_loop.

% menu_loop - show menu, read a number, run it, repeat until 0.
menu_loop :-
    show_menu,
    read_choice(Choice),
    (   Choice == 0
    ->  format("~nGoodbye.~n")
    ;   run_choice(Choice),
        menu_loop
    ).

show_menu :-
    nl,
    format("------------------------------ MAIN MENU ------------------------------~n"),
    forall(menu_item(Number, Label), format("  ~t~w~3|. ~w~n", [Number, Label])),
    format("   0. Exit~n").

% menu_item(Number, Label)  - menu text stored as facts.
menu_item(1,  'Diagnose existing academic policies').
menu_item(2,  'Evaluate teacher recruitment practices').
menu_item(3,  'Check teacher course specialization').
menu_item(4,  'View teacher availability and student selection').
menu_item(5,  'Check centralized examination arrangements').
menu_item(6,  'Check examination marking consistency').
menu_item(7,  'Apply difficulty-adjusted grade thresholds').
menu_item(8,  'View individual student examination routes').
menu_item(9,  'Generate modular and linear examination schedules').
menu_item(10, 'Identify deferred examination eligibility').
menu_item(11, 'Calculate teacher compensation').
menu_item(12, 'Check staff responsibilities').
menu_item(13, 'Check financial transparency').
menu_item(14, 'Generate a comprehensive reform report').

% read_choice(-Choice)
% Reads a whole line (no full stop needed) and converts it to a number.
read_choice(Choice) :-
    format("~nEnter your choice (0-14): "),
    flush_output,
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  Choice = 0
    ;   normalize_space(atom(Trimmed), Line),
        (   atom_number(Trimmed, Number)
        ->  Choice = Number
        ;   Choice = invalid
        )
    ).

% run_choice(+Choice) - one clause per menu option.
run_choice(1)  :- !, report_academic_policy.
run_choice(2)  :- !, report_recruitment.
run_choice(3)  :- !, report_specialization.
run_choice(4)  :- !, report_student_selection.
run_choice(5)  :- !, report_central_exams.
run_choice(6)  :- !, report_marking.
run_choice(7)  :- !, report_grading.
run_choice(8)  :- !, report_student_routes.
run_choice(9)  :- !, report_exam_schedule.
run_choice(10) :- !, report_deferred.
run_choice(11) :- !, report_compensation.
run_choice(12) :- !, report_responsibilities, report_governance.
run_choice(13) :- !, report_finance.
run_choice(14) :- !, report_comprehensive.
run_choice(_)  :- format("~n  Invalid choice. Please type a number from 0 to 14.~n").

% demo_all - runs every menu option once (useful before the viva).
demo_all :-
    forall(menu_item(Number, _), run_choice(Number)).
