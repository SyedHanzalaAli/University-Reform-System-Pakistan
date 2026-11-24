/* ==========================================================================
   FILE: knowledge_base.pl
   PURPOSE: Stores the FACTS of the expert system (the fictional dataset).

   *** EVERYTHING IN THIS FILE IS FICTIONAL DEMONSTRATION DATA. ***
   No name, mark, salary, rate or budget figure describes a real person,
   a real university or a real policy decision.

   1. WHAT THIS FILE DOES
      This file is the Knowledge Base (KB) of our expert system. It stores
      all demonstration facts for two fictional universities:
        - conventional_uni : represents traditional university practices
        - reform_uni       : represents the proposed reform operating model
      It covers courses, teachers, sections, student enrollments, attendance
      policies, recruitment processes and candidates, centralized exam papers
      and marking schemes, difficulty-adjusted grade thresholds, modular and
      linear exam choices, missed vs. attempted exams, student teacher
      selection and transfers, enrollment-based payment rates, governance
      duties, and university budgets.

   2. IMPORTANT PREDICATES (Name/Arity)
      - university/2               : university(UniId, DisplayName)
      - attendance_rule/3          : attendance_rule(UniId, SessionType, Rule)
      - policy/3                   : policy(UniId, PolicyKey, Value)
      - uses_assessment/2          : uses_assessment(UniId, AssessmentType)
      - recruitment_process/2      : recruitment_process(ProcessId, UniId)
      - recruitment_criterion/2    : recruitment_criterion(ProcessId, Criterion)
      - candidate/3                : candidate(CandId, Name, ProcessId)
      - teacher/2, course/2        : teacher(TeacherId, Name), course(CourseId, Title)
      - assigned_course/3          : assigned_course(TeacherId, CourseId, Term)
      - section/6                  : section(SecId, CourseId, TeacherId, Term, Year, Cap)
      - duty_assigned/3            : duty_assigned(UniId, Task, Role)
      - exam_session/4             : exam_session(SessionId, CourseId, Term, Year)
      - section_exam_paper/3       : section_exam_paper(SessionId, SecId, PaperId)
      - section_marking_scheme/3   : section_marking_scheme(SessionId, SecId, SchemeId)
      - grade_threshold/3          : grade_threshold(SessionId, Grade, MinMark)
      - exam_mark/3                : exam_mark(StudentId, SessionId, Mark)
      - student/2, enrolled/2      : student(StudentId, Name), enrolled(StudentId, SecId)
      - module_choice/4            : module_choice(StudentId, CourseId, ModNo, Route)
      - exam_attempted/4           : exam_attempted(StudentId, CourseId, ModNo, Mark)
      - exam_missed/3              : exam_missed(StudentId, CourseId, ModNo)
      - selection_request/3        : selection_request(StudentId, CourseId, TeacherId)
      - transfer_request/3         : transfer_request(StudentId, FromSecId, ToSecId)
      - rate_per_student/1         : rate_per_student(Rupees)
      - duty_owner/3               : duty_owner(UniId, GovernanceDuty, Office)
      - approved_allocation/4      : approved_allocation(UniId, Year, Category, AmountM)
      - actual_expenditure/4       : actual_expenditure(UniId, Year, Category, AmountM)

   3. FACTS VERSUS RULES
      - This file contains ONLY FACTS (unconditional statements of truth in the
        fictional world, ending with a full stop `.`, with no `:-` body).
      - All RULES (`Head :- Body.`) live in the reasoning modules.
      - Keeping facts separate from rules means you can add a new student,
        teacher, course, or university here without modifying a single rule.

   4. HOW QUERIES USE THE KNOWLEDGE BASE
      When you ask a query (or a rule runs), Prolog searches this file top to
      bottom using UNIFICATION (matching variables to constants) and
      BACKTRACKING (trying the next matching fact when more solutions are
      requested with `;` or `findall/3`).

   5. LOGIC IN PLAIN ENGLISH
      Every predicate is declared `:- dynamic` at the top. That gives us two
      benefits:
        (a) New facts can be added at runtime with `assertz/1` (for example,
            when a student transfer is applied or when automated tests check
            edge cases).
        (b) Under the Closed-World Assumption, if a fact is not recorded,
            querying it simply fails rather than throwing an error. Our rules
            use negation-as-failure (`\+`) to detect missing records and
            report them honestly as `unknown`.

   6. EXAMPLE QUERIES AND EXPECTED OUTPUT
      Query 1:
        ?- course(CourseId, Title).
      Expected Output:
        CourseId = cn301, Title = 'Computer Networks' ;
        CourseId = db201, Title = 'Database Systems' ;
        CourseId = os302, Title = 'Operating Systems' ;
        CourseId = ai401, Title = 'Artificial Intelligence'.

      Query 2:
        ?- section(SecId, cn301, Teacher, fall, '2025-26', Capacity).
      Expected Output:
        SecId = cn301_a, Teacher = t_ahmed,  Capacity = 4 ;
        SecId = cn301_b, Teacher = t_fatima, Capacity = 5 ;
        SecId = cn301_c, Teacher = t_bilal,  Capacity = 5.

   7. LIKELY VIVA QUESTIONS FOR THIS FILE
      Q1: Why did you declare all knowledge-base predicates as `dynamic`?
      A1: First, so the system and test suite can add or update facts at
          runtime using `assertz/1` and `retract/1`. Second, if a predicate
          has no matching facts, SWI-Prolog fails cleanly instead of raising
          an undefined-predicate error.
      Q2: Why are all clauses of the same predicate grouped together?
      A2: SWI-Prolog expects all clauses of a predicate with the same name
          and arity to be contiguous in a file; grouping them avoids
          discontiguous-predicate compiler warnings and makes tables easy to
          read.
      Q3: Can we add a fifth course or a twelfth student without changing the
          reasoning files?
      A3: Yes. Because no reasoning rule hard-codes specific student, teacher
          or course IDs, adding new facts to `knowledge_base.pl` works
          immediately across all 14 menu options.
   ========================================================================== */

