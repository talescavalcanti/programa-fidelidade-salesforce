/**
 * Processa a consulta ao ViaCEP em segundo plano.
 * Motivo do processamento assíncrono: uma trigger não pode fazer callout HTTP durante a gravação.
 * Para cada endereço: chama o ViaCEP, preenche os campos e grava um Log de Integração (auditoria).
 */
public with sharing class ViaCepQueueable implements Queueable, Database.AllowsCallouts {

    @TestVisible
    private static final Integer LIMITE_POR_EXECUCAO = 50;

    private List<Id> enderecoIds;

    public ViaCepQueueable(List<Id> enderecoIds) {
        this.enderecoIds = enderecoIds;
    }

    public void execute(QueueableContext contexto) {
        List<Id> lote = new List<Id>();
        List<Id> restantes = new List<Id>();
        for (Integer i = 0; i < enderecoIds.size(); i++) {
            if (i < LIMITE_POR_EXECUCAO) {
                lote.add(enderecoIds[i]);
            } else {
                restantes.add(enderecoIds[i]);
            }
        }

        Map<Id, Endereco__c> enderecos = new Map<Id, Endereco__c>([
            SELECT Id, CEP__c, Complemento__c
            FROM Endereco__c
            WHERE Id IN :lote
        ]);

        List<Endereco__c> paraAtualizar = new List<Endereco__c>();
        List<Log_de_Integracao__c> logs = new List<Log_de_Integracao__c>();

        // Primeiro todos os callouts; só depois as operações de banco (DML).
        for (Id enderecoId : lote) {
            Endereco__c endereco = enderecos.get(enderecoId);
            if (endereco == null) {
                continue;
            }
            ViaCepService.Resultado resultado = ViaCepService.consultar(endereco.CEP__c);
            logs.add(criarLog(endereco, resultado));
            paraAtualizar.add(aplicarResultado(endereco, resultado));
        }

        List<Database.SaveResult> salvamentos = Database.update(paraAtualizar, false);
        for (Integer i = 0; i < salvamentos.size(); i++) {
            if (!salvamentos[i].isSuccess()) {
                logs.add(criarLogDeErroDeGravacao(paraAtualizar[i], salvamentos[i].getErrors()[0].getMessage()));
            }
        }
        insert logs;

        if (!restantes.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new ViaCepQueueable(restantes));
        }
    }

    private Endereco__c aplicarResultado(Endereco__c original, ViaCepService.Resultado resultado) {
        Endereco__c atualizado = new Endereco__c(Id = original.Id);
        if (resultado.sucesso) {
            atualizado.Logradouro__c = resultado.logradouro;
            atualizado.Bairro__c = resultado.bairro;
            atualizado.Cidade__c = resultado.cidade;
            atualizado.Estado__c = resultado.estado;
            if (String.isBlank(original.Complemento__c)) {
                atualizado.Complemento__c = resultado.complemento;
            }
            atualizado.Status_da_Consulta__c = 'Sucesso';
        } else {
            atualizado.Status_da_Consulta__c = 'Erro';
        }
        return atualizado;
    }

    private Log_de_Integracao__c criarLog(Endereco__c endereco, ViaCepService.Resultado resultado) {
        return new Log_de_Integracao__c(
            Endereco__c = endereco.Id,
            CEP_Consultado__c = endereco.CEP__c,
            Sucesso__c = resultado.sucesso,
            Codigo_HTTP__c = resultado.codigoHttp,
            Mensagem__c = resultado.mensagem == null ? null : resultado.mensagem.left(255),
            Resposta__c = resultado.corpo == null ? null : resultado.corpo.left(32768),
            Data_e_Hora__c = System.now()
        );
    }

    private Log_de_Integracao__c criarLogDeErroDeGravacao(Endereco__c endereco, String erro) {
        return new Log_de_Integracao__c(
            Endereco__c = endereco.Id,
            Sucesso__c = false,
            Mensagem__c = ('Erro ao gravar o endereço: ' + erro).left(255),
            Data_e_Hora__c = System.now()
        );
    }
}
