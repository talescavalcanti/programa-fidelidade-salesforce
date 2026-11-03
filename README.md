<p align="center">
  <img src="docs/marca/logo-pontocerto.svg" alt="PontoCerto - Fidelidade que vale ponto" width="420">
</p>

# PontoCerto — Programa de Fidelidade no Salesforce

Projeto acadêmico baseado no **Tópico 4 — Programa de Fidelidade** do documento *Temas de Projetos*:
**gerenciar pontuação, benefícios, resgates e campanhas de fidelização.**

O participante acumula pontos por movimentações, campanhas promocionais multiplicam esses pontos e o saldo
pode ser trocado por benefícios (Cashback, Desconto ou Brinde). Resgates acima de **1.000 pontos** passam por
aprovação em **2 níveis** (Coordenador → Diretor). O endereço do participante é preenchido automaticamente
pelo CEP, por meio da API **ViaCEP**, com log de auditoria.

## O que existe no projeto

| Área | Entregas |
|---|---|
| **Dados** | 8 objetos customizados, relações Master-Detail e Lookup, 2 fórmulas, 3 Roll-Ups, Record Types e Page Layouts por perfil |
| **Segurança** | 3 perfis, 3 papéis com Role Hierarchy, Sharing Rule por critério, Permission Set + permissão personalizada |
| **Automação** | 3 Record-Triggered Flows, 1 Screen Flow, 2 Subflows, processo de aprovação de 2 níveis |
| **Apex** | Trigger Framework, integração ViaCEP (callout), Queueable, log de auditoria, **44 testes / 99% de cobertura** |
| **Interface** | Lightning App `PontoCerto`, Dynamic Forms, Dynamic Actions, 3 LWCs |
| **Analytics** | 4 relatórios, Dashboard Executivo e Dashboard Operacional |
| **Marca** | Nome comercial **PontoCerto**, logomarca e paleta em `docs/marca/` |

## Estrutura do repositório

```text
force-app/main/default/
├── objects/            8 objetos, campos, regras de validação e Record Types
├── layouts/            Page Layouts (por perfil e por Tipo de registro)
├── flexipages/         Páginas Lightning com Dynamic Forms e Dynamic Actions
├── applications/       Lightning App PontoCerto
├── flows/              3 Record-Triggered + 1 Screen Flow + 2 Subflows
├── approvalProcesses/  Aprovação de Resgate (2 níveis) e workflows de atualização de campo
├── classes/ triggers/  Trigger Framework, ViaCEP, Queueable, controlador das LWCs e testes
├── lwc/                saldoPontosCard, beneficiosDisponiveis, consultaCepStatus
├── profiles/ roles/ permissionsets/ sharingRules/ customPermissions/
├── reports/ dashboards/
└── remoteSiteSettings/ ViaCEP
scripts/apex/dados_demo.apex   Dados de demonstração
docs/                          Relatório final, roteiro de apresentação e marca
```

> Nem tudo pode ser versionado como código. **Usuários** (e a atribuição do Permission Set a eles) e os
> **dados de demonstração** ficam apenas no org; o roteiro em `docs/ROTEIRO_APRESENTACAO.md` explica como
> mostrá-los.

## Como instalar em outro org (Developer Edition)

```bash
sf org login web --alias fidelidade --set-default
sf project deploy start --source-dir force-app            # implanta tudo
sf apex run test --test-level RunLocalTests --code-coverage --result-format human --wait 20
sf apex run -f scripts/apex/dados_demo.apex                # dados de demonstração (opcional)
```

Pontos de atenção ao implantar em um org novo:

- Os usuários de demonstração não vêm junto. Crie um usuário por perfil (**Perfil Operacional**, **Perfil Gestor**
  e **Perfil Administrativo**) com os papéis **Operador**, **Coordenador** e **Diretor**, atribua o Permission Set
  **Ajuste de Pontos** ao Coordenador e ajuste os usernames dos aprovadores em
  `approvalProcesses/Resgate__c.Aprovacao_de_Resgate.approvalProcess-meta.xml` e o `runningUser` em
  `dashboards/PontoCerto/*.dashboard-meta.xml`.
- A integração usa **Remote Site Setting** para `https://viacep.com.br` (já incluído).
- O org de desenvolvimento usa a licença **Salesforce Platform** para os perfis personalizados.

## Documentação

- [`docs/RELATORIO_FINAL.md`](docs/RELATORIO_FINAL.md) — o que foi feito, decisões, matriz de requisitos com evidências e pendências.
- [`docs/GUIA_DE_TESTES.md`](docs/GUIA_DE_TESTES.md) — instalação em um org novo, testes automatizados e conferência das telas, passo a passo.

Victor Julius Bezerra
