% ============================================================
%  Exercise 21.1 - MINIHYPER: Learning has_daughter
%  Experimenting with modified sets of examples
%
%  To run in SWI-Prolog:
%    ?- induce(H).
%
%  Switch between EXPERIMENT sections below to test each case.
% ============================================================


% ============================================================
%  BACKGROUND KNOWLEDGE
% ============================================================

backliteral(parent(X,Y), [X,Y]).
backliteral(male(X),     [X]).
backliteral(female(X),   [X]).

prolog_predicate(parent(_,_)).
prolog_predicate(male(_)).
prolog_predicate(female(_)).

% --- Family facts ---
parent(pam, bob).
parent(tom, bob).
parent(tom, liz).
parent(bob, ann).
parent(bob, pat).
parent(pat, jim).
parent(pat, eve).

male(tom).   male(bob).   male(jim).
female(pam). female(liz). female(ann). female(pat). female(eve).


% ============================================================
%  EXPERIMENT 1 (original - baseline)
%  Expected result: has_daughter(A) :- parent(A,B), female(B).
%  All who have daughters: tom, bob, pat
%  Non-examples: pam (no children), jim (no children)
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).


% ============================================================
%  EXPERIMENT 2 - fewer positive examples
%  Remove pat from positives.
%  Effect: hypothesis may still be found (tom and bob suffice
%          to establish the parent+female pattern), but if
%          the search space is smaller it may converge faster.
%  Risk:   an overly-general hypothesis is harder to prune
%          without the third positive example.
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).


% ============================================================
%  EXPERIMENT 3 - only one positive example
%  Just tom (who has liz as a daughter).
%  Effect: underconstrained - many hypotheses are consistent.
%          The system may find has_daughter(A):-parent(A,B)
%          (without the female constraint) if negative examples
%          do not rule it out.
% ============================================================
% ex(has_daughter(tom)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).


% ============================================================
%  EXPERIMENT 4 - add a wrong positive (incorrect label)
%  Claim jim has a daughter (he does not in the family tree).
%  Effect: MINIHYPER will try to find a hypothesis that covers
%          jim, but no such background literal can be satisfied
%          for jim -> the search will FAIL or return no hypothesis.
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).
% ex(has_daughter(jim)).   % <-- incorrect / noisy positive
% nex(has_daughter(pam)).


% ============================================================
%  EXPERIMENT 5 - stronger negative set
%  Add bob as a negative example even though he HAS daughters.
%  Effect: the positive and negative sets are inconsistent;
%          no complete and consistent hypothesis exists ->
%          induce/1 will fail.
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).
% nex(has_daughter(bob)).  % <-- contradicts the positive above


% ============================================================
%  EXPERIMENT 6 - no negative examples
%  Effect: the system may return an overly-general hypothesis
%          such as has_daughter(A) :- parent(A,B).
%          (covers everyone with children, ignoring sex)
%          because there are no negatives to rule it out.
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).


% ============================================================
%  ACTIVE EXPERIMENT - change the block below to switch cases
%  Currently running: EXPERIMENT 1 (original baseline)
% ============================================================
ex(has_daughter(tom)).
ex(has_daughter(bob)).
ex(has_daughter(pat)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).

start_hyp([[has_daughter(X)]/[X]]).


% ============================================================
%  MINIHYPER ENGINE  (Ivan Bratko, Prolog for AI, Ch. 21)
% ============================================================

induce(H) :-
    start_hyp(H0),
    induce(H0, H).

induce(H, H) :-
    complete(H),
    consistent(H).

induce(H0, H) :-
    refine_hyp(H0, H1),
    induce(H1, H).

% complete/1: H covers all positive examples
complete(H) :-
    \+ ( ex(E), \+ covers(H, E) ).

% consistent/1: H does not cover any negative example
consistent(H) :-
    \+ ( nex(E), covers(H, E) ).

% covers(+Hyp, +Example)
covers(H, Example) :-
    copy_term(H, H1),
    member(Clause/Vars, H1),
    member(Example, Clause),  % head of clause matches example
    prove(Clause, Vars, H1).

% prove(+Goals, +Vars, +Hyp)
prove([], _, _).
prove([G|Gs], Vars, H) :-
    (   prolog_predicate(G)
    ->  prove_prolog(G),
        prove(Gs, Vars, H)
    ;   member(Clause/_, H),
        copy_term(Clause, [G|Body]),
        prove(Body, Vars, H),
        prove(Gs, Vars, H)
    ).

prove_prolog(parent(X,Y)) :- parent(X,Y).
prove_prolog(male(X))     :- male(X).
prove_prolog(female(X))   :- female(X).

% refine_hyp(+H0, -H): one refinement step
refine_hyp(H0, H) :-
    select(Clause0/Vars0, H0, HRest),
    refine(Clause0/Vars0, Clause/Vars),
    H = [Clause/Vars | HRest].

% refine(+Clause0/Vars0, -Clause/Vars)
% Add a background literal to the clause body
refine(Clause/Vars, NewClause/NewVars) :-
    backliteral(Lit, LitVars),
    % LitVars must share at least one variable with existing Vars
    member(V, LitVars),
    member(V, Vars),
    NewClause = [Lit | Clause],       % prepend literal
    append(Vars, LitVars, NewVars0),
    sort(NewVars0, NewVars).          % deduplicate vars


% ============================================================
%  HOW TO RUN & EXPECTED OUTPUTS
%
%  $ swipl exercise_21_1.pl
%  ?- induce(H).
%
%  EXPERIMENT 1 (baseline):
%    H = [[has_daughter(A), parent(A,B), female(B)] / [A,B]]
%    Translated: has_daughter(A) :- parent(A,B), female(B).
%
%  EXPERIMENT 2 (fewer positives):
%    Same hypothesis found - 2 examples still sufficient.
%
%  EXPERIMENT 3 (one positive only):
%    May find has_daughter(A):-parent(A,B) (no female guard)
%    because no negative rules it out for male children.
%
%  EXPERIMENT 4 (noisy positive - jim):
%    induce/1 FAILS - no consistent+complete hypothesis exists.
%
%  EXPERIMENT 5 (contradictory examples):
%    induce/1 FAILS - positive and negative sets conflict.
%
%  EXPERIMENT 6 (no negatives):
%    Overly general: has_daughter(A) :- parent(A,B).
% ============================================================