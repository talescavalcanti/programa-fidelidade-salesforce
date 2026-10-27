import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getResumo from '@salesforce/apex/FidelidadeController.getResumo';

const FORMATO = new Intl.NumberFormat('pt-BR');

export default class SaldoPontosCard extends LightningElement {
    @api recordId;
    resumo;
    erro;
    resultadoDoWire;

    @wire(getResumo, { programaId: '$recordId' })
    carregar(resultado) {
        this.resultadoDoWire = resultado;
        const { data, error } = resultado;
        if (data) {
            this.resumo = data;
            this.erro = undefined;
        } else if (error) {
            this.resumo = undefined;
            this.erro = error.body ? error.body.message : 'Erro ao carregar o saldo.';
        }
    }

    get saldoFormatado() {
        return FORMATO.format(this.resumo.saldoAtual);
    }

    get totalPontosFormatado() {
        return FORMATO.format(this.resumo.totalPontos);
    }

    get totalResgatesFormatado() {
        return FORMATO.format(this.resumo.totalResgates);
    }

    get textoProgresso() {
        if (!this.resumo.proximaCategoria) {
            return 'Categoria máxima atingida.';
        }
        return `Faltam ${FORMATO.format(this.resumo.pontosParaProxima)} pontos para a categoria ${this.resumo.proximaCategoria}.`;
    }

    get classeCategoria() {
        return `categoria categoria-${this.resumo.categoria.toLowerCase()}`;
    }

    atualizar() {
        return refreshApex(this.resultadoDoWire);
    }
}
