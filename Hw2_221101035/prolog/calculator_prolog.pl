:- use_module(library(dcg/basics)).

:- dynamic variable/2.
:- op(500, yfx, '+').
:- op(500, yfx, '-').
:- op(600, yfx, '*').
:- op(600, yfx, '/').


tokens([]) --> blanks, eos.
tokens([Token|Rest]) -->
    blanks,
    token(Token),
    tokens(Rest).

token(number(N)) -->
    number_codes(Cs), { Cs \= [], number_codes(N, Cs) }.
token(var(Atom)) -->
    ident_codes(Cs), { Cs \= [], atom_codes(Atom, Cs) }.
token(Token) -->
    [C],
    { char_code(Char, C),
      member(Char, ['+', '-', '*', '/', '=', '(', ')']),
      Token = Char }.

number_codes([C|Cs]) -->
    [C], { code_type(C, digit) }, number_codes_rest(Cs).
number_codes_rest([C|Cs]) -->
    [C], { code_type(C, digit) }, number_codes_rest(Cs).
number_codes_rest([]) --> [].

ident_codes([C|Cs]) -->
    [C], { code_type(C, alpha) }, ident_codes_rest(Cs).
ident_codes_rest([C|Cs]) -->
    [C], { code_type(C, alnum) }, ident_codes_rest(Cs).
ident_codes_rest([]) --> [].

expr(AST) --> assign_expr(AST).

assign_expr(AST) --> 
    addsub_expr(AST1), 
    (   [=] -> assign_expr(AST2), { AST = assign(AST1, AST2) }
    ;   { AST = AST1 } ).

addsub_expr(AST) -->
    muldiv_expr(AST1),
    addsub_expr_tail(AST1, AST).

addsub_expr_tail(Acc, AST) -->
    (   [+] -> muldiv_expr(E), { NewAcc = add(Acc, E) }, addsub_expr_tail(NewAcc, AST)
    ;   [-] -> muldiv_expr(E), { NewAcc = sub(Acc, E) }, addsub_expr_tail(NewAcc, AST)
    ;   [] -> { AST = Acc } ).

muldiv_expr(AST) -->
    factor(AST1),
    muldiv_expr_tail(AST1, AST).

muldiv_expr_tail(Acc, AST) -->
    (   [*] -> factor(E), { NewAcc = mul(Acc, E) }, muldiv_expr_tail(NewAcc, AST)
    ;   [/] -> factor(E), { NewAcc = div(Acc, E) }, muldiv_expr_tail(NewAcc, AST)
    ;   [] -> { AST = Acc } ).

factor(AST) --> 
    ['('], expr(AST), [')'].
factor(number(N)) --> [number(N)].
factor(var(X)) --> [var(X)].


evaluate(number(N), N).
evaluate(var(X), Value) :-
    ( variable(X, Value) -> true ; throw(error(undefined_variable(X))) ).
evaluate(add(E1, E2), Value) :-
    evaluate(E1, V1),
    evaluate(E2, V2),
    Value is V1 + V2.
evaluate(sub(E1, E2), Value) :-
    evaluate(E1, V1),
    evaluate(E2, V2),
    Value is V1 - V2.
evaluate(mul(E1, E2), Value) :-
    evaluate(E1, V1),
    evaluate(E2, V2),
    Value is V1 * V2.
evaluate(div(E1, E2), Value) :-
    evaluate(E1, V1),
    evaluate(E2, V2),
    ( V2 =:= 0 -> throw(error(division_by_zero))
    ; Value is V1 / V2 ).
evaluate(assign(var(X), E), Value) :-
    evaluate(E, V),
    retractall(variable(X, _)),
    assert(variable(X, V)),
    Value = V.
evaluate(assign(_, _), _) :-
    throw(error(invalid_assignment)).


check_parentheses(Tokens) :-
    check_parens(Tokens, 0, Count),
    Count =:= 0.

check_parens([], Count, Count).
check_parens([Token|Rest], Acc, Count) :-
    ( Token == '(' ->
         NewAcc is Acc + 1
    ; Token == ')' ->
         NewAcc is Acc - 1
    ; NewAcc = Acc
    ),
    NewAcc >= 0,
    check_parens(Rest, NewAcc, Count).


main :-
    write('Enter infix expression (or "exit"): '),
    flush_output(current_output),
    read_line_to_string(user_input, Line),
    ( Line = "exit" ->
          write('Goodbye!'), nl, halt
    ;   ( string_codes(Line, Codes),
          phrase(tokens(Tokens), Codes) ->
              ( check_parentheses(Tokens) ->
                    ( phrase(expr(AST), Tokens) ->
                          ( catch(evaluate(AST, Result), Error,
                                   (print_message(error, Error), fail))
                          ->  format("Result: ~w~n", [Result])
                          ;   format("Evaluation error~n") )
                    ;   format("Parse error: invalid expression or mismatched parentheses~n")
                    )
              ;   format("Error: Parentheses mismatch~n")
              )
          ;   format("Error: Could not tokenize input~n")
          ),
          main
    ).

:- initialization(main, main).
