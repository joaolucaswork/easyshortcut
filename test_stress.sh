#!/bin/bash

# Stress test para easyshortcut
# Simula uso intenso com múltiplos aplicativos simultaneamente

echo "=== Stress Test - easyshortcut ==="
echo ""

# Verificar se easyshortcut está rodando
if ! pgrep -x "easyshortcut" > /dev/null; then
    echo "❌ easyshortcut não está rodando!"
    exit 1
fi

pid=$(pgrep -x easyshortcut)
echo "✅ easyshortcut está rodando (PID: $pid)"
echo ""

# Capturar métricas iniciais
initial_mem=$(ps -p $pid -o rss= | awk '{print $1}')
echo "Memória inicial: $(echo "scale=2; $initial_mem/1024" | bc) MB"
echo ""

# Lista expandida de aplicativos
apps=(
    "Arc" "Claude" "ChatGPT" "Discord" "Finder" 
    "Safari" "Notes" "Calendar" "Mail" "Messages"
    "TextEdit" "Preview" "System Settings"
)

echo "Stress Test: 50 iterações com ${#apps[@]} aplicativos..."
echo "Isso irá gerar ~650 trocas de aplicativo"
echo ""

start_time=$(date +%s)

# Executar 50 iterações
for i in {1..50}; do
    for app in "${apps[@]}"; do
        osascript -e "tell application \"$app\" to activate" 2>/dev/null &
        sleep 0.05  # Troca muito rápida (50ms)
    done
    
    # Mostrar progresso a cada 10 iterações
    if [ $((i % 10)) -eq 0 ]; then
        current_mem=$(ps -p $pid -o rss= 2>/dev/null | awk '{print $1}')
        if [ -z "$current_mem" ]; then
            echo ""
            echo "❌ easyshortcut crashou na iteração $i!"
            exit 1
        fi
        echo "Iteração $i/50 - Memória: $(echo "scale=2; $current_mem/1024" | bc) MB"
    fi
done

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "✅ Stress test concluído em ${duration}s"
echo ""

# Aguardar estabilização
sleep 3

# Verificar se ainda está rodando
if ! pgrep -x "easyshortcut" > /dev/null; then
    echo "❌ easyshortcut crashou após o teste!"
    exit 1
fi

echo "✅ easyshortcut ainda está rodando"
echo ""

# Métricas finais
final_mem=$(ps -p $pid -o rss= | awk '{print $1}')
final_cpu=$(ps -p $pid -o %cpu= | awk '{print $1}')

echo "=== Métricas Finais ==="
echo "Memória inicial: $(echo "scale=2; $initial_mem/1024" | bc) MB"
echo "Memória final: $(echo "scale=2; $final_mem/1024" | bc) MB"
echo "Diferença: $(echo "scale=2; ($final_mem - $initial_mem)/1024" | bc) MB"
echo "CPU: ${final_cpu}%"
echo ""

# Verificar vazamento de memória
mem_increase=$(echo "scale=2; ($final_mem - $initial_mem)/1024" | bc)
if (( $(echo "$mem_increase > 10" | bc -l) )); then
    echo "⚠️  Possível vazamento de memória detectado (+${mem_increase} MB)"
else
    echo "✅ Sem vazamento de memória significativo"
fi

echo ""
echo "=== Stress Test Concluído ==="

