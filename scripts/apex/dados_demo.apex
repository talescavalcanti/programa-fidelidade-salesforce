// Dados de demonstração do PontoCerto.
// Executar com:  sf apex run -f scripts/apex/dados_demo.apex -o fidelidade
// Os endereços são consultados no ViaCEP de verdade (em segundo plano, via Queueable).

Map<String, Id> tipos = new Map<String, Id>();
for (String t : new List<String>{ 'Cashback', 'Desconto', 'Brinde' }) {
    tipos.put(t, Schema.SObjectType.Beneficio__c.getRecordTypeInfosByDeveloperName().get(t).getRecordTypeId());
}

// ---- Catálogo de benefícios (3 Tipos de registro) ----
List<Beneficio__c> catalogo = new List<Beneficio__c>{
    new Beneficio__c(Name = 'Cashback R$ 20', RecordTypeId = tipos.get('Cashback'), Pontos_Necessarios__c = 500, Valor_Cashback__c = 20),
    new Beneficio__c(Name = 'Cashback R$ 60', RecordTypeId = tipos.get('Cashback'), Pontos_Necessarios__c = 1400, Valor_Cashback__c = 60),
    new Beneficio__c(Name = 'Desconto de 10%', RecordTypeId = tipos.get('Desconto'), Pontos_Necessarios__c = 800, Percentual_Desconto__c = 10),
    new Beneficio__c(Name = 'Desconto de 25%', RecordTypeId = tipos.get('Desconto'), Pontos_Necessarios__c = 2500, Percentual_Desconto__c = 25),
    new Beneficio__c(Name = 'Caneca PontoCerto', RecordTypeId = tipos.get('Brinde'), Pontos_Necessarios__c = 1500, Descricao_do_Brinde__c = 'Caneca de cerâmica personalizada'),
    new Beneficio__c(Name = 'Mochila PontoCerto', RecordTypeId = tipos.get('Brinde'), Pontos_Necessarios__c = 3000, Descricao_do_Brinde__c = 'Mochila executiva')
};
insert catalogo;
Map<String, Beneficio__c> b = new Map<String, Beneficio__c>();
for (Beneficio__c item : catalogo) { b.put(item.Name, item); }

// ---- Campanha vigente ----
// Reaproveita a campanha se ela já existir; em um org novo, cria uma vigente (multiplicador 2).
List<Campanha_Promocional__c> existentes = [SELECT Id FROM Campanha_Promocional__c WHERE Name = 'Pontos em Dobro Nov' LIMIT 1];
Campanha_Promocional__c campanha = existentes.isEmpty()
    ? new Campanha_Promocional__c(Name = 'Pontos em Dobro Nov', Multiplicador__c = 2, Data_de_Inicio__c = Date.today().addDays(-30), Data_de_Fim__c = Date.today().addDays(60), Ativa__c = true)
    : existentes[0];
if (campanha.Id == null) { insert campanha; }

// ---- Participantes ----
Programa_Fidelidade__c maria = new Programa_Fidelidade__c(Name = 'Maria Souza', E_mail__c = 'maria.souza@exemplo.com', Cliente_VIP__c = true);
Programa_Fidelidade__c joao = new Programa_Fidelidade__c(Name = 'João Lima', E_mail__c = 'joao.lima@exemplo.com');
Programa_Fidelidade__c ana = new Programa_Fidelidade__c(Name = 'Ana Costa', E_mail__c = 'ana.costa@exemplo.com');
Programa_Fidelidade__c pedro = new Programa_Fidelidade__c(Name = 'Pedro Alves', E_mail__c = 'pedro.alves@exemplo.com', Status__c = 'Inativo');
insert new List<Programa_Fidelidade__c>{ maria, joao, ana, pedro };

// ---- Movimentações (o Flow calcula os pontos finais) ----
insert new List<Movimentacao_de_Pontos__c>{
    new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = maria.Id, Pontos_Base__c = 3000, Campanha__c = campanha.Id, Descricao__c = 'Compras de outubro com campanha em dobro'),
    new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = maria.Id, Pontos_Base__c = 1000, Descricao__c = 'Compra online'),
    new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = joao.Id, Pontos_Base__c = 1800, Descricao__c = 'Compras do mês'),
    new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = ana.Id, Pontos_Base__c = 300, Descricao__c = 'Primeira compra'),
    new Movimentacao_de_Pontos__c(Programa_Fidelidade__c = pedro.Id, Pontos_Base__c = 200, Data_da_Movimentacao__c = Date.today().addDays(-200), Descricao__c = 'Compra antiga')
};

// ---- Endereços (consulta real ao ViaCEP em segundo plano) ----
insert new List<Endereco__c>{
    new Endereco__c(Programa_Fidelidade__c = maria.Id, CEP__c = '01310100', Numero__c = '1578'),
    new Endereco__c(Programa_Fidelidade__c = joao.Id, CEP__c = '20040020', Numero__c = '100'),
    new Endereco__c(Programa_Fidelidade__c = ana.Id, CEP__c = '30130010', Numero__c = '45')
};

// ---- Resgates ----
// Abaixo de 1.000 pontos: aprovado automaticamente pelo Flow
insert new Resgate__c(Programa_Fidelidade__c = maria.Id, Beneficio__c = b.get('Cashback R$ 20').Id, Pontos__c = 500, Status__c = 'Em Aprovação');
insert new Resgate__c(Programa_Fidelidade__c = joao.Id, Beneficio__c = b.get('Desconto de 10%').Id, Pontos__c = 800, Status__c = 'Em Aprovação');
// Acima de 1.000 pontos: vai para o processo de aprovação (Coordenador -> Diretor)
insert new Resgate__c(Programa_Fidelidade__c = maria.Id, Beneficio__c = b.get('Caneca PontoCerto').Id, Pontos__c = 1500, Status__c = 'Em Aprovação');
