import Data.Map as Map
import Data.Time (UTCTime, getCurrentTime)
import System.IO (writeFile, appendFile)
import Data.List (maximumBy)
import Data.Ord (comparing)
import System.Directory (doesFileExist)


-- ##########################################
-- 2.1 MODULOS PRINCIPAIS: LOGICA E DADOS (ALUNO 1)
-- #####################################

-- definindo o "obejto" item
data Item = Item {
    itemID :: String,
    nome :: String,
    quantidade :: Int,
    categoria :: String
} deriving(Show, Read)

-- definindo o dicionario para guardar os itens (chave é String, e valor é Item)
inventario :: Map.Map String Item
inventario = Map.empty

-- definindo o tipo de Acao
data AcaoLog = Adicionar | Remover | Atualizar | Consulta
  deriving (Show, Read)

-- definindo o tipo de status
data StatusLog = Sucesso String | Erro String
  deriving (Show, Read)

-- definindo o "objeto" LogEntry (serve so como um registro de algo que foi feito)
data LogEntry = LogEntry {
    timestamp :: UTCTime,
    acao :: AcaoLog,
    detalhes :: String,
    status :: StatusLog,
    idItemLog :: String
} deriving(Show, Read)









-- ##########################################
-- 2.1.2 FUNCOES PURAS (ALUNO 2)
-- Implementar função de ID Duplicado
-- Talvez corrigir depois, adicionando Right para casos de falha, pq desse jeito o StatusLog só tem "Sucessos"
-- #####################################

type ResultadoOperacao = (Map.Map String Item, LogEntry)


-- ===========================================================
-- ADICIONAR Item
adicionarItem :: UTCTime -> String -> String -> Int -> String -> Map.Map String Item -> Either String ResultadoOperacao

-- recebe os parametros do item e o dicionario
adicionarItem horario itemID nome quantidade categoria inventario =
  -- validação estrutural da quantidade
  if quantidade <= 0
    then
      Left "A quantidade inicial deve ser maior que zero."
    else
      -- cria o item
      let item = Item itemID nome quantidade categoria
      -- verifica se o item ja existe no inventario (encontra pelo ID)
      in if Map.member itemID inventario
           then
             let registro = LogEntry horario Adicionar "Tentativa de adicionar item já existente no inventario" (Erro "Falha: item duplicado") itemID
             in Right (inventario, registro)
           else
             -- sucesso: insere o item e registra sucesso
             let inventarioAtualizado = Map.insert itemID item inventario
                 registro = LogEntry horario Adicionar "Item adicionado" (Sucesso "Sucesso!") itemID
             in Right (inventarioAtualizado, registro)







-- ===========================================================
-- REMOVER ITEM
-- removerItem(horario, itemID, inventario) retorna string ou resultadoOperacao

removerItem :: UTCTime -> String -> Map.Map String Item -> Either String ResultadoOperacao

-- recebe os parametros do item e o dicionario
removerItem horario itemID inventario =
  -- verifica se o item existe no inventario (encontra pelo ID)
  if Map.member itemID inventario
    then
      let inventarioAtualizado = Map.delete itemID inventario
          registro             = LogEntry horario Remover "teste" (Sucesso "Sucesso!") itemID
      in Right (inventarioAtualizado, registro) -- Right = Resultado da Operação
    else
      Left "O item não existe no inventario" -- Left = String







-- ===========================================================
-- ATUALIZAR QUANTIDADE DO ITEM
-- atualizarItem(horario, itemID, quantidadeNova, inventario) retorna string ou resultadoOperacao

atualizarItem :: UTCTime -> String -> Int -> Map.Map String Item -> Either String ResultadoOperacao

-- recebe os parametros do item e o dicionario
atualizarItem horario itemID quantidadeNova inventario =
  -- verifica se o item existe no inventario (encontra pelo ID)
  if Map.member itemID inventario
    then
      -- funcao lambda (recebe um parametro chamado item que é associado com a chave itemID no invetario, se existir a funcao é aplicada)
      let inventarioAtualizado =
            Map.update (\item -> Just item { quantidade = quantidadeNova }) itemID inventario
          registro = LogEntry horario Atualizar "teste" (Sucesso "Sucesso!") itemID
      in Right (inventarioAtualizado, registro) -- Right = Resultado da Operação
    else
      Left "O item não existe no inventario" -- Left = String





-- ===========================================================
-- CONSULTAR ITEM
-- consultarItem(horario, itemID, inventario) retorna string ou resultadoOperacao

