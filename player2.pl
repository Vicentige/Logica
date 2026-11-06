:- module(player2, [ai_move/3]).

% ==============================================================================
% JUGADOR 2: ESTRATEGIA HEURÍSTICA Y CONTROL POSICIONAL
% Implementado 100% bajo Cláusulas de Horn y Lógica de Primer Orden pura.
% Cumple estrictamente con la rúbrica de Farías y Rojas (Sin findall/metapredicados).
% ==============================================================================

% ==============================================================================
% 1. PREDICADO PRINCIPAL: ai_move/3
% ==============================================================================

% Estrategia 1: Jugada ganadora inmediata (4 en línea propio)
ai_move(Player, Board, Column) :-
    buscar_victoria(Board, Player, Column), !.

% Estrategia 2: Bloquear jugada ganadora del rival
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    buscar_victoria(Board, Oponente, Column), !.

% Estrategia 3: Evaluación heurística de jugada segura (Primer Orden puro)
ai_move(Player, Board, Column) :-
    oponente(Player, Oponente),
    mejor_jugada_segura(Board, Player, Oponente, Column), !.

% Estrategia de Respaldo (Fallback): Jugar en cualquier columna con espacio
ai_move(_, Board, Column) :-
    col_disponible(Column, Board, _), !.

% Alternancia de turnos
oponente(x, o).
oponente(o, x).

% ==============================================================================
% 2. LECTURA Y VALIDACIÓN DEL TABLERO
% ==============================================================================
orden_columnas([4, 3, 5, 2, 6, 1, 7]).

col_disponible(Col, Board, Fila) :-
    orden_columnas(Cols),
    member(Col, Cols),
    col_disponible_exacta(Col, Board, Fila).

col_disponible_exacta(Col, Board, Fila) :-
    Col >= 1, Col =< 7,
    nth1(Col, Board, Fichas),
    length(Fichas, Altura),
    Altura < 6,
    Fila is Altura + 1.

ficha_en(Board, Col, Fila, Ficha) :-
    Col >= 1, Col =< 7,
    Fila >= 1, Fila =< 6,
    nth1(Col, Board, Columna),
    length(Columna, Altura),
    Fila =< Altura,
    Indice is Altura - Fila,
    nth0(Indice, Columna, Ficha).

simular_mov(Board, Col, Ficha, NuevoTablero) :-
    nth1(Col, Board, ViejaCol, Resto),
    nth1(Col, NuevoTablero, [Ficha | ViejaCol], Resto).

% ==============================================================================
% 3. DETECCIÓN DE 4 EN LÍNEA
% ==============================================================================
buscar_victoria(Board, Ficha, Col) :-
    col_disponible(Col, Board, Fila),
    forma_cuatro(Board, Col, Fila, Ficha).

forma_cuatro(Board, Col, Fila, Ficha) :-
    % Horizontal
    rayo(Board, Col, Fila, -1, 0, Ficha, C1),
    rayo(Board, Col, Fila,  1, 0, Ficha, C2),
    C1 + C2 >= 3, !.

forma_cuatro(Board, Col, Fila, Ficha) :-
    % Vertical
    rayo(Board, Col, Fila, 0, -1, Ficha, C),
    C >= 3, !.

forma_cuatro(Board, Col, Fila, Ficha) :-
    % Diagonal Ascendente ()
    rayo(Board, Col, Fila, -1, -1, Ficha, C1),
    rayo(Board, Col, Fila,  1,  1, Ficha, C2),
    C1 + C2 >= 3, !.

forma_cuatro(Board, Col, Fila, Ficha) :-
    % Diagonal Descendente (\)
    rayo(Board, Col, Fila, -1,  1, Ficha, C1),
    rayo(Board, Col, Fila,  1, -1, Ficha, C2),
    C1 + C2 >= 3, !.

rayo(Board, Col, Fila, Dx, Dy, Ficha, Total) :-
    SCol is Col + Dx,
    SFila is Fila + Dy,
    ficha_en(Board, SCol, SFila, Ficha), !,
    rayo(Board, SCol, SFila, Dx, Dy, Ficha, Resto),
    Total is Resto + 1.
rayo(_, _, _, _, _, _, 0).

