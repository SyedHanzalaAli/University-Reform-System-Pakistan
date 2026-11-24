/* ==========================================================================
   FILE: compensation.pl         (MODULE I - Enrollment-Based Teacher Compensation)

   1. WHAT THIS FILE DOES
      Calculates teacher compensation from the number of enrolled students
      multiplied by a configurable per-student rate, explains the calculation
      step-by-step, and keeps optional course weighting completely separate and
      disabled by default.

   2. IMPORTANT PREDICATES
      - payment_for_enrollment/2   : payment_for_enrollment(Students, Payment)
      - section_payment/4          : section_payment(Section, Teacher, Students, Pay)
      - teacher_term_payment/4     : teacher_term_payment(Teacher, Term, Year, Total)
      - teacher_term_students/4    : teacher_term_students(Teacher, Term, Year, Count)
      - adjusted_section_payment/2 : adjusted_section_payment(Section, AdjustedPay)
      - report_compensation/0      : prints Menu Option 11 report

   3. FACTS VERSUS RULES
      - Facts in `knowledge_base.pl`: `rate_per_student/1` (fictional demo rate
        Rs. 1,000), `optional_feature(course_weighting, disabled)`,
        `course_weight/2`, `section/6`, and `enrolled/2`.
      - Rules perform Prolog arithmetic (`is`) and list summation (`sum_list/2`).

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      - `section_payment/4` calls `enrolled_count(Section, Students)` (from
        `student_selection.pl`) and `payment_for_enrollment(Students, Payment)`.
      - `teacher_term_payment/4` collects all section payments for a teacher in
        a given term and academic year with `findall/3` and sums them with
        `sum_list/2`.

   5. LOGIC IN PLAIN ENGLISH
      - Core formula: `Payment is Students * Rate`.
      - With the fictional demonstration rate `Rs. 1,000`:
          20 students -> Rs. 20,000
          40 students -> Rs. 40,000
          60 students -> Rs. 60,000
      - Optional course weighting (`adjusted_section_payment/2`) checks whether
        `optional_feature(course_weighting, enabled)` is true. Since it is
        `disabled` by default, the core formula is never replaced.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- payment_for_enrollment(20, P20),
           payment_for_enrollment(40, P40),
           payment_for_enrollment(60, P60).
      Expected Output:
        P20 = 20000, P40 = 40000, P60 = 60000.

      Query 2:
        ?- teacher_term_payment(t_ahmed, fall, '2025-26', PayAhmed),
           teacher_term_payment(t_usman, fall, '2025-26', PayUsman).
      Expected Output:
        PayAhmed = 4000,
        PayUsman = 5000.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: How do we change the per-student payment rate without changing the
          rules in `compensation.pl`?
      A1: Either edit `rate_per_student(1000).` in `knowledge_base.pl` or at
          runtime call `retract(rate_per_student(1000)), assertz(rate_per_student(1500)).`
      Q2: Why does Mr. Usman receive Rs. 5,000 in Fall 2025-26?
      A2: Because he teaches two sections in Fall 2025-26: `db201_b` (2 enrolled
          students = Rs. 2,000) and `os302_a` (3 enrolled students = Rs. 3,000),
          and `sum_list([2000, 3000], 5000)` gives Rs. 5,000.
   ========================================================================== */

% payment_for_enrollment(+Students, -Payment)   the core formula
payment_for_enrollment(Students, Payment) :-
    rate_per_student(Rate),
    Payment is Students * Rate.

% section_payment(?Section, ?Teacher, -Students, -Payment)
section_payment(Section, Teacher, Students, Payment) :-
    section(Section, _, Teacher, _, _, _),
    enrolled_count(Section, Students),
    payment_for_enrollment(Students, Payment).

% teacher_term_payment(?Teacher, +Term, +Year, -Total)
% Sum of the core payment over all the teacher's sections in that term.
teacher_term_payment(Teacher, Term, Year, Total) :-
    teacher(Teacher, _),
    findall(Payment,
            ( section(Section, _, Teacher, Term, Year, _),
              section_payment(Section, Teacher, _, Payment) ),
            Payments),
    sum_list(Payments, Total).

% teacher_term_students(?Teacher, +Term, +Year, -TotalStudents)
teacher_term_students(Teacher, Term, Year, TotalStudents) :-
    teacher(Teacher, _),
    findall(Count,
            ( section(Section, _, Teacher, Term, Year, _),
              enrolled_count(Section, Count) ),
            Counts),
    sum_list(Counts, TotalStudents).

% adjusted_section_payment(+Section, -Adjusted)
% OPTIONAL course weighting.  If disabled (default) Adjusted = core payment.
adjusted_section_payment(Section, Adjusted) :-
    section(Section, Course, Teacher, _, _, _),
    section_payment(Section, Teacher, _, Core),
    (   optional_feature(course_weighting, enabled),
        course_weight(Course, Weight)
    ->  Adjusted is round(Core * Weight)
    ;   Adjusted = Core
    ).

/* --------------------------------------------------------------------------
   REPORT (menu option 11)
   -------------------------------------------------------------------------- */
report_compensation :-
    print_heading('MODULE I - Enrollment-Based Teacher Compensation'),
    demo_data_notice,
    rate_per_student(Rate),
    format("  Formula: Payment = Enrolled Students x Rate.  Configured rate: Rs. ~D per student (FICTIONAL).~n", [Rate]),
    print_subheading('Illustration of the formula'),
    forall(member(Students, [20, 40, 60]),
           (   payment_for_enrollment(Students, Payment),
               format("  ~w students x Rs. ~D = Rs. ~D~n", [Students, Rate, Payment])
           )),
    current_term(Term, Year),
    format(atom(Title), "Teacher payments for ~w ~w (from demo enrollment records)", [Term, Year]),
    print_subheading(Title),
    forall(teacher(Teacher, Name), report_teacher_payment(Teacher, Name, Term, Year)),
    print_subheading('Optional course weighting'),
    (   optional_feature(course_weighting, enabled)
    ->  print_bullet('ENABLED - adjusted payments (core x course weight):'),
        forall(( section(Section, _, _, Term, Year, _), adjusted_section_payment(Section, Adjusted) ),
               format("      ~w: Rs. ~D~n", [Section, Adjusted]))
    ;   print_bullet('DISABLED (default). Only the core enrollment-based formula is applied.')
    ).

report_teacher_payment(Teacher, Name, Term, Year) :-
    teacher_term_payment(Teacher, Term, Year, Total),
    teacher_term_students(Teacher, Term, Year, Students),
    format("  ~w: ~w student(s) -> Rs. ~D~n", [Name, Students, Total]),
    forall(( section(Section, Course, Teacher, Term, Year, _),
             section_payment(Section, Teacher, Count, Payment) ),
           (   rate_per_student(Rate),
               format("      section ~w (~w): ~w x Rs. ~D = Rs. ~D~n", [Section, Course, Count, Rate, Payment])
           )).
