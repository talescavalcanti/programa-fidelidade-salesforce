import { LightningElement, api, wire } from 'lwc';
import getBeneficiosDisponiveis from '@salesforce/apex/FidelidadeController.getBeneficiosDisponiveis';

const FORMATO = new Intl.NumberFormat('pt-BR');

export default class BeneficiosDisponiveis extends LightningElement {
    @api recordId;
    beneficios = [];
    erro;
    carregado = false;
    somenteElegiveis = false;

    @wire(getBeneficiosDisponiveis, { programaId: '$recordId' })
    carregar({ data, error }) {
        if (data) {
            this.beneficios = data;
            this.erro = undefined;
            this.carregado = true;
        } else if (error) {
            this.beneficios = [];
            this.erro = error.body ? error.body.message : 'Erro ao carregar os benefícios.';
        }
    }

    get itens() {
        return this.beneficios
            .filter((b) => !this.somenteElegiveis || b.elegivel)
            .map((b) => ({
                ...b,
                pontosFormatado: FORMATO.format(b.pontos),
                textoStatus: b.elegivel ? 'Pode resgatar' : `Faltam ${FORMATO.format(b.faltam)} pts`,
                classeStatus: b.elegivel
                    ? 'slds-text-body_small slds-text-color_success'
                    : 'slds-text-body_small slds-text-color_weak'
            }));
    }

    get temItens() {
        return this.itens.length > 0;
    }

    alternarFiltro(evento) {
        this.somenteElegiveis = evento.target.checked;
    }
}
