# Distribuir o BenchTrack

O usuário recebe um ZIP portátil Windows x64 ou um APK Android assinado. As ferramentas de desenvolvimento ficam no computador do mantenedor ou no GitHub Actions.

## 1. Assinatura Android permanente

Crie uma chave uma única vez com o `keytool` do JDK 17 (disponível no PATH), na raiz do projeto:

```powershell
keytool -genkeypair -v -keystore android/release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias benchtrack
```

Guarde a chave e as senhas em backup privado. Todas as atualizações devem usar a mesma chave. Não publique esses arquivos no Git.

Para compilar localmente, crie `android/key.properties`:

```properties
storeFile=release.jks
storePassword=SENHA_DO_KEYSTORE
keyPassword=SENHA_DA_CHAVE
keyAlias=benchtrack
```

O caminho `storeFile` é relativo à pasta `android/`. Escape caracteres especiais conforme o formato Java Properties, caso existam nas senhas. Os arquivos de assinatura já são ignorados pelo Git. Builds release exigem essa configuração; `flutter run` em debug não exige.

No GitHub, em **Settings > Secrets and variables > Actions > New repository secret**, configure:

| Secret | Valor |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | Conteúdo Base64 do arquivo `release.jks` |
| `ANDROID_STORE_PASSWORD` | Senha do keystore |
| `ANDROID_KEY_PASSWORD` | Senha da chave |
| `ANDROID_KEY_ALIAS` | `benchtrack` ou o alias escolhido |

Para copiar o Base64 à área de transferência no PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path (Get-Location) 'android/release.jks'))) | Set-Clipboard
```

O workflow restaura a chave no runner temporário e a remove ao terminar. Sem os quatro secrets, o job Android falha com uma mensagem de configuração; o job Windows continua independente.

## 2. Gerar no GitHub Actions

Depois de enviar estas alterações ao GitHub:

1. Abra **Actions > Gerar aplicativos > Run workflow** e escolha a branch.
2. Aguarde os jobs Windows e Android.
3. Baixe os artifacts da execução. O download do GitHub é um ZIP externo: extraia-o para obter `BenchTrack-windows-x64.zip` ou `BenchTrack-android.apk`.
4. Extraia o ZIP Windows completo e teste num Windows x64 sem Flutter/Visual Studio. Instale o APK em um Android físico e confira login, consultas e anexos.

Artifacts são temporários e seu download pode exigir login no GitHub. Para distribuição pública e duradoura, publique uma Release.

## 3. Preparar uma Release

Atualize `version` em `pubspec.yaml`. Exemplo: `1.0.1+2`; o número após `+` deve aumentar para as atualizações Android. Envie o commit antes da tag e use a mesma versão:

```powershell
git tag v1.0.1
git push origin v1.0.1
```

Se ambos os builds passarem, a tag cria uma **Release em rascunho** com:

- `BenchTrack-windows-x64.zip`: executável, plugins, dados e DLLs do runtime Visual C++.
- `BenchTrack-android.apk`: APK universal release assinado com sua chave.
- `SHA256SUMS.txt`: hashes dos dois arquivos.

Abra **Releases**, revise o rascunho, baixe e teste os arquivos e clique em **Publish release**. Até a publicação, usuários não veem o rascunho. Não reutilize tags de versões publicadas.

## Compilar localmente

Use o ambiente descrito no README. Confira o backend em `lib/services/supabase_config.dart` antes de distribuir: a configuração fica incorporada na compilação.

### Windows (no Windows com Visual Studio C++)

```powershell
flutter pub get --enforce-lockfile
flutter build windows --release
powershell -NoProfile -File scripts/package-windows.ps1
```

Saída: `dist/BenchTrack-windows-x64.zip`. O script inclui todo o diretório `build/windows/x64/runner/Release` e as DLLs CRT x64 redistribuíveis encontradas pelo `vswhere` do Visual Studio. Ele falha se o build ou runtime estiver incompleto. A distribuição das DLLs segue os termos de redistribuição da Microsoft.

### Android (com assinatura configurada)

```powershell
flutter pub get --enforce-lockfile
flutter build apk --release
```

Saída: `build/app/outputs/flutter-apk/app-release.apk`. Renomeie para `BenchTrack-android.apk` ao distribuir.

## Limites atuais

- O ZIP Windows é portátil, sem instalador ou atualização automática. Extraia novas versões em outra pasta e atualize seu atalho.
- O executável Windows não possui certificado de assinatura de código; pode aparecer um aviso de editor desconhecido.
- O APK é distribuído fora da Play Store. Instalações antigas com chave de debug não aceitam atualização com a nova assinatura; desinstalá-las remove os dados locais.
- O application ID Android permanece `com.example.benchtrack` para preservar a identidade atual. Planeje uma identidade definitiva antes da publicação em loja.
- Os pacotes precisam de internet e de uma conta no backend. Eles não incluem servidor Supabase local.

Referências: [ZIP e runtime Windows](https://docs.flutter.dev/platform-integration/windows/building), [assinatura Android](https://docs.flutter.dev/deployment/android), [Flutter Action](https://github.com/subosito/flutter-action) e [GitHub Release Action](https://github.com/softprops/action-gh-release).
