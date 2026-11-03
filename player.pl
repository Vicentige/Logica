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

%Regla número 1: Si se puede ganar en este turno, se coloca la ficha en esa columna.
ai_move(Player, Board, Column) :-
    buscar_jugda_ganadora(Board, Player, Column), !.

%Regla número 2: Si la regla 1 falló, se revisa si el rival puede ganar, en caso de ser así se bloquea.
ai_move(Player, Board, Column) :-
    oponente(Player, Board, Column), !.

%Regla número 3: Si ninguna de las reglas anteriores se cumplió, se juega una jugada "segura".
ai_move(Player, Board, Column) :-
     jugada_segura(Player, Oponente, Board, Column), !.


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


%"nombre" consulta que ficha hay en la cordenada (Column, Fila)
nombre(Board, Column, Fila, Tokens) :-
    nth1(Column, Board, Token),


  