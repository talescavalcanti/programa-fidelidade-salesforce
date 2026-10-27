/**
 * Cria dados de teste reutilizados pelas classes de teste.
 */
@IsTest
public class TestDataFactory {

    public static Programa_Fidelidade__c criarPrograma(String nome) {
        Programa_Fidelidade__c programa = new Programa_Fidelidade__c(Name = nome, E_mail__c = 'cliente@exemplo.com');
        insert programa;
        return programa;
    }

    public static Movimentacao_de_Pontos__c criarMovimentacao(Id programaId, Decimal pontosBase, Id campanhaId) {
        Movimentacao_de_Pontos__c movimentacao = new Movimentacao_de_Pontos__c(
            Programa_Fidelidade__c = programaId,
            Pontos_Base__c = pontosBase,
            Campanha__c = campanhaId
        );
        insert movimentacao;
        return movimentacao;
    }

    public static Campanha_Promocional__c criarCampanha(Decimal multiplicador) {
        Campanha_Promocional__c campanha = new Campanha_Promocional__c(
            Name = 'Campanha de teste',
            Data_de_Inicio__c = Date.today().addDays(-1),
            Data_de_Fim__c = Date.today().addDays(30),
            Multiplicador__c = multiplicador
        );
        insert campanha;
        return campanha;
    }

    public static Beneficio__c criarBeneficio(String tipo, Decimal pontos) {
        Beneficio__c beneficio = new Beneficio__c(
            Name = 'Benefício ' + tipo,
            Pontos_Necessarios__c = pontos,
            RecordTypeId = Schema.SObjectType.Beneficio__c.getRecordTypeInfosByDeveloperName().get(tipo).getRecordTypeId()
        );
        if (tipo == 'Cashback') {
            beneficio.Valor_Cashback__c = 20;
        } else if (tipo == 'Desconto') {
            beneficio.Percentual_Desconto__c = 10;
        } else {
            beneficio.Descricao_do_Brinde__c = 'Caneca';
        }
        insert beneficio;
        return beneficio;
    }

    public static Resgate__c montarResgate(Id programaId, Beneficio__c beneficio) {
        return new Resgate__c(
            Programa_Fidelidade__c = programaId,
            Beneficio__c = beneficio.Id,
            Pontos__c = beneficio.Pontos_Necessarios__c,
            Status__c = 'Em Aprovação'
        );
    }

    public static Endereco__c criarEndereco(Id programaId, String cep) {
        return new Endereco__c(Programa_Fidelidade__c = programaId, CEP__c = cep, Numero__c = '1000');
    }

    /** Cria um usuário de teste com o perfil e o papel informados. */
    public static User criarUsuario(String nomePerfil, String nomePapel, String apelido) {
        Id perfilId = [SELECT Id FROM Profile WHERE Name = :nomePerfil LIMIT 1].Id;
        Id papelId = [SELECT Id FROM UserRole WHERE Name = :nomePapel LIMIT 1].Id;
        User usuario = new User(
            Username = apelido + System.currentTimeMillis() + '@teste.fidelidade.com',
            LastName = apelido,
            Email = apelido + '@teste.fidelidade.com',
            Alias = apelido.left(8),
            ProfileId = perfilId,
            UserRoleId = papelId,
            TimeZoneSidKey = 'America/Sao_Paulo',
            LocaleSidKey = 'pt_BR',
            LanguageLocaleKey = 'pt_BR',
            EmailEncodingKey = 'UTF-8'
        );
        // Evita o erro de DML misto (objeto de configuração + objeto de dados no mesmo teste)
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert usuario;
        }
        return usuario;
    }

    public static void atribuirPermissionSet(Id usuarioId, String nomeDoPermissionSet) {
        Id permissionSetId = [SELECT Id FROM PermissionSet WHERE Name = :nomeDoPermissionSet LIMIT 1].Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert new PermissionSetAssignment(AssigneeId = usuarioId, PermissionSetId = permissionSetId);
        }
    }
}
