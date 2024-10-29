% A state in the blocks world
%
%          c 
%          a  b
% table	=  =  =  =

block(a).
block(b).
block(c).
table(t).

% Start and goal not actions --> constraints actions > start, actions < finish
% Put them as pseudo-actions in plans, not search for them

alldifferent([_]). 
alldifferent([H | Rest]) :-
    \+ member(H, Rest),  
    alldifferent(Rest). 

% Start action: sets the initial state of the world
action(start, 
    [],  % No preconditions, just defines the initial state
    [clear(b), clear(c), on(a, t), on(b, t), on(c, a)]).  % Initial positions of blocks

% Move block X onto block Y
action(move(X, Y, Z),  % X is moved onto Y from Z
    [clear(X), clear(Y), on(X, Z)],  % Preconditions: X and Y are blocks, and both are clear
    [on(X, Y), not(clear(Y)), clear(Z), not(on(X, Z))]) :- 
    block(X), block(Y), block(Z),
    alldifferent([X, Y, Z]).

action(movefromT(X, Y, t),  % X is moved onto Y from Z
    [clear(X), clear(Y), on(X, t)],  % Preconditions: X and Y are blocks, and both are clear
    [on(X, Y), not(clear(Y)), not(on(X, t))]) :- 
    block(X), block(Y), 
    alldifferent([X, Y, t]).

% Move block X onto the table from block Z.
action(moveT(X, t, Z),  % X is moved onto the table from Z
    [clear(X), on(X, Z), not(on(X, t))],  % Preconditions: X is clear and on Z, and not already on the table
    [on(X, t), clear(Z), not(on(X, Z))]) :-
    block(X), block(Z),
    alldifferent([X, Z]).
  
% Finish action: specifies the goal state of the world
action(finish,
    [on(b, c)],  % on(b,c)
    []).  % No effects, finish is just a goal to satisfy the preconditions

% List of partial plans, priority queue
% Epanaliptiki ekva8ynsh gia na mhn pesoume se apeiro va8os

% Energeies polles fores sto plano, identifier na valw id kai xrono enar3hs, duration is 1
% start time is 0 sta8era
% finish time < 100
% na valw dhlwsh constraint

% The main solve function to start the POP planning process
plan(Solution) :-
    action(finish, Preconditions, _),          % Get the preconditions of the 'finish' action (goal state)
    add_pairs(Preconditions, finish, Agenda),  % Create the initial agenda from finish preconditions
    pop([[start, finish], [constraint(start < finish)], []], Agenda, Solution).       % Start the POP algorithm with an empty plan, ordering, and causal links

% Actions (1 or more) [A, O, L]

% Partial Order Planning (POP) Algorithm
% pop([A, O, L], Agenda, Solution)
% A: list of actions, O: list of ordering constraints, L: list of causal links
% Agenda: list of pairs <precondition, action> that still need to be achieved
% Solution: the final plan when the agenda is empty

%%%%% Helpers
add_pairs([], _, []).  % Base case: empty list of preconditions results in an empty list
add_pairs([H|T], Name, [[H, Name]|List2]) :-  % Pair the first precondition with the action
    add_pairs(T, Name, List2).  % Recursively process the rest of the preconditions

% ActionNew in A
helper_pop(ActionNew, A, Agenda, A, Agenda) :-
    member(ActionNew, A), !.

% ActionNew not in A
helper_pop(ActionNew, A, Agenda, [ActionNew | A], NewAgenda) :-
    action(ActionNew, PrecondNew, _),
    % Append new action preconditions to Agenda
    add_pairs(PrecondNew, ActionNew, NewPairs), 
    append(NewPairs, Agenda, NewAgenda). 

new_action(Action, Q, ActionNew):-            
    action(ActionNew, _, EffectsNew), 
    member(Q, EffectsNew).

% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], [A, O, L]).

% New Action not in A
pop([A, O, L], [[Q, Action] | Agenda], Solution) :-
    % Find new Action 
    new_action(Action, Q, ActionNew),

    % Behavior depending on whether ActionNew in A                
    helper_pop(ActionNew, A, Agenda, NewA, NewAgenda),

    % Call with new stuff
    pop([NewA,                      
         [constraint(ActionNew < Action) | O], 
         [causal_link(ActionNew, Action, Q) | L]], 
        NewAgenda, Solution).  



