# Exercício 21.1 — MINIHYPER: Aprendendo `has_daughter`

## O que é o MINIHYPER?

MINIHYPER é um sistema de **Programação Lógica Indutiva (ILP)** — ele aprende regras Prolog automaticamente a partir de exemplos positivos e negativos, usando conhecimento de fundo (*background knowledge*).

O objetivo do exercício 21.1 é experimentar **como modificar os conjuntos de exemplos afeta a hipótese aprendida**.

---

## Estrutura do programa

### 1. Conhecimento de fundo (*Background Knowledge*)

Define quais predicados podem ser usados na hipótese aprendida:

```prolog
backliteral(parent(X,Y), [X,Y]).
backliteral(female(X),   [X]).
backliteral(male(X),     [X]).
```

E os fatos da família:

```
Tom e Pam são pais de Bob.
Tom é pai de Liz.
Bob é pai de Ann e Pat.
Pat é pai de Jim e Eve.
```

### 2. Exemplos positivos e negativos

```prolog
ex(has_daughter(tom)).   % tom TEM filha (liz)
ex(has_daughter(bob)).   % bob TEM filha (ann, pat)
ex(has_daughter(pat)).   % pat TEM filha (eve)

nex(has_daughter(pam)).  % pam NÃO tem filha
nex(has_daughter(jim)).  % jim NÃO tem filha
```

### 3. Hipótese inicial

```prolog
start_hyp([[has_daughter(X)]/[X]]).
```

A hipótese começa vazia: `has_daughter(X).` — sem corpo, sem condições.

---

## Como o algoritmo funciona

O MINIHYPER usa **iterative deepening** — busca em profundidade com limite crescente:

```
Profundidade 0: has_daughter(X).                          → incompleta
Profundidade 1: has_daughter(X) :- parent(X,Y).           → inconsistente
Profundidade 2: has_daughter(X) :- parent(X,Y), female(Y). → SOLUÇÃO ✓
```

A cada passo, um literal de background é adicionado ao corpo da cláusula. O processo para quando a hipótese é:

- **Completa**: cobre todos os exemplos positivos
- **Consistente**: não cobre nenhum exemplo negativo

---

## Os 6 experimentos

### Experimento 1 — Baseline (original)

```prolog
ex(has_daughter(tom)).
ex(has_daughter(bob)).
ex(has_daughter(pat)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).
```

**Resultado:**
```prolog
has_daughter(A) :- parent(A,B), female(B).
```
Hipótese correta e mínima. Encontrada na profundidade 4.

---

### Experimento 2 — Menos exemplos positivos (remove `pat`)

```prolog
ex(has_daughter(tom)).
ex(has_daughter(bob)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).
```

**Resultado:** mesma hipótese correta.

**Conclusão:** dois exemplos positivos já são suficientes para induzir a regra,
pois `tom` e `bob` juntos evidenciam o padrão `parent + female`.

---

### Experimento 3 — Sem exemplos negativos

```prolog
ex(has_daughter(tom)).
ex(has_daughter(bob)).
ex(has_daughter(pat)).
% sem nex(...)
```

**Resultado provável:**
```prolog
has_daughter(A) :- parent(A,B).
```

**Conclusão:** sem negativos, nada impede a hipótese de ser geral demais.
A condição `female(B)` é descartada porque não há contra-exemplos com filhos homens.

---

### Experimento 4 — Exemplo positivo incorreto (ruído)

```prolog
ex(has_daughter(jim)).  % ERRADO: jim não tem filhos
```

**Resultado:** `induce(H)` **falha**.

**Conclusão:** não existe nenhuma combinação de literais de background que
cubra `jim` (ele não aparece como pai em nenhum fato). Dados ruidosos
tornam o aprendizado impossível neste sistema.

---

### Experimento 5 — Exemplos contraditórios

```prolog
ex(has_daughter(bob)).   % positivo
nex(has_daughter(bob)).  % negativo — contradição!
```

**Resultado:** `induce(H)` **falha**.

**Conclusão:** nenhuma hipótese pode ser ao mesmo tempo completa (cobrir `bob`)
e consistente (não cobrir `bob`). O sistema não lida com ruído ou contradições.

---

### Experimento 6 — Apenas um exemplo positivo

```prolog
ex(has_daughter(tom)).
nex(has_daughter(pam)).
nex(has_daughter(jim)).
```

**Resultado:** pode encontrar a hipótese correta, mas também pode aceitar
hipóteses mais específicas como:
```prolog
has_daughter(A) :- parent(A, liz).
```

**Conclusão:** poucos exemplos deixam o espaço de hipóteses mal restringido —
soluções "decoradas" (que memorizam o exemplo) podem surgir.

---

## Resumo comparativo

| Experimento | Modificação | Hipótese aprendida | Observação |
|:-----------:|-------------|-------------------|------------|
| 1 | Baseline | `has_daughter(A) :- parent(A,B), female(B).` | Correta ✓ |
| 2 | Remove 1 positivo | Mesma hipótese | 2 exemplos bastam |
| 3 | Sem negativos | `has_daughter(A) :- parent(A,B).` | Geral demais |
| 4 | Positivo ruidoso | **Falha** | Ruído impossibilita aprendizado |
| 5 | Contradição | **Falha** | Inconsistência nos dados |
| 6 | 1 só positivo | Hipótese específica demais | Risco de overfitting |

---

## Lição principal

> A qualidade dos exemplos determina a qualidade da hipótese aprendida.
> O MINIHYPER é sensível a ruído e contradições, e requer exemplos negativos
> para evitar hipóteses excessivamente gerais.

---

## Como rodar no SWISH

1. Acesse [swish.swi-prolog.org](https://swish.swi-prolog.org)
2. Cole o código do arquivo `exercise_21_1_swish.pl`
3. Na caixa de query, digite:

```prolog
induce(H).
```

O sistema imprimirá as profundidades tentadas e retornará a hipótese aprendida.
