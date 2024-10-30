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

action(movefromT(X, Y, t), ID, 
    [clear(X), clear(Y), on(X, t)],  
    [on(X, Y), not(clear(Y)), not(on(X, t))]) :- 
    block(X), block(Y), 
    alldifferent([X, Y, t]).

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

action(finish, -1,
    [on(b, c)],  
    []). 

plan(Solution, Goal) :-
    %action(finish, Preconditions, _),         
    add_pairs(Goal, finish, Agenda),  
    pop([[[start, 0], [finish, -1]], [start #< finish], []], Agenda, 1, Solution).    

add_pairs([], _, []). 
add_pairs([H|T], Name, [[H, Name]|List2]) :-  
    add_pairs(T, Name, List2).  

% Selects Q (can change how the selection is made later)
%select_Q([[Q, Action] | _], Q, Action).

%%%% Select Action
% Action already in A
select_action(Q, _, ActionNew, A, Agenda, A, Agenda):-
    member([ActionNew, _], A),
    action(ActionNew, _, _, Effects),
    member(Q, Effects),!.


% Action is new
select_action(Q, ID, ActionNew, A, Agenda, [[ActionNew, ID] | A], NewAgenda) :-
    action(ActionNew, ID, Preconditions, Effects),
    member(Q, Effects),

    % Append new action preconditions to Agenda
    add_pairs(Preconditions, ActionNew, NewPairs), 
    append(NewPairs, Agenda, NewAgenda).

% Base case: when the agenda is empty, the solution is the current plan
pop([A, O, L], [], _, [A, O, L]).

% New Action in A
pop([A, O, L], [[Q, Action]|Agenda], ID, Solution) :-
    % Select new Action
    member([ActionNew, _], A),
    action(ActionNew, _, _, Effects),
    member(Q, Effects),
    \+ member(Action #< ActionNew, O),!,

    write('New A: '), write(A), nl,

    % Call with new stuff
    pop([A,                      
         [ActionNew #< Action | O], 
         [causal_link(ActionNew, Action, Q) | L]], 
        Agenda, ID, Solution).  

% New Action NOT in A
pop([A, O, L], [[Q, Action]|Agenda], ID, Solution) :-
    % Select new Action
    action(ActionNew, ID, Preconditions, Effects),
    member(Q, Effects),

    % Append new action preconditions to Agenda
    add_pairs(Preconditions, ActionNew, NewPairs), 
    append(NewPairs, Agenda, NewAgenda),

    IDnew is ID + 1,
    % Call with new stuff
    pop([[[ActionNew, ID] | A],                      
         [ActionNew #< Action | O], 
         [causal_link(ActionNew, Action, Q) | L]], 
        NewAgenda, IDnew, Solution).