:- dynamic
    university/2,
    attendance_rule/3,
    policy/3,
    uses_assessment/2,
    practical_component/3,
    recruitment_process/2,
    recruitment_criterion/2,
    process_requires_experience/2,
    hiring_pass_mark/2,
    candidate/3,
    candidate_qualification/3,
    candidate_score/3,
    candidate_experience_years/2,
    teacher/2,
    course/2,
    assigned_course/3,
    section/6,
    current_term/2,
    duty_assigned/3,
    exam_session/4,
    section_exam_paper/3,
    paper_prepared_by/2,
    section_marking_scheme/3,
    scheme_prepared_by/2,
    scheme_question/5,
    scripts_marked_by/3,
    moderation_record/2,
    difficulty_review/3,
    grade_threshold/3,
    exam_mark/3,
    student/2,
    enrolled/2,
    module_choice/4,
    exam_attempted/4,
    exam_missed/3,
    module_pass_mark/2,
    course_exam_day/2,
    linear_exam_week/2,
    extended_period_capacity/2,
    selection_request/3,
    transfer_request/3,
    transfer_window/3,
    transfer_procedure_step/2,
    confidential_feedback/3,
    rate_per_student/1,
    optional_feature/2,
    course_weight/2,
    duty_owner/3,
    reporting_year/1,
    approved_allocation/4,
    actual_expenditure/4,
    expenditure_documented/4,
    variance_review_percent/1.

/* --------------------------------------------------------------------------
   0. UNIVERSITIES
   university(UniversityId, DisplayName)
   -------------------------------------------------------------------------- */
university(conventional_uni, 'Demo Conventional University (fictional)').
university(reform_uni,       'Demo Reform University (fictional)').

/* --------------------------------------------------------------------------
   MODULE A - ATTENDANCE AND LEARNING
   -------------------------------------------------------------------------- */
% attendance_rule(University, SessionType, Rule)   Rule = compulsory | optional
attendance_rule(conventional_uni, lecture, compulsory).
attendance_rule(reform_uni,       lecture, optional).

% policy(University, PolicyKey, Value)
policy(conventional_uni, minimum_attendance_percent,          75).
policy(conventional_uni, attendance_affects_marks,            yes).
policy(conventional_uni, attendance_affects_exam_eligibility, yes).
policy(conventional_uni, external_learning_resources,         discouraged).
policy(reform_uni,       minimum_attendance_percent,          none).
policy(reform_uni,       attendance_affects_marks,            no).
policy(reform_uni,       attendance_affects_exam_eligibility, no).
policy(reform_uni,       external_learning_resources,         allowed).

