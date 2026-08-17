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

## ⚙️ Requisitos

Para executar o projeto localmente:

- Flutter
- Dart
- Android Studio para desenvolvimento Android
- Visual Studio com desenvolvimento Desktop em C++ para Windows
- Projeto configurado no Supabase
- Git

Verifique o ambiente:

```bash
flutter doctor
```

---

## 🚀 Instalação

Clone o repositório:

```bash
git clone https://github.com/SEU-USUARIO/benchtrack.git
```

Entre no diretório:

```bash
cd benchtrack
```

Instale as dependências:

```bash
flutter pub get
```

---

## 🔑 Configuração do Supabase

Configure as credenciais do seu projeto Supabase conforme a estrutura existente em:

```text
lib/services/supabase_config.dart
```

> ⚠️ **Nunca publique senhas, tokens privados ou credenciais administrativas no GitHub.**

Configure também corretamente as políticas de segurança (RLS) e permissões do Storage.

---

## ▶️ Executando

### Windows

```bash
flutter devices
flutter run -d windows
```

### Android

Conecte um dispositivo ou inicialize um emulador:

```bash
flutter devices
flutter run
```

---

## 🧹 Limpeza

Caso seja necessário reconstruir o projeto:

```bash
flutter clean
flutter pub get
```

Depois execute novamente:

```bash
flutter run -d windows
```

ou:

```bash
flutter run
```

---

## 📦 Build

### Windows

```bash
flutter build windows
```

### Android APK

```bash
flutter build apk
```

O APK será gerado em:

```text
build/app/outputs/flutter-apk/
```

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
