# Bootloader em Assembly x86

Este repositório contém um bootloader simples escrito em *Assembly* x86 de 16 bits (`bootloader.asm`).  
Ao inicializar, ele:

1. Limpa a tela.  
2. Exibe um prompt solicitando seu nome.  
3. Lê a entrada digitada direto do teclado (com suporte a *backspace*).  
4. Imprime uma saudação personalizada (`Olá, <nome>!`).  
5. Retorna ao passo 2 até que seja enviada uma linha vazia, quando então encerra com a mensagem de despedida **"Flw irmao!"**.

---

## Pré-requisitos

* **NASM** – montador utilizado para gerar o binário (`.bin`).  
  Versão ≥ 2.15 recomendada.
* **QEMU** (opcional) – emulador para testar o bootloader sem precisar gravar em mídia física.
* Ambiente Linux/macOS ou WSL. Em Windows puro, adapte os comandos de *shell* ou use *PowerShell*.

Instalação no Arch Linux:
```bash
sudo pacman -S nasm qemu-base   # ou "qemu-full" se precisar de interfaces gráficas
```
Ubuntu/Debian:
```bash
sudo apt-get install nasm qemu-system-x86
```

---

## Compilação

Use o seguinte comando para traduzir `bootloader.asm` para um binário de 512 bytes compatível com setor de boot:
```bash
nasm -f bin bootloader.asm -o bootloader.bin
```
* `-f bin` instrui o NASM a gerar um arquivo *flat binary* (sem cabeçalhos).
* O resultado **deve** ter exatamente 512 bytes; os últimos dois bytes são a assinatura `0x55AA` exigida pelo BIOS.

Você pode verificar o tamanho assim:
```bash
stat -c "%n: %s bytes" bootloader.bin
```

---

## Execução emulado (QEMU)

Máquina virtual para executar o bootloader

```bash
qemu-system-i386 -drive format=raw,file=bootloader.bin
```

---

## Estrutura do Código

| Seção                | Descrição rápida |
|----------------------|------------------|
| `start`              | Configura registradores, segmentos, pilha e chama `clear_screen`. |
| `main_loop`          | Loop principal que exibe o prompt, lê a linha e decide entre saudar ou encerrar. |
| `read_line`          | Lê caracteres via interrupção `16h`, trata *backspace* e finaliza com `0x00`. |
| `print_string`       | Imprime string 0-terminated usando interrupção `10h` função `0x0E`. |
| `print_message`      | Combina saudação fixa com o texto digitado e coloca `!` no final. |
| `clear_screen`       | Usa interrupção `10h` função `06h` para limpar a tela e reposicionar o cursor. |
| `hang`               | *Loop* infinito após a mensagem de despedida. |

Comentários no próprio arquivo explicam detalhadamente cada instrução.

---

## Como Funciona o Processo de Boot
1. O BIOS localiza o primeiro setor de boot do dispositivo escolhido e o carrega em `0x7C00`.
2. Verifica a assinatura `55AA`; em caso de ausência, considera o setor inválido.
3. Transfere execução para `0x7C00` com a CPU ainda em modo real (16 bits).