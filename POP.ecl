% Load the CLP library
:- use_module(library(clpfd)).  % Import the constraint logic programming library

% Define blocks and the table
block(a).
block(b).
block(c).
table(t).

alldifferent([_]).
alldifferent([H | Rest]) :-
    \+ member(H, Rest),
    alldifferent(Rest).

% Define actions with their effects
action(start, 0,
    [],
    [clear(b), clear(c), on(a, t), on(b, t), on(c, a)]).

action(moveT(X, t, Z), ID,
    [clear(X), on(X, Z), not(on(X, t))],
    [on(X, t), clear(Z), not(on(X, Z))]) :-
    block(X), block(Z),
    alldifferent([X, Z]).

action(move(X, Y, Z), ID,
    [clear(X), clear(Y), on(X, Z)],
    [on(X, Y), not(clear(Y)), clear(Z), not(on(X, Z))]) :-
    block(X), block(Y), block(Z),
    alldifferent([X, Y, Z]).

action(movefromT(X, Y, t), ID,
    [clear(X), clear(Y), on(X, t)],
    [on(X, Y), not(clear(Y)), not(on(X, t))]) :-
    block(X), block(Y),
    alldifferent([X, Y, t]).

action(finish, -1,
    [on(b, c)],
    []).

% Plan predicate to generate the solution
plan(Solution, Goal) :-
    add_pairs(Goal, finish, Agenda),
    pop([[[start, 0], [finish, -1]], [start #< finish], []], Agenda, 1, Solution).

add_pairs([], _, []).
add_pairs([H|T], Name, [[H, Name]|List2]) :-
    add_pairs(T, Name, List2).

% Select Action
select_action(Q, _, ActionNew, A, Agenda, A, Agenda) :-
    member([ActionNew, _], A),
    action(ActionNew, _, _, Effects),
    member(Q, Effects), !.

% New action selection with constraints
select_action(Q, ID, ActionNew, A, Agenda, [[ActionNew, ID] | A], NewAgenda) :-
    action(ActionNew, ID, Preconditions, Effects),
    member(Q, Effects),
    
    % Append new action preconditions to Agenda
    add_pairs(Preconditions, ActionNew, NewPairs),
    append(NewPairs, Agenda, NewAgenda),

    % Ensure chronological order
    apply_constraints(ActionNew, A).

% Apply constraints for action ordering
apply_constraints(ActionNew, A) :-
    % Find actions in A that must be before ActionNew
    findall(Action, (member([Action, _], A),
                     causal_link(ActionNew, Action, _)), Links),
    % Apply constraints for all linked actions
    maplist(action_order(ActionNew), Links).

% Define the action order constraint
action_order(ActionNew, Action) :-
    % Ensure ActionNew comes before Action
    ActionNew #< Action.

% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], _, [A, O, L]).

pop([A, O, L], [[Q, Action] | Agenda], ID, Solution) :-
    % Select new Action
    select_action(Q, ID, ActionNew, A, Agenda, NewA, NewAgenda),

    IDnew is ID + 1,
    % Call with new stuff
    pop([NewA,
         [ActionNew #< Action | O],
         [causal_link(ActionNew, Action, Q) | L]],
        NewAgenda, IDnew, Solution).
