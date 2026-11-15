// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Emplake';

  @override
  String get tagline => 'Transforme placas de carro em equações';

  @override
  String get groupMembers => 'Integrantes do grupo';

  @override
  String get language => 'Idioma';

  @override
  String get navGame => 'Jogar';

  @override
  String get navHistory => 'Resolvidos';

  @override
  String get navHelp => 'Ajuda';

  @override
  String get navSettings => 'Configurações';

  @override
  String get levelEasy => 'Fácil';

  @override
  String get levelIntermediate => 'Intermediário';

  @override
  String get levelAdvanced => 'Avançado';

  @override
  String get levelHard => 'Difícil';

  @override
  String score(int points) {
    return 'Pontos: $points';
  }

  @override
  String get plateRegion => 'MERCOSUL · BRASIL';

  @override
  String slotLabel(int n) {
    return 'Encaixe $n';
  }

  @override
  String get selectSlotHint =>
      'Toque em um “_” e depois nos operadores para inseri-los ali.';

  @override
  String get preview => 'Fórmula renderizada';

  @override
  String sides(String left, String right) {
    return 'Esquerda = $left   ·   Direita = $right';
  }

  @override
  String get verify => 'Verificar';

  @override
  String get skip => 'Pular número';

  @override
  String get clear => 'Limpar';

  @override
  String get undo => 'Remover o último operador do encaixe';

  @override
  String get prevSlot => 'Encaixe anterior';

  @override
  String get nextSlot => 'Próximo encaixe';

  @override
  String correct(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '+$points pontos',
      one: '+1 ponto',
    );
    return 'Correto! $_temp0';
  }

  @override
  String wrong(String left, String right) {
    return 'Não é igual: $left ≠ $right';
  }

  @override
  String get allSolved => 'Você resolveu todos os números deste nível!';

  @override
  String get loading => 'Carregando…';

  @override
  String loadError(String error) {
    return 'Não foi possível carregar seus dados: $error';
  }

  @override
  String saveError(String error) {
    return 'Não foi possível salvar sua resposta: $error';
  }

  @override
  String get retry => 'Tentar novamente';

  @override
  String get cloudOffline =>
      'sem conexão com a internet, ou o servidor não respondeu.';

  @override
  String get cloudDenied => 'acesso negado. Saia e entre novamente.';

  @override
  String get cloudUnknown => 'erro inesperado.';

  @override
  String errUnexpected(String token) {
    return 'Símbolo inesperado “$token”.';
  }

  @override
  String get errIncomplete => 'A expressão está incompleta.';

  @override
  String errUnclosed(String token) {
    return 'Falta fechar com “$token”.';
  }

  @override
  String get errEquals => 'A equação precisa de exatamente um “=”.';

  @override
  String get errEmptySide => 'Os dois lados do “=” precisam de uma expressão.';

  @override
  String get errDivZero => 'Divisão por zero.';

  @override
  String get errNonInteger =>
      'Divisão não inteira só é permitida no nível Fácil.';

  @override
  String get errFactorial =>
      'O fatorial precisa de um número inteiro entre 0 e 18.';

  @override
  String get errSqrtNegative => 'Raiz quadrada de número negativo.';

  @override
  String get errPower => 'Potência inválida.';

  @override
  String get errTooBig => 'O resultado é grande demais.';

  @override
  String errNotAllowed(String token) {
    return '“$token” não está disponível neste nível.';
  }

  @override
  String cantPlace(String token, int slot) {
    return '“$token” não pode ficar no encaixe $slot aqui.';
  }

  @override
  String get opPlus => 'Adição';

  @override
  String get opMinus => 'Subtração ou sinal negativo';

  @override
  String get opTimes => 'Multiplicação';

  @override
  String get opDivide => 'Divisão';

  @override
  String get opLParen => 'Abre parêntese';

  @override
  String get opRParen => 'Fecha parêntese';

  @override
  String get opSqrt => 'Raiz quadrada';

  @override
  String get opCbrt => 'Raiz cúbica';

  @override
  String get opFact => 'Fatorial';

  @override
  String get opPow => 'Exponenciação (**)';

  @override
  String get opAbs => 'Módulo |x| (abre e fecha)';

  @override
  String get opFloorL => 'Base ⌊x⌋: abre';

  @override
  String get opFloorR => 'Base ⌊x⌋: fecha';

  @override
  String get opCeilL => 'Teto ⌈x⌉: abre';

  @override
  String get opCeilR => 'Teto ⌈x⌉: fecha';

  @override
  String get opEquals => 'Mover o sinal de igual para o “_” selecionado';

  @override
  String get equalsTip =>
      'Arraste o sinal = até um “_”, ou toque nele e depois em um “_”';

  @override
  String get moveEqualsHint => 'Agora toque no “_” onde o sinal = deve ficar.';

  @override
  String get historyTitle => 'Números resolvidos';

  @override
  String get historyEmpty => 'Nenhum número resolvido neste nível ainda.';

  @override
  String totalScore(int points) {
    return 'Pontuação total: $points';
  }

  @override
  String solvedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count resolvidos',
      one: '1 resolvido',
      zero: 'nenhum resolvido',
    );
    return '$_temp0';
  }

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get fontFamily => 'Fonte';

  @override
  String get seedColor => 'Cor semente';

  @override
  String get presets => 'Temas prontos';

  @override
  String get presetPlate => 'Placa Mercosul';

  @override
  String get presetForest => 'Floresta';

  @override
  String get presetSunset => 'Pôr do sol';

  @override
  String get presetGrape => 'Uva';

  @override
  String get presetTerminal => 'Terminal';

  @override
  String get sound => 'Efeitos sonoros';

  @override
  String get soundHint => 'Desligado por padrão';

  @override
  String get account => 'Conta';

  @override
  String signedInAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get signOut => 'Sair';

  @override
  String get helpTitle => 'Como jogar';

  @override
  String get helpBody =>
      'Aparece o número de quatro dígitos de uma placa. Mantenha os dígitos na ordem e insira operadores ao redor deles para que a equação fique verdadeira. Dígitos sem nada entre eles formam um único número (4 e 1 formam 41).\n\nCada “_” é um lugar onde cabem símbolos: antes, entre e depois dos dígitos, e dos dois lados do sinal =. Toque em um “_” para selecioná-lo e depois toque nos operadores para inseri-los ali. Sempre que ainda couber outro símbolo depois dos que você colocou, aparece um novo “_”, então dá para encadear símbolos como √( ou )!; combinações impossíveis como ++ são recusadas. A tecla de apagar remove o último símbolo ao lado do “_” selecionado. O sinal = está sempre na placa: para movê-lo, arraste-o até outro “_”, ou toque nele e depois em um “_”, ou selecione um “_” e aperte a tecla =.\n\nToque em Verificar para validar a resposta. Respostas corretas valem pontos (Fácil 1, Intermediário 2, Avançado 3, Difícil 4) e aquele número nunca mais aparece naquele nível. Só são sorteadas placas que têm solução. Travou? Pule o número.';

  @override
  String get helpExample => 'Exemplo com 8131:';

  @override
  String get helpOperators => 'Operadores por nível';

  @override
  String get close => 'Fechar';
}
