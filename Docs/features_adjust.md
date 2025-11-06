# Guia de Implementação Elegante para Leitura de Atalhos de Teclado no macOS

Este documento descreve uma forma mais estável, previsível e “nativa” de coletar atalhos de teclado de aplicativos no macOS, sem precisar **simular cliques** ou expandir menus usando `AXPress`.

## Problema da Implementação Atual

A implementação atual usa ações do tipo:

```swift
AXPress
click
```

Essas chamadas simulam **a expansão real do menu**, como se o usuário estivesse clicando nele.  
Isso traz alguns problemas:

- O menu **pisca ou realmente abre** na interface.
- Dependência de tempo (delay entre expansões).
- Pode falhar se o aplicativo estiver em estado inesperado.
- Interfere com o usuário caso ele esteja usando o Mac no momento.

Essa abordagem funciona, mas é **frágil** e pode quebrar facilmente.

---

## Abordagem Mais Elegante

A ideia é **nunca pressionar** ou expandir menus visualmente.  
Ao invés disso, usa-se apenas **leitura estrutural da Árvore de Acessibilidade** (`AXUIElement`).

### Ponto central

Use esta API para **apenas ler atributos**, nunca `AXPress`:

```swift
AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, &children)
```

Você pode percorrer o menu recursivamente e encontrar:

- `kAXMenuBarAttribute` para o menu raiz
- `kAXMenuItemCmdChar` para a tecla
- `kAXMenuItemCmdModifiers` para ⌘, ⇧, ⌥, ^, etc.

### Exemplo de Sequência (conceitual)

```swift
let app = AXUIElementCreateApplication(pid)
AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute, &menuBar)

func parseMenu(_ element) {
    AXUIElementCopyAttributeValue(element, kAXChildrenAttribute, &children)
    for child in children {
        // Obter título
        // Obter keyEquivalent (kAXMenuItemCmdChar)
        // Obter modificadores (kAXMenuItemCmdModifiers)
        // Se tiver submenu -> parseMenu(submenu)
    }
}
```

### Sem `AXPress`, sem piscar menu, sem race conditions.

---

## Extra: Quando o App Não Expõe Menus via AX

Alguns apps (ex: Electron + menus customizados) podem não expor atalhos corretamente.

Nestes casos:

1. **Verifique AppleScript (ScriptingBridge)**  
   Alguns apps expõem menus via AppleScript mesmo quando não expõem via AX.

2. **fallback:** ler diretamente `~/Library/Preferences/com.seu.app.plist`  
   muitos apps guardam atalhos lá.

---

## Mapeando os Modificadores

Traduza `kAXMenuItemCmdModifiers` usando máscara de bits:

| Máscara | Símbolo | Tecla |
|--------|---------|------|
| `cmd`  | ⌘       | Command |
| `shift`| ⇧       | Shift |
| `alt`  | ⌥       | Option |
| `ctrl` | ⌃       | Control |

Monte a string final assim:

```
⌘ ⇧ K
⌥ ⌘ F
⌃ ⌘ S
```

---

## Por Que Isso é Melhor?

| Critério | Pressionar Menus | Apenas Ler Atributos |
|--------|------------------|----------------------|
| Estável | ❌ Não            | ✅ Sim |
| Invisível ao usuário | ❌ Não | ✅ Sim |
| Sem delays | ❌ Não | ✅ Sim |
| Fácil manter | ❌ Não | ✅ Sim |

---

## Resumo

- Simular clique no menu funciona, mas é gambiarra.
- A abordagem elegante é **somente ler a árvore AX**.
- Use `kAXMenuItemCmdChar` e `kAXMenuItemCmdModifiers` para montar atalhos.

---

Pronto. Esta é a base do método usado por apps como **Raycast**, **Alfred** e **BetterTouchTool**, e é a abordagem mais confiável e nativa disponível no macOS.
