/* ==========================================================================
   FILE: utilities.pl
   PURPOSE: Small printing and list-formatting helpers used by every module.

   1. WHAT THIS FILE DOES
      Provides reusable console output helpers (`print_heading/1`,
      `print_subheading/1`, `print_bullet/1`, `print_tagged/2`,
      `print_list_or_none/3`, `print_all_tagged/2`, `demo_data_notice/0`) so
      all 14 menu reports have a clean, consistent text layout.

   2. IMPORTANT PREDICATES
      - print_heading/1      : prints a major boxed report title
      - print_subheading/1   : prints a section divider title
      - print_bullet/1       : prints a single bullet line (`  * ...`)
      - print_tagged/2       : prints `  [TAG] Text`
      - print_list_or_none/3 : prints a tagged list, or a fallback if `[]`
      - print_all_tagged/2   : recursive list printer (`[Item | Rest]`)
      - demo_data_notice/0   : prints a reminder that all data is fictional

   3. FACTS VERSUS RULES
      This file contains only formatting rules (no domain facts).

   4. LOGIC IN PLAIN ENGLISH
      `print_all_tagged/2` demonstrates classic Prolog list recursion:
        - Base case: empty list `[]` does nothing and succeeds.
        - Recursive step: `[Item | Rest]` prints `Item` with `Tag`, then
          recursively calls `print_all_tagged(Rest, Tag)`.

   5. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query:
        ?- print_list_or_none(['Issue 1', 'Issue 2'], 'ISSUE', 'No issues.').
      Expected Output:
          [ISSUE] Issue 1
          [ISSUE] Issue 2

   6. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Where is list recursion used in `utilities.pl`?
      A1: In `print_all_tagged([Item | Rest], Tag)`, which splits a list into
          its head `Item` and tail `Rest`, prints `Item`, and recurses on `Rest`
          until the base case `print_all_tagged([], _Tag)`.
   ========================================================================== */

% print_heading(+Title)
% Prints a large boxed heading for a report.
print_heading(Title) :-
    nl,
    format("==================================================================~n"),
    format("  ~w~n", [Title]),
    format("==================================================================~n").

% print_subheading(+Title)
% Prints a smaller heading inside a report.
print_subheading(Title) :-
    nl,
    format("--- ~w ---~n", [Title]).

% print_bullet(+Text)
% Prints one bullet line.
print_bullet(Text) :-
    format("  * ~w~n", [Text]).

% print_tagged(+Tag, +Text)
% Prints a line such as "  [ISSUE] Attendance is compulsory."
print_tagged(Tag, Text) :-
    format("  [~w] ~w~n", [Tag, Text]).

% print_list_or_none(+List, +Tag, +NoneMessage)
% Prints every item of List with a tag, or a message if the list is empty.
print_list_or_none([], _Tag, NoneMessage) :-
    print_bullet(NoneMessage).
print_list_or_none([First | Rest], Tag, _NoneMessage) :-
    print_all_tagged([First | Rest], Tag).

% print_all_tagged(+List, +Tag)
% Recursive list processing: print the head, then the tail.
print_all_tagged([], _Tag).
print_all_tagged([Item | Rest], Tag) :-
    print_tagged(Tag, Item),
    print_all_tagged(Rest, Tag).

% demo_data_notice
% Reminds the audience that every figure is fictional.
demo_data_notice :-
    format("  (All names, numbers and records are FICTIONAL DEMONSTRATION DATA.)~n").
