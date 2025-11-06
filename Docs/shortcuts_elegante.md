# Leitura Elegante de Atalhos de Teclado via Accessibility API (Estilo Raycast)

Este documento descreve como implementar uma coleta de atalhos de teclado de apps no macOS
de forma **silenciosa, sem abrir menus visualmente**, usando apenas a API de Acessibilidade
(`AXUIElementCopyAttributeValue`), com cache e fallback seguro.

---

## Objetivo

Extrair atalhos de menu de qualquer aplicativo que possua barra de menus,
sem:

- Simular cliques (sem `AXPress`)
- Piscar menus na tela
- Fazer varreduras lentas repetidas

---

## Arquitetura Geral

1. Obter a lista de aplicativos ativos.
2. Para cada app:
   - Obter referência de `AXMenuBar`.
   - Percorrer recursivamente os menus (somente leitura).
   - Extrair título + atalho (char + modificadores).
3. Salvar resultado em **cache**.
4. Atualizar apenas quando:
   - o app abrir/fechar
   - o menu mudar (usando observers AX ou timers leves)

---

## Dependências Necessárias

```swift
import Cocoa
import ApplicationServices
```

---

## Código Base

### 1. Função utilitária para ler atributos AX com tipo seguro

```swift
func axAttribute<T>(_ element: AXUIElement, _ attribute: CFString) -> T? {
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(element, attribute, &value)
    guard result == .success else { return nil }
    return value as? T
}
```

---

### 2. Obter a barra de menu de um app

```swift
func menuBar(for app: NSRunningApplication) -> AXUIElement? {
    let appElement = AXUIElementCreateApplication(app.processIdentifier)
    return axAttribute(appElement, kAXMenuBarAttribute)
}
```

---

### 3. Varredura Recursiva Elegante (sem `AXPress`)

```swift
struct MenuShortcut {
    let title: String
    let command: String?      // ex: "C"
    let modifiers: [String]   // ex: ["⌘", "⇧"]
}

func collectMenuItems(from element: AXUIElement) -> [MenuShortcut] {
    var shortcuts: [MenuShortcut] = []

    guard let items: [AXUIElement] = axAttribute(element, kAXChildrenAttribute as CFString) else {
        return []
    }

    for item in items {
        let title: String = axAttribute(item, kAXTitleAttribute as CFString) ?? ""
        let cmdChar: String? = axAttribute(item, kAXMenuItemCmdCharAttribute as CFString)
        let modifierFlags: Int? = axAttribute(item, kAXMenuItemCmdModifiersAttribute as CFString)

        let modifiers = modifierFlags.map { flagsToSymbols($0) } ?? []

        if let cmdChar = cmdChar, !cmdChar.isEmpty {
            shortcuts.append(MenuShortcut(title: title, command: cmdChar, modifiers: modifiers))
        }

        // Recursão em submenus, sem abrir nada
        if let submenu: AXUIElement = axAttribute(item, kAXMenuItemSubmenuAttribute as CFString) {
            shortcuts.append(contentsOf: collectMenuItems(from: submenu))
        }
    }

    return shortcuts
}
```

---

### 4. Conversão de modificadores para símbolos amigáveis

```swift
func flagsToSymbols(_ flags: Int) -> [String] {
    var result: [String] = []
    if flags & 0x18 != 0 { result.append("⌘") } // command
    if flags & 0x02 != 0 { result.append("⌥") } // option
    if flags & 0x04 != 0 { result.append("⌃") } // control
    if flags & 0x01 != 0 { result.append("⇧") } // shift
    return result
}
```

---

### 5. Cache Inteligente (simples)

```swift
var shortcutsCache: [pid_t: [MenuShortcut]] = [:]

func shortcuts(for app: NSRunningApplication) -> [MenuShortcut] {
    if let cached = shortcutsCache[app.processIdentifier] {
        return cached
    }

    guard let bar = menuBar(for: app) else { return [] }
    let collected = collectMenuItems(from: bar)
    shortcutsCache[app.processIdentifier] = collected
    return collected
}
```

---

## Como Atualizar o Cache Sem Travar

```swift
NotificationCenter.default.addObserver(
    forName: NSWorkspace.didActivateApplicationNotification,
    object: nil,
    queue: .main
) { _ in shortcutsCache.removeAll() }
```

---

## Conclusão

Esta abordagem:

- **Não abre menus**
- **Não pisca UI**
- **Lê todos os atalhos**
- **Funciona com SwiftUI ou AppKit**
- **É o mesmo método de apps como Raycast, Alfred e KeyClu**