% uses_assessment(University, AssessmentType)
uses_assessment(conventional_uni, homework_assignment).
uses_assessment(conventional_uni, random_quiz).
uses_assessment(conventional_uni, unannounced_test).
uses_assessment(conventional_uni, take_home_assessment).
uses_assessment(conventional_uni, scheduled_supervised_exam).
uses_assessment(reform_uni,       scheduled_supervised_exam).

% practical_component(University, Course, Description)
% Stored SEPARATELY from lecture attendance.
practical_component(reform_uni, cn301, 'Router configuration lab (demo)').

/* --------------------------------------------------------------------------
   MODULE B - TEACHER RECRUITMENT
   -------------------------------------------------------------------------- */
% recruitment_process(ProcessId, University)
recruitment_process(conv_hiring,   conventional_uni).
recruitment_process(reform_hiring, reform_uni).

% recruitment_criterion(ProcessId, Criterion)
recruitment_criterion(conv_hiring,   academic_qualification).
recruitment_criterion(conv_hiring,   research_publications).
recruitment_criterion(reform_hiring, academic_qualification).
recruitment_criterion(reform_hiring, subject_knowledge_test).
recruitment_criterion(reform_hiring, demonstration_lecture).
recruitment_criterion(reform_hiring, teaching_communication).
recruitment_criterion(reform_hiring, practical_experience).

% process_requires_experience(ProcessId, MinimumYears) - "where appropriate"
process_requires_experience(reform_hiring, 2).

% hiring_pass_mark(Criterion, PassMarkOutOf10) - configurable
hiring_pass_mark(subject_knowledge_test, 6).
hiring_pass_mark(demonstration_lecture,  6).
hiring_pass_mark(teaching_communication, 6).

% candidate(CandidateId, Name, ProcessId)
candidate(c_kamran, 'Dr. Kamran (demo candidate)', reform_hiring).
candidate(c_sana,   'Ms. Sana (demo candidate)',   reform_hiring).
candidate(c_imran,  'Mr. Imran (demo candidate)',  reform_hiring).

% candidate_qualification(CandidateId, Degree, relevant | not_relevant)
candidate_qualification(c_kamran, 'PhD Computer Science',    relevant).
candidate_qualification(c_sana,   'MS Computer Networks',    relevant).
candidate_qualification(c_imran,  'MS Software Engineering', relevant).

% candidate_score(CandidateId, Criterion, ScoreOutOf10)
% Note: c_imran has no demonstration_lecture or teaching_communication score yet.
candidate_score(c_kamran, subject_knowledge_test, 9).
candidate_score(c_kamran, demonstration_lecture,  4).
candidate_score(c_kamran, teaching_communication, 5).
candidate_score(c_sana,   subject_knowledge_test, 8).
candidate_score(c_sana,   demonstration_lecture,  9).
candidate_score(c_sana,   teaching_communication, 8).
candidate_score(c_imran,  subject_knowledge_test, 7).

% candidate_experience_years(CandidateId, Years)
candidate_experience_years(c_kamran, 1).
candidate_experience_years(c_sana,   3).
candidate_experience_years(c_imran,  4).

/* --------------------------------------------------------------------------
   MODULE C - TEACHERS, COURSES AND SECTIONS
   -------------------------------------------------------------------------- */
% teacher(TeacherId, Name)
teacher(t_ahmed,  'Mr. Ahmed (demo)').
teacher(t_fatima, 'Ms. Fatima (demo)').
teacher(t_bilal,  'Mr. Bilal (demo)').
teacher(t_ayesha, 'Ms. Ayesha (demo)').
teacher(t_usman,  'Mr. Usman (demo)').

% course(CourseId, Title)
course(cn301, 'Computer Networks').
course(db201, 'Database Systems').
course(os302, 'Operating Systems').
course(ai401, 'Artificial Intelligence').

