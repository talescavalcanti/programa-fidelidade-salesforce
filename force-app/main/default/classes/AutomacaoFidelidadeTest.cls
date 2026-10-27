/**
 * Testes de integração das automações (Flows, Roll-Ups, fórmulas, validações e aprovação).
 */
@IsTest
private class AutomacaoFidelidadeTest {

    private static Saldo_de_Pontos__c saldoDe(Id programaId) {
        return [SELECT Saldo_Atual__c, Categoria_Atual__c FROM Saldo_de_Pontos__c WHERE Programa_Fidelidade__c = :programaId];
    }

    @IsTest
    static void criarProgramaCriaOSaldoAutomaticamente() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Saldo');
        System.assertEquals(1, [SELECT COUNT() FROM Saldo_de_Pontos__c WHERE Programa_Fidelidade__c = :programa.Id]);
        System.assertEquals(0, saldoDe(programa.Id).Saldo_Atual__c);
        System.assertEquals('Bronze', saldoDe(programa.Id).Categoria_Atual__c);
    }

    @IsTest
    static void campanhaMultiplicaOsPontosEAjusteNao() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Campanha');
        Campanha_Promocional__c dobro = TestDataFactory.criarCampanha(2);
        Movimentacao_de_Pontos__c comCampanha = TestDataFactory.criarMovimentacao(programa.Id, 300, dobro.Id);
        Movimentacao_de_Pontos__c semCampanha = TestDataFactory.criarMovimentacao(programa.Id, 500, null);
        Movimentacao_de_Pontos__c ajuste = new Movimentacao_de_Pontos__c(
            Programa_Fidelidade__c = programa.Id, Tipo__c = 'Ajuste', Pontos_Base__c = -100);
        insert ajuste;

        System.assertEquals(600, [SELECT Pontos__c FROM Movimentacao_de_Pontos__c WHERE Id = :comCampanha.Id].Pontos__c);
        System.assertEquals(500, [SELECT Pontos__c FROM Movimentacao_de_Pontos__c WHERE Id = :semCampanha.Id].Pontos__c);
        System.assertEquals(-100, [SELECT Pontos__c FROM Movimentacao_de_Pontos__c WHERE Id = :ajuste.Id].Pontos__c);
        Programa_Fidelidade__c recalculado = [SELECT Total_de_Pontos__c, Ultima_Movimentacao__c FROM Programa_Fidelidade__c WHERE Id = :programa.Id];
        System.assertEquals(1000, recalculado.Total_de_Pontos__c);
        System.assertEquals(Date.today(), recalculado.Ultima_Movimentacao__c);
    }

    @IsTest
    static void categoriaSegueAsFaixasDePontos() {
        Programa_Fidelidade__c prata = TestDataFactory.criarPrograma('Prata');
        TestDataFactory.criarMovimentacao(prata.Id, 1000, null);
        System.assertEquals('Prata', saldoDe(prata.Id).Categoria_Atual__c);
        Programa_Fidelidade__c ouro = TestDataFactory.criarPrograma('Ouro');
        TestDataFactory.criarMovimentacao(ouro.Id, 5000, null);
        System.assertEquals('Ouro', saldoDe(ouro.Id).Categoria_Atual__c);
        Programa_Fidelidade__c bronze = TestDataFactory.criarPrograma('Bronze');
        TestDataFactory.criarMovimentacao(bronze.Id, 999, null);
        System.assertEquals('Bronze', saldoDe(bronze.Id).Categoria_Atual__c);
    }

    @IsTest
    static void campanhaForaDaVigenciaOuMultiplicadorInvalidoSaoRecusados() {
        Campanha_Promocional__c invalida = new Campanha_Promocional__c(
            Name = 'Ruim', Data_de_Inicio__c = Date.today(), Data_de_Fim__c = Date.today().addDays(-5), Multiplicador__c = 0.5);
        try {
            insert invalida;
            System.assert(false, 'Deveria falhar');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('multiplicador') || e.getMessage().contains('data de fim'), e.getMessage());
        }
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente vigência');
        Campanha_Promocional__c campanha = TestDataFactory.criarCampanha(2);
        try {
            insert new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = programa.Id, Pontos_Base__c = 100,
                Campanha__c = campanha.Id, Data_da_Movimentacao__c = Date.today().addDays(90));
            System.assert(false, 'Deveria falhar: fora da vigência');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('campanha ativa e vigente'), e.getMessage());
        }
    }

    @IsTest
    static void tiposDeRegistroDoBeneficioExigemOsCamposCertos() {
        Beneficio__c cashback = TestDataFactory.criarBeneficio('Cashback', 500);
        Beneficio__c desconto = TestDataFactory.criarBeneficio('Desconto', 800);
        Beneficio__c brinde = TestDataFactory.criarBeneficio('Brinde', 1500);
        System.assertEquals('Cashback', [SELECT RecordType.DeveloperName FROM Beneficio__c WHERE Id = :cashback.Id].RecordType.DeveloperName);
        System.assertEquals('Desconto', [SELECT RecordType.DeveloperName FROM Beneficio__c WHERE Id = :desconto.Id].RecordType.DeveloperName);
        System.assertEquals('Brinde', [SELECT RecordType.DeveloperName FROM Beneficio__c WHERE Id = :brinde.Id].RecordType.DeveloperName);

        Map<String, Id> tipos = new Map<String, Id>();
        for (String t : new List<String>{'Cashback', 'Desconto', 'Brinde'}) {
            tipos.put(t, Schema.SObjectType.Beneficio__c.getRecordTypeInfosByDeveloperName().get(t).getRecordTypeId());
        }
        List<Beneficio__c> invalidos = new List<Beneficio__c>{
            new Beneficio__c(Name = 'a', RecordTypeId = tipos.get('Cashback'), Pontos_Necessarios__c = 10),
            new Beneficio__c(Name = 'b', RecordTypeId = tipos.get('Desconto'), Pontos_Necessarios__c = 10, Percentual_Desconto__c = 150),
            new Beneficio__c(Name = 'c', RecordTypeId = tipos.get('Brinde'), Pontos_Necessarios__c = 10),
            new Beneficio__c(Name = 'd', RecordTypeId = tipos.get('Brinde'), Pontos_Necessarios__c = 0, Descricao_do_Brinde__c = 'x')
        };
        for (Beneficio__c b : invalidos) {
            try {
                insert b;
                System.assert(false, 'Deveria ter sido recusado: ' + b.Name);
            } catch (DmlException e) {
                System.assert(true);
            }
        }
    }

    @IsTest
    static void resgateAbaixoDoLimiteEAprovadoAutomaticamente() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Resgate');
        TestDataFactory.criarMovimentacao(programa.Id, 2000, null);
        Beneficio__c cashback = TestDataFactory.criarBeneficio('Cashback', 500);
        Resgate__c resgate = TestDataFactory.montarResgate(programa.Id, cashback);
        insert resgate;

        Resgate__c salvo = [SELECT Status__c, Exige_Aprovacao__c FROM Resgate__c WHERE Id = :resgate.Id];
        System.assertEquals('Aprovado', salvo.Status__c);
        System.assertEquals(false, salvo.Exige_Aprovacao__c);
        System.assertEquals(1500, saldoDe(programa.Id).Saldo_Atual__c);
        System.assertEquals(500, [SELECT Total_de_Resgates__c FROM Programa_Fidelidade__c WHERE Id = :programa.Id].Total_de_Resgates__c);
    }

    @IsTest
    static void resgateAcimaDoLimiteVaiParaAprovacaoEReservaOsPontos() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Aprovação');
        TestDataFactory.criarMovimentacao(programa.Id, 2000, null);
        Beneficio__c brinde = TestDataFactory.criarBeneficio('Brinde', 1500);
        Resgate__c resgate = TestDataFactory.montarResgate(programa.Id, brinde);
        insert resgate;

        Resgate__c salvo = [SELECT Status__c, Exige_Aprovacao__c FROM Resgate__c WHERE Id = :resgate.Id];
        System.assertEquals('Em Aprovação', salvo.Status__c);
        System.assertEquals(true, salvo.Exige_Aprovacao__c);
        System.assertEquals(1, [SELECT COUNT() FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :resgate.Id],
            'Deve haver uma aprovação pendente');
        System.assertEquals(500, saldoDe(programa.Id).Saldo_Atual__c, 'Os pontos ficam reservados enquanto pendente');
    }

    @IsTest
    static void aprovacaoEmDoisNiveisConcluiOResgate() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente 2 níveis');
        TestDataFactory.criarMovimentacao(programa.Id, 2000, null);
        Resgate__c resgate = TestDataFactory.montarResgate(programa.Id, TestDataFactory.criarBeneficio('Brinde', 1500));
        insert resgate;

        for (Integer nivel = 1; nivel <= 2; nivel++) {
            ProcessInstanceWorkitem item = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :resgate.Id];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setAction('Approve');
            req.setWorkitemId(item.Id);
            Approval.process(req);
            if (nivel == 1) {
                System.assertEquals('Em Aprovação', [SELECT Status__c FROM Resgate__c WHERE Id = :resgate.Id].Status__c,
                    'Após o nível 1 ainda falta o nível 2');
            }
        }
        System.assertEquals('Aprovado', [SELECT Status__c FROM Resgate__c WHERE Id = :resgate.Id].Status__c);
    }

    @IsTest
    static void rejeicaoDevolveOsPontosAoSaldo() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente rejeição');
        TestDataFactory.criarMovimentacao(programa.Id, 2000, null);
        Resgate__c resgate = TestDataFactory.montarResgate(programa.Id, TestDataFactory.criarBeneficio('Brinde', 1500));
        insert resgate;
        System.assertEquals(500, saldoDe(programa.Id).Saldo_Atual__c);

        ProcessInstanceWorkitem item = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :resgate.Id];
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setAction('Reject');
        req.setWorkitemId(item.Id);
        Approval.process(req);

        System.assertEquals('Rejeitado', [SELECT Status__c FROM Resgate__c WHERE Id = :resgate.Id].Status__c);
        System.assertEquals(2000, saldoDe(programa.Id).Saldo_Atual__c, 'Os pontos voltam ao saldo');
    }

    @IsTest
    static void resgatesInvalidosSaoRecusados() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente inválido');
        TestDataFactory.criarMovimentacao(programa.Id, 600, null);
        Beneficio__c caro = TestDataFactory.criarBeneficio('Brinde', 1500);
        Beneficio__c barato = TestDataFactory.criarBeneficio('Cashback', 500);

        try {
            insert TestDataFactory.montarResgate(programa.Id, caro);
            System.assert(false, 'Deveria falhar por saldo insuficiente');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Saldo de pontos insuficiente'), e.getMessage());
        }

        Resgate__c pontosErrados = TestDataFactory.montarResgate(programa.Id, barato);
        pontosErrados.Pontos__c = 100;
        try {
            insert pontosErrados;
            System.assert(false, 'Deveria falhar: pontos diferentes do benefício');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('devem ser iguais'), e.getMessage());
        }

        Resgate__c jaAprovado = TestDataFactory.montarResgate(programa.Id, barato);
        jaAprovado.Status__c = 'Aprovado';
        try {
            insert jaAprovado;
            System.assert(false, 'Deveria falhar: status inicial');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Em Aprovação'), e.getMessage());
        }

        barato.Ativo__c = false;
        update barato;
        try {
            insert TestDataFactory.montarResgate(programa.Id, barato);
            System.assert(false, 'Deveria falhar: benefício inativo');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('inativo'), e.getMessage());
        }
    }
}
