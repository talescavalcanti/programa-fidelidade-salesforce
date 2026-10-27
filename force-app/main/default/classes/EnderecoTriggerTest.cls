@IsTest
private class EnderecoTriggerTest {

    @IsTest
    static void insercaoConsultaOViaCepEPreencheOEndereco() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente CEP');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());

        Test.startTest();
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310100');
        insert endereco;
        Test.stopTest();

        Endereco__c salvo = [
            SELECT CEP__c, Logradouro__c, Bairro__c, Cidade__c, Estado__c, Status_da_Consulta__c
            FROM Endereco__c WHERE Id = :endereco.Id
        ];
        System.assertEquals('01310-100', salvo.CEP__c, 'O CEP deve ser padronizado');
        System.assertEquals('Avenida Paulista', salvo.Logradouro__c);
        System.assertEquals('Bela Vista', salvo.Bairro__c);
        System.assertEquals('São Paulo', salvo.Cidade__c);
        System.assertEquals('SP', salvo.Estado__c);
        System.assertEquals('Sucesso', salvo.Status_da_Consulta__c);

        List<Log_de_Integracao__c> logs = [
            SELECT Sucesso__c, Codigo_HTTP__c, CEP_Consultado__c, Resposta__c
            FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id
        ];
        System.assertEquals(1, logs.size(), 'Deve existir um log de auditoria');
        System.assert(logs[0].Sucesso__c);
        System.assertEquals(200, logs[0].Codigo_HTTP__c);
        System.assertEquals('01310-100', logs[0].CEP_Consultado__c);
        System.assert(logs[0].Resposta__c.contains('Paulista'));
    }

    @IsTest
    static void cepInexistenteMarcaErroEGravaLog() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente CEP inexistente');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.naoEncontrado());

        Test.startTest();
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '99999-999');
        insert endereco;
        Test.stopTest();

        Endereco__c salvo = [SELECT Status_da_Consulta__c, Logradouro__c FROM Endereco__c WHERE Id = :endereco.Id];
        System.assertEquals('Erro', salvo.Status_da_Consulta__c);
        System.assertEquals(null, salvo.Logradouro__c);
        Log_de_Integracao__c log = [SELECT Sucesso__c, Mensagem__c FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id];
        System.assert(!log.Sucesso__c);
        System.assert(log.Mensagem__c.contains('não encontrado'));
    }

    @IsTest
    static void falhaDeIntegracaoMarcaErroEGravaLog() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente sem rede');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.excecao());

        Test.startTest();
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');
        insert endereco;
        Test.stopTest();

        System.assertEquals('Erro', [SELECT Status_da_Consulta__c FROM Endereco__c WHERE Id = :endereco.Id].Status_da_Consulta__c);
        Log_de_Integracao__c log = [SELECT Sucesso__c, Mensagem__c FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id];
        System.assert(!log.Sucesso__c);
        System.assert(log.Mensagem__c.contains('Falha na integração'));
    }

    @IsTest
    static void alterarOutroCampoNaoConsultaOViaCepDeNovo() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente alteração');
        TriggerHandler.desativar('EnderecoTriggerHandler');
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');
        insert endereco;
        TriggerHandler.reativar('EnderecoTriggerHandler');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());

        Test.startTest();
        update new Endereco__c(Id = endereco.Id, Numero__c = '2000');
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id],
            'Alterar o número não deve consultar o ViaCEP');
    }

    @IsTest
    static void alterarOCepLimpaOEnderecoEConsultaDeNovo() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente novo CEP');
        TriggerHandler.desativar('EnderecoTriggerHandler');
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');
        endereco.Logradouro__c = 'Rua Antiga';
        insert endereco;
        TriggerHandler.reativar('EnderecoTriggerHandler');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());

        Test.startTest();
        update new Endereco__c(Id = endereco.Id, CEP__c = '01001000');
        Test.stopTest();

        Endereco__c salvo = [SELECT CEP__c, Logradouro__c, Status_da_Consulta__c FROM Endereco__c WHERE Id = :endereco.Id];
        System.assertEquals('01001-000', salvo.CEP__c);
        System.assertEquals('Avenida Paulista', salvo.Logradouro__c, 'O endereço antigo foi substituído');
        System.assertEquals('Sucesso', salvo.Status_da_Consulta__c);
        System.assertEquals(1, [SELECT COUNT() FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id]);
    }

    @IsTest
    static void enderecoInexistenteNaoGeraLogNemErro() {
        Id idFalso = Endereco__c.SObjectType.getDescribe().getKeyPrefix() + '000000000001';
        Test.startTest();
        new ViaCepQueueable(new List<Id>{ idFalso }).execute(null);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Log_de_Integracao__c]);
    }

    @IsTest
    static void falhaAoGravarOEnderecoGeraLogDeErro() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente UF longa');
        // UF com 3 letras não cabe no campo Estado (2 caracteres): a gravação falha
        Test.setMock(HttpCalloutMock.class, new ViaCepMock(200,
            '{"logradouro":"Rua A","bairro":"B","localidade":"C","uf":"SAO"}'));

        Test.startTest();
        Endereco__c endereco = TestDataFactory.criarEndereco(programa.Id, '01310-100');
        insert endereco;
        Test.stopTest();

        List<Log_de_Integracao__c> logs = [SELECT Sucesso__c, Mensagem__c FROM Log_de_Integracao__c WHERE Endereco__c = :endereco.Id];
        System.assertEquals(2, logs.size(), 'Um log da consulta e um log do erro de gravação');
        Integer erros = 0;
        for (Log_de_Integracao__c log : logs) {
            if (!log.Sucesso__c && log.Mensagem__c.contains('Erro ao gravar')) {
                erros++;
            }
        }
        System.assertEquals(1, erros);
        System.assertEquals('Pendente', [SELECT Status_da_Consulta__c FROM Endereco__c WHERE Id = :endereco.Id].Status_da_Consulta__c);
    }

    @IsTest
    static void loteMaiorQueOLimiteEProcessadoEmPartes() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente muitos endereços');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());
        List<Endereco__c> enderecos = new List<Endereco__c>();
        for (Integer i = 0; i < ViaCepQueueable.LIMITE_POR_EXECUCAO + 5; i++) {
            enderecos.add(TestDataFactory.criarEndereco(programa.Id, '01310100'));
        }
        Test.startTest();
        insert enderecos;
        Test.stopTest();
        // Em produção o excedente segue em um novo job encadeado; em teste só o primeiro lote roda.
        System.assertEquals(ViaCepQueueable.LIMITE_POR_EXECUCAO, [SELECT COUNT() FROM Log_de_Integracao__c]);
        System.assertEquals(5, [SELECT COUNT() FROM Endereco__c WHERE Status_da_Consulta__c = 'Pendente']);
    }

    @IsTest
    static void insercaoEmLoteGeraUmLogPorEndereco() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente lote');
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());
        List<Endereco__c> enderecos = new List<Endereco__c>();
        for (Integer i = 0; i < 10; i++) {
            enderecos.add(TestDataFactory.criarEndereco(programa.Id, '01310100'));
        }
        Test.startTest();
        insert enderecos;
        Test.stopTest();
        System.assertEquals(10, [SELECT COUNT() FROM Log_de_Integracao__c WHERE Sucesso__c = true]);
        System.assertEquals(10, [SELECT COUNT() FROM Endereco__c WHERE Status_da_Consulta__c = 'Sucesso']);
    }

    @IsTest
    static void cepComFormatoInvalidoEBloqueadoPelaValidacao() {
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente CEP ruim');
        try {
            insert TestDataFactory.criarEndereco(programa.Id, '12AB');
            System.assert(false, 'Deveria ter sido bloqueado pela regra de validação');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('CEP inválido'), e.getMessage());
        }
    }

    @IsTest
    static void handlerPodeSerDesativado() {
        TriggerHandler.desativar('EnderecoTriggerHandler');
        System.assert(TriggerHandler.estaDesativado('EnderecoTriggerHandler'));
        Programa_Fidelidade__c programa = TestDataFactory.criarPrograma('Cliente bypass');
        Test.startTest();
        insert TestDataFactory.criarEndereco(programa.Id, '01310-100');
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM Log_de_Integracao__c], 'Sem handler, não há consulta');
        TriggerHandler.reativar('EnderecoTriggerHandler');
        System.assert(!TriggerHandler.estaDesativado('EnderecoTriggerHandler'));
    }

    @IsTest
    static void normalizarCepAceitaVariosFormatos() {
        System.assertEquals('01310-100', EnderecoTriggerHandler.normalizarCep('01310100'));
        System.assertEquals('01310-100', EnderecoTriggerHandler.normalizarCep(' 01.310-100 '));
        System.assertEquals('12AB', EnderecoTriggerHandler.normalizarCep(' 12AB '));
        System.assertEquals(null, EnderecoTriggerHandler.normalizarCep(null));
    }
}