% assigned_course(TeacherId, CourseId, Term) - approved pair (1 Fall, 1 Spring)
assigned_course(t_ahmed,  cn301, fall).
assigned_course(t_ahmed,  os302, spring).
assigned_course(t_fatima, cn301, fall).
assigned_course(t_fatima, db201, spring).
assigned_course(t_bilal,  cn301, fall).
assigned_course(t_bilal,  ai401, spring).
assigned_course(t_ayesha, db201, fall).
assigned_course(t_ayesha, cn301, spring).
assigned_course(t_usman,  os302, fall).
assigned_course(t_usman,  ai401, spring).

% current_term(Term, AcademicYear)
current_term(fall, '2025-26').

% section(SectionId, CourseId, TeacherId, Term, AcademicYear, Capacity)
section(cn301_a,   cn301, t_ahmed,  fall,   '2025-26', 4).
section(cn301_b,   cn301, t_fatima, fall,   '2025-26', 5).
section(cn301_c,   cn301, t_bilal,  fall,   '2025-26', 5).
section(db201_a,   db201, t_ayesha, fall,   '2025-26', 5).
section(db201_b,   db201, t_usman,  fall,   '2025-26', 4). % VIOLATION: unrelated course
section(os302_a,   os302, t_usman,  fall,   '2025-26', 5).
section(os302_s,   os302, t_ahmed,  spring, '2025-26', 5).
section(db201_s,   db201, t_fatima, spring, '2025-26', 5).
section(ai401_s,   ai401, t_bilal,  spring, '2025-26', 5).
section(cn301_s,   cn301, t_ayesha, spring, '2025-26', 5).
section(os302_b,   os302, t_usman,  spring, '2025-26', 5). % VIOLATION: wrong term
section(cn301_sum, cn301, t_ahmed,  summer, '2025-26', 5). % Allowed summer repeat
section(cn301_a27, cn301, t_ahmed,  fall,   '2026-27', 5). % Allowed next-year continuation

/* --------------------------------------------------------------------------
   MODULE D - TEACHING AND EXAMINATION RESPONSIBILITIES
   duty_assigned(University, Task, Role)
   -------------------------------------------------------------------------- */
duty_assigned(conventional_uni, deliver_lectures,    teacher).
duty_assigned(conventional_uni, academic_guidance,   teacher).
duty_assigned(conventional_uni, prepare_exam_papers, teacher).
duty_assigned(conventional_uni, invigilation,        teacher).
duty_assigned(conventional_uni, exam_logistics,      exam_assistants).
duty_assigned(conventional_uni, mark_answer_scripts, teacher).
% Note: conventional_uni has no moderation, quality_assurance or academic_appeals owner.
duty_assigned(reform_uni,       deliver_lectures,    teacher).
duty_assigned(reform_uni,       academic_guidance,   teacher).
duty_assigned(reform_uni,       prepare_exam_papers, central_exam_team).
duty_assigned(reform_uni,       invigilation,        exam_assistants).
duty_assigned(reform_uni,       exam_logistics,      exam_assistants).
duty_assigned(reform_uni,       mark_answer_scripts, central_marking_assistants).
duty_assigned(reform_uni,       moderation,          academic_oversight).
duty_assigned(reform_uni,       quality_assurance,   academic_oversight).
duty_assigned(reform_uni,       academic_appeals,    academic_oversight).

/* --------------------------------------------------------------------------
   MODULE E - CENTRALIZED EXAMINATIONS AND MARKING
   -------------------------------------------------------------------------- */
% exam_session(SessionId, CourseId, Term, AcademicYear)
exam_session(cn301_fall2025, cn301, fall, '2025-26').
exam_session(db201_fall2025, db201, fall, '2025-26').
exam_session(cn301_fall2020, cn301, fall, '2020-21'). % historical grading demo
exam_session(cn301_fall2021, cn301, fall, '2021-22'). % historical grading demo

% section_exam_paper(SessionId, SectionId, PaperId)
section_exam_paper(cn301_fall2025, cn301_a, cn_paper_2025).
section_exam_paper(cn301_fall2025, cn301_b, cn_paper_2025).
section_exam_paper(cn301_fall2025, cn301_c, cn_paper_2025).
section_exam_paper(db201_fall2025, db201_a, db_paper_ayesha).
section_exam_paper(db201_fall2025, db201_b, db_paper_usman).

