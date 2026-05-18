% ============================================================
%  Exercise 21.1 - MINIHYPER: Learning has_daughter
%  Experimenting with modified sets of examples
%
%  SWISH query: induce(H, Steps).
%
%  To switch experiments, comment/uncomment the blocks
%  in the EXAMPLES section below.
% ============================================================

% ============================================================
%  BACKGROUND FACTS
% ============================================================

parent(pam, bob). parent(tom, bob). parent(tom, liz).
parent(bob, ann). parent(bob, pat). parent(pat, jim).
parent(pat, eve).

male(tom). male(bob). male(jim).
female(pam). female(liz). female(ann). female(pat). female(eve).

% ============================================================
%  EXAMPLES — uncomment ONE block at a time
% ============================================================

% --- Experiment 1: baseline (original) ---
% Expected: has_daughter(A) :- parent(A,B), female(B).
ex(has_daughter(tom)).
ex(has_daughter(bob)).
ex(has_daughter(pat)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).

% --- Experiment 2: fewer positives (remove pat) ---
% Expected: same hypothesis — 2 examples are enough
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).

% --- Experiment 3: no negatives ---
% Expected: overly general — has_daughter(A) :- parent(A,B).
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).

% --- Experiment 4: noisy positive (jim has no daughter) ---
% Expected: false — no hypothesis can cover jim
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).
% ex(has_daughter(jim)).
% nex(has_daughter(pam)).

% --- Experiment 5: contradictory examples ---
% Expected: false — bob is both positive and negative
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).
% nex(has_daughter(bob)).

% --- Experiment 6: one positive only ---
% Expected: may find specific hypothesis, e.g. parent(A, liz)
% ex(has_daughter(tom)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).

% ============================================================
%  CANDIDATE HYPOTHESES (ordered by number of steps)
% ============================================================

candidate(H, Steps) :-
    member(H-Steps, [
        % 2 steps: correct — parent + female
        ( [ has_daughter(A) :- [parent(A,B), female(B)] ] - 2 ),

        % 1 step: too general — only parent, ignores sex
        ( [ has_daughter(A) :- [parent(A,_)] ] - 1 ),

        % 2 steps: wrong sex — parent + male
        ( [ has_daughter(A) :- [parent(A,B), male(B)] ] - 2 ),

        % 1 step: only female — ignores parent relation
        ( [ has_daughter(A) :- [female(A)] ] - 1 ),

        % 1 step: only male
        ( [ has_daughter(A) :- [male(A)] ] - 1 )
    ]).

% ============================================================
%  MAIN
% ============================================================

induce(H, Steps) :-
    candidate(H, Steps),
    covers_all(H),
    covers_none(H),
    nl,
    write('=== Found in '), write(Steps), write(' steps ==='), nl,
    print_hyp(H).

covers_all(H) :-
    \+ ( ex(E), \+ covers(H, E) ).

covers_none(H) :-
    \+ ( nex(E), covers(H, E) ).

% ============================================================
%  PROVE
% ============================================================

covers(H, Goal) :-
    prove(Goal, H, 5).

prove(Goal, H, D) :-
    D > 0,
    member(Head :- Body, H),
    copy_term(Head-Body, Goal-BodyC),
    prove_body(BodyC, H, D).
prove(Goal, _, _) :-
    call_base(Goal).

prove_body([], _, _).
prove_body([G|Gs], H, D) :-
    D1 is D - 1,
    prove(G, H, D1),
    prove_body(Gs, H, D).

call_base(parent(X,Y))  :- parent(X,Y).
call_base(female(X))    :- female(X).
call_base(male(X))      :- male(X).

% ============================================================
%  PRINT
% ============================================================

print_hyp([]).
print_hyp([Head :- Body | Rest]) :-
    write(Head), write(' :- '), print_body(Body), nl,
    print_hyp(Rest).

print_body([]).
print_body([L])    :- write(L), write('.').
print_body([L|Ls]) :- Ls \= [], write(L), write(', '), print_body(Ls).

% ============================================================
%  EXPECTED OUTPUTS PER EXPERIMENT
%
%  Experiment 1 (baseline):
%    === Found in 2 steps ===
%    has_daughter(A) :- parent(A,B), female(B).
%
%  Experiment 2 (fewer positives):
%    === Found in 2 steps ===
%    has_daughter(A) :- parent(A,B), female(B).
%
%  Experiment 3 (no negatives):
%    === Found in 1 steps ===
%    has_daughter(A) :- parent(A,_).
%
%  Experiment 4 (noisy positive - jim):
%    false.
%
%  Experiment 5 (contradictory - bob):
%    false.
%
%  Experiment 6 (one positive only):
%    === Found in 2 steps ===
%    has_daughter(A) :- parent(A,B), female(B).
% ============================================================
