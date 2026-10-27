/**
 * Handler da trigger de Endereço.
 * - Antes de salvar: padroniza o CEP (00000-000) e marca a consulta como Pendente.
 * - Depois de salvar: enfileira a consulta ao ViaCEP (callout não pode ser feito na trigger).
 */
public with sharing class EnderecoTriggerHandler extends TriggerHandler {

    protected override void antesDeInserir() {
        for (Endereco__c endereco : (List<Endereco__c>) Trigger.new) {
            prepararConsulta(endereco, false);
        }
    }

    protected override void antesDeAtualizar() {
        Map<Id, Endereco__c> antigos = (Map<Id, Endereco__c>) Trigger.oldMap;
        for (Endereco__c endereco : (List<Endereco__c>) Trigger.new) {
            if (cepMudou(endereco, antigos.get(endereco.Id))) {
                prepararConsulta(endereco, true);
            }
        }
    }

    protected override void depoisDeInserir() {
        List<Id> ids = new List<Id>();
        for (Endereco__c endereco : (List<Endereco__c>) Trigger.new) {
            ids.add(endereco.Id);
        }
        enfileirar(ids);
    }

    protected override void depoisDeAtualizar() {
        Map<Id, Endereco__c> antigos = (Map<Id, Endereco__c>) Trigger.oldMap;
        List<Id> ids = new List<Id>();
        for (Endereco__c endereco : (List<Endereco__c>) Trigger.new) {
            if (cepMudou(endereco, antigos.get(endereco.Id))) {
                ids.add(endereco.Id);
            }
        }
        enfileirar(ids);
    }

    private Boolean cepMudou(Endereco__c novo, Endereco__c antigo) {
        return novo.CEP__c != antigo.CEP__c;
    }

    private void prepararConsulta(Endereco__c endereco, Boolean limparEndereco) {
        endereco.CEP__c = normalizarCep(endereco.CEP__c);
        endereco.Status_da_Consulta__c = 'Pendente';
        if (limparEndereco) {
            endereco.Logradouro__c = null;
            endereco.Bairro__c = null;
            endereco.Cidade__c = null;
            endereco.Estado__c = null;
        }
    }

    private void enfileirar(List<Id> ids) {
        if (!ids.isEmpty()) {
            System.enqueueJob(new ViaCepQueueable(ids));
        }
    }

    /** Deixa o CEP no formato 00000-000 quando ele tem 8 dígitos. */
    @TestVisible
    private static String normalizarCep(String cep) {
        if (String.isBlank(cep)) {
            return cep;
        }
        String digitos = cep.replaceAll('[^0-9]', '');
        if (digitos.length() == 8) {
            return digitos.substring(0, 5) + '-' + digitos.substring(5);
        }
        return cep.trim();
    }
}