% paper_prepared_by(PaperId, Preparer)
paper_prepared_by(cn_paper_2025,   central_exam_team).
paper_prepared_by(db_paper_ayesha, t_ayesha).
paper_prepared_by(db_paper_usman,  t_usman).

% section_marking_scheme(SessionId, SectionId, SchemeId)
section_marking_scheme(cn301_fall2025, cn301_a, cn_scheme_2025).
section_marking_scheme(cn301_fall2025, cn301_b, cn_scheme_2025).
section_marking_scheme(cn301_fall2025, cn301_c, cn_scheme_2025).
section_marking_scheme(db201_fall2025, db201_a, db_scheme_ayesha).
section_marking_scheme(db201_fall2025, db201_b, db_scheme_usman).

% scheme_prepared_by(SchemeId, Preparer)
scheme_prepared_by(cn_scheme_2025,   central_exam_team).
scheme_prepared_by(db_scheme_ayesha, t_ayesha).
scheme_prepared_by(db_scheme_usman,  t_usman).

% scheme_question(SchemeId, QuestionNo, Marks, ExpectedAnswer, PartialCredit)
% Note: db_scheme_usman has no recorded questions -> incomplete scheme.
scheme_question(cn_scheme_2025, 1, 30, 'Explain the OSI and TCP/IP models',
                'Up to 10 marks per correctly explained layer group').
scheme_question(cn_scheme_2025, 2, 40, 'Subnet a given network address',
                '10 marks method, 20 marks correct subnets, 10 marks explanation').
scheme_question(cn_scheme_2025, 3, 30, 'Compare TCP and UDP',
                '5 marks per valid, correctly explained difference').
scheme_question(db_scheme_ayesha, 1, 100, 'Whole paper', 'Teacher discretion').

% scripts_marked_by(SessionId, SectionId, Marker)
scripts_marked_by(cn301_fall2025, cn301_a, central_marking_assistants).
scripts_marked_by(cn301_fall2025, cn301_b, central_marking_assistants).
scripts_marked_by(cn301_fall2025, cn301_c, central_marking_assistants).
scripts_marked_by(db201_fall2025, db201_a, t_ayesha).
scripts_marked_by(db201_fall2025, db201_b, t_usman).

% moderation_record(SessionId, Description)
moderation_record(cn301_fall2025, 'Sample of scripts second-marked by academic oversight (demo)').

/* --------------------------------------------------------------------------
   MODULE F - DIFFICULTY-ADJUSTED, STANDARDS-BASED GRADING
   (HYPOTHETICAL sessions and thresholds, explicitly labelled as demo input.)
   -------------------------------------------------------------------------- */
% difficulty_review(SessionId, ApprovedAssessment, Notes)
difficulty_review(cn301_fall2020, relatively_easy,
    'HYPOTHETICAL: exam team judged questions straightforward, full syllabus coverage, clear wording').
difficulty_review(cn301_fall2021, relatively_difficult,
    'HYPOTHETICAL: exam team judged questions complex, multi-step, demanding standard').

% grade_threshold(SessionId, Grade, MinimumMark)
grade_threshold(cn301_fall2020, a, 85).
grade_threshold(cn301_fall2020, b, 70).
grade_threshold(cn301_fall2020, c, 55).
grade_threshold(cn301_fall2020, d, 45).
grade_threshold(cn301_fall2020, f, 0).
grade_threshold(cn301_fall2021, a, 75).
grade_threshold(cn301_fall2021, b, 60).
grade_threshold(cn301_fall2021, c, 45).
grade_threshold(cn301_fall2021, d, 35).
grade_threshold(cn301_fall2021, f, 0).

% exam_mark(StudentId, SessionId, Mark)
exam_mark(s20_1, cn301_fall2020, 92).
exam_mark(s20_2, cn301_fall2020, 88).
exam_mark(s20_3, cn301_fall2020, 86).
exam_mark(s20_4, cn301_fall2020, 85).
exam_mark(s20_5, cn301_fall2020, 60).
exam_mark(s21_1, cn301_fall2021, 80).
exam_mark(s21_2, cn301_fall2021, 78).
exam_mark(s21_3, cn301_fall2021, 62).
exam_mark(s21_4, cn301_fall2021, 46).
exam_mark(s21_5, cn301_fall2021, 30).

