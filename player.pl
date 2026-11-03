:- module(player, [ai_move/3]).
:- use_module(library(random)).

%============================================================================================
% 1.PREDICADO PRINCIPAL: ai_move(Ficha, Tablero, Columna)
%   Reglas para la AI/Robot
%   1) Tomar jugada ganadora
%   2) Bloquear al rival si es que tiene jugada ganadora
%   3) En caso contrario, buscar la mejor jugada:
%       -buscar una jugada segura, en la cual el siguiente movimiento del PLAYER NO gane. 
%============================================================================================

%Regla número 1: Si se puede ganar en este turno, se coloca la ficha en esa columna.("atacar")
ai_move(Player, Board, Column) :-
    buscar_jugada_ganadora(Board, Player, Column), !.

%Regla número 2: Si la regla 1 falló, se revisa si el rival puede ganar, en caso de ser así se bloquea.("defender/bloquear")
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    buscar_jugada_ganadora(Board, Oponente, Column), !.

%Regla número 3: Si ninguna de las reglas anteriores se cumplió, se juega una jugada segura.("estrategia")
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    jugada_segura(Player, Oponente, Board, Column), !.

% Regla 4 Respaldo : Si no hay jugada segura, juega en cualquier columna válida
ai_move(_, Board, Column) :-
    can_play(Column, Board, _), !.


%Relación para alternar turnos entre jugadores.
oponente(x,o).
oponente(o,x).

%============================================================================================
% 2.LECTURA DEL TABLERO.
% Verifica si la columna no está llena (height < 6)
% Calcular la fila en la que caerá la ficha (1-6)
%============================================================================================

%Columnas ordenadas por prioridad
columnas_ordenadas([4,3,5,2,6,1,7]).

%can_play es una regla que verifica si la columna está llena, y dice en que fila seria el siguiente Token (height > 6)
can_play(Column, Board, Fila) :-
    columnas_ordenadas(Cols),
    member(Column, Cols),
    nth1(Column, Board, Tokens),
    length(Tokens, Height),
    Height < 6,
    Fila is Height + 1.



% ficha_en consulta que ficha ("x","o")hay en la cordenada (Column, Fila), 
ficha_en(Board, Column, Fila, Ficha) :-
    Column >= 1, Column =< 7,
    Fila >= 1, Fila =< 6,
    nth1(Column, Board, ColumnaFichas),
    length(ColumnaFichas, Height),
    Fila =< Height,
    Indice is Height - Fila,
    nth0(Indice, ColumnaFichas, Ficha).%nth0 busca el elemento en el numero(indice) de la lista columna con elementos Ficha


  