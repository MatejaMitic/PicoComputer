Overview
The project is organized into three layers of increasing complexity:

Simulation — Behavioral RTL modules verified in ModelSim/QuestaSim
Synthesis 1 — picoComputer running programs loaded from a .mif file, with PC/SP displayed on seven-segment displays
Synthesis 2 — Full system with PS/2 keyboard input and VGA monitor output


Architecture
The processor follows the picoComputer architecture with:

16-bit unsigned integer data path
64-word memory (6-bit address space) split into:

Addresses 0–7: General-Purpose Registers (GPR)
Addresses 8–63: Program, data, and stack


Program Counter (PC) — starts at address 8
Stack Pointer (SP) — starts at the last address (63) and grows downward
Internal registers: IR (32-bit), MAR (6-bit), MDR (16-bit), ACC (16-bit)

Instruction Set
OpcodeMnemonicOperation0000MOV X, Ymem[X] ← mem[Y]0001ADD X, Y, Zmem[X] ← mem[Y] + mem[Z]0010SUB X, Y, Zmem[X] ← mem[Y] - mem[Z]0011MUL X, Y, Zmem[X] ← mem[Y] * mem[Z]0100DIV X, Y, Zmem[X] ← mem[Y] / mem[Z] (unimplemented)0111IN Xmem[X] ← stdin (blocking)1000OUT Xstdout ← mem[X]1111STOP [X, Y, Z]Halt; optionally print up to 3 values
Instructions are 1 or 2 words (32-bit). The top 4 bits are the opcode; each operand uses 4 bits (1 mode bit + 3 address bits). Mode 0 = direct, mode 1 = indirect addressing.

Project Structure
src/
├── simulation/
│   ├── modules/
│   │   ├── alu.v          # 4-bit ALU (ADD, SUB, MUL, DIV, NOT, XOR, OR, AND)
│   │   └── register.v     # 4-bit register (CLR, LOAD, INC, DEC, SHL, SHR)
│   ├── top.v              # Simulation testbench
│   └── top.sv             # UVM verification testbench
├── synthesis2/            # Synthesis 1 + PS/2 + VGA
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
└── synthesis3/            # Extension modifications
    └── ...                # Same structure as synthesis2

tooling/
├── mem_init.mif           # Default program (IN/OUT/ADD/SUB/MUL demo)
├── mem_init_mod2.mif      # Modified program (Mod 2)
├── mem_init_mod3.mif      # Modified program (Mod 3)
├── makefile               # Build automation
└── config/                # ModelSim scripts, board pin assignments

Demo Program (mem_init.mif)
The default memory initialization file runs the following program:
IN  A          ; A = <input>
OUT A          ; print A
MOV B, A       ; B = A
ADD C, A, B    ; C = A + B
OUT C          ; print C
IN  D          ; D = <input>
SUB C, C, D    ; C = C - D
MOV E, C       ; E = C
OUT E          ; print E
IN  C          ; C = <input>
MUL E, E, C    ; E = E * C
OUT E          ; print E
STOP

Hardware
Designed and synthesized for the Altera DE0 / DE0-CV development boards.
SignalDE0-CV MappingClock50 MHz onboard oscillatorResetsw[9] (active-low, async)Input datasw[3:0] (Synthesis 1) / PS/2 keyboard (Synthesis 2)Output dataled[4:0]PC / SP displayhex[27:0] (four 7-segment digits)VGA outputmnt[13:0] — hsync, vsync, R[3:0], G[3:0], B[3:0]CPU ready LEDled[5] (Synthesis 2)
The memory and CPU run on a 1 Hz divided clock (50 MHz ÷ 50,000,000) to allow step-by-step observation on the board.

Simulation
Simulation is driven from top.v / top.sv and covers:

ALU — exhaustive input sweep for all arithmetic and logic operations, with pauses between groups
Register — 1000 pseudorandom input combinations; monitors output changes and prints simulation time with all relevant port values
UVM verification (top.sv) — randomized constrained tests with code coverage reporting

To run in ModelSim:
tcldo config/run.tcl
run -all

Tools
ToolPurposeModelSim / QuestaSimSimulation & UVM verificationIntel Quartus PrimeSynthesis & place-and-routemake (xpack)Build automation
