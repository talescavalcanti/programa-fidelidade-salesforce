/**
 * Única trigger do objeto Endereço. Toda a lógica fica no handler.
 */
trigger EnderecoTrigger on Endereco__c (before insert, before update, after insert, after update) {
    new EnderecoTriggerHandler().run();
}
