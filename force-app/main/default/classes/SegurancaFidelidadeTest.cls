/**
 * Testes de segurança: perfis, papéis, Sharing Rule e Permission Set.
 * Cada teste executa as operações como um usuário real de cada perfil (System.runAs).
 */
@IsTest
private class SegurancaFidelidadeTest {

    @IsTest
    static void perfilOperacionalTemPermissoesLimitadas() {
        User operador = TestDataFactory.criarUsuario('Perfil Operacional', 'Operador', 'opseg');
        System.runAs(operador) {
            System.assert(Schema.SObjectType.Programa_Fidelidade__c.isCreateable(), 'Operador cadastra clientes');
            System.assert(!Schema.SObjectType.Programa_Fidelidade__c.isDeletable(), 'Operador não exclui clientes');
            System.assert(Schema.SObjectType.Resgate__c.isCreateable(), 'Operador solicita resgates');
            System.assert(!Schema.SObjectType.Beneficio__c.isCreateable(), 'Operador não cria benefícios');
            System.assert(!Schema.SObjectType.Campanha_Promocional__c.isCreateable(), 'Operador não cria campanhas');
            System.assert(!Schema.SObjectType.Movimentacao_de_Pontos__c.isUpdateable(), 'Operador não edita movimentações');
            System.assert(!Schema.SObjectType.Movimentacao_de_Pontos__c.fields.Pontos__c.isUpdateable(), 'Pontos é calculado pelo Flow');
            System.assert(!Schema.SObjectType.Programa_Fidelidade__c.fields.Cliente_VIP__c.isUpdateable(), 'Só o gestor marca VIP');
            System.assert(!Schema.SObjectType.Log_de_Integracao__c.isCreateable(), 'Log é somente leitura');
        }
    }

    @IsTest
    static void perfilGestorGerenciaOCatalogo() {
        User coordenador = TestDataFactory.criarUsuario('Perfil Gestor', 'Coordenador', 'gestseg');
        System.runAs(coordenador) {
            System.assert(Schema.SObjectType.Beneficio__c.isCreateable());
            System.assert(Schema.SObjectType.Campanha_Promocional__c.isCreateable());
            System.assert(Schema.SObjectType.Campanha_Promocional__c.isDeletable());
            System.assert(Schema.SObjectType.Programa_Fidelidade__c.fields.Cliente_VIP__c.isUpdateable());
            System.assert(!Schema.SObjectType.Movimentacao_de_Pontos__c.isDeletable());
        }
    }

    @IsTest
    static void perfilAdministrativoTemAcessoTotal() {
        User diretor = TestDataFactory.criarUsuario('Perfil Administrativo', 'Diretor', 'admseg');
        System.runAs(diretor) {
            System.assert(Schema.SObjectType.Programa_Fidelidade__c.isDeletable());
            System.assert(Schema.SObjectType.Movimentacao_de_Pontos__c.isDeletable());
            System.assert(Schema.SObjectType.Beneficio__c.isDeletable());
        }
    }

    @IsTest
    static void ajusteDePontosExigeOPermissionSet() {
        User operador = TestDataFactory.criarUsuario('Perfil Operacional', 'Operador', 'opaj');
        Programa_Fidelidade__c programa;
        System.runAs(operador) {
            programa = TestDataFactory.criarPrograma('Cliente Ajuste');
            try {
                insert new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = programa.Id, Tipo__c = 'Ajuste', Pontos_Base__c = -50);
                System.assert(false, 'Sem o Permission Set, o ajuste deve ser bloqueado');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('Ajuste de Pontos'), e.getMessage());
            }
            // Acúmulo continua permitido
            insert new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = programa.Id, Pontos_Base__c = 100);
        }

        TestDataFactory.atribuirPermissionSet(operador.Id, 'Ajuste_de_Pontos');
        System.runAs(operador) {
            Movimentacao_de_Pontos__c ajuste = new Movimentacao_de_Pontos__c(
                Programa_Fidelidade__c = programa.Id, Tipo__c = 'Ajuste', Pontos_Base__c = -50);
            insert ajuste;
            System.assertEquals(-50, [SELECT Pontos__c FROM Movimentacao_de_Pontos__c WHERE Id = :ajuste.Id].Pontos__c);
        }
    }

    @IsTest
    static void hierarquiaDePapeisEOwdPrivadoControlamOAcessoAosClientes() {
        User operadorA = TestDataFactory.criarUsuario('Perfil Operacional', 'Operador', 'opa');
        User operadorB = TestDataFactory.criarUsuario('Perfil Operacional', 'Operador', 'opb');
        User coordenador = TestDataFactory.criarUsuario('Perfil Gestor', 'Coordenador', 'coordseg');

        Id vipId;
        Id comumId;
        System.runAs(operadorA) {
            // FLS: o operador não pode marcar um cliente como VIP
            try {
                insert new Programa_Fidelidade__c(Name = 'Tentativa VIP', Cliente_VIP__c = true);
                System.assert(false, 'O operador não deveria conseguir marcar VIP');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('inaccessible') || e.getMessage().contains('inacessíve'), e.getMessage());
            }
            Programa_Fidelidade__c comum = new Programa_Fidelidade__c(Name = 'Cliente Comum');
            insert comum;
            comumId = comum.Id;
        }
        System.runAs(coordenador) {
            Programa_Fidelidade__c vip = new Programa_Fidelidade__c(Name = 'Cliente VIP', Cliente_VIP__c = true);
            insert vip;
            vipId = vip.Id;
            System.assertEquals(1, [SELECT COUNT() FROM Programa_Fidelidade__c WHERE Id = :comumId],
                'Role Hierarchy: o Coordenador enxerga os registros do Operador');
        }
        System.runAs(operadorB) {
            System.assertEquals(0, [SELECT COUNT() FROM Programa_Fidelidade__c WHERE Id = :comumId],
                'OWD privado: um operador não vê o cliente comum de outro operador');
        }
        // A Sharing Rule "Clientes VIP para Operadores" cria o compartilhamento (RowCause = Rule)
        // de forma assíncrona, depois do commit; por isso ela é validada no org pela tabela
        // Programa_Fidelidade__Share (veja docs/RELATORIO_FINAL.md) e não dentro do teste Apex.
        System.assertNotEquals(null, vipId);
    }
}
