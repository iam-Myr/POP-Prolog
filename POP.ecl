% A state in the blocks world
%
%          c 
%          a  b
% table	=  =  =  =

%start([clear(b), clear(c), on(a, table), on(b, table), on(c, a)]).

% GOAL
%goal([on(a,b),on(b,c)]).

% Define actions for the planner
% action(Name, Preconditions, Effects)

% Move block X onto block Y
action(move(X, Y),  % X is moved onto Y
    [block(X), block(Y), clear(Y), clear(X)],  % Preconditions: X and Y are blocks and both are clear
    [on(X, Y), not(clear(Y))]).      % Effects: X is now on Y, X remains clear, Y is no longer clear

% Move block X onto the table
action(move(X, table),  % X is moved onto the table
    [block(X), clear(X), not(on(X, table))],  % Preconditions: X is a block, clear, and not already on the table
    [on(X, table), clear(X)]).                % Effects: X is on the table and X is clear (it has no block on it)

% Start action: sets the initial state of the world
action(start, 
    [],  % No preconditions, just defines the initial state
    [block(a), block(b), block(c),  % a, b, c are blocks
    clear(b), clear(c), on(a, table), on(b, table), on(c, a)]).  % Initial positions of blocks

% Finish action: specifies the goal state of the world
action(finish,
    [on(a, b)],  %on(b,c)
    []).  % No effects, finish is just a goal to satisfy the preconditions

% Causal link representation
% causal_link(A1, A2, Precondition): A1 produces Precondition, which is needed by A2
% Ordering constraint representation: constraint(Action1 < Action2)

% Helper function to pair action preconditions with their corresponding actions
add_pairs([], _, []).  % Base case: empty list of preconditions results in an empty list
add_pairs([H|T], Name, [[H, Name]|List2]) :-  % Pair the first precondition with the action
    add_pairs(T, Name, List2).  % Recursively process the rest of the preconditions


% The main solve function to start the POP planning process
solve(Solution) :-
    action(finish, Preconditions, _),          % Get the preconditions of the 'finish' action (goal state)
    add_pairs(Preconditions, finish, Agenda),  % Create the initial agenda from finish preconditions
    pop([[], [], []], Agenda, Solution).       % Start the POP algorithm with an empty plan, ordering, and causal links

% Action in A
helper_pop(ActionNew, A, Agenda, A, Agenda) :-
    member(ActionNew, A),!.

% Action not in A
helper_pop(ActionNew, A, Agenda, [ActionNew | A], NewAgenda) :-
    action(ActionNew, PrecondNew, _),
    % Append new things
    add_pairs(PrecondNew, ActionNew, NewPairs), 
    append(NewPairs, Agenda, NewAgenda). 


new_action(Action, Q, ActionNew):-
    action(Action, Preconditions, _),
    member(Q, Preconditions),                 
    action(ActionNew, _, EffectsNew), 
    member(Q, EffectsNew). 

% Partial Order Planning (POP) Algorithm
% pop([A, O, L], Agenda, Solution)
% A: list of actions, O: list of ordering constraints, L: list of causal links
% Agenda: list of pairs <precondition, action> that still need to be achieved
% Solution: the final plan when the agenda is empty

% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], [A, O, L]).

% New Action not in A
pop([A, O, L], [[Q, Action] | Agenda], Solution) :-
    action(Action, Preconditions, _),   % Current action and its effects

    % Find new Action 
    new_action(Action, Q, ActionNew),

    % Behavior depending on whether ActionNew in A                
    helper_pop(ActionNew, A, Agenda, NewA, NewAgenda),

    % Call with new stuff
    pop([NewA,                      
         [constraint(ActionNew < Action) | O], 
         [causal_link(ActionNew, Action, Q) | L]], 
        NewAgenda, Solution).  



