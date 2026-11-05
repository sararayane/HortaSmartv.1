import '../modelos/canteiro.dart';

/// Dados locais de demonstração para desenvolver a interface antes da integração.
class RepositorioCanteiro {
  static List<Canteiro> criarDadosDemonstracao() => const [
        Canteiro(
          id: 'canteiro-01',
          nome: 'Canteiro 1',
          cultura: 'Alface',
          umidadeAtual: 68,
          metaUmidade: 65,
          conectado: true,
          irrigando: false,
          modo: ModoIrrigacao.automatico,
          intervaloHoras: 4,
          valorSeco: 3000,
          valorMolhado: 1400,
        ),
        Canteiro(
          id: 'canteiro-02',
          nome: 'Canteiro 2',
          cultura: 'Tomate',
          umidadeAtual: 42,
          metaUmidade: 55,
          conectado: true,
          irrigando: false,
          modo: ModoIrrigacao.automatico,
          intervaloHoras: 6,
          valorSeco: 3050,
          valorMolhado: 1350,
        ),
        Canteiro(
          id: 'canteiro-03',
          nome: 'Canteiro 3',
          cultura: 'Cenoura',
          umidadeAtual: 28,
          metaUmidade: 50,
          conectado: true,
          irrigando: false,
          modo: ModoIrrigacao.automatico,
          intervaloHoras: 6,
          valorSeco: 2980,
          valorMolhado: 1380,
        ),
        Canteiro(
          id: 'canteiro-04',
          nome: 'Canteiro 4',
          cultura: 'Rúcula',
          umidadeAtual: 76,
          metaUmidade: 60,
          conectado: true,
          irrigando: false,
          modo: ModoIrrigacao.automatico,
          intervaloHoras: 4,
          valorSeco: 3020,
          valorMolhado: 1420,
        ),
      ];
}
