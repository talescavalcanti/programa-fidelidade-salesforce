/**
 * Consulta a API pública ViaCEP (https://viacep.com.br) por meio de um Apex Callout.
 * Não grava nada: apenas devolve o resultado para quem chamou decidir o que fazer.
 */
public with sharing class ViaCepService {

    public class Resultado {
        public Boolean sucesso = false;
        public Integer codigoHttp;
        public String mensagem;
        public String corpo;
        public String logradouro;
        public String complemento;
        public String bairro;
        public String cidade;
        public String estado;
    }

    @TestVisible
    private static final String URL_BASE = 'https://viacep.com.br/ws/';

    public static Resultado consultar(String cep) {
        Resultado resultado = new Resultado();
        String digitos = String.isBlank(cep) ? '' : cep.replaceAll('[^0-9]', '');
        if (digitos.length() != 8) {
            resultado.mensagem = 'CEP inválido: informe 8 dígitos.';
            return resultado;
        }

        HttpRequest requisicao = new HttpRequest();
        requisicao.setEndpoint(URL_BASE + digitos + '/json/');
        requisicao.setMethod('GET');
        requisicao.setTimeout(10000);

        try {
            HttpResponse resposta = new Http().send(requisicao);
            resultado.codigoHttp = resposta.getStatusCode();
            resultado.corpo = resposta.getBody();
            if (resposta.getStatusCode() != 200) {
                resultado.mensagem = 'O ViaCEP respondeu com o código HTTP ' + resposta.getStatusCode() + '.';
                return resultado;
            }
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(resposta.getBody());
            if (json.containsKey('erro')) {
                resultado.mensagem = 'CEP não encontrado na base do ViaCEP.';
                return resultado;
            }
            resultado.logradouro = (String) json.get('logradouro');
            resultado.complemento = (String) json.get('complemento');
            resultado.bairro = (String) json.get('bairro');
            resultado.cidade = (String) json.get('localidade');
            resultado.estado = (String) json.get('uf');
            resultado.sucesso = true;
            resultado.mensagem = 'Endereço preenchido com sucesso.';
        } catch (Exception e) {
            resultado.mensagem = 'Falha na integração com o ViaCEP: ' + e.getMessage();
        }
        return resultado;
    }
}
