% A state in the blocks world
%
%          c 
%          a  b
% table	=  =  =  =

%start([clear(b), clear(c), on(a, table), on(b, table), on(c, a)]).

% GOAL
%goal([on(a,b),on(b,c),on(c, table)]).

% Define actions for the planner
% action(Name, Preconditions, Effects)

% Move block X onto block Y
action(move(X, Y),  % X is moved onto Y
    [block(X), block(Y), clear(X), clear(Y)],  % Preconditions: X and Y are blocks and both are clear
    [on(X, Y), clear(X), not(clear(Y))]).      % Effects: X is now on Y, X remains clear, Y is no longer clear

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
    [on(b, c)],  % ADD ON(C,A) AGAIN
    []).  % No effects, finish is just a goal to satisfy the preconditions


% Causal link representation
% causal_link(A1, A2, Precondition): A1 produces Precondition, which is needed by A2
% Ordering constraint representation: constraint(Action1 < Action2)

% Helper function to pair action preconditions with their corresponding actions
add_pairs([], _, []).  % Base case: empty list of preconditions results in an empty list
add_pairs([H|T], Name, [[H, Name]|List2]) :-  % Pair the first precondition with the action
    add_pairs(T, Name, List2).  % Recursively process the rest of the preconditions


% The main solve function to start the POP planning process
solve(Solution, pop) :-
    action(finish, Preconditions, _),          % Get the preconditions of the 'finish' action (goal state)
    add_pairs(Preconditions, finish, Agenda),  % Create the initial agenda from finish preconditions
    pop([[], [], []], Agenda, Solution).       % Start the POP algorithm with an empty plan, ordering, and causal links


% Partial Order Planning (POP) Algorithm
% pop([A, O, L], Agenda, Solution)
% A: list of actions, O: list of ordering constraints, L: list of causal links
% Agenda: list of pairs <precondition, action> that still need to be achieved
% Solution: the final plan when the agenda is empty

% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], [A, O, L]).

% Case where ActionNew is not yet in A, we add it along with its preconditions to the agenda
pop([A, O, L], [[Q, Action] | Agenda], Solution) :-
    action(Action, Preconditions, Effects),   % Current action and its effects
    member(Q, Preconditions),                 % Q is a precondition of the current action
    action(ActionNew, PrecondNew, EffectsNew), % New action that produces Q
    member(Q, EffectsNew),                    % Check if ActionNew produces the effect Q
    add_pairs(PrecondNew, ActionNew, NewPairs), % Add the preconditions of ActionNew to the agenda
    append(NewPairs, Agenda, UpdatedAgenda),  % Combine the new preconditions with the existing agenda
    pop([[ActionNew | A],                      % Add ActionNew to the list of actions
         [constraint(ActionNew < Action) | O], % Add the ordering constraint
         [causal_link(ActionNew, Action, Q) | L]], % Add the causal link
        UpdatedAgenda, Solution).  % Continue solving with the updated agenda


% Case where ActionNew is already in A, and we just need to add the causal link and ordering constraint
pop([A, O, L], [[Q, Action] | Agenda], Solution) :-
    action(Action, Preconditions, Effects),   % Current action and its effects
    member(Q, Preconditions),                 % Q is a precondition of the current action
    action(ActionNew, _, EffectsNew),         % ActionNew is another action
    member(Q, EffectsNew),                    % ActionNew produces the effect that satisfies precondition Q
    member(ActionNew, A), !,                  % If ActionNew is already in A, we avoid backtracking (cut operator)
    pop([A, [constraint(ActionNew < Action) | O],  % Add ordering constraint: ActionNew before Action
             [causal_link(ActionNew, Action, Q) | L]],  % Add causal link: ActionNew -> Action (produces Q)
        Agenda, Solution).  % Continue solving with the updated agenda

