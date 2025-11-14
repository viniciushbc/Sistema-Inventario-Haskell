# Sistema de Inventário em Haskell

Sistema de controle de inventário desenvolvido em Haskell, utilizando funções puras para a lógica de negócio e funções de I/O apenas para interação com o usuário e persistência em arquivos (`Inventario.dat` e `Auditoria.log`).

O programa permite:

* Cadastrar itens no inventário
* Atualizar/Definir quantidades
* Remover quantidades
* Consultar itens
* Listar todos os itens
* Gerar relatório de movimentações e erros a partir do arquivo de auditoria

---

## 1. Informações da Disciplina

* **Instituição:** *Pontifícia Universidade Católica do Paraná - PUCPR*
* **Curso:** *Bacharelado em Ciência da Computação*
* **Disciplina:** *Programação Lógica e Funcional*
* **Professor(a):** *Frank Coelho de Alcantara*

### Grupo

* *Aluno [1] & [3] - Eduardo dos Santos Rodrigues* — GitHub: [@eduardo13ds](https://github.com/eduardo13ds)
* *Aluno [2] & [4] - Vinícius Henrique Budag Coelho* — GitHub: [@viniciushbc](https://github.com/viniciushbc)

---

## 2. Como executar?

**Como executar?**
Acesse o OnlineGDB pelo link: *[main.hs](https://onlinegdb.com/bcC1uMUco)*

### Passos básicos

1. Acesse o link acima (projeto já configurado no OnlineGDB).
2. Verifique se o código Haskell está na aba principal (`main.hs`).
3. Clique em **Run** para executar.
4. Use o menu exibido no console para interagir com o sistema.

---

## 3. Estrutura do Código

O código segue a seguinte organização:

### 3.1. Tipos de Dados

#### Item

```haskell
data Item = Item {
    itemID     :: String,
    nome       :: String,
    quantidade :: Int,
    categoria  :: String
} deriving(Show, Read)
```

#### Logs

```haskell
data AcaoLog = Adicionar | Remover | Atualizar | Consulta
  deriving (Show, Read)

data StatusLog = Sucesso String | Erro String
  deriving (Show, Read)

data LogEntry = LogEntry {
    timestamp :: UTCTime,
    acao      :: AcaoLog,
    detalhes  :: String,
    status    :: StatusLog,
    idItemLog :: String
} deriving(Show, Read)

type ResultadoOperacao = (Map.Map String Item, LogEntry)
```

---

### 3.2. Funções de Lógica de Negócio (Funções Puras)

Principais funções da lógica:

* **`adicionarItem`**

  * Valida quantidade inicial (> 0).
  * Verifica se o ID do item já existe no inventário.
  * Em caso de **item duplicado**:

    * Não altera o inventário.
    * Retorna `Right (inventario, registro)` com `status = Erro "Falha: item duplicado"`.
  * Em caso de **sucesso**:

    * Insere o item no `Map`.
    * Retorna `Right (inventarioAtualizado, registro)` com `status = Sucesso "Sucesso!"`.
  * Em caso de **quantidade inválida** (<= 0):

    * Retorna `Left "A quantidade inicial deve ser maior que zero."`.

---

* **`removerItem`**

  * Remove completamente um item do inventário (pelo ID), se existir.
  * Em caso de sucesso, retorna `Right (inventarioAtualizado, registro)`.
  * Em caso de item inexistente, retorna `Left "O item não existe no inventario"`.

---

* **`atualizarItem`**

  * Define uma **nova quantidade absoluta** para o item (sobrescreve a quantidade atual).
  * Em caso de item inexistente, retorna `Left "O item não existe no inventario"`.

---

* **`consultarItem`**

  * Verifica se o item existe pelo ID.
  * Em caso de sucesso, **não altera** o inventário e retorna:

    * `Right (inventario, registro)` com `acao = Consulta`.
  * Em caso de inexistência, retorna `Left "Item nao encontrado"`.

---

* **`removerQuantidade`**

  * Lê a quantidade atual do item.
  * Se a quantidade a remover for **menor ou igual a 0**:

    * `Left "A quantidade a remover deve ser maior que zero."`
  * Se a quantidade a remover for **maior que o estoque atual**:

    * Não altera o inventário.
    * Retorna `Right (inventario, registro)` com
      `status = Erro "Falha: estoque insuficiente"`.
  * Se a remoção **zerar o estoque**:

    * Chama `removerItem` e remove o item por completo.
  * Se a remoção for **válida** (quantidade restante > 0):

    * Atualiza a quantidade e retorna `Right (inventarioAtualizado, registro)` com `Sucesso`.

---

### 3.3. Funções de Relatório (Análise de Logs)

* **`historicoPorItem :: String -> [LogEntry] -> [LogEntry]`**
  Retorna todos os registros de log referentes ao `itemID` informado.

* **`logsDeErro :: [LogEntry] -> [LogEntry]`**
  Filtra apenas as entradas de log em que `status` é `Erro ...`.

* **`itemMaisMovimentado :: [LogEntry] -> Maybe (String, Int)`**
  Conta quantas vezes cada `itemID` aparece na lista de logs e retorna o item com maior número de movimentações (ou `Nothing` se não houver registros).

---

### 3.4. Persistência (Arquivos)

* **Inventário (`Inventario.dat`)**

  * `salvarInventario "Inventario.dat"`
    Serializa o `Map String Item` com `show` e grava em arquivo.

  * `carregarInventario "Inventario.dat"`

    * Se o arquivo **não existir**, retorna `Map.empty`.
    * Se existir, utiliza `read` para reconstruir o mapa.

* **Auditoria (`Auditoria.log`)**

  * `salvarLog "Auditoria.log"`
    Serializa um `LogEntry` com `show` e faz `append` no arquivo.

  * `carregarLogs "Auditoria.log"`

    * Se o arquivo não existir, retorna lista vazia.
    * Caso exista, lê linha a linha e usa `read` para reconstruir `[LogEntry]`.

---

### 3.5. Loop Principal (Menu Interativo)

A função principal de loop é:

```haskell
loop :: Map.Map String Item -> IO ()
```

Responsável por:

* Exibir o menu com as opções:
  `1` Adicionar, `2` Remover quantidade, `3` Atualizar quantidade, `4` Consultar, `5` Listar, `6` Relatório, `0` Sair.
* Ler a opção do usuário com `getLine`.
* Ler os dados necessários (ID, nome, quantidade, categoria).
* Chamar as **funções puras** (`adicionarItem`, `removerQuantidade`, `atualizarItem`, `consultarItem`).
* Tratar:

  * `Left` → erros estruturais (ex.: quantidade inválida, item inexistente).
  * `Right` → tanto sucesso quanto falhas de regra de negócio (estoque insuficiente, item duplicado), inspecionando `status` no `LogEntry`.
* Salvar inventário e logs sempre que necessário.
* Rechamar `loop` com o inventário atualizado.

A função `main`:

```haskell
main :: IO ()
main = do
  inventarioInicial <- carregarInventario "Inventario.dat"
  loop inventarioInicial
```
---

## 4. Observações sobre o Repositório e Commits

* O desenvolvimento principal foi feito no **OnlineGDB**, onde o grupo implementou e testou todo o código interativamente.
* O repositório GitHub foi criado **apenas após** o término do trabalho, e o código-fonte final foi enviado via upload (não há um histórico incremental de commits de desenvolvimento).

---
