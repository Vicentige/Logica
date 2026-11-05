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

%Regla número 3: Crear trampa, buscando armar un 3 en linea seguro
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    crear_trampa(Player, Oponente, Board, Column), !.

%Regla número 4: Si ninguna de las reglas anteriores se cumplió, se juega una jugada segura.("estrategia")
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    jugada_segura(Player, Oponente, Board, Column), !.

% Regla número 5 (Respaldo) : Si no hay jugada segura, juega en cualquier columna válida
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



% ficha_en consulta que ficha ("X","O")hay en la cordenada (Column, Fila), 
ficha_en(Board, Column, Fila, Ficha) :-
    Column >= 1, Column =< 7,
    Fila >= 1, Fila =< 6,
    nth1(Column, Board, ColumnaFichas),
    length(ColumnaFichas, Height),
    Fila =< Height,
    Indice is Height - Fila,
    nth0(Indice, ColumnaFichas, Ficha).%nth0 busca el elemento en el numero(indice) de la lista columna con elementos Ficha


%============================================================================================
% 3. DETECCIÓN DE 4 EN LÍNEA (JUGADA GANADORA)
%    Verifica si colocando Ficha en (Column, Fila) se completan 4 consecutivas.
%============================================================================================

% Prueba columnas válidas en orden de prioridad hasta hallar una que complete 4 en línea.
buscar_jugada_ganadora(Board, Ficha, Column) :-
    can_play(Column, Board, Fila),

    conecta_cuatro(Board, Column, Fila, Ficha).
    % Verifica si la ficha recién puesta en (Col, Fila) forma 4 en alguna de las 4 direcciones.

% 1. Horizontal: izquierda [-1, 0] y derecha [1, 0]
conecta_cuatro(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, -1, 0, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1, 0, Ficha, C2),
    C1 + C2 >= 3, !.

% 2. Vertical: hacia abajo [0, -1] (hacia arriba aún no hay fichas)
conecta_cuatro(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, 0, -1, Ficha, C),
    C >= 3, !.

% 3. Diagonal Ascendente: abajo-izq [-1, -1] y arriba-der [1, 1]
conecta_cuatro(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, -1, -1, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1,  1, Ficha, C2),
    C1 + C2 >= 3, !.

% 4. Diagonal Descendente (\): arriba-izq [-1, 1] y abajo-der [1, -1]    
conecta_cuatro(Board, Col, Fila, Ficha) :-   
    contar_rayo(Board, Col, Fila, -1,  1, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1, -1, Ficha, C2),
    C1 + C2 >= 3, !.


% Va paso a paso en la dirección (Dx, Dy) contando fichas iguales consecutivas.
contar_rayo(Board, Col, Fila, Dx, Dy, Ficha, Cantidad) :-
    SiguienteCol is Col + Dx,
    SiguienteFila is Fila + Dy,
    ficha_en(Board, SiguienteCol, SiguienteFila, Ficha), !,
    contar_rayo(Board, SiguienteCol, SiguienteFila, Dx, Dy, Ficha, Resto),
    Cantidad is Resto + 1.
contar_rayo(_, _, _, _, _, _, 0).


%============================================================================================
% 4. JUGADAS SEGURAS (EVITAR REGALAR LA VICTORIA AL RIVAL)
%    Una jugada es segura si el rival NO puede ganar jugando encima de nuestra ficha.
%============================================================================================

%Regla encargada de encontrar una columna en la cual se pueda colocar una ficha y que el rival
%no gane en el siguiente turno.

jugada_segura(Player, Oponente, Board, Column):-
    can_play(Column, Board, Fila), es_segura(Board, Column, Fila, Player, Oponente).

% Caso 1: Si nuestra ficha cae en la fila 6 (tope del "tablero"), la columna se llenó (no hay peligro arriba).
es_segura(_, _, 6, _, _) :- !.
% Caso 2: Si cae en una fila menor, comprobamos que el rival NO gane en la fila inmediatamente superior.
es_segura(Board, Col, Fila, Player, Oponente) :-
    FilaArriba is Fila + 1,
    simular_jugada(Board, Col, Player, TableroSimulado),
    \+ conecta_cuatro(TableroSimulado, Col, FilaArriba, Oponente).

% Inserta "imaginariamente" una ficha a la cabeza de la columna elegida.
simular_jugada(Board, Col, Ficha, NuevoTablero) :-
    nth1(Col, Board, ColumnaVieja, RestoTablero),
    nth1(Col, NuevoTablero, [Ficha | ColumnaVieja], RestoTablero).

%=========================================================================================================================================
% 5. Deteccion de 3 en linea(Crear amenaza para lograr la victoria)
%    Buscamos crear un 3 en linea para que el rival necesite 2 turnos para bloquearnos y asi nosotros poder ganar en el siguiente turno.
%=========================================================================================================================================

% 1. Horizontal: izquierda(<-) [-1, 0] y derecha(->) [1, 0]
conecta_tres(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, -1, 0, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1, 0, Ficha, C2),
    C1 + C2 >= 2, !.

% 2. Vertical: hacia abajo [0, -1] (hacia arriba aún no hay fichas)
conecta_tres(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, 0, -1, Ficha, C),
    C >= 2, !.

% 3. Diagonal Ascendente("/"): abajo-izq [-1, -1] y arriba-der [1, 1]
conecta_tres(Board, Col, Fila, Ficha) :-
    contar_rayo(Board, Col, Fila, -1, -1, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1,  1, Ficha, C2),
    C1 + C2 >= 2, !.

% 4. Diagonal Descendente (\): arriba-izq [-1, 1] y abajo-der [1, -1]    
conecta_tres(Board, Col, Fila, Ficha) :-   
    contar_rayo(Board, Col, Fila, -1,  1, Ficha, C1),
    contar_rayo(Board, Col, Fila,  1, -1, Ficha, C2),
    C1 + C2 >= 2, !.
%buscamos una columna que arme 3 en linea y que sea segura, es decir que el oponente no pueda ganar en la siguiente jugada.
crear_trampa(Player, Oponente, Board, Column) :-
    can_play(Column, Board, Fila),
    es_segura(Board, Column, Fila, Player, Oponente),
    conecta_tres(Board, Column, Fila, Player).



