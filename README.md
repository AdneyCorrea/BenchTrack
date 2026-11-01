> **Uso interno:** o BenchTrack exige login para acessar suas funcionalidades. As credenciais de acesso são exclusivas do criador do aplicativo.

<div align="center">
  <img src="assets/branding/benchtrack_logo.png" alt="BenchTrack" width="280">

# BenchTrack

Gerenciamento de montagem, acompanhamento de testes e aprovação de workstations.

[![Última versão](https://img.shields.io/github/v/release/AdneyCorrea/BenchTrack)](https://github.com/AdneyCorrea/BenchTrack/releases/latest)

[Baixar](#baixar-e-instalar) · [Funcionalidades](#funcionalidades) · [Desenvolvimento](docs/DEVELOPMENT.md) · [Distribuição](docs/DISTRIBUTION.md)

</div>

O **BenchTrack** organiza o fluxo de trabalho de cada equipamento, do cadastro dos componentes ao resultado final dos testes. Desenvolvido em Flutter para Windows e Android, utiliza Supabase para autenticação, banco de dados e armazenamento de anexos.

## Baixar e instalar

**Para usar o aplicativo, não é necessário instalar Flutter, Dart, Git ou ferramentas de desenvolvimento.**

| Plataforma | Requisito | Download |
|---|---|---|
| Windows | Windows 10/11, 64 bits (x64) | [Baixar ZIP](https://github.com/AdneyCorrea/BenchTrack/releases/latest/download/BenchTrack-windows-x64.zip) |
| Android | Android 7.0 ou superior | [Baixar APK](https://github.com/AdneyCorrea/BenchTrack/releases/latest/download/BenchTrack-android.apk) |

Os links apontam para a versão publicada mais recente. Consulte também as [notas das versões](https://github.com/AdneyCorrea/BenchTrack/releases) e os [checksums SHA-256](https://github.com/AdneyCorrea/BenchTrack/releases/latest/download/SHA256SUMS.txt). Na página de Releases, os pacotes estão em **Assets**; os arquivos **Source code** contêm o código-fonte.

### Windows

1. Baixe `BenchTrack-windows-x64.zip`.
2. Extraia **todo o conteúdo** para uma pasta do computador.
3. Abra `BenchTrack.exe` na pasta extraída.

Mantenha as DLLs e a pasta `data` junto do executável. O runtime Visual C++ está incluído no pacote. O aplicativo é portátil: não há instalador ou atualização automática. Para atualizar, extraia a nova versão em outra pasta e atualize seu atalho.

O executável ainda não possui certificado de assinatura de código; o Windows pode exibir um aviso de editor desconhecido.

### Android

1. Baixe `BenchTrack-android.apk` no celular.
2. Abra o arquivo e, se solicitado, autorize o navegador ou gerenciador de arquivos a instalar esse APK.
3. Conclua a instalação e abra o BenchTrack.

Para atualizar, instale o novo APK sobre a versão anterior. A distribuição usa uma assinatura permanente; preserve essa assinatura nas próximas versões.

> **Migração do APK antigo:** se você instalou uma versão assinada com chave de depuração, desinstale-a antes de instalar a versão pública 1.0.0. Isso remove a sessão e os dados locais. Os registros persistidos no Supabase permanecem no servidor.

### Primeiro acesso

Conecte-se à internet e entre com a conta fornecida pelo administrador. O aplicativo não oferece cadastro de conta na tela de login. O usuário final não precisa criar um projeto Supabase.

## Funcionalidades

| Área | Recursos |
|---|---|
| Workstations | Cadastro de equipamentos e componentes, busca, consulta por status e exclusão com confirmação. |
| Testes de 48 horas | Registro do início, acompanhamento do tempo decorrido, histórico e resultado. |
| Aprovação | Aprovação ou reprovação e organização dos equipamentos finalizados. |
| Ocorrências | Registro de tipo, descrição, data e anexos associados ao equipamento. |
| Arquivos | Seleção, upload, consulta e exclusão de anexos no Supabase Storage. |
| Dashboard | Visão dos equipamentos em montagem, em teste, aprovados e reprovados. |
| Autenticação | Login, sessão persistente e logout com Supabase Auth. |

O horário de início dos testes fica salvo, permitindo recalcular o tempo ao reabrir o aplicativo. O BenchTrack acompanha o processo e registra resultados; a contagem de tempo não executa uma carga de estresse no hardware com o aplicativo fechado.

```text
Cadastro → Montagem → Teste de 48 horas → Aprovação ou reprovação → Finalizados
```

## Desenvolvimento

Para modificar o código e executar em modo de desenvolvimento, siga o [guia de desenvolvimento](docs/DEVELOPMENT.md). Ele reúne os requisitos de Flutter, configuração do Supabase, execução por plataforma e soluções para problemas comuns.

```powershell
git clone https://github.com/AdneyCorrea/BenchTrack.git
cd BenchTrack
flutter pub get --enforce-lockfile
flutter run -d windows
```

O exemplo pressupõe o ambiente Windows configurado conforme o guia. O projeto usa Flutter **3.44.0** no CI; o Dart acompanha o Flutter. Para Android, selecione o dispositivo com `flutter devices` e execute `flutter run -d ID_DO_DISPOSITIVO`.

### Estrutura

```text
BenchTrack/
├── .github/workflows/   # Validação e geração de pacotes
├── android/            # Projeto Android e assinatura
├── windows/            # Projeto desktop Windows
├── assets/branding/    # Identidade visual
├── lib/
│   ├── models/         # Modelos de dados
│   ├── screens/        # Telas
│   ├── services/       # Integração com Supabase
│   ├── theme/          # Tema visual
│   └── widgets/        # Componentes de interface
├── supabase/           # Scripts SQL de configuração
├── test/               # Testes Flutter
├── scripts/            # Empacotamento Windows
└── docs/               # Guias de desenvolvimento e distribuição
```

O repositório também contém scaffolds para outras plataformas Flutter. Os pacotes distribuídos atualmente são para Windows e Android.

### Tecnologias e dados

- **Flutter e Dart:** interface e lógica do aplicativo.
- **Supabase Auth:** autenticação e sessão.
- **PostgreSQL:** workstations, testes, ocorrências e metadados de anexos.
- **Supabase Storage:** armazenamento de arquivos.
- **GitHub Actions:** análise, testes e geração de pacotes.

### Segurança

A configuração do cliente fica em `lib/services/supabase_config.dart`, com URL e chave pública `publishable`. O controle de acesso depende das políticas RLS e das permissões do Storage. As políticas atuais permitem acesso a usuários autenticados e precisam ser revisadas para usos que exijam isolamento por empresa.

Nunca inclua chaves administrativas, `service_role`, senhas ou arquivos de assinatura no repositório. As instruções para configurar seu próprio backend estão no [guia de desenvolvimento](docs/DEVELOPMENT.md#supabase).

## Publicar novas versões

O [guia de distribuição](docs/DISTRIBUTION.md) explica assinatura Android, geração do ZIP Windows, artifacts do GitHub Actions e publicação de Releases.

A validação do código acontece em pushes na `main` e pull requests. A geração dos aplicativos é um workflow separado, acionado manualmente ou por tags `v*`. Uma tag que já tenha Release publicada é preservada, sem substituir seus arquivos.

## Próximos passos

- Relatórios e exportação de dados.
- Notificações e histórico avançado.
- Permissões por usuário.
- Instalador Windows e atualização automática.
- Publicação em lojas de aplicativos.

Sugestões e problemas podem ser registrados em [Issues](https://github.com/AdneyCorrea/BenchTrack/issues). Ao relatar um erro, informe a plataforma, a versão do aplicativo e os passos para reproduzi-lo.

## Autor e uso

Desenvolvido por [Adney Correa](https://github.com/AdneyCorrea), estudante de Engenharia de Software, como projeto prático de aplicações multiplataforma, persistência de dados e acompanhamento de workstations.

Este repositório não possui uma licença de software definida. Consulte o autor antes de utilizar, modificar ou redistribuir o código comercialmente.
