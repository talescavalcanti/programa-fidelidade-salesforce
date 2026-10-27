# Roteiro de Apresentação — PontoCerto

**Duração sugerida:** 15 a 18 minutos (10 de demonstração, 5 a 8 de explicação e perguntas).
**Regra de ouro:** explique com as suas palavras. As falas abaixo são um ponto de partida; se algo não fizer
sentido para você, reescreva. Cada bloco termina com *"em uma frase"*, que é o que você deve saber dizer de cabeça.

## Antes de começar (5 minutos de preparação)

- [ ] Abra o org e o app **PontoCerto**. Deixe aberta uma aba com o **Dashboard Executivo** e outra com o repositório no GitHub.
- [ ] Atualize os dois dashboards (botão **Atualizar**).
- [ ] Confirme que o cliente **Maria Souza** mostra o resgate da *Caneca PontoCerto* em **Em Aprovação**.
- [ ] Tenha o `docs/marca/logo-pontocerto.svg` aberto para o primeiro slide, ou imprima-o.
- [ ] Anote a senha de quem for usar o **Login como** (Configuração → Usuários → Usuários → **Login**).
- [ ] Se a demonstração for repetida, rode `sf apex run -f scripts/apex/dados_demo.apex` em um org limpo.

**Dados de demonstração**

| Participante | Situação | Para que serve na demo |
|---|---|---|
| **Maria Souza** | Ouro, VIP, saldo de 5.000 pontos, resgate da Caneca (1.500 pts) pendente | Aprovação em 2 níveis, saldo, VIP |
| **João Lima** | Prata, saldo de 1.000 pontos | Resgate pequeno aprovado sozinho |
| **Ana Costa** | Bronze, saldo de 300 pontos | Progresso para a próxima categoria |
| **Pedro Alves** | Inativo | Dynamic Forms: seção e ação somem |

**Usuários** (Login como): `operador.512b2c4f1757@agentforce.com` (Perfil Operacional, papel Operador),
`coordenador.512b2c4f1757@agentforce.com` (Perfil Gestor, papel Coordenador, com o Permission Set *Ajuste de Pontos*),
`diretor.512b2c4f1757@agentforce.com` (Perfil Administrativo, papel Diretor).

---

## Bloco 1 — Abertura e marca (1 min)

**Mostre:** a logomarca e a tela inicial do app PontoCerto.

**Fale:** "O PontoCerto é um programa de fidelidade construído no Salesforce. O cliente acumula pontos, uma
campanha pode multiplicar esses pontos, e ele troca o saldo por benefícios. Quando o resgate é grande, passa por
aprovação em dois níveis. O nome vem da ideia de que cada ponto conta. A logomarca é uma estrela, que remete a
pontos e recompensas, com uma marca de confirmação, que remete ao *ponto certo*. As cores são azul, que passa
confiança, e dourado, que lembra recompensa."

**Em uma frase:** *Gerencia pontuação, benefícios, resgates e campanhas, que é o objetivo do Tópico 4.*

## Bloco 2 — Modelo de dados (2 min)

**Mostre:** o diagrama da seção 2 do `RELATORIO_FINAL.md` (ou o Gerenciador de objetos).

**Fale:** "Tenho 8 objetos: os 6 do tema, mais o Endereço, que o ViaCEP exige, e um Log de Integração para
auditoria. O **Programa Fidelidade** é a adesão de um cliente. Movimentação, Resgate, Saldo e Endereço são
**Master-Detail** dele, porque precisam dele para existir e porque só o Master-Detail permite **Roll-Up**: o
*Total de Pontos* soma as movimentações e o *Total de Resgates* soma os resgates que não foram rejeitados.
Benefício, Campanha e Log usam **Lookup**, porque são catálogos ou registros que não dependem do pai. O **Saldo
de Pontos** tem as duas fórmulas: *Saldo Atual* é pontos menos resgates, e *Categoria Atual* é Bronze, Prata ou
Ouro conforme o total acumulado. O Benefício tem três **Tipos de registro**: Cashback, Desconto e Brinde, cada um com campos
e regras próprios."

**Em uma frase:** *Master-Detail onde preciso de Roll-Up, Lookup onde o registro é independente.*

## Bloco 3 — Participante, pontos e campanha (3 min)

