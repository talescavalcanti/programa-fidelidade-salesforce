# PontoCerto — Guia de testes

Este guia permite que outra pessoa instale o projeto e confira tudo sozinha. Ele tem três partes:

1. **Instalação** em um org Developer Edition novo.
2. **Testes automatizados** (Apex), por linha de comando.
3. **Testes nas telas**, feitos no navegador com os três usuários de demonstração.

> Se você só quer **ver** o projeto funcionando e já tem acesso a um org com tudo instalado, pule para a [parte 3](#3-testes-nas-telas).

---

## 1. Instalação em um org novo

### O que você precisa

- Um org **Developer Edition** gratuito: <https://developer.salesforce.com/signup>.
- Pelo menos **3 licenças Salesforce Platform livres** (Configuração → Informações da empresa → Licenças de usuário).
- O **Salesforce CLI** (`sf`) e o **Java 17 ou superior**.
- Acesso ao repositório (privado): `git clone https://github.com/talescavalcanti/programa-fidelidade-salesforce.git`.

### Passo a passo

O deploy referencia usuários pelo *username* (aprovadores do processo e usuário dos dashboards), então **os usuários precisam existir antes**. Por isso a ordem abaixo importa.

**1. Entre no org pela CLI**

```bash
cd programa-fidelidade-salesforce
sf org login web --alias fidelidade --set-default
```

**2. Crie 3 usuários provisórios** (Configuração → Usuários → Usuários → Novo usuário)

| Nome | Username (exemplo) | Licença | Perfil provisório |
|---|---|---|---|
| Operador Demo | `operador.SEU_SUFIXO@exemplo.com` | Salesforce Platform | Salesforce Platform User |
| Coordenador Demo | `coordenador.SEU_SUFIXO@exemplo.com` | Salesforce Platform | Salesforce Platform User |
| Diretor Demo | `diretor.SEU_SUFIXO@exemplo.com` | Salesforce Platform | Salesforce Platform User |

O username precisa ter formato de e-mail e ser único no mundo todo, por isso o sufixo. Use um e-mail seu real no campo **E-mail**. Perfis e papéis definitivos entram no passo 5, porque ainda não existem.

**3. Troque os usernames dos arquivos que os citam** (substitua pelos seus)

```bash
# Aprovadores do processo de aprovação (Coordenador no nível 1, Diretor no nível 2)
F=force-app/main/default/approvalProcesses/Resgate__c.Aprovacao_de_Resgate.approvalProcess-meta.xml
sed -i '' 's/coordenador.512b2c4f1757@agentforce.com/coordenador.SEU_SUFIXO@exemplo.com/' "$F"
sed -i '' 's/diretor.512b2c4f1757@agentforce.com/diretor.SEU_SUFIXO@exemplo.com/' "$F"

# Usuário que executa os dashboards (use o SEU username de administrador)
sed -i '' 's/jtcs.512b2c4f1757@agentforce.com/SEU_USERNAME_ADMIN/' force-app/main/default/dashboards/PontoCerto/*.xml
```

(No Linux, remova o `''` depois do `-i`.)

**4. Implante tudo**

```bash
sf project deploy start --source-dir force-app
```

**5. Complete os usuários** (Configuração → Usuários → editar cada um)

| Usuário | Perfil | Papel |
|---|---|---|
| Operador Demo | Perfil Operacional | Operador |
| Coordenador Demo | Perfil Gestor | Coordenador |
| Diretor Demo | Perfil Administrativo | Diretor |

Depois atribua o **Permission Set "Ajuste de Pontos"** ao **Coordenador Demo** (abra o usuário → Atribuições de conjunto de permissões).

**6. Ative o "Login como"** para você entrar como cada usuário sem senha:
Configuração → Políticas de acesso de login → marque **Os administradores podem fazer login como qualquer usuário** → Salvar.

**7. Carregue os dados de demonstração**

```bash
sf apex run -f scripts/apex/dados_demo.apex
```

Isso cria 6 benefícios (2 de cada tipo), a campanha "Pontos em Dobro Nov", 4 clientes, movimentações, 3 endereços e 3 resgates. Os endereços são consultados no ViaCEP de verdade, em segundo plano, então a internet precisa estar liberada para o Salesforce.

---

## 2. Testes automatizados (Apex)

```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 20
```

**Esperado**

| Resultado | Valor |
|---|---|
| Testes executados | 44 |
| Falhas | 0 |
| Cobertura geral | 99% (o PDF exige no mínimo 85%) |

Eles cobrem: o cálculo de pontos com campanha, o fluxo de resgate e a aprovação em 2 níveis, a segurança executada como cada perfil, a integração ViaCEP com mock, os casos de erro e um lote maior que 50 registros.

---

## 3. Testes nas telas

Faça na ordem. O passo 9 muda dados de forma permanente (a Caneca deixa de estar "Em Aprovação"). Para repetir a demonstração depois, recrie os dados com `scripts/apex/dados_demo.apex` (apague os registros antigos antes, senão ficarão duplicados).

**Como entrar como outro usuário.** Como administrador: engrenagem → Configuração → Usuários → Usuários → abra o usuário → botão **Login**. Para voltar, clique em **Fazer logout como …** no banner azul do topo. Use uma janela anônima se quiser manter o administrador aberto ao mesmo tempo.

### Como administrador

**1. App PontoCerto**
- Como: Iniciador de aplicativos (os nove pontinhos) → pesquise **PontoCerto**.
- Esperado: o app abre com as guias Programas Fidelidade, Movimentações de Pontos, Resgates, Benefícios, Campanhas Promocionais, Endereços, Saldos de Pontos, Logs de Integração, Relatórios e Dashboards.

**2. Cliente ativo (Dynamic Forms e Dynamic Actions)**
- Como: Programas Fidelidade → **Maria Souza**.
- Esperado: o cartão de saldo mostra 5.000 pontos, categoria Ouro e barra de progresso; a lista de benefícios disponíveis aparece; a seção de resumo mostra Total de Pontos 7.000 e Total de Resgates 2.000; o botão **Novo Resgate** aparece no topo.

**3. Cliente inativo**
- Como: abra **Pedro Alves**.
- Esperado: a seção de pontos e a ação Novo Resgate **não** aparecem.

**4. Cálculo de pontos com campanha**
- Como: na Maria, na lista Movimentações de Pontos → Novo. Pontos Base = 400, campanha Pontos em Dobro Nov. Salve.
- Esperado: o campo Pontos fica em **800** sozinho. No cartão de saldo, clique em Atualizar: o saldo sobe de 5.000 para 5.800.

**5. Screen Flow "Novo Resgate"**
- Como: na Maria → **Novo Resgate** → escolha Cashback R$ 20 (500 pontos) e conclua.
- Esperado: o fluxo mostra o saldo e os benefícios possíveis; o resgate nasce **Aprovado** sozinho (abaixo de 1.000 pontos); o saldo cai 500.
- Teste de erro (opcional): tente resgatar mais do que o saldo. O fluxo recusa com uma mensagem.

**6. Record Types de Benefício**
- Como: guia Benefícios → abra um Cashback, um Desconto e um Brinde.
- Esperado: o campo de detalhe muda com o tipo (valor do cashback, percentual de desconto, descrição do brinde).

**7. Endereço e ViaCEP**
- Como: na Maria → Endereços → Novo. CEP `01310100`, Número `1000`. Salve.
- Esperado: o cartão Consulta de CEP mostra **Pendente** e, em poucos segundos (clique em Atualizar), **Sucesso**; os campos se preenchem (Avenida Paulista, Bela Vista, São Paulo, SP); em Logs de Integração existe um registro com HTTP 200.
- Erros: CEP `99999999` termina em Status Erro com o log "CEP não encontrado". CEP `12AB` é recusado na hora pela validação.

**8. Dashboards**
- Como: guia Dashboards → pasta PontoCerto → **Dashboard Executivo** e **Dashboard Operacional**. Clique em Atualizar em cada um.
- Esperado: o Executivo mostra Clientes ativos e Engajamento; o Operacional mostra Resgates pendentes e Pontuação acumulada. Nenhum fica vazio (se ficar, clique em Atualizar de novo).

### Como Coordenador e Diretor

**9. Aprovação em 2 níveis** (resgate da Caneca, 1.500 pontos, **Em Aprovação**)
- Entre como **Coordenador Demo**. Abra o resgate RES-… da Caneca. Em **Relacionado → Histórico de aprovação → Exibir tudo**, clique em **Aprovar** (ou use o sino de notificações).
- Esperado: o Status continua **Em Aprovação**, porque falta o nível 2.
- Tente editar o Status à mão (Editar → Status → Aprovado → Salvar). Esperado: **bloqueado**, porque o registro está travado durante a aprovação.
- Saia do login e entre como **Diretor Demo**. Aprove de novo.
- Esperado: o Status vira **Aprovado**. Em Relacionado → Histórico de aprovação aparecem os dois níveis como Aprovado.
- Não edite o Status direto como Diretor: o Perfil Administrativo tem permissão ampla e isso pularia o teste.
- Rejeição (opcional): crie outro resgate acima de 1.000 pontos e rejeite. O Status vira Rejeitado e os pontos voltam ao saldo.

**10. Layouts por perfil**
- Como Diretor (Perfil Administrativo): no resgate, aba Relacionado → aparece **Histórico de aprovação**.
- Como Coordenador (Perfil Gestor): a mesma aba **não** mostra essa lista. O Operador também vê um layout diferente do Gestor (sem "Exige Aprovação").

**11. Listas**
- Como qualquer usuário: guia Resgates → clique na seta ao lado de "Recentes" → escolha **Tudo**. Sem isso, um usuário novo vê a lista vazia.

### Como Operador

**12. Segurança**
- Entre como **Operador Demo**.
- Esperado: não há botão de excluir cliente; registrar uma Movimentação do tipo **Ajuste** é bloqueado com a mensagem sobre o conjunto de permissões Ajuste de Pontos; o Operador enxerga a Maria (que é VIP) e não os clientes comuns. Se a Maria não aparecer, aguarde um pouco e recarregue: o compartilhamento da regra é assíncrono.

---

## O que os usuários enxergam (resumo)

Os clientes de demonstração pertencem ao administrador, que não tem papel. Por isso a Sharing Rule por critério (Cliente VIP) é o que dá acesso à Maria a quem tem papel. Os outros clientes aparecem só para o administrador e para o Diretor.

| Usuário | Clientes que lê | Resgates que lê |
|---|---|---|
| Operador | 1 de 4 (a Maria, VIP) | 3 de 4 |
| Coordenador | 1 de 4 (a Maria, VIP) | 3 de 4 |
| Diretor | 4 de 4 | 4 de 4 |

---

## Problemas comuns

| Sintoma | Causa e solução |
|---|---|
| Botão **Login** não aparece | Falta ativar "Os administradores podem fazer login como qualquer usuário" (passo 1.6), ou o usuário está inativo. |
| `sf project deploy` falha no processo de aprovação | O username do aprovador não existe no org. Refaça o passo 1.3 com os usernames certos. |
| Dashboard falha ou fica vazio | O `runningUser` não é um usuário válido do org. Refaça o passo 1.3 e implante de novo; depois clique em Atualizar. |
| Cartão de CEP fica em Pendente | A consulta roda em segundo plano. Aguarde alguns segundos e clique em Atualizar. Confirme que o Remote Site Setting do ViaCEP foi implantado. |
| Lista de Resgates vazia | Você está em "Recentes". Troque para **Tudo**. |
| Coordenador não vê os clientes comuns | É o esperado: eles são do administrador, que está fora da hierarquia. Veja o resumo acima. |
| O Operador não vê a Maria | A Sharing Rule é assíncrona. Aguarde e recarregue. |
| Usuário não consegue ser criado com a licença | Falta licença Salesforce Platform livre. Confira em Informações da empresa. |
