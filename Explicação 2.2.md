# Exercício 21.2 — Debug do MINIHYPER para `predecessor`

## Por que precisamos de debug?

O MINIHYPER puro entra em **loop infinito** ao tentar aprender `predecessor`,
porque a hipótese é recursiva — `predecessor` chama `predecessor`. Para
diagnosticar onde exatamente a busca falha, isolamos cada componente do
sistema em queries separadas.

---

## Estrutura do arquivo de debug

O arquivo tem três partes:

### 1. Fatos da família

```prolog
parent(pam, bob). parent(tom, bob). parent(tom, liz).
parent(bob, ann). parent(bob, pat). parent(pat, jim).
parent(pat, eve).
```

São os fatos de background que o sistema usa para provar os exemplos.
A árvore genealógica é:

```
tom ──┬── bob ──┬── ann
     │          └── pat ──┬── jim
     └── liz              └── eve
pam ─────bob
```

---

### 2. `call_base/1` — prova fatos do Prolog diretamente

```prolog
call_base(parent(X,Y)) :- parent(X,Y).
```

Substitui o `call/1` bloqueado pelo SWISH. Sempre que um literal é um
**predicado base** (não hipótese), usamos `call_base` em vez de `call`.

---

### 3. `prove/3` — prova com limite de profundidade

```prolog
prove(Goal, H, D) :-
    D > 0,
    D1 is D - 1,
    member(Head :- Body, H),
    copy_term(Head-Body, Goal-BodyC),
    prove_body(BodyC, H, D1).
prove(Goal, _, _) :-
    call_base(Goal).
```

| Parâmetro | Significado |
|-----------|-------------|
| `Goal` | literal a provar (ex: `predecessor(tom, liz)`) |
| `H` | hipótese atual (lista de cláusulas) |
| `D` | profundidade máxima restante |

**Como funciona:**

1. Se `D > 0`, tenta usar uma cláusula da hipótese `H` para provar `Goal`
2. `copy_term` renomeia as variáveis da cláusula para evitar conflitos
3. Se nenhuma cláusula da hipótese serve, tenta `call_base` (fatos do Prolog)
4. Se `D = 0`, a recursão para — evitando loop infinito

---

### 4. `prove_body/3` — prova uma lista de literais

```prolog
prove_body([], _, _).
prove_body([G|Gs], H, D) :-
    prove(G, H, D),
    prove_body(Gs, H, D).
```

Prova cada literal do corpo da cláusula em sequência. Lista vazia = sucesso.

---

## As 5 queries de diagnóstico

Cada query testa uma camada do sistema. Rodam **uma por vez** no SWISH.

---

### Query 1 — Os fatos estão carregados?

```prolog
parent(tom, liz).
```

**Esperado:** `true`

**O que testa:** se o arquivo foi carregado corretamente no SWISH.
Se falhar aqui, o problema é no carregamento do arquivo.

---

### Query 2 — `call_base` funciona?

```prolog
call_base(parent(tom, liz)).
```

**Esperado:** `true`

**O que testa:** se o substituto do `call/1` consegue acessar os fatos.
Se falhar aqui, o problema está na definição de `call_base`.

---

### Query 3 — `prove` funciona para o caso base?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)],
     predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
prove(predecessor(tom, liz), H, 5).
```

**Esperado:** `true`

**O que testa:** se `prove` consegue provar um caso direto (não recursivo).
`tom` é pai de `liz`, então `predecessor(tom, liz)` deve ser provado
apenas com a primeira cláusula: `predecessor(X,Y) :- parent(X,Y)`.

---

### Query 4 — `prove` funciona para o caso recursivo?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)],
     predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
prove(predecessor(pam, jim), H, 5).
```

**Esperado:** `true`

**O que testa:** o caso mais difícil — `pam` não é pai direto de `jim`,
mas é avô (pam → bob → pat → jim). Requer aplicar a cláusula recursiva
**três vezes**. Se falhar aqui, o problema está na recursão do `prove`.

---

### Query 5 — A hipótese cobre todos os positivos?

```prolog
H = [predecessor(X,Y) :- [parent(X,Y)],
     predecessor(A,B) :- [parent(A,C), predecessor(C,B)]],
\+ (member(E, [predecessor(pam,bob),
               predecessor(pam,jim),
               predecessor(tom,ann),
               predecessor(tom,jim),
               predecessor(tom,liz)]),
    \+ prove(E, H, 6)).
```

**Esperado:** `true`

**O que testa:** se a hipótese completa cobre **todos** os exemplos positivos.
É o equivalente ao predicado `covers_all` do MINIHYPER.

---

## Fluxo de diagnóstico

```
Query 1 falha? → problema no carregamento do arquivo
    ↓ passa
Query 2 falha? → problema em call_base
    ↓ passa
Query 3 falha? → problema em prove (caso base)
    ↓ passa
Query 4 falha? → problema em prove (caso recursivo / depth limit)
    ↓ passa
Query 5 falha? → problema na cobertura completa da hipótese
    ↓ passa
→ O sistema funciona! O bug está em outra parte do induce/2
```

---

## Hipótese-alvo que estamos tentando verificar

```prolog
predecessor(X,Y) :- parent(X,Y).
predecessor(X,Y) :- parent(X,Z), predecessor(Z,Y).
```

Essa hipótese requer **3 passos de refinamento** partindo de:

```prolog
predecessor(X1,Y1).   % cláusula 1 vazia
predecessor(X2,Y2).   % cláusula 2 vazia
```

| Passo | Ação | Resultado |
|:-----:|------|-----------|
| 1 | Adiciona `parent(X1,Y1)` à cláusula 1 | `predecessor(X,Y) :- parent(X,Y).` |
| 2 | Adiciona `parent(X2,Z)` à cláusula 2 | `predecessor(X,Y) :- parent(X,Z).` |
| 3 | Adiciona `predecessor(Z,Y2)` à cláusula 2 | `predecessor(X,Y) :- parent(X,Z), predecessor(Z,Y).` |