**Passos:**
1. Abra **Maria Souza**. Mostre o cartão **Saldo de Pontos**: saldo 5.000, categoria **Ouro**, barra de progresso.
2. Mostre a seção **Resumo de Pontos** (Total de Pontos 7.000, Total de Resgates 2.000).
3. Abra **Pedro Alves** (Inativo): a seção de pontos e a ação **Novo Resgate** não aparecem.
4. Volte à Maria → lista **Movimentações de Pontos** → **Novo**. Informe **Pontos Base 400** e escolha a campanha
   **Pontos em Dobro Nov**. Salve e mostre que **Pontos = 800**, calculado sozinho.
5. Volte à página da Maria e clique em **Atualizar** no cartão: o saldo subiu 800.

**Fale:** "O campo *Pontos* eu não digito: um **Flow disparado antes de salvar** calcula Pontos Base vezes o
multiplicador da campanha. Como é *before-save*, não gasta uma gravação extra. A campanha só aparece se estiver
ativa e vigente na data da movimentação, e isso é regra de filtro, sem código. Na página, usei **Dynamic Forms**:
a seção de pontos só aparece para cliente ativo, e a ação **Novo Resgate** é uma **Dynamic Action** com o mesmo
critério."

**Em uma frase:** *O Flow calcula os pontos, os Roll-Ups e as fórmulas mantêm saldo e categoria sempre corretos.*

## Bloco 4 — Benefícios e resgate (3 min)

**Passos:**
1. Na Maria, mostre o cartão **Benefícios Disponíveis**: quais ela pode resgatar e quantos pontos faltam para os outros.
   Ligue o filtro *Só os que posso resgatar*.
2. Clique em **Novo Resgate** (Screen Flow). Escolha **Cashback R$ 20** (500 pts) e conclua: o Resgate nasce e fica
   **Aprovado** sozinho, e o saldo cai 500.
3. Mostre o resgate da **Caneca** (1.500 pts) em **Em Aprovação**: o saldo já descontou esses pontos (ficaram reservados).
4. Mostre a aprovação:
   - **Login como Coordenador** → itens a aprovar → aprove (nível 1).
   - **Login como Diretor** → aprove (nível 2). O Status vira **Aprovado**.
5. (Opcional) Crie outro resgate grande e **rejeite**: o Status vira **Rejeitado** e os pontos voltam ao saldo.

**Fale:** "Resgate até 1.000 pontos é aprovado automaticamente. Acima disso, o Flow envia para o **processo de
aprovação de dois níveis**: primeiro o Coordenador, depois o Diretor. Enquanto está pendente, o resgate **não é
efetivado**, mas **já reserva os pontos**, porque o Roll-Up conta tudo que não foi rejeitado. Se for rejeitado,
os pontos voltam sozinhos, sem código. O limite está em um só lugar, o **Subflow** de verificação, que é usado
tanto pelo Flow do resgate quanto pelo Screen Flow, que avisa o usuário se vai precisar de aprovação."

**Em uma frase:** *Aprovação por valor, em dois níveis, e o pendente reserva os pontos sem processar nada definitivo.*

## Bloco 5 — ViaCEP e auditoria (2 min)

**Passos:**
1. Na Maria → **Endereços** → **Novo**. Informe o CEP **01310100** (sem hífen) e o número. Salve.
2. Na página do Endereço, o cartão **Consulta de CEP** mostra *Pendente* e, em segundos, **Sucesso** com a mensagem.
   Mostre os campos preenchidos: Avenida Paulista, Bela Vista, São Paulo, SP.
3. Mostre a lista **Logs de Integração**: código HTTP 200 e a resposta da API.
4. Crie outro endereço com **99999999**: Status **Erro**, log "CEP não encontrado". Tente **12AB**: é recusado na hora.

**Fale:** "Uma *trigger* não pode fazer chamada HTTP enquanto grava. Por isso a trigger do Endereço, que segue
meu **Trigger Framework**, só padroniza o CEP e **enfileira um Queueable**. O Queueable roda em segundo plano,
chama o ViaCEP, preenche o endereço e **grava um log de auditoria**, de sucesso ou de erro. Usei um objeto de log
porque *debug* some, e o log fica disponível para relatório."

**Em uma frase:** *Trigger + Queueable fazem o callout fora da gravação, e o log guarda tudo para auditoria.*

## Bloco 6 — Segurança (2 min)

**Passos:**
1. **Login como Operador:** tente excluir um cliente (não há o botão) e registrar um **Ajuste** em uma movimentação
   (é bloqueado: "Apenas usuários com o conjunto de permissões Ajuste de Pontos...").
