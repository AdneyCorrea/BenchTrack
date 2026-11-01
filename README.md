# 🖥️ BenchTrack

> Sistema multiplataforma para gerenciamento, acompanhamento e validação de Workstations.

O **BenchTrack** é uma aplicação desenvolvida em **Flutter** para organizar o fluxo de montagem e testes de Workstations, permitindo cadastrar equipamentos, acompanhar testes de estabilidade, registrar ocorrências, anexar arquivos e controlar o resultado final de cada máquina.

O projeto utiliza **Supabase** como backend, proporcionando autenticação, persistência dos dados e armazenamento de arquivos.

---

## ✨ Funcionalidades

### 🖥️ Gerenciamento de Workstations
- Cadastro e visualização de Workstations
- Consulta detalhada dos componentes
- Busca de Workstations
- Organização por status
- Exclusão com confirmação
- Persistência dos dados no Supabase

### 🧪 Teste de estabilidade de 48 horas
- Início do teste de 48 horas
- Cronômetro em tempo real
- Persistência do horário de início
- Contagem continua mesmo após fechar o aplicativo
- Funcionamento no Windows e Android
- Registro do resultado
- Aprovação ou reprovação
- Histórico dos testes

### ✅ Aprovação e reprovação
Após finalizar um teste, a Workstation pode ser marcada como:
- ✅ **Aprovada**
- ❌ **Reprovada**

As máquinas finalizadas são organizadas na área **Finalizados**, onde seu resultado é exibido.

### ⚠️ Ocorrências
- Registro de ocorrências durante os testes
- Tipo e descrição
- Data e Workstation relacionada
- Arquivos anexados
- Exclusão de ocorrências

### 📎 Arquivos
- Seleção e upload de arquivos
- Visualização dos arquivos associados
- Armazenamento no Supabase Storage
- Exclusão de arquivos

### 📊 Dashboard
O painel inicial apresenta dados reais obtidos do banco:
- Workstations em montagem
- Workstations em teste
- Workstations aprovadas
- Workstations reprovadas

### 🔐 Autenticação
- Login utilizando Supabase Auth
- Sessão persistente
- Logout

---

## ☁️ Supabase

O Supabase é utilizado como backend da aplicação.

**Recursos utilizados:**
- PostgreSQL
- Supabase Auth
- Supabase Storage
- API do Supabase
- Persistência de dados
- Controle de acesso

**Principais tabelas:**
```text
workstations
stress_tests
```

---

## 📱 Plataformas

| Plataforma | Status |
|---|---|
| 🪟 Windows | ✅ Funcionando |
| 🤖 Android | ✅ Funcionando |

---

## 🛠️ Tecnologias

| Tecnologia | Utilização |
|---|---|
| **Flutter** | Desenvolvimento multiplataforma |
| **Dart** | Linguagem principal |
| **Supabase** | Backend |
| **PostgreSQL** | Banco de dados |
| **Supabase Auth** | Autenticação |
| **Supabase Storage** | Armazenamento de arquivos |
| **Git** | Controle de versão |
| **GitHub** | Versionamento e documentação |

---

## 📂 Estrutura do projeto

```text
benchtrack/
├── android/
├── ios/
├── linux/
├── macos/
├── web/
├── windows/
├── assets/
│   └── branding/
├── lib/
│   ├── models/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── widgets/
│   ├── app.dart
│   └── main.dart
├── supabase/
├── test/
├── pubspec.yaml
└── README.md
```

---

## 📥 Usar o aplicativo sem ferramentas de desenvolvimento

