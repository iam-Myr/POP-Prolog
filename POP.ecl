% A state in the blocks world
%          
%          c 
%          a  b
% table	=  =  =  =

block(a).
block(b).
block(c).
table(t).

alldifferent([_]). 
alldifferent([H | Rest]) :-
    \+ member(H, Rest),  
    alldifferent(Rest). 

action(start, 0,
    [],  
    [clear(b), clear(c), on(a, t), on(b, t), on(c, a)]). 

action(move(X, Y, Z), ID,  
    [clear(X), clear(Y), on(X, Z)],  
    [on(X, Y), not(clear(Y)), clear(Z), not(on(X, Z))]) :- 
    block(X), block(Y), block(Z),
    alldifferent([X, Y, Z]).

action(move(X, Y, t), ID, 
    [clear(X), clear(Y), on(X, t)],  
    [on(X, Y), not(clear(Y)), not(on(X, t))]) :- 
    block(X), block(Y), 
    alldifferent([X, Y, t]).

% Move to table
action(move(X, t, Z), ID, 
    [clear(X), on(X, Z), not(on(X, t))],  
    [on(X, t), clear(Z), not(on(X, Z))]) :-
    block(X), block(Z),
    alldifferent([X, Z]).

action(finish, -1,
    [on(b, c)],  
    []). 

plan(Solution, Goal, Level) :-
    %action(finish, Preconditions, _),         
    add_pairs(Goal, finish, Agenda),  
    pop([[[start, 0], [finish, -1]], [start #< finish], []], Agenda, 1, Level, Solution).    

add_pairs([], _, []). 
add_pairs([H|T], Name, [[H, Name]|List2]) :-  
    add_pairs(T, Name, List2).  

% Selects Q (can change how the selection is made later)
%select_Q([[Q, Action] | _], Q, Action).


% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], _, _, [A, O, L]).

% When Level is -1, fail.
pop(_, _, _, -1, _) :-
    !,fail.

% New Action in A
pop([A, O, L], [[Q, Action]|Agenda], ID, Level, Solution) :-
    % Select new Action
    member([ActionNew, IDnew], A),
    member([Action, IDold], A),
    action(ActionNew, _, _, Effects),
    member(Q, Effects),
    \+ member([Action, IDold] #< [ActionNew, IDnew], O),

    write('New Q: '), write(Q), write(' -> '), write(ActionNew), nl,
    NewLevel is Level - 1,
    % Adding new ordering constraint while keeping O as a set
    union([[ActionNew, IDnew] #< [Action, IDold]], O, NewO),

    % Adding new causal link while keeping L as a set
    union([causal_link([ActionNew, IDnew], [Action, IDold], Q)], L, NewL),

    % Call with new stuff
    pop([A, NewO, NewL], Agenda, ID, NewLevel, Solution).  

% New Action NOT in A
pop([A, O, L], [[Q, Action]|Agenda], ID, Level, Solution) :-
    % Select new Action
    action(ActionNew, ID, Preconditions, Effects),
    member(Q, Effects),

    write('New Q: '), write(Q), write(' -> '), write(ActionNew), nl,

    % Append new action preconditions to Agenda
    add_pairs(Preconditions, ActionNew, NewPairs), 
    append(NewPairs, Agenda, NewAgenda),

    IDnew is ID + 1,
    NewLevel is Level - 1,

    member([Action, IDold], A),

    % Adding new ordering constraint while keeping O as a set
    union([[ActionNew, ID] #< [Action, IDold]], O, NewO),

% Adding new causal link while keeping L as a set
    union([causal_link([ActionNew, IDnew], [Action, IDold], Q)], L, NewL),

    % Call with new stuff
    pop([[[ActionNew, ID] | A], NewO, NewL], NewAgenda, IDnew, NewLevel, Solution).


