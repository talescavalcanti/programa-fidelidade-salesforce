@IsTest
private class FidelidadeControllerTest {

    @IsTest
    static void resumoCalculaSaldoCategoriaEProgresso() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Resumo');
        TestDataFactory.criarMovimentacao(programa.Id, 2000, null);
        insert TestDataFactory.montarResgate(programa.Id, TestDataFactory.criarBeneficio('Cashback', 500));

        FidelidadeController.ResumoDto dto = FidelidadeController.getResumo(programa.Id);
        System.assertEquals(2000, dto.totalPontos);
        System.assertEquals(500, dto.totalResgates);
        System.assertEquals(1500, dto.saldoAtual);
        System.assertEquals('Prata', dto.categoria);
        System.assertEquals('Ouro', dto.proximaCategoria);
        System.assertEquals(3000, dto.pontosParaProxima);
        System.assertEquals(40, dto.percentual);
    }

    @IsTest
    static void resumoDeClienteBronzeEOuro() {
        Programa_Fidelidade__c bronze = TestDataFactory.criarPrograma('Bronze');
        TestDataFactory.criarMovimentacao(bronze.Id, 250, null);
        FidelidadeController.ResumoDto b = FidelidadeController.getResumo(bronze.Id);
        System.assertEquals('Prata', b.proximaCategoria);
        System.assertEquals(750, b.pontosParaProxima);
        System.assertEquals(25, b.percentual);

        Programa_Fidelidade__c ouro = TestDataFactory.criarPrograma('Ouro');
        TestDataFactory.criarMovimentacao(ouro.Id, 6000, null);
        FidelidadeController.ResumoDto o = FidelidadeController.getResumo(ouro.Id);
        System.assertEquals('Ouro', o.categoria);
        System.assertEquals(null, o.proximaCategoria);
        System.assertEquals(100, o.percentual);
    }

    @IsTest
    static void resumoComIdInexistenteLancaErroAmigavel() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Apagado');
        Id idApagado = programa.Id;
        delete programa;
        try {
            FidelidadeController.getResumo(idApagado);
            System.assert(false, 'Deveria lançar exceção');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void beneficiosEUltimoLogComIdInexistenteLancamErroAmigavel() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Apagado 2');
        Id idApagado = programa.Id;
        delete programa;
        try {
            FidelidadeController.getBeneficiosDisponiveis(idApagado);
            System.assert(false, 'Deveria lançar exceção');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        try {
            FidelidadeController.getUltimoLog(Endereco__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001');
            System.assert(false, 'Deveria lançar exceção');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void beneficiosIndicamElegibilidadePeloSaldo() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Benefícios');
        TestDataFactory.criarMovimentacao(programa.Id, 800, null);
        TestDataFactory.criarBeneficio('Cashback', 500);
        TestDataFactory.criarBeneficio('Desconto', 800);
        TestDataFactory.criarBeneficio('Brinde', 1500);
        Beneficio__c inativo = TestDataFactory.criarBeneficio('Cashback', 100);
        inativo.Ativo__c = false;
        update inativo;

        List<FidelidadeController.BeneficioDto> lista = FidelidadeController.getBeneficiosDisponiveis(programa.Id);
        System.assertEquals(3, lista.size(), 'Benefício inativo não aparece');
        System.assertEquals('Cashback', lista[0].tipo);
        System.assertEquals(true, lista[0].elegivel);
        System.assert(lista[0].detalhe.contains('R$ 20.00'), lista[0].detalhe);
        System.assertEquals(true, lista[1].elegivel);
        System.assert(lista[1].detalhe.contains('desconto'), lista[1].detalhe);
        System.assertEquals(false, lista[2].elegivel);
        System.assertEquals(700, lista[2].faltam);
        System.assertEquals('Caneca', lista[2].detalhe);
    }

    @IsTest
    static void ultimoLogMostraAConsultaMaisRecente() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente Log');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');

        FidelidadeController.LogDto antes;
        Test.startTest();
        insert endereco;
        Test.stopTest();

        FidelidadeController.LogDto dto = FidelidadeController.getUltimoLog(endereco.Id);
        System.assertEquals('Sucesso', dto.statusConsulta);
        System.assertEquals(true, dto.sucesso);
        System.assertEquals(200, dto.codigoHttp);
        System.assertNotEquals(null, dto.dataHora);
    }

    @IsTest
    static void ultimoLogSemConsultaRetornaApenasOStatus() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente sem log');
        TriggerHandler.desativar('EnderecoTriggerHandler');
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');
        insert endereco;
        FidelidadeController.LogDto dto = FidelidadeController.getUltimoLog(endereco.Id);
        System.assertEquals(null, dto.sucesso);
        System.assertEquals(null, dto.mensagem);
    }

    @IsTest
    static void operadorUsaOControladorComSuasPermissoes() {
        User operador = TestDataFactory.criarUsuario('Perfil Operacional', 'Operador', 'opctl');
        Programa_Fidelidade__c programa;
        System.runAs(operador) {
            programa = TestDataFactory.criarPrograma('Cliente do operador');
            FidelidadeController.ResumoDto dto = FidelidadeController.getResumo(programa.Id);
            System.assertEquals(0, dto.saldoAtual);
            System.assertEquals('Bronze', dto.categoria);
            System.assertEquals(0, FidelidadeController.getBeneficiosDisponiveis(programa.Id).size());
        }
    }
}
