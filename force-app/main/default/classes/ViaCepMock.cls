/**
 * Resposta simulada do ViaCEP para os testes (nenhuma chamada real é feita).
 */
@IsTest
public class ViaCepMock implements HttpCalloutMock {
    private Integer status;
    private String corpo;
    private Boolean lancarExcecao = false;

    public ViaCepMock(Integer status, String corpo) {
        this.status = status;
        this.corpo = corpo;
    }

    public static ViaCepMock sucesso() {
        return new ViaCepMock(200, '{"cep":"01310-100","logradouro":"Avenida Paulista","complemento":"de 612 a 1510 - lado par","bairro":"Bela Vista","localidade":"São Paulo","uf":"SP"}');
    }

    public static ViaCepMock naoEncontrado() {
        return new ViaCepMock(200, '{"erro": true}');
    }

    public static ViaCepMock erroHttp() {
        return new ViaCepMock(500, 'Erro interno');
    }

    public static ViaCepMock excecao() {
        ViaCepMock mock = new ViaCepMock(0, '');
        mock.lancarExcecao = true;
        return mock;
    }

    public HttpResponse respond(HttpRequest requisicao) {
        if (lancarExcecao) {
            throw new CalloutException('Tempo esgotado (simulado)');
        }
        HttpResponse resposta = new HttpResponse();
        resposta.setHeader('Content-Type', 'application/json');
        resposta.setStatusCode(status);
        resposta.setBody(corpo);
        return resposta;
    }
}
