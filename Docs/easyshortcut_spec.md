# Objetivo
Criar um aplicativo leve que fica na **menu bar do macOS**, exibindo **todos os atalhos de teclado** disponíveis no aplicativo atualmente ativo. O foco é ser **rápido**, **nativo**, **limpo** e com **UI contemporânea (SwiftUI)**.

---

## Recursos / Funcionalidades

### 1. Ícone na Menu Bar
- O app deve residir como um pequeno ícone na barra de menu superior.
- Clicar no ícone **abre um popover** com a interface.
- O popover deve fechar automaticamente quando o usuário clicar fora.

### 2. Detecção do Aplicativo Ativo
- Detectar constantemente **qual app está focado**.
- Atualizar automaticamente a lista de atalhos ao focar outro app.

### 3. Leitura dos Atalhos de Teclado
- Obter a estrutura de menus do app ativo.
- Para cada item de menu, extrair:
  - Nome do comando
  - Combinação de teclas (`⌘`, `⌥`, `⌃`, `⇧` etc.)
  - Hierarquia (ex.: File → New → ...)

### 4. Interface Moderna e Nativa
- UI feita em **SwiftUI**.
- Modo claro / escuro automático.
- Campo de busca para filtrar atalhos.
- Layout minimalista, sem poluição visual.

### 5. Permissões do Sistema
- Solicitar permissão de **Acessibilidade** para ler estrutura dos menus.
- Detectar e mostrar aviso amigável se a permissão não estiver concedida.

---

## Stack Técnica

| Parte | Framework / Tecnologia | Motivo |
|------|------------------------|--------|
| Ícone na menu bar | **AppKit → NSStatusItem** | Menu bar é baseado em AppKit, não SwiftUI |
| Janela Popover | **NSPopover** | Comportamento nativo de popover |
| UI geral | **SwiftUI** | Interface moderna, simples e reativa |
| Leitura dos atalhos | **AXUIElement (Accessibility API)** | Permite inspecionar menus de outros apps |
| Detecção do app ativo | **NSWorkspace.shared.notificationCenter** | Recebe eventos quando o foco muda |
| Mapeamento da estrutura de menus | **AXMenuBar / AXMenuBarItem** | Percorre árvore dos menus |
| Build / Setup | **Xcode** | Necessário para assinar, rodar e empacotar o app |

---

## APIs Detalhadas

### NSStatusItem (Menu Bar)
```swift
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button?.image = NSImage(named: "StatusIcon")
```

### NSPopover (Mini-Janelinha)
```swift
let popover = NSPopover()
popover.behavior = .transient
popover.contentViewController = NSHostingController(rootView: ContentView())
```

### SwiftUI (Interface)
```swift
struct ContentView: View {
    @State var searchQuery = ""
    @State var shortcuts: [ShortcutItem] = []

    var body: some View {
        VStack {
            TextField("Buscar atalho...", text: $searchQuery)
            List(filteredShortcuts) { item in
                ShortcutRow(item)
            }
        }
        .padding(12)
    }
}
```

### AXAccessibility (Leitura dos menus)
```swift
let systemWideElement = AXUIElementCreateSystemWide()
AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBar)
```

### NSWorkspace (Detectar app ativo)
```swift
NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { notification in
    // Atualizar atalhos aqui
}
```

---

## Permissões Necessárias

Para ler menus de outros aplicativos, é preciso **Acessibilidade**:

**Sistema → Privacidade e Segurança → Acessibilidade → Adicionar o app**

O app deve estar compilado e movido para `/Applications` antes de pedir permissão.

---

## Ferramentas de Desenvolvimento

| Ferramenta | Necessária? | Observação |
|-----------|-------------|------------|
| **Xcode** | ✅ **Sim** | Você precisa dele para compilar, assinar, debugar e gerenciar entitlements |
| VSCode | ✅ Opcional | Você pode editar código Swift nele, mas **não consegue rodar/assinar o app fácil** |
| Swift Package Manager | ✅ Incluso no Swift | Para modularizar e testar partes do código sem UI |

### Resumo Direto:
- **Você pode editar no VSCode** se quiser
- **Mas você vai precisar do Xcode para rodar e empacotar o app**
- O app é macOS-only, então Xcode é **inevitável**

---

## Estrutura Recomendada de Projeto

```
ProjectRoot/
  Sources/
    Views/
    Models/
    Services/
      AccessibilityReader.swift
      AppWatcher.swift
  Assets/
  StatusBarController.swift
  AppDelegate.swift
  ContentView.swift
```

---

## Próximos Passos
1. Criar projeto `macOS App` no Xcode (AppKit + SwiftUI).
2. Adicionar `NSStatusItem` e `NSPopover`.
3. Criar serviço que detecta app ativo.
4. Criar leitor de menus via `AXUIElement`.
5. Conectar tudo e montar UI bonitinha.
```