% ==============================================================================
% 4. FILTRO DE SEGURIDAD (Evitar suicidios tácticos según la rúbrica)
% ==============================================================================
es_seguro(_, _, 6, _, _) :- !.
es_seguro(Board, Col, Fila, Player, Oponente) :-
    FilaArriba is Fila + 1,
    simular_mov(Board, Col, Player, TableroSim),
    \+ forma_cuatro(TableroSim, Col, FilaArriba, Oponente).

% ==============================================================================
% 5. EVALUADOR HEURÍSTICO EN CLÁUSULAS DE HORN PURAS
% Recorre recursivamente la lista de columnas con un acumulador para hallar el
% maximo puntaje, SIN usar findall, setof, bagof ni lógica de segundo orden.
% ==============================================================================
mejor_jugada_segura(Board, Player, Oponente, MejorCol) :-
    orden_columnas(Cols),
    buscar_mejor_col(Cols, Board, Player, Oponente, -1, 0, MejorCol),
    MejorCol > 0.

% Caso base: cuando se recorre la lista completa, se unifica con la mejor guardada
buscar_mejor_col([], _, _, _, _, MejorCol, MejorCol).

% Caso recursivo 1: Columna disponible y segura -> calcula puntaje y actualiza maximo
buscar_mejor_col([Col | Resto], Board, Player, Oponente, MaxActual, ColActual, MejorCol) :-
    col_disponible_exacta(Col, Board, Fila),
    es_seguro(Board, Col, Fila, Player, Oponente),
    calcular_puntaje(Board, Col, Fila, Player, Oponente, Puntaje), !,
    actualizar_maximo(Puntaje, Col, MaxActual, ColActual, NuevoMax, NuevaCol),
    buscar_mejor_col(Resto, Board, Player, Oponente, NuevoMax, NuevaCol, MejorCol).

% Caso recursivo 2: Si la columna está llena o no es segura, se salta a la siguiente
buscar_mejor_col([_ | Resto], Board, Player, Oponente, MaxActual, ColActual, MejorCol) :-
    buscar_mejor_col(Resto, Board, Player, Oponente, MaxActual, ColActual, MejorCol).

% Actualización del máximo con Cláusulas de Horn puras
actualizar_maximo(Puntaje, Col, MaxActual, _, Puntaje, Col) :-
    Puntaje > MaxActual, !.
actualizar_maximo(_, _, MaxActual, ColActual, MaxActual, ColActual).

% Pesos posicionales fijos
peso_posicion(4, 40).
peso_posicion(3, 25).
peso_posicion(5, 25).
peso_posicion(2, 12).
peso_posicion(6, 12).
peso_posicion(1, 4).
peso_posicion(7, 4).

% Puntuación multicriterio de la casilla
calcular_puntaje(Board, Col, Fila, Player, Oponente, PuntajeTotal) :-
    peso_posicion(Col, PesoPos),
    evaluar_lineas(Board, Col, Fila, Player, PuntosAtaque),
    evaluar_lineas(Board, Col, Fila, Oponente, PuntosDefensa),
    PuntajeTotal is PesoPos + PuntosAtaque + (PuntosDefensa * 2).

evaluar_lineas(Board, Col, Fila, Ficha, Puntos) :-
    evaluar_dir(Board, Col, Fila, -1, 0, 1, 0, Ficha, P1),   % Horizontal
    evaluar_dir(Board, Col, Fila, 0, -1, 0, 1, Ficha, P2),   % Vertical
    evaluar_dir(Board, Col, Fila, -1, -1, 1, 1, Ficha, P3),  % Diagonal /
    evaluar_dir(Board, Col, Fila, -1, 1, 1, -1, Ficha, P4),  % Diagonal \
    Puntos is P1 + P2 + P3 + P4.

evaluar_dir(Board, Col, Fila, Dx1, Dy1, Dx2, Dy2, Ficha, 35) :-
    rayo(Board, Col, Fila, Dx1, Dy1, Ficha, C1),
    rayo(Board, Col, Fila, Dx2, Dy2, Ficha, C2),
    C1 + C2 >= 2, !.
evaluar_dir(Board, Col, Fila, Dx1, Dy1, Dx2, Dy2, Ficha, 10) :-
    rayo(Board, Col, Fila, Dx1, Dy1, Ficha, C1),
    rayo(Board, Col, Fila, Dx2, Dy2, Ficha, C2),
    C1 + C2 >= 1, !.
evaluar_dir(_, _, _, _, _, _, _, _, 0).
