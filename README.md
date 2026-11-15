# Emplake

Jogo em Flutter em que o jogador transforma os quatro dígitos de uma placa de carro em uma equação verdadeira, inserindo operadores entre eles sem mudar a ordem dos dígitos.

**Jogar:** https://emplake-rm-jl.web.app

Trabalho em grupo de Renan Matulianes Arnaldo e João Augusto Luvizotto.

## Funcionalidades

- Quatro níveis (Fácil, Intermediário, Avançado e Difícil), cada um com seu conjunto de operadores.
- Fórmula renderizada em LaTeX logo abaixo da equação montada.
- Login com e-mail e senha ou Google (`firebase_ui_auth`); pontuação e números resolvidos guardados no Firestore.
- Só são sorteadas placas que têm solução e que o jogador ainda não resolveu.
- Português e inglês (`flutter_localizations`), tema claro/escuro, cor semente, fonte e tamanho da fonte configuráveis.
- Navegação com `go_router` e `curved_navigation_bar`; estado com `flutter_riverpod`.
- O app reabre na última página visitada (`shared_preferences`).

## Como rodar

```bash
flutter pub get
flutter run -d chrome
```

## Testes

```bash
flutter test
```

## Placas sem solução

`lib/unsolvable.dart` é gerado por um solucionador que testa as 10.000 placas em cada nível com as mesmas regras do jogo:

```bash
dart run tool/solve.dart
```

## Publicar

```bash
flutter build web --release
firebase deploy --only hosting
```
