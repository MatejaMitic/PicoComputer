# picoComputer Project

## Overview

The project is organized into three layers of increasing complexity:

### 1. Simulation
Behavioral RTL modules verified in ModelSim/QuestaSim.

### 2. Synthesis 1
`picoComputer` running programs loaded from a `.mif` file, with `PC` and `SP` displayed on seven-segment displays.

### 3. Synthesis 2
Full system with PS/2 keyboard input and VGA monitor output.

---

## Architecture

The processor follows the `picoComputer` architecture with:

- **16-bit unsigned integer** data path
- **64-word memory** (6-bit address space), split into:
  - **Addresses 0–7:** General-Purpose Registers (GPR)
  - **Addresses 8–63:** Program, data, and stack
- **Program Counter (PC):** starts at address `8`
- **Stack Pointer (SP):** starts at the last address (`63`) and grows downward
- Internal registers:
  - `IR` (32-bit)
  - `MAR` (6-bit)
  - `MDR` (16-bit)
  - `ACC` (16-bit)

---

## Instruction Set

Instructions are 1 or 2 words (32-bit). The top 4 bits are the opcode; each operand uses 4 bits:

- **1 mode bit**
- **3 address bits**

Addressing modes:

- `0` = direct
- `1` = indirect

| Opcode | Mnemonic | Operation |
|--------|----------|-----------|
| `0000` | `MOV X, Y` | `mem[X] ← mem[Y]` |
| `0001` | `ADD X, Y, Z` | `mem[X] ← mem[Y] + mem[Z]` |
| `0010` | `SUB X, Y, Z` | `mem[X] ← mem[Y] - mem[Z]` |
| `0011` | `MUL X, Y, Z` | `mem[X] ← mem[Y] * mem[Z]` |
| `0100` | `DIV X, Y, Z` | `mem[X] ← mem[Y] / mem[Z]` *(unimplemented)* |
| `0111` | `IN X` | `mem[X] ← stdin` *(blocking)* |
| `1000` | `OUT X` | `stdout ← mem[X]` |
| `1111` | `STOP [X, Y, Z]` | Halt; optionally print up to 3 values |

---

## Project Structure

```text
src/
├── simulation/
│   ├── modules/
│   │   ├── alu.v          # 4-bit ALU (ADD, SUB, MUL, DIV, NOT, XOR, OR, AND)
│   │   └── register.v     # 4-bit register (CLR, LOAD, INC, DEC, SHL, SHR)
│   ├── top.v              # Simulation testbench
│   └── top.sv             # UVM verification testbench
├── synthesis/            # Synthesis 1 + PS/2 + VGA
│   ├── modules/
│   │   ├── alu.v          # Parametric ALU (DATA_WIDTH)
│   │   ├── register.v     # Parametric register (DATA_WIDTH)
│   │   ├── clk_div.v      # Clock divider (DIVISOR parameter)
│   │   ├── memory.v       # 64×16 RAM with .mif initialization
│   │   ├── cpu.v          # picoComputer FSM
│   │   ├── bcd.v          # Binary → BCD converter
│   │   ├── ssd.v          # Seven-segment display encoder
│   │   ├── debouncer.v    # Button debouncer
│   │   ├── red.v          # Rising-edge detector
│   │   ├── ps2.v          # PS/2 keyboard controller
│   │   ├── scan_codes.v   # PS/2 scan code → digit decoder
│   │   ├── color_codes.v  # Digit → 12-bit RGB color encoder
│   │   ├── vga.v          # VGA controller (split-screen, two colors)
│   │   └── top.v          # Top-level entity
│   ├── DE0_TOP.v          # Board wrapper — Cyclone III
│   └── DE0_CV_TOP.v       # Board wrapper — Cyclone V


tooling/
├── mem_init.mif           # Default program (IN/OUT/ADD/SUB/MUL demo)
├── mem_init_mod2.mif      # Modified program (Mod 2)
├── mem_init_mod3.mif      # Modified program (Mod 3)
├── makefile               # Build automation
└── config/                # ModelSim scripts, board pin assignments