/* --------------------------------------------------------------------------
   STUDENTS AND ENROLLMENTS
   -------------------------------------------------------------------------- */
% student(StudentId, Name)
student(s20_1, 'Demo Student 2020-1').
student(s20_2, 'Demo Student 2020-2').
student(s20_3, 'Demo Student 2020-3').
student(s20_4, 'Demo Student 2020-4').
student(s20_5, 'Demo Student 2020-5').
student(s21_1, 'Demo Student 2021-1').
student(s21_2, 'Demo Student 2021-2').
student(s21_3, 'Demo Student 2021-3').
student(s21_4, 'Demo Student 2021-4').
student(s21_5, 'Demo Student 2021-5').
student(s01,   'Ali Raza').
student(s02,   'Hira Khan').
student(s03,   'Omar Farooq').
student(s04,   'Sara Malik').
student(s05,   'Danish Iqbal').
student(s06,   'Mahnoor Shah').
student(s07,   'Hamza Tariq').
student(s08,   'Zara Ahmed').
student(s09,   'Fahad Javed').
student(s10,   'Iqra Noor').
student(s11,   'Ayan Qureshi').

% enrolled(StudentId, SectionId)
enrolled(s01, cn301_a).
enrolled(s02, cn301_a).
enrolled(s03, cn301_a).
enrolled(s04, cn301_a).          % cn301_a is now FULL (capacity 4)
enrolled(s05, cn301_b).
enrolled(s06, cn301_b).
enrolled(s07, cn301_b).
enrolled(s08, cn301_c).
enrolled(s09, cn301_c).
enrolled(s01, db201_a).
enrolled(s03, db201_a).
enrolled(s05, db201_a).
enrolled(s10, db201_a).
enrolled(s02, db201_b).
enrolled(s04, db201_b).
enrolled(s01, os302_a).
enrolled(s06, os302_a).
enrolled(s10, os302_a).

/* --------------------------------------------------------------------------
   MODULE G - MODULAR / LINEAR EXAMINATIONS
   -------------------------------------------------------------------------- */
% module_choice(StudentId, CourseId, ModuleNo, modular | linear)
% s01: mixed (modular, linear, modular, linear)
module_choice(s01, cn301, 1, modular).
module_choice(s01, cn301, 2, linear).
module_choice(s01, cn301, 3, modular).
module_choice(s01, cn301, 4, linear).
% s02: all modular (missed module 2, attempted module 3 below standard)
module_choice(s02, cn301, 1, modular).
module_choice(s02, cn301, 2, modular).
module_choice(s02, cn301, 3, modular).
module_choice(s02, cn301, 4, modular).
% s03: all linear
module_choice(s03, cn301, 1, linear).
module_choice(s03, cn301, 2, linear).
module_choice(s03, cn301, 3, linear).
module_choice(s03, cn301, 4, linear).
% s04: modular for module 1, linear for 2-4
module_choice(s04, cn301, 1, modular).
module_choice(s04, cn301, 2, linear).
module_choice(s04, cn301, 3, linear).
module_choice(s04, cn301, 4, linear).
% s05: all modular (missed modules 1 and 4)
module_choice(s05, cn301, 1, modular).
module_choice(s05, cn301, 2, modular).
module_choice(s05, cn301, 3, modular).
module_choice(s05, cn301, 4, modular).
% s06: all modular, all attempted
module_choice(s06, cn301, 1, modular).
module_choice(s06, cn301, 2, modular).
module_choice(s06, cn301, 3, modular).
module_choice(s06, cn301, 4, modular).
% s07: modular 1-2, linear 3-4
module_choice(s07, cn301, 1, modular).
module_choice(s07, cn301, 2, modular).
module_choice(s07, cn301, 3, linear).
module_choice(s07, cn301, 4, linear).
% s08: all linear
module_choice(s08, cn301, 1, linear).
module_choice(s08, cn301, 2, linear).
module_choice(s08, cn301, 3, linear).
module_choice(s08, cn301, 4, linear).
% s09: linear 1, modular 2, modular 3 (missed), linear 4
module_choice(s09, cn301, 1, linear).
module_choice(s09, cn301, 2, modular).
module_choice(s09, cn301, 3, modular).
module_choice(s09, cn301, 4, linear).
% s01 in db201 and os302 (creates week 5 Tuesday clash between db201 and os302)
module_choice(s01, db201, 1, modular).
module_choice(s01, db201, 2, modular).
module_choice(s01, db201, 3, modular).
module_choice(s01, db201, 4, modular).
module_choice(s01, os302, 1, modular).
module_choice(s01, os302, 2, linear).
module_choice(s01, os302, 3, linear).
module_choice(s01, os302, 4, linear).
% s10 in db201 (missed module 2 -> deferred week 22) and os302 (linear -> week 22 clash)
module_choice(s10, db201, 1, modular).
module_choice(s10, db201, 2, modular).
module_choice(s10, db201, 3, modular).
module_choice(s10, db201, 4, modular).
module_choice(s10, os302, 1, linear).
module_choice(s10, os302, 2, linear).
module_choice(s10, os302, 3, linear).
module_choice(s10, os302, 4, linear).

