# HortaSmart — aplicativo Flutter responsivo

Interface demonstrativa de irrigação inteligente com quatro telas e layout responsivo para celular, tablet e desktop. Os nomes de pastas e arquivos do projeto estão em português.

## Como aplicar ao seu projeto

1. Extraia o ZIP em uma pasta temporária.
2. Faça uma cópia de segurança da pasta `lib` atual do seu projeto.
3. Copie a pasta `lib` extraída para a raiz do seu projeto Flutter, substituindo a antiga pasta `lib`.
4. Mantenha o `pubspec.yaml` do seu projeto e confirme que esta dependência está em `dependencies`.

   ```yaml
   fl_chart: ^0.68.0
   ```

5. Na raiz do projeto, execute:

   ```bash
   flutter pub get
   flutter run
   ```

## O que foi preparado

- **Painel:** nome HortaSmart no cabeçalho, conexão ESP32, clima demonstrativo, cartões de canteiros com umidade e indicadores verde/amarelo/vermelho.
- **Irrigação:** seleção do canteiro, modo automático/manual, meta de 0% a 100%, intervalo de verificação e comandos manuais demonstrativos.
- **Histórico:** gráfico de umidade por canteiro, gráficos alternativos de acionamentos e consumo estimado, resumo por canteiro e período de 24 horas/7 dias.
- **Configurações:** cadastro e remoção de canteiros, status dos ESP32, calibração, definição individual de metas e programação.
- Navegação inferior no celular e menu lateral em telas maiores.
- Componentes visuais reutilizáveis, tema, modelo e camada de serviços isolada.

## Limites desta versão

Esta é uma versão de front-end com dados ilustrativos. Firebase, leituras reais do ESP32, API de previsão do tempo e acionamento físico da bomba ainda não estão conectados. Cadastros e alterações permanecem na memória enquanto o aplicativo está aberto.

Antes de controlar bombas de verdade, valide os comandos no firmware do ESP32 e implemente proteções como limite máximo de irrigação, sensor/condição de água disponível e estado seguro em caso de perda de conexão. A estimativa de litros depende da vazão real da bomba ou de um sensor de fluxo.