Baixe os pacotes em [Releases](https://github.com/AdneyCorrea/BenchTrack/releases), na seção **Assets**. Os arquivos **Source code** são o código-fonte, não o aplicativo pronto.

- [⬇️ Baixar para Windows x64](https://github.com/AdneyCorrea/BenchTrack/releases/latest/download/BenchTrack-windows-x64.zip)
- [⬇️ Baixar para Android](https://github.com/AdneyCorrea/BenchTrack/releases/latest/download/BenchTrack-android.apk)

Os links acima apontam para os pacotes da versão publicada mais recente. Para preparar novas versões, consulte o [guia de distribuição](docs/DISTRIBUTION.md).

### Windows 10/11 x64

1. Baixe `BenchTrack-windows-x64.zip`.
2. Extraia **todo** o ZIP para uma pasta do computador.
3. Abra `benchtrack.exe` dentro da pasta extraída.

Mantenha as DLLs e a pasta `data` junto do executável. O pacote gerado pelo workflow inclui o runtime C++; o usuário não precisa instalar Flutter, Dart, Git ou Visual Studio.

### Android

1. Baixe `BenchTrack-android.apk` no celular.
2. Abra o arquivo e autorize o navegador ou gerenciador de arquivos a instalar esse APK, se solicitado.
3. Instale e abra o BenchTrack.

Não é necessário instalar Android Studio, Flutter ou Java no celular. As atualizações precisam usar a mesma assinatura. Uma instalação antiga com chave de debug pode precisar ser desinstalada antes; isso remove sua sessão e os dados locais.

### Acesso

É necessário ter internet e uma conta criada pelo administrador no Supabase usado pela compilação. A tela atual oferece login, sem cadastro de conta pelo aplicativo. O usuário final não precisa criar um projeto Supabase.

---

## 🛠️ Desenvolver pelo código-fonte

### Requisitos

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

### Instalação

```powershell
git clone https://github.com/AdneyCorrea/BenchTrack.git
cd BenchTrack
flutter pub get --enforce-lockfile
```

### Supabase

`lib/services/supabase_config.dart` já aponta para um projeto Supabase com URL e chave **publishable** públicas de cliente. Para usar a instância existente, basta uma conta autorizada.

Para usar seu próprio backend:

1. Crie um projeto Supabase.
2. Revise e execute os scripts de `supabase/` no SQL Editor na ordem `01` a `06`.
3. Crie os usuários em **Authentication > Users**.
4. Substitua `url` e `publishableKey` no arquivo de configuração pelos valores do seu projeto. A validação atual aceita HTTPS e chave com prefixo `sb_publishable_`.
5. Recompile o aplicativo para incorporar a configuração.

Os scripts incluem tabelas, políticas e Storage. Revise as permissões: as políticas atuais dão acesso a usuários autenticados e não isolam empresas. Nunca inclua chaves `service_role`, secret keys ou senhas administrativas no cliente.

### Executar no Windows

```powershell
flutter devices
flutter run -d windows
```

### Executar no Android

Conecte o celular ou inicie um emulador no Device Manager do Android Studio. Substitua `ID_DO_DISPOSITIVO` pelo ID Android listado:

```powershell
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

### Problemas comuns

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

## 📦 Gerar pacotes

O workflow [Gerar aplicativos](.github/workflows/build.yml) compila Windows e Android no GitHub Actions. A execução manual gera artifacts para download; tags `v*` também criam uma Release **em rascunho**, com ZIP, APK e checksums para testar antes de publicar.

O [guia de distribuição](docs/DISTRIBUTION.md) explica a configuração inicial da assinatura Android, a compilação local e a publicação. O ZIP Windows é portátil; ainda não há instalador ou atualização automática.

Referências oficiais: [distribuição Windows](https://docs.flutter.dev/platform-integration/windows/building) e [release Android](https://docs.flutter.dev/deployment/android).

---
## 🎨 Identidade visual

O BenchTrack possui uma identidade visual própria inspirada no estilo tecnológico/gamer:

- ⚫ Interface escura
- 🔴 Vermelho como cor de destaque
- 🖥️ Elementos relacionados a hardware
- 🎮 Estética tecnológica
- 🦅 Identidade visual personalizada
- 📱 Interface adaptada para Android
- 🪟 Interface adaptada para Windows

---

## 🔄 Fluxo de dados

```text
Flutter
   │
   ▼
Services
   │
   ▼
Supabase
   │
   ├── PostgreSQL
   ├── Authentication
   └── Storage
```

---

## 🧠 Conceitos aplicados

- Desenvolvimento multiplataforma
- Programação em Dart
- Desenvolvimento de interfaces
- Gerenciamento de estado
- Persistência de dados
- Banco de dados relacional
- APIs
- Autenticação
- Armazenamento em nuvem
- CRUD
- Controle de sessão
- Validação de dados
- Tratamento de erros
- Integração com serviços externos
- Controle de versão com Git

---

## 🔒 Segurança

Como o projeto utiliza Supabase, é importante configurar corretamente:

- Row Level Security (RLS)
- Políticas de acesso
- Permissões do Storage
- Autenticação
- Chaves públicas e privadas
- Permissões das tabelas

Nunca coloque informações como:

```text
senha
service_role key
tokens privados
credenciais administrativas
```

diretamente no código público.

---

## 📌 Status do projeto

🟢 **Em desenvolvimento ativo**

### Funcionalidades concluídas

- [x] Cadastro de Workstations
- [x] Dashboard
- [x] Busca de Workstations
- [x] Autenticação
- [x] Login persistente
- [x] Persistência de dados
- [x] Integração com Supabase
- [x] Teste de estabilidade de 48 horas
- [x] Cronômetro persistente
- [x] Teste funcionando com aplicativo fechado
- [x] Aprovação de Workstations
- [x] Reprovação de Workstations
- [x] Área de finalizados
- [x] Histórico de testes
- [x] Registro de ocorrências
- [x] Exclusão de ocorrências
- [x] Upload de arquivos
- [x] Exclusão de arquivos
- [x] Exclusão de Workstations
- [x] Confirmação de exclusão
- [x] Funcionamento no Windows
- [x] Funcionamento no Android
- [x] Identidade visual personalizada
- [x] Logo personalizada
- [x] Ícones personalizados

---

## 🔮 Possíveis melhorias futuras

- [ ] Relatórios de testes
- [ ] Exportação de dados
- [ ] Histórico avançado
- [ ] Notificações
- [ ] Monitoramento adicional de hardware
- [ ] Métricas avançadas de benchmark
- [ ] Sistema de permissões por usuário
- [ ] Melhorias adicionais na interface
- [ ] Distribuição oficial para Android
- [ ] Instalador para Windows

---

## 🎯 Objetivo profissional

O BenchTrack também funciona como um projeto prático para aplicação de conhecimentos de Engenharia de Software.

O projeto envolve construção de interfaces, banco de dados, autenticação, armazenamento em nuvem e desenvolvimento multiplataforma.

```text
Flutter
   +
Dart
   +
Supabase
   +
PostgreSQL
   +
Authentication
   +
Storage
   +
Git/GitHub
   +
Engenharia de Software
```

---

## 👨‍💻 Autor

**Adney Correa**

Estudante de Engenharia de Software com experiência prática em:

- Suporte técnico
- Hardware
- Montagem e diagnóstico de computadores
- Desenvolvimento de aplicações
- Automação de processos
- Flutter
- Dart
- Banco de dados
- Integração com APIs
- Inteligência Artificial e Prompt Engineering

---

## 📄 Licença

Este projeto foi desenvolvido para fins de estudo, desenvolvimento e demonstração de conhecimentos em Engenharia de Software.

Consulte os termos definidos pelo autor antes de utilizar, modificar ou redistribuir o código comercialmente.

---

## ⭐ BenchTrack

**Organizando Workstations. Simplificando testes.**

```text
🖥️ Cadastro
      ↓
🔧 Montagem
      ↓
🧪 48h de estabilidade
      ↓
✅ Aprovado / ❌ Reprovado
      ↓
📁 Finalizados
```

⭐ Se você gostou do projeto, considere deixar uma estrela no repositório!
