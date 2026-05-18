% ============================================================
%  Exercise 21.1 - MINIHYPER com limite de profundidade
%  Compatível com SWISH (swish.swi-prolog.org)
%  Query: induce(H).
% ============================================================

% --- Background knowledge ---
backliteral(parent(X,Y), [X,Y]).
backliteral(female(X),   [X]).
backliteral(male(X),     [X]).

prolog_predicate(parent(_,_)).
prolog_predicate(female(_)).
prolog_predicate(male(_)).

% --- Family facts ---
parent(pam, bob). parent(tom, bob). parent(tom, liz).
parent(bob, ann). parent(bob, pat). parent(pat, jim).
parent(pat, eve).

male(tom). male(bob). male(jim).
female(pam). female(liz). female(ann). female(pat). female(eve).

% ============================================================
%  EXPERIMENT 1 (baseline) - descomentar um bloco por vez
% ============================================================
ex(has_daughter(tom)).
ex(has_daughter(bob)).
ex(has_daughter(pat)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).

% ============================================================
%  EXPERIMENT 2 - menos positivos (remover pat)
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% nex(has_daughter(pam)).
% nex(has_daughter(jim)).

% ============================================================
%  EXPERIMENT 3 - sem negativos (hipótese geral demais)
% ============================================================
% ex(has_daughter(tom)).
% ex(has_daughter(bob)).
% ex(has_daughter(pat)).

start_hyp([[has_daughter(X)]/[X]]).

% ============================================================
%  ENGINE com iterative deepening (MaxDepth)
% ============================================================

induce(H) :-
    start_hyp(H0),
    between(0, 6, MaxD),          % tenta profundidade 0,1,2,...,6
    write('Trying depth: '), write(MaxD), nl,
    induce(H0, H, MaxD), !.       % para na primeira solução

induce(H, H, _) :-
    complete(H),
    consistent(H).

induce(H0, H, MaxD) :-
    MaxD > 0,
    refine_hyp(H0, H1),
    MaxD1 is MaxD - 1,
    induce(H1, H, MaxD1).

% --- Completude e consistência ---
complete(H) :-
    \+ ( ex(E), \+ covers(H, E) ).

consistent(H) :-
    \+ ( nex(E), covers(H, E) ).

% --- Cobertura ---
covers(H, Example) :-
    copy_term(H, H1),
    member(Clause/_, H1),
    Clause = [Example|Body],
    prove(Body, H1).

% --- Prova ---
prove([], _).
prove([G|Gs], H) :-
    (   prolog_predicate(G)
    ->  prove_prolog(G)
    ;   member(Clause/_, H),
        copy_term(Clause, [G|Body]),
        prove(Body, H)
    ),
    prove(Gs, H).

prove_prolog(parent(X,Y)) :- parent(X,Y).
prove_prolog(female(X))   :- female(X).
prove_prolog(male(X))     :- male(X).

% --- Refinamento ---
refine_hyp(H0, H) :-
    select(Clause0/Vars0, H0, HRest),
    refine(Clause0/Vars0, Clause/Vars),
    H = [Clause/Vars | HRest].

refine(Clause/Vars, [Lit|Clause]/NewVars) :-
    backliteral(Lit, LitVars),
    member(V, LitVars),
    member(V, Vars),
    append(Vars, LitVars, NewVars0),
    sort(NewVars0, NewVars).

% ============================================================
%  RESULTADO ESPERADO (Experiment 1):
%    Trying depth: 0
%    Trying depth: 1
%    ...
%    Trying depth: 4
%    H = [[has_daughter(A), parent(A,B), female(B)] / [A,B]]
%
%  Ou seja: has_daughter(A) :- parent(A,B), female(B).
% ============================================================