% exam_attempted(StudentId, CourseId, ModuleNo, Mark)
exam_attempted(s01, cn301, 1, 78).
exam_attempted(s01, cn301, 3, 66).
exam_attempted(s02, cn301, 1, 72).
exam_attempted(s02, cn301, 3, 38).
exam_attempted(s02, cn301, 4, 65).
exam_attempted(s04, cn301, 1, 80).
exam_attempted(s05, cn301, 2, 55).
exam_attempted(s05, cn301, 3, 61).
exam_attempted(s06, cn301, 1, 50).
exam_attempted(s06, cn301, 2, 45).
exam_attempted(s06, cn301, 3, 70).
exam_attempted(s06, cn301, 4, 68).
exam_attempted(s07, cn301, 1, 90).
exam_attempted(s07, cn301, 2, 85).
exam_attempted(s09, cn301, 2, 47).
exam_attempted(s10, db201, 1, 64).

% exam_missed(StudentId, CourseId, ModuleNo)
exam_missed(s02, cn301, 2).
exam_missed(s05, cn301, 1).
exam_missed(s05, cn301, 4).
exam_missed(s09, cn301, 3).
exam_missed(s10, db201, 2).

% module_pass_mark(CourseId, Mark) - HYPOTHETICAL standard set by exam team
module_pass_mark(cn301, 40).
module_pass_mark(db201, 40).
module_pass_mark(os302, 40).

% course_exam_day(CourseId, Day)
course_exam_day(cn301, monday).
course_exam_day(db201, tuesday).
course_exam_day(os302, tuesday).
course_exam_day(ai401, wednesday).

% linear_exam_week(ModuleNo, Week) - configurable default (Weeks 21-24)
linear_exam_week(1, 21).
linear_exam_week(2, 22).
linear_exam_week(3, 23).
linear_exam_week(4, 24).

% extended_period_capacity(Week, Seats)
extended_period_capacity(21, 30).
extended_period_capacity(22, 30).
extended_period_capacity(23, 30).
extended_period_capacity(24, 30).

/* --------------------------------------------------------------------------
   MODULE H - STUDENT TEACHER SELECTION
   -------------------------------------------------------------------------- */
% selection_request(StudentId, CourseId, PreferredTeacherId)
selection_request(s10, cn301, t_ahmed).  % Ahmed's section is full -> waitlisted
selection_request(s11, cn301, t_bilal).  % Bilal's section has seats -> approved
selection_request(s01, cn301, t_fatima). % s01 already enrolled -> must transfer

% transfer_request(StudentId, FromSectionId, ToSectionId)
transfer_request(s07, cn301_b, cn301_c). % allowed
transfer_request(s09, cn301_c, cn301_a). % destination full
transfer_request(s05, cn301_b, db201_b). % different course

% transfer_window(Term, AcademicYear, open | closed)
transfer_window(fall, '2025-26', open).

% transfer_procedure_step(StepNo, Description)
transfer_procedure_step(1, 'Student submits a transfer request during the open transfer window').
transfer_procedure_step(2, 'System checks: enrolled in source section, same course, seat available').
transfer_procedure_step(3, 'Academic office approves the request and updates the enrollment record').
transfer_procedure_step(4, 'Student and both teachers are notified').

