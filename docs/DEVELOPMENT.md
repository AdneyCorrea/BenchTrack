# Desenvolvimento

## Requisitos

- **Flutter 3.44.0**, versão usada no workflow, ou versão compatível com o `pubspec.lock` (Flutter >=3.44.0 e Dart >=3.12.0). O Dart já acompanha o Flutter.
- Git para clonar o repositório.
- **Windows**: compilar no Windows com Visual Studio e a carga **Desenvolvimento para desktop com C++**. Visual Studio Code não substitui esse compilador.
- **Android**: Android SDK e JDK 17. Android Studio facilita a instalação do SDK e do emulador. Para celular físico, ative a depuração USB e autorize o computador.

Referências: [instalar Flutter](https://docs.flutter.dev/install), [ambiente Windows](https://docs.flutter.dev/platform-integration/windows/setup) e [ambiente Android](https://docs.flutter.dev/platform-integration/android/setup).

Confira o ambiente e resolva os itens da plataforma desejada:

```powershell
flutter --version
flutter doctor -v
```

Para Android, aceite as licenças:

```powershell
flutter doctor --android-licenses
```

## Instalação

```powershell
git clone https://github.com/AdneyCorrea/BenchTrack.git
cd BenchTrack
flutter pub get --enforce-lockfile
```

## Supabase

`lib/services/supabase_config.dart` já aponta para um projeto Supabase com URL e chave **publishable** públicas de cliente. Para usar a instância existente, basta uma conta autorizada.

Para usar seu próprio backend:

1. Crie um projeto Supabase.
2. Revise e execute os scripts de `supabase/` no SQL Editor na ordem `01` a `06`.
3. Crie os usuários em **Authentication > Users**.
4. Substitua `url` e `publishableKey` no arquivo de configuração pelos valores do seu projeto. A validação atual aceita HTTPS e chave com prefixo `sb_publishable_`.
5. Recompile o aplicativo para incorporar a configuração.

Os scripts incluem tabelas, políticas e Storage. Revise as permissões: as políticas atuais dão acesso a usuários autenticados e não isolam empresas. Nunca inclua chaves `service_role`, secret keys ou senhas administrativas no cliente.

## Executar no Windows

```powershell
flutter devices
flutter run -d windows
```

## Executar no Android

Conecte o celular ou inicie um emulador no Device Manager do Android Studio. Substitua `ID_DO_DISPOSITIVO` pelo ID Android listado:

```powershell
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

## Problemas comuns

| Sintoma | Solução |
|---|---|
| `flutter` não reconhecido | Adicione o `bin` do Flutter ao PATH e reabra o terminal. |
| Dependências exigem Dart/Flutter mais novo | Use a versão indicada acima; Dart acompanha Flutter. |
| Windows indisponível | Execute `flutter config --enable-windows-desktop` e confira a carga C++ no `flutter doctor -v`. |
| Android não aparece | Confira emulador, cabo, driver, depuração USB e autorização no celular. |
| Login ou consultas falham | Confira internet, conta, configuração Supabase, scripts e políticas RLS/Storage. |
| APK release falha na assinatura | Configure `android/key.properties` seguindo o guia de distribuição. |

Se houver resíduos de uma compilação anterior após mudar o SDK:

```powershell
flutter clean
flutter pub get --enforce-lockfile
```

---


## Validação

O workflow Validar projeto executa a análise estática e os testes em pushes na main e pull requests. Para conferir localmente:

```powershell
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test
```

Para gerar os pacotes, consulte [Distribuição](DISTRIBUTION.md).
