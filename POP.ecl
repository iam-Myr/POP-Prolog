% A state in the blocks world
%
%          c 
%          a  b
% table	=  =  =  =

%start([clear(b), clear(c), on(a, table), on(b, table), on(c, a)]).

% GOAL
%goal([on(a,b),on(b,c),on(c, table)]).

% ACTIONS
% action(name, preconditions, effects)
action(move(X,Y), % Move X to Y
    [block(X), block(Y), clear(X), clear(Y)], % Preconditions
    [on(X,Y), not(clear(Y))]). % Effects

action(move(X,table), % Move X to table
    [block(X), clear(X), not(on(X, table))], % Preconditions
    [on(X,table)]). % Effects

action(start, 
    [], %No preconditions, only effects
    [block(a), block(b), block(c),
    clear(b), clear(c), on(a, table), on(b, table), on(c, a)]).

action(finish,
    [on(a,b), on(b,c), on(c, table)], 
    []). %No effects, only preconditions


% Causal Link representation L
%causal_link(A1,A2,Precondition) A1 - Precondition -> A2
% Ordering Constraint



add_pairs([], _, []).  % Base case: when the list is empty, the result is an empty list.
add_pairs([H|T], Name, [[H, Name]|List2]) :-
    add_pairs(T, Name, List2).  % Recursive case: pair the head of the list with Name and recurse on the tail.


%POP Algorithm
% pop([A,O,L], Agenta) where 
% A is a list of actions
% O is a list of ordering constraints
% L is a list of causal links
% Agenta is a list of pairs of <precondition, action>

% If Agenta is empty, Plan is the solution
pop(Solution,[]). 

%               q      a
pop([A, O, L],[[Q, Action] | Rest]) :-
    action(Action, Preconditions, Effects), % a is an action
    member(Q, Preconditions), % q is a precondition of a
    action(ActionNew, _, EffectsNew), % A new Action
    member(Q, EffectsNew), % New action's effect is precondition of Action a
    member(ActionNew, A), !, %New action is in list A and cut afterwards cause mutex
    pop([A,[constraint(ActionNew < Action)|O],[causal_link(ActionNew, Action, Q)|L]],
        [Rest])


% ActionNew is not in A
pop([A, O, L],[[Q, Action] | Rest]) :-
    action(Action, Preconditions, Effects), % a is an action
    member(Q, Preconditions), % q is a precondition of a
    action(ActionNew, PrecondNew, EffectsNew), % A new Action
    member(Q, EffectsNew), % New action's effect is precondition of Action a
     % Use add_pairs to generate the new agenda
    add_pairs(PrecondNew, ActionNew, NewAgenda),
    pop([[ActionNew|A],
        [constraint(ActionNew < Action)|O],[causal_link(ActionNew, Action, Q)|L]],
        [NewAgenda|Rest]). % Add ActionNew's preconditions to the Agenda