consultarItem :: UTCTime -> String -> Map.Map String Item -> Either String ResultadoOperacao
consultarItem horario itemID inventario =
  -- Verifica se o item existe no inventário (encontra pelo ID)
  if Map.member itemID inventario
    then
      let registro = LogEntry horario Consulta "Item encontrado no inventário" (Sucesso "Sucesso!") itemID
      in Right (inventario, registro) -- Right = Resultado da operação
    else
      Left "Item nao encontrado" -- Left = String




-- ===========================================================
-- REMOVER QUANTIDADE DO ITEM
-- removerQuantidade(horario, itemID, quantidadeRemover, inventario)
-- retorna string ou resultadoOperacao
removerQuantidade :: UTCTime -> String -> Int -> Map.Map String Item -> Either String ResultadoOperacao
removerQuantidade horario itemID quantidadeRemover inventario =
  case Map.lookup itemID inventario of
    --LOOKUP PRA VER SE O ITEM EXISTE
    Nothing ->
      Left "O item não existe no inventario"

    Just itemAtual ->
      let quantidadeAtual  = quantidade itemAtual
          novaQuantidade   = quantidadeAtual - quantidadeRemover
      in if quantidadeRemover <= 0
           then
             Left "A quantidade a remover deve ser maior que zero."
         else if novaQuantidade < 0
           then
             --ESTOQUE INSUFICIENTE
             let registro =
                   LogEntry
                     horario
                     Remover
                     "Tentativa de remover mais itens que o estoque tem disponivel"
                     (Erro "Falha: estoque insuficiente")
                     itemID
             -- inventario NAO MUDA
             in Right (inventario, registro)
         else if novaQuantidade == 0 -- SE A QUANTIDADE FOR 0, REMOVER ITEM
           then
             -- zerei o estoque: agora posso remover o item inteiro usando removerItem
             removerItem horario itemID inventario
         else
             -- REMOCAO VALIDA: ATUALIZA QUANTIDADE
             let itemAtualizado       = itemAtual { quantidade = novaQuantidade }
                 inventarioAtualizado = Map.insert itemID itemAtualizado inventario
                 registro =
                   LogEntry
                     horario
                     Remover
                     "Remocao de unidades do estoque"
                     (Sucesso "Sucesso!")
                     itemID
             in Right (inventarioAtualizado, registro)









-- ##########################################
-- 4. FUNCOES PURAS DE RELATORIO (ALUNO 4)
-- ANALISE DE LOGS
-- #####################################

-- ===========================================================
-- HISTORICO POR ITEM
-- historicoPorItem(itemID, [Registros]) retorna [Registros]

historicoPorItem :: String -> [LogEntry] -> [LogEntry]
historicoPorItem buscaID logs =
  Prelude.filter (\registros -> idItemLog registros == buscaID) logs



-- ===========================================================
-- LOGS DE ERRO
-- logsDeErro([Registros]) retorna [Registros]

logsDeErro :: [LogEntry] -> [LogEntry]
logsDeErro logsComErro =
  Prelude.filter
    (\registro ->
       case status registro of
         Erro _    -> True
         Sucesso _ -> False
    )
    logsComErro



