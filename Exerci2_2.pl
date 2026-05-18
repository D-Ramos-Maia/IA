% ============================================================
%  DEBUG - Exercise 21.2
%  Run each query below one at a time to find the problem
% ============================================================

parent(pam, bob). parent(tom, bob). parent(tom, liz).
parent(bob, ann). parent(bob, pat). parent(pat, jim).
parent(pat, eve).

call_base(parent(X,Y)) :- parent(X,Y).

% --- The hypothesis we want to test ---
hyp([
    predecessor(X,Y) :- [parent(X,Y)],
    predecessor(A,B) :- [parent(A,C), predecessor(C,B)]
]).

% --- Prove with depth limit ---
prove(Goal, H, D) :-
    D > 0,
    D1 is D - 1,
    member(Head :- Body, H),
    copy_term(Head-Body, Goal-BodyC),
    prove_body(BodyC, H, D1).
prove(Goal, _, _) :-
    call_base(Goal).

prove_body([], _, _).
prove_body([G|Gs], H, D) :-
    prove(G, H, D),
    prove_body(Gs, H, D).

% ============================================================
%  Run these queries ONE AT A TIME in SWISH:
%
%  1) Test if parent facts work:
%     parent(tom, liz).
%
%  2) Test call_base:
%     call_base(parent(tom, liz)).
%
%  3) Build H manually and test prove:
%     H = [predecessor(X,Y) :- [parent(X,Y)],
%          predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
%     prove(predecessor(tom,liz), H, 5).
%
%  4) Test prove for recursive case:
%     H = [predecessor(X,Y) :- [parent(X,Y)],
%          predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
%     prove(predecessor(pam,jim), H, 5).
%
%  5) Test covers_all:
%     H = [predecessor(X,Y) :- [parent(X,Y)],
%          predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
%     \+ (member(E, [predecessor(pam,bob),
%                    predecessor(pam,jim),
%                    predecessor(tom,ann),
%                    predecessor(tom,jim),
%                    predecessor(tom,liz)]),
%         \+ prove(E, H, 6)).
% ============================================================
