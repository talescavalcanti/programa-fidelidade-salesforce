@IsTest
private class TriggerHandlerTest {

    /** Handler de teste: registra qual método foi chamado para cada evento. */
    private class HandlerGravador extends TriggerHandler {
        public List<String> chamadas = new List<String>();
        protected override void antesDeInserir() { chamadas.add('antesDeInserir'); }
        protected override void antesDeAtualizar() { chamadas.add('antesDeAtualizar'); }
        protected override void antesDeExcluir() { chamadas.add('antesDeExcluir'); }
        protected override void depoisDeInserir() { chamadas.add('depoisDeInserir'); }
        protected override void depoisDeAtualizar() { chamadas.add('depoisDeAtualizar'); }
        protected override void depoisDeExcluir() { chamadas.add('depoisDeExcluir'); }
        protected override void depoisDeRestaurar() { chamadas.add('depoisDeRestaurar'); }
    }

    @IsTest
    static void cadaEventoChamaOMetodoCorrespondente() {
        HandlerGravador handler = new HandlerGravador();
        handler.executar(System.TriggerOperation.BEFORE_INSERT);
        handler.executar(System.TriggerOperation.BEFORE_UPDATE);
        handler.executar(System.TriggerOperation.BEFORE_DELETE);
        handler.executar(System.TriggerOperation.AFTER_INSERT);
        handler.executar(System.TriggerOperation.AFTER_UPDATE);
        handler.executar(System.TriggerOperation.AFTER_DELETE);
        handler.executar(System.TriggerOperation.AFTER_UNDELETE);
        System.assertEquals(new List<String>{
            'antesDeInserir', 'antesDeAtualizar', 'antesDeExcluir',
            'depoisDeInserir', 'depoisDeAtualizar', 'depoisDeExcluir', 'depoisDeRestaurar'
        }, handler.chamadas);
    }

    @IsTest
    static void handlerBaseNaoFazNadaPorPadrao() {
        TriggerHandler base = new TriggerHandler();
        for (System.TriggerOperation operacao : System.TriggerOperation.values()) {
            base.executar(operacao);
        }
        System.assert(true, 'Nenhuma exceção esperada');
    }

    @IsTest
    static void runForaDeUmaTriggerNaoExecutaNada() {
        HandlerGravador handler = new HandlerGravador();
        handler.run();
        System.assertEquals(0, handler.chamadas.size());
    }

    @IsTest
    static void nomeDoHandlerEUsadoParaDesativar() {
        HandlerGravador handler = new HandlerGravador();
        String nome = handler.nomeDoHandler();
        System.assert(nome.contains('HandlerGravador'), nome);
        TriggerHandler.desativar(nome);
        System.assert(TriggerHandler.estaDesativado(nome));
        handler.run();
        TriggerHandler.reativar(nome);
        System.assert(!TriggerHandler.estaDesativado(nome));
    }
}
