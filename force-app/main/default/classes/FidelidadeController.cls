/**
 * Controlador das LWCs do Programa de Fidelidade.
 * Usa WITH USER_MODE: respeita as permissões do perfil de quem está usando a tela.
 */
public with sharing class FidelidadeController {

    // Faixas de categoria (mesmas da fórmula Categoria Atual em Saldo de Pontos)
    @TestVisible private static final Decimal LIMITE_PRATA = 1000;
    @TestVisible private static final Decimal LIMITE_OURO = 5000;

    public class ResumoDto {
        @AuraEnabled public Decimal totalPontos;
        @AuraEnabled public Decimal totalResgates;
        @AuraEnabled public Decimal saldoAtual;
        @AuraEnabled public String categoria;
        @AuraEnabled public String proximaCategoria;
        @AuraEnabled public Decimal pontosParaProxima;
        @AuraEnabled public Decimal percentual;
    }

    public class BeneficioDto {
        @AuraEnabled public Id id;
        @AuraEnabled public String nome;
        @AuraEnabled public String tipo;
        @AuraEnabled public String detalhe;
        @AuraEnabled public Decimal pontos;
        @AuraEnabled public Boolean elegivel;
        @AuraEnabled public Decimal faltam;
    }

    public class LogDto {
        @AuraEnabled public String statusConsulta;
        @AuraEnabled public Boolean sucesso;
        @AuraEnabled public String mensagem;
        @AuraEnabled public Datetime dataHora;
        @AuraEnabled public Integer codigoHttp;
    }

    @AuraEnabled(cacheable=true)
    public static ResumoDto getResumo(Id programaId) {
        try {
            Programa_Fidelidade__c programa = [
                SELECT Total_de_Pontos__c, Total_de_Resgates__c
                FROM Programa_Fidelidade__c
                WHERE Id = :programaId
                WITH USER_MODE
            ];
            List<Saldo_de_Pontos__c> saldos = [
                SELECT Saldo_Atual__c, Categoria_Atual__c
                FROM Saldo_de_Pontos__c
                WHERE Programa_Fidelidade__c = :programaId
                WITH USER_MODE
                LIMIT 1
            ];
            ResumoDto dto = new ResumoDto();
            dto.totalPontos = valor(programa.Total_de_Pontos__c);
            dto.totalResgates = valor(programa.Total_de_Resgates__c);
            dto.saldoAtual = saldos.isEmpty() ? dto.totalPontos - dto.totalResgates : valor(saldos[0].Saldo_Atual__c);
            dto.categoria = saldos.isEmpty() ? 'Bronze' : saldos[0].Categoria_Atual__c;
            calcularProgresso(dto);
            return dto;
        } catch (Exception e) {
            throw new AuraHandledException('Não foi possível carregar o resumo: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<BeneficioDto> getBeneficiosDisponiveis(Id programaId) {
        try {
            ResumoDto resumo = getResumo(programaId);
            List<BeneficioDto> resultado = new List<BeneficioDto>();
            for (Beneficio__c b : [
                SELECT Name, RecordType.Name, Pontos_Necessarios__c, Valor_Cashback__c,
                       Percentual_Desconto__c, Descricao_do_Brinde__c
                FROM Beneficio__c
                WHERE Ativo__c = true
                WITH USER_MODE
                ORDER BY Pontos_Necessarios__c ASC
            ]) {
                BeneficioDto dto = new BeneficioDto();
                dto.id = b.Id;
                dto.nome = b.Name;
                dto.tipo = b.RecordType.Name;
                dto.pontos = b.Pontos_Necessarios__c;
                dto.detalhe = descrever(b);
                dto.elegivel = b.Pontos_Necessarios__c <= resumo.saldoAtual;
                dto.faltam = dto.elegivel ? 0 : b.Pontos_Necessarios__c - resumo.saldoAtual;
                resultado.add(dto);
            }
            return resultado;
        } catch (Exception e) {
            throw new AuraHandledException('Não foi possível carregar os benefícios: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static LogDto getUltimoLog(Id enderecoId) {
        try {
            Endereco__c endereco = [
                SELECT Status_da_Consulta__c
                FROM Endereco__c
                WHERE Id = :enderecoId
                WITH USER_MODE
            ];
            LogDto dto = new LogDto();
            dto.statusConsulta = endereco.Status_da_Consulta__c;
            List<Log_de_Integracao__c> logs = [
                SELECT Sucesso__c, Mensagem__c, Data_e_Hora__c, Codigo_HTTP__c
                FROM Log_de_Integracao__c
                WHERE Endereco__c = :enderecoId
                WITH USER_MODE
                ORDER BY Data_e_Hora__c DESC, CreatedDate DESC
                LIMIT 1
            ];
            if (!logs.isEmpty()) {
                dto.sucesso = logs[0].Sucesso__c;
                dto.mensagem = logs[0].Mensagem__c;
                dto.dataHora = logs[0].Data_e_Hora__c;
                dto.codigoHttp = logs[0].Codigo_HTTP__c == null ? null : Integer.valueOf(logs[0].Codigo_HTTP__c);
            }
            return dto;
        } catch (Exception e) {
            throw new AuraHandledException('Não foi possível carregar o log: ' + e.getMessage());
        }
    }

    private static Decimal valor(Decimal numero) {
        return numero == null ? 0 : numero;
    }

    private static void calcularProgresso(ResumoDto dto) {
        if (dto.totalPontos >= LIMITE_OURO) {
            dto.proximaCategoria = null;
            dto.pontosParaProxima = 0;
            dto.percentual = 100;
        } else if (dto.totalPontos >= LIMITE_PRATA) {
            dto.proximaCategoria = 'Ouro';
            dto.pontosParaProxima = LIMITE_OURO - dto.totalPontos;
            dto.percentual = (dto.totalPontos / LIMITE_OURO * 100).setScale(0);
        } else {
            dto.proximaCategoria = 'Prata';
            dto.pontosParaProxima = LIMITE_PRATA - dto.totalPontos;
            dto.percentual = (dto.totalPontos / LIMITE_PRATA * 100).setScale(0);
        }
    }

    private static String descrever(Beneficio__c b) {
        switch on b.RecordType.Name {
            when 'Cashback' {
                return 'R$ ' + (b.Valor_Cashback__c == null ? '0' : String.valueOf(b.Valor_Cashback__c.setScale(2))) + ' de volta';
            }
            when 'Desconto' {
                // Campos de porcentagem guardam o valor como decimal (10% = 0,1) nas fórmulas;
                // no Apex o valor chega como digitado (10).
                return (b.Percentual_Desconto__c == null ? '0' : String.valueOf(b.Percentual_Desconto__c)) + '% de desconto';
            }
            when else {
                return b.Descricao_do_Brinde__c;
            }
        }
    }
}
