/**
 * Classe base do Trigger Framework do projeto.
 * Cada trigger delega a execução a um handler que estende esta classe e
 * sobrescreve apenas os eventos de que precisa.
 */
public virtual class TriggerHandler {
    private static Set<String> desativados = new Set<String>();

    public static void desativar(String nomeDoHandler) {
        desativados.add(nomeDoHandler);
    }

    public static void reativar(String nomeDoHandler) {
        desativados.remove(nomeDoHandler);
    }

    public static Boolean estaDesativado(String nomeDoHandler) {
        return desativados.contains(nomeDoHandler);
    }

    /** Ponto de entrada chamado pela trigger. */
    public void run() {
        if (Trigger.operationType == null || estaDesativado(nomeDoHandler())) {
            return;
        }
        executar(Trigger.operationType);
    }

    /** Encaminha a operação para o método correspondente (separado de run() para poder ser testado). */
    @TestVisible
    protected void executar(System.TriggerOperation operacao) {
        switch on operacao {
            when BEFORE_INSERT { antesDeInserir(); }
            when BEFORE_UPDATE { antesDeAtualizar(); }
            when BEFORE_DELETE { antesDeExcluir(); }
            when AFTER_INSERT { depoisDeInserir(); }
            when AFTER_UPDATE { depoisDeAtualizar(); }
            when AFTER_DELETE { depoisDeExcluir(); }
            when AFTER_UNDELETE { depoisDeRestaurar(); }
        }
    }

    @TestVisible
    protected String nomeDoHandler() {
        return String.valueOf(this).substringBefore(':');
    }

    protected virtual void antesDeInserir() {}
    protected virtual void antesDeAtualizar() {}
    protected virtual void antesDeExcluir() {}
    protected virtual void depoisDeInserir() {}
    protected virtual void depoisDeAtualizar() {}
    protected virtual void depoisDeExcluir() {}
    protected virtual void depoisDeRestaurar() {}
}
