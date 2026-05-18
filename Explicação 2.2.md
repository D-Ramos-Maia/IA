# Exercício 21.2 — Debug: Comandos para rodar no SWISH

## Como carregar o arquivo

1. Acesse [swish.swi-prolog.org](https://swish.swi-prolog.org)
2. Cole o conteúdo do arquivo `exercise_21_2_debug.pl` no painel esquerdo
3. Clique em **Consult** (ou `Ctrl+Enter`) para carregar
4. Execute as queries abaixo **uma por vez** na caixa inferior

---

## Queries — rode nesta ordem

### Query 1 — Os fatos estão carregados?

```prolog
parent(tom, liz).
```

| Esperado | Significado se falhar |
|----------|-----------------------|
| `true` | O arquivo não foi carregado corretamente no SWISH |

---

### Query 2 — `call_base` funciona?

```prolog
call_base(parent(tom, liz)).
```

| Esperado | Significado se falhar |
|----------|-----------------------|
| `true` | Problema na definição de `call_base/1` |

---

### Query 3 — `prove` funciona para o caso base (não recursivo)?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], prove(predecessor(tom,liz), H, 5).
```

| Esperado | Significado se falhar |
|----------|-----------------------|
| `true` | Problema em `prove/3` para casos diretos |

`tom` é pai direto de `liz`, então basta aplicar a primeira cláusula:
`predecessor(X,Y) :- parent(X,Y).`

---

### Query 4 — `prove` funciona para o caso recursivo?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], prove(predecessor(pam,jim), H, 5).
```

| Esperado | Significado se falhar |
|----------|-----------------------|
| `true` | Problema na recursão de `prove/3` ou no depth limit |

`pam` não é pai direto de `jim` — o caminho é `pam → bob → pat → jim`.
Requer aplicar a cláusula recursiva **três vezes**.

---

### Query 5 — A hipótese cobre todos os positivos?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], \+ (member(E, [predecessor(pam,bob), predecessor(pam,jim), predecessor(tom,ann), predecessor(tom,jim), predecessor(tom,liz)]), \+ prove(E, H, 6)).
```

| Esperado | Significado se falhar |
|----------|-----------------------|
| `true` | A hipótese não cobre algum exemplo positivo |

---

## Fluxo de diagnóstico

```
Query 1 falha? → recarregue o arquivo no SWISH
    ↓ passa
Query 2 falha? → corrija call_base/1
    ↓ passa
Query 3 falha? → corrija prove/3 (caso base)
    ↓ passa
Query 4 falha? → corrija prove/3 (recursão) ou aumente o depth limit
    ↓ passa
Query 5 falha? → algum exemplo positivo não está sendo coberto
    ↓ todas passam
→ O prove funciona. O problema está em outro lugar do induce/2.
```

---

## Queries extras de diagnóstico

Caso alguma query falhe, use estas para investigar mais:

```prolog
% Ver todos os fatos parent carregados
parent(X, Y).

% Testar um exemplo negativo (deve falhar)
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], prove(predecessor(liz,bob), H, 5).

% Ver os membros da hipótese H
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], member(Clause, H).

% Testar prove_body diretamente
H = [predecessor(X,Y) :- [parent(X,Y)], predecessor(A,B) :- [parent(A,C), predecessor(C,B)]], prove_body([parent(tom,liz)], H, 3).
```
