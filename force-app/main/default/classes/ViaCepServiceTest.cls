@IsTest
private class ViaCepServiceTest {

    @IsTest
    static void cepValidoPreencheOsDados() {
        Test.setMock(HttpCalloutMock.class, ViaCepMock.sucesso());
        Test.startTest();
        ViaCepService.Resultado resultado = ViaCepService.consultar('01310-100');
        Test.stopTest();
        System.assert(resultado.sucesso, 'A consulta deveria ter sucesso');
        System.assertEquals('Avenida Paulista', resultado.logradouro);
        System.assertEquals('Bela Vista', resultado.bairro);
        System.assertEquals('São Paulo', resultado.cidade);
        System.assertEquals('SP', resultado.estado);
        System.assertEquals(200, resultado.codigoHttp);
    }

    @IsTest
    static void cepComFormatoInvalidoNaoChamaAApi() {
        // Sem mock: se houvesse callout, o teste falharia
        ViaCepService.Resultado curto = ViaCepService.consultar('123');
        ViaCepService.Resultado vazio = ViaCepService.consultar(null);
        System.assert(!curto.sucesso);
        System.assert(!vazio.sucesso);
        System.assert(curto.mensagem.contains('inválido'));
        System.assertEquals(null, curto.codigoHttp, 'Não deve haver código HTTP sem chamada');
    }

    @IsTest
    static void cepInexistenteRetornaErro() {
        Test.setMock(HttpCalloutMock.class, ViaCepMock.naoEncontrado());
        Test.startTest();
        ViaCepService.Resultado resultado = ViaCepService.consultar('99999999');
        Test.stopTest();
        System.assert(!resultado.sucesso);
        System.assert(resultado.mensagem.contains('não encontrado'));
    }

    @IsTest
    static void erroHttpRetornaMensagemComOCodigo() {
        Test.setMock(HttpCalloutMock.class, ViaCepMock.erroHttp());
        Test.startTest();
        ViaCepService.Resultado resultado = ViaCepService.consultar('01310100');
        Test.stopTest();
        System.assert(!resultado.sucesso);
        System.assertEquals(500, resultado.codigoHttp);
        System.assert(resultado.mensagem.contains('500'));
    }

    @IsTest
    static void falhaDeRedeNaoLancaExcecao() {
        Test.setMock(HttpCalloutMock.class, ViaCepMock.excecao());
        Test.startTest();
        ViaCepService.Resultado resultado = ViaCepService.consultar('01310100');
        Test.stopTest();
        System.assert(!resultado.sucesso);
        System.assert(resultado.mensagem.contains('Falha na integração'));
    }
}
