import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getUltimoLog from '@salesforce/apex/FidelidadeController.getUltimoLog';

const INTERVALO_MS = 3000;
const MAXIMO_DE_TENTATIVAS = 5;

export default class ConsultaCepStatus extends LightningElement {
    @api recordId;
    log;
    erro;
    resultadoDoWire;
    tentativas = 0;
    temporizador;

    @wire(getUltimoLog, { enderecoId: '$recordId' })
    carregar(resultado) {
        this.resultadoDoWire = resultado;
        const { data, error } = resultado;
        if (data) {
            this.log = data;
            this.erro = undefined;
            this.aguardarSeNecessario();
        } else if (error) {
            this.log = undefined;
            this.erro = error.body ? error.body.message : 'Erro ao carregar o log.';
        }
    }

    // A consulta roda em segundo plano (Queueable): enquanto estiver Pendente, atualiza sozinho.
    aguardarSeNecessario() {
        if (this.aguardando && this.tentativas < MAXIMO_DE_TENTATIVAS) {
            this.tentativas += 1;
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            this.temporizador = setTimeout(() => refreshApex(this.resultadoDoWire), INTERVALO_MS);
        }
    }

    disconnectedCallback() {
        clearTimeout(this.temporizador);
    }

    get aguardando() {
        return this.log && this.log.statusConsulta === 'Pendente';
    }

    get classeStatus() {
        const status = this.log ? this.log.statusConsulta : '';
        if (status === 'Sucesso') {
            return 'slds-theme_success';
        }
        return status === 'Erro' ? 'slds-theme_error' : '';
    }

    get dataFormatada() {
        return this.log && this.log.dataHora ? new Date(this.log.dataHora).toLocaleString('pt-BR') : '';
    }

    atualizar() {
        this.tentativas = 0;
        return refreshApex(this.resultadoDoWire);
    }
}