2. **Login como Coordenador:** ele registra o **Ajuste** (tem o Permission Set) e enxerga os clientes do Operador.
3. Mostre o cliente **VIP** (Maria) aparecendo para o Operador, e um cliente comum de outro operador não.

**Fale:** "O **Perfil** diz o que o usuário pode fazer com cada objeto e campo: o Operacional cadastra e
solicita, o Gestor mantém catálogo e campanhas, o Administrativo tem acesso total. O **Papel** define quem
enxerga os registros de quem: Diretor, Coordenador e Operador formam a **hierarquia**, e o dado de um operador sobe
para os chefes. O acesso é **privado** por padrão, e a **Sharing Rule** libera os clientes VIP para todos os
operadores. O **Permission Set** dá uma função especial sem mudar de perfil: registrar ajustes de pontos."

**Em uma frase:** *Perfil define o que faz, papel define o que vê, regra compartilha por critério, Permission Set dá o extra.*

## Bloco 7 — Dashboards (1 min)

**Mostre:** Dashboard Executivo (**Clientes ativos**, **Engajamento**) e Dashboard Operacional (**Resgates
pendentes**, **Pontuação acumulada**).

**Fale:** "*Cliente ativo* é quem tem Status Ativo e ao menos uma movimentação nos últimos 90 dias.
*Engajamento* é a quantidade de movimentações por semana nos últimos 30 dias. *Resgates pendentes* é o que
está em aprovação, e *Pontuação acumulada* é a soma dos pontos. Conferi cada número com uma consulta direta aos dados."

**Em uma frase:** *Quatro indicadores simples e conferíveis, divididos entre gestão e operação.*

## Bloco 8 — Apex, testes e repositório (2 min)

**Mostre:** o repositório no GitHub e a execução dos testes (`sf apex run test`), ou o resultado já salvo.

**Fale:** "O **Trigger Framework** é uma classe base com um método por evento. Cada trigger tem um handler que
sobrescreve só o que precisa, e dá para desativar um handler nos testes. São **44 testes com 99% de cobertura**,
mas o importante é o que eles verificam: uso mock do ViaCEP, testo caminhos de erro, lote de 55 endereços, e
testo a segurança executando como um usuário de cada perfil. Todo o código e as configurações estão neste
repositório. O que não é código, como usuários e dados, mostro direto no Salesforce."

**Em uma frase:** *Apex só onde o Flow não alcança, testado de verdade, e tudo versionado.*

## Fechamento (30 s)

"Atendi todos os requisitos obrigatórios: modelo de dados, segurança, três Flows de gatilho, Screen Flow e
Subflows, aprovação em dois níveis, Apex com Queueable e ViaCEP, interface com Dynamic Forms, Dynamic Actions e
LWCs, dois dashboards, repositório e marca. Obrigado."

---

## Roteiro de contingência (se algo falhar ao vivo)

| Problema | O que fazer |
|---|---|
| O cartão de CEP fica em *Pendente* | Espere 5 segundos e clique em **Atualizar** (a consulta roda em segundo plano) |
| O Operador não vê o cliente VIP | O compartilhamento da regra é **assíncrono**: espere um pouco e recarregue |
| O dashboard parece vazio | Clique em **Atualizar** |
| A tela de login como outro usuário falha | Mostre os testes de segurança (`SegurancaFidelidadeTest`) e explique que eles rodam como cada perfil |
| O ViaCEP fora do ar | Mostre o log de erro: é o tratamento de falha funcionando (Status *Erro* + log) |

---

## Perguntas prováveis do professor (e como pensar nas respostas)

**1. Por que Master-Detail e não Lookup?**
Porque o Roll-Up Summary só funciona no pai de uma Master-Detail, e Movimentação e Resgate não fazem sentido sem o participante. Benefício, Campanha e Log são independentes, então usam Lookup.

**2. Por que as fórmulas estão no Saldo e os Roll-Ups no Programa?**
Fórmula lê campos do pai (os Roll-Ups) por relacionamento. O PDF não diz em qual objeto ficam; foi uma decisão minha, e o Saldo de Pontos é a "carteira" que exibe o resultado.

**3. Como você evita processar um resgate pendente antes da aprovação?**
O resgate nasce *Em Aprovação*, não é efetivado até o processo terminar, e já reserva os pontos porque o Roll-Up conta tudo que não foi rejeitado. Rejeitar devolve os pontos sozinho.

