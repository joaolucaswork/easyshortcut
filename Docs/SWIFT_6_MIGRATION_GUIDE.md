# 🚀 Guia Completo de Migração: Swift 5.0 → Swift 6.2
## easyshortcut - Menu Bar Application

**Data de Criação:** 6 de Novembro de 2025  
**Versão Atual:** Swift 5.0 + Xcode 15.0 + macOS 13.0 SDK  
**Versão Alvo:** Swift 6.2.1 + Xcode 16.2 + macOS 15.0 SDK  
**Tempo Estimado:** 8-14 horas (1-2 dias)  
**Complexidade:** 🟡 Baixa a Moderada

---

## 📋 Índice

1. [Visão Geral da Migração](#1-visão-geral-da-migração)
2. [Pré-requisitos e Preparação](#2-pré-requisitos-e-preparação)
3. [Análise do Código Atual](#3-análise-do-código-atual)
4. [Mudanças Necessárias por Arquivo](#4-mudanças-necessárias-por-arquivo)
5. [Guia Passo a Passo](#5-guia-passo-a-passo)
6. [Checklist de Migração](#6-checklist-de-migração)
7. [Troubleshooting](#7-troubleshooting)
8. [Recursos e Referências](#8-recursos-e-referências)

---

## 1. Visão Geral da Migração

### 1.1 Estado Atual vs. Estado Alvo

| Componente | Atual | Alvo | Gap |
|------------|-------|------|-----|
| **Swift** | 5.0 (Mar 2019) | 6.2.1 (Nov 2025) | 6+ anos |
| **Xcode** | 15.0 (Set 2023) | 16.2 (Nov 2025) | 1+ ano |
| **macOS SDK** | 13.0 Ventura | 15.0 Sequoia | 2 versões |
| **Deployment Target** | macOS 13.0 | macOS 14.0 (recomendado) | 1 versão |
| **Xcode Tools Version** | 15.0 | 16.2 | - |

### 1.2 Por Que Migrar?

#### ✅ Benefícios Imediatos
- **Segurança de Dados:** Eliminação de data races em tempo de compilação
- **App Store Compliance:** Desde Abril 2025, requer Xcode 16+ para submissões
- **Performance:** Compilação mais rápida e runtime otimizado
- **Ferramentas:** Autocomplete preditivo, melhores diagnósticos

#### ✅ Benefícios de Longo Prazo
- **Manutenibilidade:** Código moderno, mais fácil de contratar desenvolvedores
- **Segurança:** Patches de segurança mais recentes
- **Compatibilidade:** Trabalhar com bibliotecas modernas
- **Future-proof:** Preparado para próximas versões do Swift

### 1.3 Avaliação de Risco

**Nível de Risco:** 🟢 **BAIXO**

**Por quê?**
- ✅ Código já usa padrões modernos (`@MainActor`, `async/await`)
- ✅ Sem dependências de terceiros
- ✅ Codebase pequeno (~700 linhas)
- ✅ Tipos de valor (structs) já são Sendable
- ✅ Arquitetura limpa e bem isolada

**Riscos Potenciais:**
- ⚠️ APIs de Acessibilidade podem precisar de verificação de thread safety
- ⚠️ Notificações NSWorkspace precisam de isolamento correto
- ⚠️ Mistura de Combine + Concurrency pode precisar revisão

---

## 2. Pré-requisitos e Preparação

### 2.1 Requisitos de Sistema

#### Hardware Mínimo
- **Mac:** Apple Silicon ou Intel (recomendado: Apple Silicon para melhor performance)
- **RAM:** 8GB mínimo, 16GB recomendado
- **Espaço em Disco:** 50GB livres (para Xcode 16 + SDKs)

#### Software Necessário
- **macOS:** 14.5 Sonoma ou superior (recomendado: 15.0 Sequoia)
- **Xcode:** 16.2 ou superior
- **Command Line Tools:** Versão correspondente ao Xcode

### 2.2 Verificar Ambiente Atual

#### Passo 1: Documentar Estado Atual
```bash
# Documentar versões atuais antes da migração
cd /Users/lucas/Documents/GitHub/easyshortcut
xcodebuild -version > migration_baseline.txt
swift --version >> migration_baseline.txt
git log --oneline -5 >> migration_baseline.txt
```

#### Passo 3: Instalar Ferramentas

**Atualizar Xcode:**
1. Abrir App Store
2. Buscar "Xcode"
3. Instalar Xcode 16.2 (ou versão mais recente)
4. Aguardar download completo (~15GB)

**Ou via linha de comando:**
```bash
# Verificar versão atual
xcodebuild -version

# Após instalar Xcode 16.2, selecionar como padrão
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Instalar Command Line Tools
xcode-select --install

# Verificar instalação
xcodebuild -version
# Deve mostrar: Xcode 16.2 ou superior
```

#### Passo 4: Verificar Ambiente
```bash
# Verificar Swift version
swift --version
# Deve mostrar: Swift version 6.2.x

# Verificar SDKs disponíveis
xcodebuild -showsdks | grep macos
# Deve incluir: macOS 15.0 ou superior

# Verificar espaço em disco
df -h
# Deve ter pelo menos 50GB livres
```

---

## 3. Análise do Código Atual

### 3.1 Arquivos do Projeto

```
easyshortcut/
├── Sources/
│   ├── AppDelegate.swift              # ✅ Pronto para Swift 6
│   ├── StatusBarController.swift      # ✅ Pronto para Swift 6
│   ├── Models/
│   │   └── ShortcutItem.swift        # ✅ Struct - Auto Sendable
│   ├── Services/
│   │   ├── AccessibilityReader.swift # ⚠️ Precisa revisão
│   │   └── AppWatcher.swift          # ⚠️ Precisa revisão
│   └── Views/
│       └── ContentView.swift         # ✅ Pronto para Swift 6
├── Assets.xcassets/
├── Info.plist
├── easyshortcut.entitlements
└── easyshortcut.xcodeproj/
```

### 3.2 Análise de Concorrência Atual

#### ✅ Padrões Modernos Já Implementados

**1. Uso de @MainActor**
```swift
// AccessibilityReader.swift (Linha 14)
@MainActor
final class AccessibilityReader: ObservableObject {
    // ✅ Correto: Classe isolada no main thread
}

// AppWatcher.swift (Linha 27)
@MainActor
final class AppWatcher: ObservableObject {
    // ✅ Correto: Classe isolada no main thread
}
```

**2. Uso de async/await**
```swift
// AccessibilityReader.swift (Linha 126)
private func readMenus(for app: NSRunningApplication) async {
    // ✅ Correto: Função assíncrona
}
```

**3. Uso de Task com isolamento**
```swift
// AccessibilityReader.swift (Linha 59)
Task { @MainActor in
    self?.readMenusForActiveApp()
}
// ✅ Correto: Task explicitamente isolado
```

**4. Structs como Value Types**
```swift
// ShortcutItem.swift (Linha 4)
struct ShortcutItem: Identifiable, Equatable, Hashable {
    // ✅ Correto: Struct é automaticamente Sendable
}

// AppWatcher.swift (Linha 14)
struct ActiveAppInfo {
    // ✅ Correto: Struct é automaticamente Sendable
}
```

#### ⚠️ Áreas que Precisam Atenção

**1. Combine + Concurrency**
```swift
// AccessibilityReader.swift (Linhas 56-63)
private func setupAppWatcher() {
    appWatcherCancellable = AppWatcher.shared.$activeAppInfo
        .sink { [weak self] _ in
            Task { @MainActor in
                self?.readMenusForActiveApp()
            }
        }
}
```
**Análise:** Este padrão está correto, mas Swift 6 pode exigir verificações adicionais.

**2. Acesso a APIs de Acessibilidade**
```swift
// AccessibilityReader.swift (Linha 134)
guard let menuBar: AXUIElement = copyAXAttribute(appElement, kAXMenuBarAttribute as CFString) else {
    // ⚠️ Verificar: APIs C podem precisar de isolamento explícito
}
```

**3. NSWorkspace Notifications**
```swift
// AppWatcher.swift (Linhas 89-95)
observer = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main  // ✅ Correto: Especifica main queue
) { [weak self] notification in
    self?.handleApplicationActivation(notification)
}
```

### 3.3 Inventário de Tipos

| Tipo | Arquivo | Sendable? | Isolamento | Status |
|------|---------|-----------|------------|--------|
| `ShortcutItem` | ShortcutItem.swift | ✅ Auto | Nenhum | ✅ OK |
| `ActiveAppInfo` | AppWatcher.swift | ✅ Auto | Nenhum | ✅ OK |
| `AccessibilityReader` | AccessibilityReader.swift | ❌ Classe | @MainActor | ⚠️ Revisar |
| `AppWatcher` | AppWatcher.swift | ❌ Classe | @MainActor | ⚠️ Revisar |
| `StatusBarController` | StatusBarController.swift | ❌ Classe | Nenhum | ⚠️ Revisar |
| `AppDelegate` | AppDelegate.swift | ❌ Classe | Nenhum | ⚠️ Revisar |

---

## 4. Mudanças Necessárias por Arquivo

### 4.1 AppDelegate.swift

**Status Atual:** ✅ Pronto para Swift 6 (mínimas mudanças)

**Mudanças Necessárias:**
```swift
// ANTES (Swift 5.0)
@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarController = StatusBarController()
    }
}

// DEPOIS (Swift 6.2)
@main
@MainActor  // ✅ ADICIONAR: Isolar no main thread
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBarController = StatusBarController()
    }
}
```

**Justificativa:** AppDelegate lida com UI e deve estar no main thread.

---

### 4.2 StatusBarController.swift

**Status Atual:** ⚠️ Precisa de isolamento

**Mudanças Necessárias:**
```swift
// ANTES (Swift 5.0)
class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init() {
        // ...
    }
}

// DEPOIS (Swift 6.2)
@MainActor  // ✅ ADICIONAR: Classe lida com UI
final class StatusBarController {  // ✅ ADICIONAR: final para performance
    private let statusItem: NSStatusItem
    private let popover: NSPopover

    init() {
        // ...
    }
}
```

**Justificativa:** StatusBarController gerencia NSStatusItem e NSPopover (componentes de UI).

---

### 4.3 ShortcutItem.swift

**Status Atual:** ✅ Pronto para Swift 6 (nenhuma mudança necessária)

**Análise:**
```swift
struct ShortcutItem: Identifiable, Equatable, Hashable {
    let id: UUID = UUID()
    let title: String
    let shortcut: String?
    let menuPath: [String]
    let isEnabled: Bool
    let role: String?
    let isSeparator: Bool
}
```

✅ **Struct com propriedades imutáveis** → Automaticamente Sendable
✅ **Sem referências a classes** → Thread-safe por design
✅ **Nenhuma mudança necessária**

---

### 4.4 AccessibilityReader.swift

**Status Atual:** ⚠️ Precisa de revisão cuidadosa

**Mudanças Necessárias:**

#### Mudança 1: Verificar isolamento de métodos privados
```swift
// ANTES (Swift 5.0)
private func copyAXAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, attribute, &value)
    // ...
}

// DEPOIS (Swift 6.2)
nonisolated private func copyAXAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
    // ✅ ADICIONAR: nonisolated para funções que não acessam estado mutável
    var value: CFTypeRef?
    let error = AXUIElementCopyAttributeValue(element, attribute, &value)
    // ...
}
```

#### Mudança 2: Marcar funções de leitura como async onde apropriado
```swift
// ANTES (Swift 5.0)
private func readMenusForActiveApp() {
    // ...
    Task {
        await readMenus(for: runningApp)
    }
}

// DEPOIS (Swift 6.2) - Opção 1: Manter como está
// OU Opção 2: Tornar async
private func readMenusForActiveApp() async {
    // ...
    await readMenus(for: runningApp)
}
```

#### Mudança 3: Adicionar Sendable onde necessário
```swift
// Se AccessibilityAuthorizationStatus for compartilhado entre threads
enum AccessibilityAuthorizationStatus: Sendable {  // ✅ ADICIONAR
    case notDetermined
    case denied
    case authorized
}
```

---

### 4.5 AppWatcher.swift

**Status Atual:** ⚠️ Precisa de revisão

**Mudanças Necessárias:**

#### Mudança 1: Marcar struct como Sendable explicitamente
```swift
// ANTES (Swift 5.0)
struct ActiveAppInfo {
    let name: String?
    let bundleID: String?
    let app: NSRunningApplication
}

// DEPOIS (Swift 6.2)
struct ActiveAppInfo: Sendable {  // ✅ ADICIONAR: Explícito
    let name: String?
    let bundleID: String?
    let app: NSRunningApplication  // ⚠️ NSRunningApplication deve ser Sendable
}
```

**Nota:** Verificar se `NSRunningApplication` é Sendable no SDK. Se não for, pode ser necessário ajustar.

#### Mudança 2: Verificar closure em addObserver
```swift
// ANTES (Swift 5.0)
observer = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { [weak self] notification in
    self?.handleApplicationActivation(notification)
}

// DEPOIS (Swift 6.2) - Pode precisar de @Sendable
observer = NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { [weak self] notification in  // Swift 6 pode inferir @Sendable
    self?.handleApplicationActivation(notification)
}
```

---

### 4.6 ContentView.swift

**Status Atual:** ✅ Pronto para Swift 6 (nenhuma mudança necessária)

**Análise:**
```swift
struct ContentView: View {
    @State private var searchQuery = ""
    @State private var shortcuts: [String] = []

    var body: some View {
        // SwiftUI code
    }
}
```

✅ **SwiftUI View** → Automaticamente isolado no main thread
✅ **@State** → Gerenciado pelo SwiftUI
✅ **Nenhuma mudança necessária**

---

## 5. Guia Passo a Passo

### FASE 1: Atualização de Ferramentas (1-2 horas)

#### Passo 1.1: Atualizar macOS
```bash
# Verificar versão atual
sw_vers

# Se < 14.5, atualizar via System Settings
# Preferências do Sistema → Atualização de Software
```

#### Passo 1.2: Instalar Xcode 16.2
```bash
# Opção 1: Via App Store (recomendado)
# Abrir App Store → Buscar "Xcode" → Instalar

# Opção 2: Via linha de comando (se tiver Apple Developer account)
# Baixar de developer.apple.com/download

# Após instalação, configurar
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
xcode-select --install

# Verificar
xcodebuild -version
# Esperado: Xcode 16.2 ou superior
```

#### Passo 1.3: Verificar Swift Version
```bash
swift --version
# Esperado: Swift version 6.2.x
```

---

### FASE 2: Preparação do Projeto (30 minutos)

#### Passo 2.1: Abrir Projeto no Xcode 16
```bash
cd /Users/lucas/Documents/GitHub/easyshortcut
open easyshortcut.xcodeproj
```

**Xcode pode mostrar alertas:**
- "Update to recommended settings?" → **Clicar "Perform Changes"**
- "Convert to latest Swift syntax?" → **NÃO CLICAR AINDA** (faremos manualmente)

#### Passo 2.2: Limpar Build Artifacts
```bash
# No Xcode: Product → Clean Build Folder (Cmd+Shift+K)
# Ou via terminal:
rm -rf ~/Library/Developer/Xcode/DerivedData/easyshortcut-*
```

#### Passo 2.3: Build Inicial (Swift 5.0)
```bash
# No Xcode: Product → Build (Cmd+B)
# Deve compilar sem erros (ainda em Swift 5.0)
```

---

### FASE 3: Migração Incremental (6-10 horas)

#### Passo 3.1: Habilitar Upcoming Features (2-3 horas)

**No Xcode:**
1. Selecionar projeto `easyshortcut` no Navigator
2. Selecionar target `easyshortcut`
3. Ir para **Build Settings**
4. Buscar "Upcoming Features"

**Habilitar um por vez, na ordem:**

##### Feature 1: ExistentialAny
```
Build Settings → Swift Compiler - Upcoming Features
→ Require Explicit 'any' for Existential Types = YES
```

**Build e corrigir erros:**
```bash
# No Xcode: Product → Build (Cmd+B)
# Se houver erros relacionados a protocolos, adicionar 'any':
# ANTES: var delegate: MyProtocol?
# DEPOIS: var delegate: any MyProtocol?
```

**Commit (opcional):**
```bash
git add .
git commit -m "Enable ExistentialAny upcoming feature"
```

##### Feature 2: ConciseMagicFile
```
Build Settings → Swift Compiler - Upcoming Features
→ Concise Magic File Names = YES
```

**Build:**
```bash
# Deve compilar sem erros
```

##### Feature 3: ForwardTrailingClosures
```
Build Settings → Swift Compiler - Upcoming Features
→ Forward Trailing Closures = YES
```

**Build:**
```bash
# Deve compilar sem erros
```

##### Feature 4: BareSlashRegexLiterals
```
Build Settings → Swift Compiler - Upcoming Features
→ Bare Slash Regex Literals = YES
```

**Build:**
```bash
# Deve compilar sem erros
```

---

#### Passo 3.2: Habilitar Strict Concurrency (2-4 horas)

**No Xcode:**
```
Build Settings → Swift Compiler - Concurrency
→ Strict Concurrency Checking
```

##### Nível 1: Minimal
```
Strict Concurrency Checking = Minimal
```

**Build e analisar warnings:**
```bash
# No Xcode: Product → Build (Cmd+B)
# Revisar todos os warnings no Issue Navigator
```

**Corrigir warnings comuns:**

**Warning 1: "Call to main actor-isolated method requires 'await'"**
```swift
// ANTES
self?.readMenusForActiveApp()

// DEPOIS
await self?.readMenusForActiveApp()
```

**Warning 2: "Capture of 'self' with non-sendable type"**
```swift
// ANTES
Task {
    self.doSomething()
}

// DEPOIS
Task { @MainActor in
    self.doSomething()
}
```

##### Nível 2: Targeted
```
Strict Concurrency Checking = Targeted
```

**Build e corrigir novos warnings:**
```bash
# Mais warnings aparecerão
# Focar em:
# - Adicionar @MainActor onde necessário
# - Adicionar await onde necessário
# - Marcar tipos como Sendable
```

**Exemplo de correções:**

**AppDelegate.swift:**
```swift
@main
@MainActor  // ✅ ADICIONAR
class AppDelegate: NSObject, NSApplicationDelegate {
    // ...
}
```

**StatusBarController.swift:**
```swift
@MainActor  // ✅ ADICIONAR
final class StatusBarController {  // ✅ ADICIONAR final
    // ...
}
```

##### Nível 3: Complete
```
Strict Concurrency Checking = Complete
```

**Build e corrigir todos os warnings restantes:**

**AccessibilityReader.swift - Possíveis mudanças:**
```swift
// Marcar enum como Sendable
enum AccessibilityAuthorizationStatus: Sendable {
    case notDetermined
    case denied
    case authorized
}

// Marcar métodos auxiliares como nonisolated
nonisolated private func copyAXAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
    // ...
}

nonisolated private func copyAXString(_ element: AXUIElement, _ attribute: CFString) -> String? {
    // ...
}

nonisolated private func copyAXArray(_ element: AXUIElement, _ attribute: CFString) -> [AXUIElement] {
    // ...
}
```

**AppWatcher.swift - Possíveis mudanças:**
```swift
// Marcar struct como Sendable explicitamente
struct ActiveAppInfo: Sendable {
    let name: String?
    let bundleID: String?
    let app: NSRunningApplication
}
```

---

#### Passo 3.3: Atualizar Swift Language Version (1-2 horas)

**No Xcode:**
```
Build Settings → Swift Compiler - Language
→ Swift Language Version = Swift 6
```

**Build e corrigir erros:**
```bash
# No Xcode: Product → Build (Cmd+B)
# Agora warnings se tornam ERROS
```

**Erros comuns e soluções:**

**Erro 1: "Expression is 'async' but is not marked with 'await'"**
```swift
// ANTES
Task {
    readMenusForActiveApp()
}

// DEPOIS
Task {
    await readMenusForActiveApp()
}
```

**Erro 2: "Main actor-isolated property cannot be referenced from a non-isolated context"**
```swift
// ANTES
func someFunction() {
    self.shortcuts = []  // Erro se shortcuts é @Published
}

// DEPOIS
@MainActor
func someFunction() {
    self.shortcuts = []
}
```

**Erro 3: "Type does not conform to the 'Sendable' protocol"**
```swift
// ANTES
struct MyType {
    var mutableProperty: String
}

// DEPOIS
struct MyType: Sendable {
    let immutableProperty: String  // Mudar para let
}
```

**Build até compilar sem erros:**
```bash
# Repetir: Build → Fix → Build
# Até: Build Succeeded
```

---

#### Passo 3.4: Atualizar Deployment Target (Opcional, 30 minutos)

**No Xcode:**
```
Build Settings → Deployment
→ macOS Deployment Target = 14.0
```

**Justificativa:**
- macOS 14.0 (Sonoma) lançado em Setembro 2023
- Ainda suporta Macs de 2-3 anos atrás
- Habilita APIs mais modernas

**Build e testar:**
```bash
# No Xcode: Product → Build (Cmd+B)
# Deve compilar sem erros
```

---

### FASE 4: Testes e Validação (2-4 horas)

#### Passo 4.1: Testes Funcionais

**Teste 1: Build e Run**
```bash
# No Xcode: Product → Run (Cmd+R)
# Verificar:
# ✅ App inicia sem crashes
# ✅ Ícone aparece na menu bar
# ✅ Clicar no ícone abre popover
```

**Teste 2: Permissões de Acessibilidade**
```bash
# 1. Abrir System Settings → Privacy & Security → Accessibility
# 2. Verificar se easyshortcut está na lista
# 3. Se não estiver, adicionar
# 4. Testar leitura de menus de outro app (ex: Safari)
```

**Teste 3: Troca de Aplicativos**
```bash
# 1. Abrir Safari
# 2. Clicar no ícone do easyshortcut
# 3. Verificar se mostra atalhos do Safari
# 4. Trocar para Finder
# 5. Clicar no ícone novamente
# 6. Verificar se mostra atalhos do Finder
```

**Teste 4: Busca de Atalhos**
```bash
# 1. Abrir popover
# 2. Digitar no campo de busca
# 3. Verificar se filtra atalhos corretamente
```

**Teste 5: Performance**
```bash
# 1. Abrir Activity Monitor
# 2. Buscar "easyshortcut"
# 3. Verificar uso de CPU (deve ser <5% em idle)
# 4. Verificar uso de memória (deve ser <50MB)
```

#### Passo 4.2: Testes de Concorrência

**Teste 1: Troca Rápida de Apps**
```bash
# 1. Abrir vários apps (Safari, Finder, TextEdit, etc.)
# 2. Trocar rapidamente entre eles (Cmd+Tab)
# 3. Verificar se não há crashes ou travamentos
# 4. Verificar logs no Console.app para warnings
```

**Teste 2: Stress Test**
```bash
# 1. Abrir 10+ aplicativos
# 2. Trocar entre eles rapidamente
# 3. Abrir/fechar popover repetidamente
# 4. Verificar estabilidade
```

#### Passo 4.3: Verificar Logs

**No Console.app:**
```bash
# 1. Abrir Console.app
# 2. Filtrar por "easyshortcut"
# 3. Procurar por:
#    - ❌ Erros (vermelho)
#    - ⚠️ Warnings (amarelo)
#    - 🔵 Data race warnings
```

**Logs esperados:**
```
✅ "Application did finish launching"
✅ "Status bar controller initialized"
✅ "App watcher started monitoring"
❌ NÃO deve ter: "Data race detected"
❌ NÃO deve ter: "Thread sanitizer warning"
```

#### Passo 4.4: Testes com Thread Sanitizer (Opcional)

**Habilitar Thread Sanitizer:**
```
Xcode → Product → Scheme → Edit Scheme
→ Run → Diagnostics
→ ✅ Thread Sanitizer
```

**Run e verificar:**
```bash
# No Xcode: Product → Run (Cmd+R)
# Usar o app normalmente
# Thread Sanitizer detectará data races
# Se houver, corrigir antes de prosseguir
```

---

### FASE 5: Otimização (Opcional, 2-4 horas)

#### Passo 5.1: Adotar Recursos do Swift 6.2

**Recurso 1: Typed Throws**
```swift
// ANTES
func validate(name: String) throws {
    guard !name.isEmpty else {
        throw ValidationError.emptyName
    }
}

// DEPOIS (Swift 6.2)
func validate(name: String) throws(ValidationError) {
    guard !name.isEmpty else {
        throw .emptyName  // Tipo inferido
    }
}
```

**Recurso 2: @concurrent Attribute**
```swift
// Para funções que devem rodar concorrentemente
@concurrent
func processInBackground() async {
    // Esta função roda no thread pool
}
```

**Recurso 3: Access-Level Imports**
```swift
// ANTES
import Foundation
import AppKit

// DEPOIS (Swift 6.2) - Otimização de build
internal import Foundation
private import AppKit  // Apenas para este arquivo
```

#### Passo 5.2: Performance Profiling

**Com Instruments:**
```bash
# 1. Xcode → Product → Profile (Cmd+I)
# 2. Escolher "Time Profiler"
# 3. Usar o app normalmente
# 4. Identificar hotspots
# 5. Otimizar se necessário
```

**Métricas alvo:**
- **Tempo de inicialização:** < 500ms
- **Uso de CPU (idle):** < 5%
- **Uso de memória:** < 50MB
- **Tempo de resposta (UI):** < 16ms (60 FPS)

---

## 6. Checklist de Migração

### ✅ Pré-Migração
- [x] Backup completo do projeto (git commit + tag) ✅ **JÁ FEITO**
- [x] Branch de migração criado ✅ **JÁ FEITO**
- [ ] Xcode 16.2 instalado
- [ ] macOS 14.5+ instalado
- [ ] Documentação do estado atual salva

### ✅ Fase 1: Ferramentas
- [ ] Xcode 16.2 instalado e configurado
- [ ] Swift 6.2 verificado (`swift --version`)
- [ ] Command Line Tools atualizados
- [ ] Projeto abre no Xcode 16 sem erros

### ✅ Fase 2: Upcoming Features
- [ ] ExistentialAny habilitado e testado
- [ ] ConciseMagicFile habilitado e testado
- [ ] ForwardTrailingClosures habilitado e testado
- [ ] BareSlashRegexLiterals habilitado e testado
- [ ] Todos os commits feitos

### ✅ Fase 3: Strict Concurrency
- [ ] Minimal: Habilitado, warnings corrigidos, commit
- [ ] Targeted: Habilitado, warnings corrigidos, commit
- [ ] Complete: Habilitado, warnings corrigidos, commit

### ✅ Fase 4: Swift 6
- [ ] Swift Language Version = 6
- [ ] Build sem erros
- [ ] Todos os warnings de concorrência resolvidos
- [ ] Commit final da migração

### ✅ Fase 5: Testes
- [ ] App inicia sem crashes
- [ ] Ícone da menu bar aparece
- [ ] Popover abre/fecha corretamente
- [ ] Leitura de menus funciona
- [ ] Troca de apps funciona
- [ ] Busca funciona
- [ ] Performance aceitável
- [ ] Sem data races (Thread Sanitizer)
- [ ] Logs limpos (sem erros/warnings)

### ✅ Pós-Migração
- [ ] Deployment target atualizado (opcional)
- [ ] Recursos Swift 6.2 adotados (opcional)
- [ ] Performance otimizada (opcional)
- [ ] Documentação atualizada
- [ ] README.md atualizado com nova versão
- [ ] Commit final da migração
- [ ] Push para repositório remoto

---

## 7. Troubleshooting

### Problema 1: "Call to main actor-isolated method requires 'await'"

**Erro:**
```
error: call to main actor-isolated instance method 'readMenusForActiveApp()'
in a synchronous nonisolated context
```

**Solução:**
```swift
// Opção 1: Adicionar await
await self.readMenusForActiveApp()

// Opção 2: Usar Task
Task { @MainActor in
    self.readMenusForActiveApp()
}

// Opção 3: Marcar função como @MainActor
@MainActor
func callerFunction() {
    self.readMenusForActiveApp()  // OK, ambos no MainActor
}
```

---

### Problema 2: "Type does not conform to 'Sendable'"

**Erro:**
```
error: type 'MyClass' does not conform to the 'Sendable' protocol
```

**Solução:**

**Para structs:**
```swift
// Adicionar conformance explícita
struct MyStruct: Sendable {
    let property: String  // Deve ser imutável (let)
}
```

**Para classes:**
```swift
// Opção 1: Usar @MainActor (se for UI)
@MainActor
final class MyClass {
    var property: String
}

// Opção 2: Usar @unchecked Sendable (cuidado!)
final class MyClass: @unchecked Sendable {
    private let lock = NSLock()
    private var _property: String

    var property: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _property
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _property = newValue
        }
    }
}
```

---

### Problema 3: "Capture of 'self' with non-sendable type"

**Erro:**
```
warning: capture of 'self' with non-sendable type 'MyClass' in a
@Sendable closure
```

**Solução:**
```swift
// ANTES
Task {
    self.doSomething()
}

// DEPOIS - Opção 1: Marcar classe como @MainActor
@MainActor
class MyClass {
    func doSomething() { }
}

Task { @MainActor in
    self.doSomething()
}

// DEPOIS - Opção 2: Usar weak self
Task { [weak self] in
    await self?.doSomething()
}
```

---

### Problema 4: NSRunningApplication não é Sendable

**Erro:**
```
error: stored property 'app' of 'Sendable'-conforming struct 'ActiveAppInfo'
has non-sendable type 'NSRunningApplication'
```

**Solução:**
```swift
// Opção 1: Remover Sendable do struct (se possível)
struct ActiveAppInfo {  // Sem : Sendable
    let name: String?
    let bundleID: String?
    let app: NSRunningApplication
}

// Opção 2: Armazenar apenas dados Sendable
struct ActiveAppInfo: Sendable {
    let name: String?
    let bundleID: String?
    let processIdentifier: pid_t  // Em vez de NSRunningApplication
}

// Opção 3: Usar @unchecked Sendable (último recurso)
struct ActiveAppInfo: @unchecked Sendable {
    let name: String?
    let bundleID: String?
    let app: NSRunningApplication
}
```

---

### Problema 5: Build muito lento após migração

**Sintomas:**
- Build demora 5+ minutos
- Xcode trava durante compilação

**Soluções:**
```bash
# 1. Limpar DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Limpar build folder no Xcode
# Product → Clean Build Folder (Cmd+Shift+K)

# 3. Reiniciar Xcode

# 4. Verificar Build Settings
# Build Settings → Build Options
# → Compilation Mode = Incremental (não Whole Module em Debug)

# 5. Desabilitar Index-While-Building temporariamente
# Xcode → Settings → General
# → ❌ Enable Index-While-Building Functionality
```

---

### Problema 6: Thread Sanitizer detecta data race

**Erro no Console:**
```
WARNING: ThreadSanitizer: data race
  Write of size 8 at 0x... by thread T1
  Previous read of size 8 at 0x... by thread T2
```

**Solução:**
```swift
// Identificar a variável problemática
// Exemplo: var shortcuts: [ShortcutItem] = []

// Opção 1: Isolar no MainActor
@MainActor
class MyClass {
    var shortcuts: [ShortcutItem] = []  // Agora protegido
}

// Opção 2: Usar actor
actor MyActor {
    var shortcuts: [ShortcutItem] = []

    func addShortcut(_ item: ShortcutItem) {
        shortcuts.append(item)
    }
}

// Opção 3: Usar lock manual (último recurso)
final class MyClass {
    private let lock = NSLock()
    private var _shortcuts: [ShortcutItem] = []

    var shortcuts: [ShortcutItem] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _shortcuts
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _shortcuts = newValue
        }
    }
}
```

---

### Problema 7: Xcode não mostra Swift 6 nas opções

**Sintomas:**
- Swift Language Version só mostra até 5.x
- Não aparece opção "Swift 6"

**Solução:**
```bash
# 1. Verificar versão do Xcode
xcodebuild -version
# Deve ser 16.0 ou superior

# 2. Verificar Swift version
swift --version
# Deve ser 6.x

# 3. Se ainda não aparecer, limpar cache
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode

# 4. Reiniciar Xcode

# 5. Reabrir projeto
open easyshortcut.xcodeproj
```

---

## 8. Recursos e Referências

### 📚 Documentação Oficial

#### Swift.org
- **Guia de Migração Swift 6:** https://swift.org/migration/documentation/migrationguide/
- **Swift 6.2 Release Notes:** https://swift.org/blog/swift-6.2-released/
- **Swift Evolution Proposals:** https://www.swift.org/swift-evolution/

#### Apple Developer
- **Xcode 16 Release Notes:** https://developer.apple.com/documentation/xcode-release-notes/xcode-16-release-notes
- **Swift Concurrency:** https://developer.apple.com/documentation/swift/concurrency
- **Sendable Protocol:** https://developer.apple.com/documentation/swift/sendable

### 📖 Artigos e Tutoriais

#### SwiftLee (Antoine van der Lee)
- **Swift 6 Migration Guide:** https://www.avanderlee.com/concurrency/swift-6-migrating-xcode-projects-packages/
- **Strict Concurrency Checking:** https://www.avanderlee.com/swift/sendable-protocol-closures/
- **Swift 6.2 Changes:** https://www.avanderlee.com/concurrency/swift-6-2-concurrency-changes/

#### Hacking with Swift (Paul Hudson)
- **What's New in Swift 6.2:** https://www.hackingwithswift.com/articles/277/whats-new-in-swift-6-2
- **Swift Concurrency by Example:** https://www.hackingwithswift.com/quick-start/concurrency

#### Kodeco (Ray Wenderlich)
- **Migrating to Swift 6 Tutorial:** https://www.kodeco.com/48297451-migrating-to-swift-6-tutorial

### 🎥 Vídeos WWDC

- **WWDC 2024: What's new in Swift:** https://developer.apple.com/videos/play/wwdc2024/10136/
- **WWDC 2024: Migrate your app to Swift 6:** https://developer.apple.com/videos/play/wwdc2024/10169/
- **WWDC 2025: Embracing Swift concurrency:** https://developer.apple.com/videos/play/wwdc2025/268/

### 🛠️ Ferramentas

#### Xcode
- **Download:** https://developer.apple.com/xcode/
- **Release Notes:** https://developer.apple.com/documentation/xcode-release-notes

#### Swift Toolchain
- **Download:** https://swift.org/download/
- **Snapshots:** https://swift.org/download/#snapshots

### 💬 Comunidade

#### Fóruns
- **Swift Forums:** https://forums.swift.org/
- **Apple Developer Forums:** https://developer.apple.com/forums/

#### Stack Overflow
- **Tag: swift6:** https://stackoverflow.com/questions/tagged/swift6
- **Tag: swift-concurrency:** https://stackoverflow.com/questions/tagged/swift-concurrency

---

## 📝 Notas Finais

### Dicas de Sucesso

1. **Vá Devagar:** Migre incrementalmente, não tudo de uma vez
2. **Commit Frequente:** Faça commits após cada mudança bem-sucedida
3. **Teste Sempre:** Teste após cada fase da migração
4. **Leia os Erros:** Mensagens de erro do Swift 6 são muito descritivas
5. **Use Thread Sanitizer:** Detecta data races que você pode não ver
6. **Peça Ajuda:** Comunidade Swift é muito ativa e prestativa

### Quando Pedir Ajuda

Se você encontrar:
- ❌ Erros que não entende após 30 minutos
- ❌ Data races que não consegue resolver
- ❌ Performance degradada significativamente
- ❌ Crashes inexplicáveis

**Onde pedir ajuda:**
1. Swift Forums: https://forums.swift.org/
2. Stack Overflow: https://stackoverflow.com/questions/tagged/swift6
3. Apple Developer Forums: https://developer.apple.com/forums/

### Próximos Passos Após Migração

1. **Atualizar README.md** com nova versão do Swift
2. **Criar Release Notes** documentando mudanças
3. **Considerar CI/CD** para builds automatizados
4. **Explorar Swift 6.2 Features** para melhorar código
5. **Monitorar Performance** em produção

---

## ✅ Conclusão

Você agora tem um guia completo para migrar seu projeto de Swift 5.0 para Swift 6.2!

**Lembre-se:**
- ✅ Seu código já está bem estruturado
- ✅ A migração é mais fácil do que parece
- ✅ Swift 6 tornará seu app mais seguro e confiável
- ✅ A comunidade está aqui para ajudar

**Boa sorte com a migração! 🚀**

---

**Última Atualização:** 6 de Novembro de 2025
**Versão do Guia:** 1.0
**Autor:** Augment AI Agent

