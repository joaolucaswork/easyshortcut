#!/bin/bash

# Script de teste de concorrência para easyshortcut
# Simula troca rápida entre múltiplos aplicativos

echo "=== Teste de Concorrência - easyshortcut ==="
echo ""

# Lista de aplicativos para testar
apps=(
    "Arc"
    "Claude"
    "ChatGPT"
    "Discord"
    "Finder"
    "Safari"
    "Notes"
    "Calendar"
    "Mail"
    "Messages"
)

echo "Iniciando teste com ${#apps[@]} aplicativos..."
echo ""

# Verificar se easyshortcut está rodando
if ! pgrep -x "easyshortcut" > /dev/null; then
    echo "❌ easyshortcut não está rodando!"
    exit 1
fi

echo "✅ easyshortcut está rodando (PID: $(pgrep -x easyshortcut))"
echo ""

# Capturar uso inicial de memória e CPU
initial_mem=$(ps aux | grep -i easyshortcut | grep -v grep | awk '{print $6}')
echo "Memória inicial: $(echo "scale=2; $initial_mem/1024" | bc) MB"
echo ""

# Teste 1: Troca rápida entre aplicativos
echo "Teste 1: Troca rápida entre aplicativos (10 iterações)..."
for i in {1..10}; do
    for app in "${apps[@]}"; do
        osascript -e "tell application \"$app\" to activate" 2>/dev/null &
        sleep 0.1
    done
    echo -n "."
done
echo " ✅"
echo ""

# Aguardar estabilização
sleep 2

# Verificar se easyshortcut ainda está rodando
if ! pgrep -x "easyshortcut" > /dev/null; then
    echo "❌ easyshortcut crashou durante o teste!"
    exit 1
fi

echo "✅ easyshortcut ainda está rodando após teste de troca rápida"
echo ""

# Capturar uso final de memória e CPU
final_mem=$(ps aux | grep -i easyshortcut | grep -v grep | awk '{print $6}')
final_cpu=$(ps aux | grep -i easyshortcut | grep -v grep | awk '{print $3}')

echo "Memória final: $(echo "scale=2; $final_mem/1024" | bc) MB"
echo "CPU final: ${final_cpu}%"
echo ""

# Calcular diferença de memória
mem_diff=$(echo "scale=2; ($final_mem - $initial_mem)/1024" | bc)
echo "Diferença de memória: ${mem_diff} MB"
echo ""

# Verificar logs para erros
echo "Verificando logs para erros de concorrência..."
error_count=$(log show --predicate 'process == "easyshortcut"' --last 1m --style compact 2>/dev/null | grep -i "error\|crash\|race" | wc -l)

if [ "$error_count" -gt 0 ]; then
    echo "⚠️  Encontrados $error_count possíveis erros nos logs"
else
    echo "✅ Nenhum erro encontrado nos logs"
fi

echo ""
echo "=== Teste de Concorrência Concluído ==="