**4. Por que Queueable e não callout direto na trigger?**
Uma trigger não pode fazer callout enquanto grava (há trabalho não confirmado). O Queueable roda depois, em segundo plano, e pode chamar a API.

**5. Por que Queueable e não Batch?**
O volume é pequeno e acionado por evento (um endereço salvo). Batch é para processar grandes volumes em lote. Queueable é mais simples e basta.

**6. Como funciona o Trigger Framework?**
Uma classe base com um método por evento (antes/depois de inserir, atualizar etc.). Cada trigger só chama `new Handler().run()`. Assim há uma trigger por objeto e a lógica fica organizada e testável.

**7. Por que Flow para uns casos e Apex para outros?**
Flow para regras de negócio simples (calcular pontos, direcionar aprovação). Apex só onde o Flow não dá, como o callout com tratamento de resposta, e onde preciso de testes unitários.

**8. Por que o cálculo de pontos é um Flow *before-save*?**
É o mais rápido: altera o próprio registro antes de gravar, sem DML extra.

**9. Qual a diferença entre Perfil, Papel, Sharing Rule e Permission Set?**
Perfil: permissões base de objeto e campo. Papel: posição na hierarquia, define visibilidade para cima. Sharing Rule: abre acesso a registros por critério. Permission Set: permissões extras sem trocar de perfil.

**10. Por que o acesso ao Programa é privado?**
Para mostrar a hierarquia e a Sharing Rule funcionando. Cada operador vê só os seus clientes, o coordenador vê os do time, e os VIP são compartilhados.

**11. O que acontece se o ViaCEP cair?**
A consulta falha com tratamento: o Status vira *Erro*, o log registra a mensagem, e o usuário continua trabalhando. Nada quebra.

**12. Por que um objeto de log e não `System.debug`?**
Debug é temporário e some. O objeto é persistente, consultável e pode virar relatório, que é o que auditoria exige.

**13. O código funciona com muitos registros (bulk)?**
Sim. O handler percorre listas, e o Queueable processa até 50 endereços por execução e encadeia o resto. Testei com 10 e com 55 endereços.

**14. Como a regra "só participa de campanha vigente" é garantida?**
Por um filtro na relação de pesquisa *Campanha* da Movimentação (ativa, e a data da movimentação dentro do período). Fica na configuração, sem código, e vale também para cargas por API.

**15. Cobertura de 85% garante qualidade?**
Não por si só. Os meus testes têm *asserts* de comportamento: cenários positivos e negativos, erros de integração, lote e segurança por perfil. A cobertura é 99%, mas o que importa é o que eles verificam.

**16. O que é Dynamic Forms e Dynamic Actions?**
Dynamic Forms: campos e seções com regras de visibilidade na própria página, por exemplo mostrar o valor de cashback só no Tipo Cashback. Dynamic Actions: botões que aparecem conforme uma condição, como *Novo Resgate* só para cliente ativo.

**17. Como as LWCs falam com o Salesforce?**
Chamam métodos Apex do `FidelidadeController` com `@wire` (métodos `cacheable`), e o botão de atualizar usa `refreshApex`. O controlador usa `WITH USER_MODE`, então respeita as permissões do usuário.

**18. E se o limite de 1.000 pontos mudar?**
Altero em um só lugar, o Subflow `Sub_Verificar_Limite`. O Flow do resgate e o Screen Flow usam o mesmo.

**19. Quais as limitações e melhorias?**
Aprovadores fixos por usuário (poderia ser fila ou campo de gerente), sem validade de pontos, sem notificações por e-mail, sem Batch de fechamento mensal, e o logo ainda não está dentro do app. Eram opcionais fora do escopo.

**20. O que não está no repositório?**
Usuários, atribuição do Permission Set a eles e os dados de demonstração. O resto (objetos, flows, Apex, LWC, segurança, relatórios) é versionado.

**21. Como você validou que está tudo certo?**
Com testes Apex, com um cenário ponta a ponta executado por CLI, conferindo cada resultado esperado, e comparando os números dos relatórios com consultas diretas aos dados.

**22. Por que um campo de porcentagem se comporta diferente na validação?**
Em fórmulas e regras de validação o campo Porcentagem é lido como decimal (100% é 1). Percebi isso num teste que aceitou 150% e corrigi a regra.