-- ===========================================================
-- RANK MOVIMENTACAO
-- itemMaisMovimentado([Registros]) retorna (itemID, movimentacoes)
itemMaisMovimentado :: [LogEntry] -> Maybe (String, Int)
itemMaisMovimentado logs =
    
    -- contagem: dicionario com (ID, Quantidade de vezes q aparece)
    let contagem :: Map.Map String Int
        contagem =
            -- fromListWith (+) SOMA VALORES(aparicoes) DE CHAVES(Id's) REPETIDAS
            Map.fromListWith (+)
                [ (idItemLog logEntry, 1) | logEntry <- logs ]

    -- se o dicionario for vazio, nao existe item mais movimentado
    in if Map.null contagem
        then Nothing
        else
            -- maximumBy (comparing snd) pega o par (chave, valor) com maior "valor", no caso quantidade de aparicoes
            Just (maximumBy (comparing snd) (Map.toList contagem))



-- ===========================================================
-- CARREGA LOGS DO ARQUIVO AUDITORIA.LOG
-- carregarLogs(arquivo.log) retorna [LogEntry]
carregarLogs :: FilePath -> IO [LogEntry]
carregarLogs arquivo = do
  existe <- doesFileExist arquivo
  if not existe
    then return []  -- se ainda nao existe log, retorna lista vazia
    else do
      conteudo <- readFile arquivo
      let linhas = Prelude.filter (not . Prelude.null) (lines conteudo)
          logs   = Prelude.map read linhas :: [LogEntry]  -- usa Read derivado de LogEntry
      return logs



-- ===========================================================
-- CARREGA O INVENTARIO DO ARQUIVO INVENTARIO.DAT
-- carregarInventario(arquivo.dat) retorna Map String Item
carregarInventario :: FilePath -> IO (Map.Map String Item)
carregarInventario arquivo = do
  existe <- doesFileExist arquivo
  if not existe
    then return Map.empty-- se ainda nao existir o arquivo, começa com um invetario vazio
    else do
      conteudo <- readFile arquivo
      let inventarioDat = read conteudo :: Map.Map String Item
      return inventarioDat







-- ##########################################
-- 3. Loop Principal e Persistência (IO) (ALUNO 3)
-- #####################################


-- SALVAR O INVENTARIO NO ARQUIVO INVENTARIO.DAT
-- salvarInventario(arquivo.dat, inventario)
salvarInventario :: FilePath -> Map.Map String Item -> IO ()
salvarInventario arquivo inventario = do
  let inventarioStr = show inventario ++ "\n" -- "show" transforma o inventario pra string
  writeFile arquivo inventarioStr             -- reescreve a string no arquivo


-- SALVA OS REGISTROS NO ARQUIVO AUDITORIA.LOG
-- salvarLog(arquivo.log, registro)
salvarLog :: FilePath -> LogEntry -> IO ()
salvarLog arquivo logEntry = do
  let logStr = show logEntry ++ "\n" -- transforma o log pra string
  appendFile arquivo logStr          -- adiciona no arquivo (append, vira histórico)


-- MENU - LOOP DE EXECUCAO
-- loop(inventario)
loop :: Map.Map String Item -> IO ()
loop inventarioLoop = do
  putStrLn " --------------- \n"
  putStrLn "1 - Adicionar Item"
  putStrLn "2 - Remover quantidade do Item"
  putStrLn "3 - Atualizar Quantidade (definir valor)"
  putStrLn "4 - Consultar Item"
  putStrLn "5 - Listar Itens"
  putStrLn "6 - Relatório de registros\n"
  putStrLn "0 - Fechar o programa\n"
  putStrLn "Selecione a ação: "

  opcaoSelecionada <- getLine

  case opcaoSelecionada of
    "1" -> do
      putStrLn "\n= ADICIONANDO NOVO ITEM\n"
      putStrLn "ID: "
      idItem <- getLine

      putStrLn "Nome: "
      nomeItem <- getLine

      putStrLn "Quantidade: "
      quantidadeItemString <- getLine

      putStrLn "Categoria: "
      categoriaItem <- getLine

      let quantidadeItem = read quantidadeItemString :: Int -- READ transforma um str pra int

      horario <- getCurrentTime

      let resultado =
            adicionarItem horario idItem nomeItem quantidadeItem categoriaItem inventarioLoop

      -- TRATAMENTO DE ERRO "TRY CATCH"
      case resultado of
        -- se o resultado for Left, erro, printa a mensagem
        Left stringErro -> do
          putStrLn "\n---------------"
          putStrLn ("Erro: " ++ stringErro)
          putStrLn "---------------\n"
          loop inventarioLoop

        -- se o resultado for Right, sucesso/falha, segue o fluxo
        Right (inventarioNovo, registro) -> do
          salvarLog "Auditoria.log" registro
          case status registro of
            Erro msg -> do
              putStrLn "\n---------------"
              putStrLn ("Erro: " ++ msg)
              putStrLn "---------------\n"
              -- inventário não muda nesse caso
              loop inventarioLoop

            Sucesso _ -> do
              salvarInventario "Inventario.dat" inventarioNovo
              putStrLn "\n---------------"
              putStrLn "Item adicionado com sucesso!"
              putStrLn "---------------\n"
              loop inventarioNovo


    "2" -> do
      putStrLn "\n= REMOVENDO QUANTIDADE DO ITEM\n"
      putStrLn "ID: "
      idItem <- getLine

      putStrLn "Quantidade a remover: "
      quantidadeRemoverStr <- getLine
      let quantidadeRemover = read quantidadeRemoverStr :: Int

      horario <- getCurrentTime

      let resultado = removerQuantidade horario idItem quantidadeRemover inventarioLoop

      case resultado of
        -- erro estrutural: item nao existe, quantidade <= 0, etc.
        Left stringErro -> do
          putStrLn "\n---------------"
          putStrLn ("Erro: " ++ stringErro)
          putStrLn "---------------\n"
          loop inventarioLoop

        -- sucesso OU falha de logica (estoque insuficiente) vêm em Right
        Right (inventarioNovo, registro) -> do
          -- sempre salvar o LOG (tanto sucesso quanto falha de logica)
          salvarLog "Auditoria.log" registro
          case status registro of
            Erro msg -> do
              -- FALHA DE LÓGICA: ESTOQUE INSUFICIENTE
              putStrLn "\n---------------"
              putStrLn ("Erro: " ++ msg)
              putStrLn "---------------\n"
              -- inventario nao muda nesse caso
              loop inventarioLoop

            Sucesso _ -> do
              -- SUCESSO: atualiza o arquivo de inventario e o mapa em memoria
              salvarInventario "Inventario.dat" inventarioNovo
              putStrLn "\n---------------"
              putStrLn "Remocao de unidades realizada com sucesso!"
              putStrLn "---------------\n"
              loop inventarioNovo

    "3" -> do
      putStrLn "\n= ATUALIZANDO QUANTIDADE\n"
      putStrLn "ID: "
      idItem <- getLine

      putStrLn "Nova quantidade: "
      quantidadeItem <- getLine

      let quantidadeNova = read quantidadeItem :: Int

      horario <- getCurrentTime

      let resultado = atualizarItem horario idItem quantidadeNova inventarioLoop

      case resultado of
        Left stringErro -> do
          putStrLn "\n---------------"
          putStrLn ("Erro: " ++ stringErro)
          putStrLn "---------------\n"
          loop inventarioLoop

        Right (inventarioNovaQuantidade, registro) -> do
          salvarInventario "Inventario.dat" inventarioNovaQuantidade
          salvarLog "Auditoria.log" registro
          putStrLn "\n---------------"
          putStrLn "Quantidade atualizada com sucesso!"
          putStrLn "---------------\n"
          loop inventarioNovaQuantidade

    "4" -> do
      putStrLn "\n= CONSULTANDO ITEM\n"
      putStrLn "ID: "
      idItem <- getLine

      horario <- getCurrentTime

      let resultado = consultarItem horario idItem inventarioLoop

      case resultado of
        -- erro: item não encontrado
        Left stringErro -> do
          putStrLn "\n---------------"
          putStrLn ("Erro: " ++ stringErro)
          putStrLn "---------------\n"
          loop inventarioLoop

        -- sucesso: salva log e mostra o item
        Right (_, registro) -> do
          salvarLog "Auditoria.log" registro
          putStrLn "\n---------------"
          putStrLn "Consulta realizada com sucesso!"
          putStrLn "---------------\n"

          case Map.lookup idItem inventarioLoop of
            Just item -> print item     -- imprime o item completo
            Nothing   -> return ()      -- em tese não deveria cair aqui

          loop inventarioLoop

    "5" -> do
      putStrLn "\n= INVENTARIO\n"
      if Map.null inventarioLoop
        then putStrLn "Nenhum item cadastrado."
        else mapM_ print (Map.toList inventarioLoop)
      putStrLn ""
      loop inventarioLoop

    "6" -> do
      putStrLn "\n= RELATORIO DE REGISTROS\n"

      -- carrega todos os logs do arquivo
      logs <- carregarLogs "Auditoria.log"

      putStrLn $ "Total de registros de log: " ++ show (length logs)

      -- ITEM MAIS MOVIMENTADO
      putStrLn "\n-- Item mais movimentado --"
      case itemMaisMovimentado logs of
        Nothing -> putStrLn "Nao ha movimentacoes registradas."
        Just (idMais, qtd) ->
          putStrLn $ "Item: " ++ idMais ++ " | Movimentacoes: " ++ show qtd

      -- LOGS DE ERRO
      putStrLn "\n-- Logs de erro --"
      let erros = logsDeErro logs
      if Prelude.null erros
        then putStrLn "Nenhum erro registrado."
        else mapM_ print erros

      -- HISTORICO POR ITEM
      putStrLn "\n-- Historico por item --"
      putStrLn "ID do item:"
      idBusca <- getLine

      if Prelude.null idBusca
        then do
          putStrLn "\nVoltando ao menu...\n"
          loop inventarioLoop
        else do
          let historico = historicoPorItem idBusca logs
          if Prelude.null historico
            then putStrLn "Nenhum registro encontrado para esse item."
            else mapM_ print historico
          loop inventarioLoop

    "0" -> do
      putStrLn "\nSaindo...\n"
      return ()

    _ -> do
      putStrLn "\nOpção inválida!\n"
      loop inventarioLoop


main :: IO ()
main = do
  inventarioInicial <- carregarInventario "Inventario.dat"
  loop inventarioInicial