% confidential_feedback(SectionId, RatingOutOf5, Comment) - no student ID stored
confidential_feedback(cn301_a, 5, 'Very clear explanations').
confidential_feedback(cn301_a, 4, 'Good examples, a bit fast').
confidential_feedback(cn301_b, 3, 'Helpful but slides are outdated').
confidential_feedback(cn301_c, 4, 'Patient with questions').
confidential_feedback(db201_b, 2, 'Lectures often unrelated to syllabus').

/* --------------------------------------------------------------------------
   MODULE I - ENROLLMENT-BASED COMPENSATION
   -------------------------------------------------------------------------- */
rate_per_student(1000).
optional_feature(course_weighting, disabled).
course_weight(cn301, 1.2).
course_weight(db201, 1.0).
course_weight(os302, 1.1).
course_weight(ai401, 1.3).

/* --------------------------------------------------------------------------
   MODULE J - GOVERNANCE AND FINANCIAL TRANSPARENCY
   -------------------------------------------------------------------------- */
% duty_owner(University, GovernanceDuty, Office)
duty_owner(conventional_uni, teaching,                   faculty).
duty_owner(conventional_uni, examination_administration, registrar_office).
duty_owner(conventional_uni, examination_administration, faculty). % two owners -> unclear
duty_owner(conventional_uni, student_records,            registrar_office).
duty_owner(conventional_uni, financial_management,       finance_office).
duty_owner(reform_uni,       teaching,                   faculty).
duty_owner(reform_uni,       curriculum_coordination,    curriculum_committee).
duty_owner(reform_uni,       examination_administration, central_exam_office).
duty_owner(reform_uni,       student_records,            registrar_office).
duty_owner(reform_uni,       financial_management,       finance_office).
duty_owner(reform_uni,       laboratory_maintenance,     lab_services_unit).
duty_owner(reform_uni,       student_complaints,         student_affairs_office).

reporting_year('2025-26').
variance_review_percent(10).

% approved_allocation(University, Year, Category, RupeesMillions)
approved_allocation(reform_uni,       '2025-26', faculty_salaries,   400).
approved_allocation(reform_uni,       '2025-26', administration,     120).
approved_allocation(reform_uni,       '2025-26', laboratories,        80).
approved_allocation(reform_uni,       '2025-26', research,            60).
approved_allocation(reform_uni,       '2025-26', libraries,           30).
approved_allocation(reform_uni,       '2025-26', student_facilities,  50).
approved_allocation(reform_uni,       '2025-26', infrastructure,     100).
approved_allocation(conventional_uni, '2025-26', faculty_salaries,   350).
approved_allocation(conventional_uni, '2025-26', administration,     200).
approved_allocation(conventional_uni, '2025-26', infrastructure,     150).

% actual_expenditure(University, Year, Category, RupeesMillions)
actual_expenditure(reform_uni,       '2025-26', faculty_salaries,   395).
actual_expenditure(reform_uni,       '2025-26', administration,     150). % +25% -> review
actual_expenditure(reform_uni,       '2025-26', laboratories,        78).
actual_expenditure(reform_uni,       '2025-26', libraries,           29).
actual_expenditure(reform_uni,       '2025-26', student_facilities,  52).
actual_expenditure(reform_uni,       '2025-26', infrastructure,      97).
actual_expenditure(conventional_uni, '2025-26', faculty_salaries,   340).
actual_expenditure(conventional_uni, '2025-26', administration,     230).

% expenditure_documented(University, Year, Category, yes | no)
expenditure_documented(reform_uni,       '2025-26', faculty_salaries,   yes).
expenditure_documented(reform_uni,       '2025-26', administration,     yes).
expenditure_documented(reform_uni,       '2025-26', laboratories,       yes).
expenditure_documented(reform_uni,       '2025-26', libraries,          yes).
expenditure_documented(reform_uni,       '2025-26', student_facilities, no).
expenditure_documented(reform_uni,       '2025-26', infrastructure,     yes).
expenditure_documented(conventional_uni, '2025-26', faculty_salaries,   yes).
