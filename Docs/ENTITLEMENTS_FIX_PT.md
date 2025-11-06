# Correção de Permissões - App não aparece na lista de Acessibilidade

## 🐛 Problema Identificado

O app estava dizendo que as permissões não foram concedidas, mas **não aparecia automaticamente** na lista de Acessibilidade em Configurações do Sistema.

## 🔍 Causa Raiz

O arquivo `easyshortcut.entitlements` estava **vazio**, fazendo com que o Xcode adicionasse automaticamente:
- `com.apple.security.app-sandbox = YES` (Sandbox ATIVADO)

**Problema**: A API de Acessibilidade do macOS **NÃO funciona** com o App Sandbox ativado, pois ela precisa acessar elementos de UI de outros aplicativos, o que é bloqueado pelo sandbox.

## ✅ Solução Implementada

### 1. Configuração do `easyshortcut.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- App Sandbox DESATIVADO (necessário para Accessibility API) -->
	<key>com.apple.security.app-sandbox</key>
	<false/>
	
	<!-- Hardened Runtime ativado para segurança -->
	<key>com.apple.security.cs.allow-jit</key>
	<false/>
	<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
	<false/>
	<key>com.apple.security.cs.allow-dyld-environment-variables</key>
	<false/>
	<key>com.apple.security.cs.disable-library-validation</key>
	<false/>
	<key>com.apple.security.cs.disable-executable-page-protection</key>
	<false/>
</dict>
</plist>
```

### 2. Configuração do Projeto Xcode

Alterado em `easyshortcut.xcodeproj/project.pbxproj`:
- **Debug**: `ENABLE_APP_SANDBOX = NO`
- **Release**: `ENABLE_APP_SANDBOX = NO`

### 3. Entitlements Finais Verificados

```
✅ com.apple.security.app-sandbox = false
✅ com.apple.security.automation.apple-events = true (adicionado automaticamente)
✅ Hardened Runtime configurado corretamente
```

## 🧪 Como Testar

### Passo 1: Clean Build
```bash
cd /Users/lucas/Documents/GitHub/easyshortcut
xcodebuild -project easyshortcut.xcodeproj -scheme easyshortcut -configuration Debug clean build
```

### Passo 2: Executar o App

**Opção A - Via Xcode:**
1. Abra o projeto no Xcode
2. Pressione `Cmd+R` para executar
3. O app deve aparecer na barra de menu (ícone de teclado)

**Opção B - Via Terminal:**
```bash
open /Users/lucas/Library/Developer/Xcode/DerivedData/easyshortcut-*/Build/Products/Debug/easyshortcut.app
```

### Passo 3: Verificar Permissões

1. **Primeira execução**: O macOS deve mostrar um diálogo pedindo permissão de Acessibilidade
2. Clique em "Abrir Preferências do Sistema" (ou similar)
3. **IMPORTANTE**: O app "easyshortcut" deve aparecer AUTOMATICAMENTE na lista
4. Marque a caixa ao lado de "easyshortcut" para conceder permissão
5. Pode ser necessário reiniciar o app

### Passo 4: Verificar Funcionamento

1. Com as permissões concedidas, abra o app
2. Clique no ícone de teclado na barra de menu
3. **Esperado**: Deve mostrar os atalhos do app ativo (ex: Xcode, Safari, Finder)
4. Troque de app e verifique se os atalhos atualizam automaticamente

## 📊 Logs de Debug

Abra o Console.app e filtre por "easyshortcut" para ver:

```
✅ PermissionsManager: Accessibility permissions granted
📱 AppWatcher: Captured initial app: Xcode
📱 AccessibilityReader: Reading menus for app: Xcode (com.apple.dt.Xcode)
✅ AccessibilityReader: Successfully read 247 shortcuts
```

## ⚠️ Troubleshooting

### Problema: App ainda não aparece na lista
**Solução**: 
1. Feche completamente o app
2. Execute: `killall easyshortcut`
3. Limpe o cache do sistema: `tccutil reset Accessibility`
4. Execute o app novamente

### Problema: Permissão concedida mas não funciona
**Solução**:
1. Remova o app da lista de Acessibilidade
2. Feche o app completamente
3. Execute novamente e conceda permissão novamente

### Problema: "Operation not permitted"
**Solução**: Verifique se o sandbox está realmente desativado:
```bash
codesign -d --entitlements - /caminho/para/easyshortcut.app
```
Deve mostrar `com.apple.security.app-sandbox = false`

## 📝 Notas Importantes

1. **Sandbox vs Segurança**: Desativar o sandbox é necessário para a API de Acessibilidade, mas o Hardened Runtime ainda fornece proteções de segurança
2. **Notarização**: Para distribuir o app, será necessário notarização da Apple (requer Developer ID)
3. **Privacidade**: O app só lê estruturas de menu, não captura conteúdo ou dados sensíveis

## ✅ Checklist de Verificação

- [ ] Build bem-sucedido sem erros
- [ ] Entitlements corretos verificados com `codesign`
- [ ] App aparece automaticamente na lista de Acessibilidade
- [ ] Permissão pode ser concedida
- [ ] Atalhos aparecem após conceder permissão
- [ ] Atalhos atualizam ao trocar de app
- [ ] Logs de debug aparecem no Console.app

