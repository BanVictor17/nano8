# nano8

A custom 8-bit, multi-cycle processor for the Tang Nano 9K FPGA board.

## Status

An 8-bit combinational ALU and its testbench are implemented. All 12 directed
test cases pass with Icarus Verilog. An eight-register file and its testbench
are also implemented, and the register file tests pass with Icarus Verilog.
An 8-bit program counter and its testbench are also implemented, and the PC
tests pass with Icarus Verilog. No CPU instructions have been implemented,
and no board validation has been completed yet.

## Target and tools

- Board: Tang Nano 9K
- FPGA: GW1NR-LV9QN88PC6/I5, version C
- Board clock: 27 MHz
- Host: Windows with PowerShell
- FPGA toolchain: GOWIN FPGA Designer Education
- RTL simulation: Icarus Verilog (`iverilog` and `vvp`)

## Planned architecture

The processor will use eight general-purpose 8-bit registers, an ALU, a program
counter, an instruction register, a synchronous instruction ROM, and an FSM
control unit. Later stages will add a stored zero flag, data RAM, and GPIO,
timer, and UART peripherals accessed through memory-mapped I/O.

The program counter is 8 bits wide and will address 256 instruction words in
ROM. Advancing the PC by one selects the next instruction word. Instruction
width, instruction encoding, and data memory address width have not been
defined yet. The initial programs will be encoded manually in ROM.

## 8-bit ALU

The first RTL module is `rtl/alu8.sv`. Its interface is:

| Port | Direction | Width | Meaning |
| --- | --- | --- | --- |
| `a` | Input | 8 bits | First operand |
| `b` | Input | 8 bits | Second operand |
| `op` | Input | 3-bit enum | ALU operation selector |
| `result` | Output | 8 bits | Combinational result |
| `zero` | Output | 1 bit | High when `result` is zero |

| `op` | Operation | Result |
| --- | --- | --- |
| `3'b000` | ADD | `a + b`, modulo 256 |
| `3'b001` | SUB | `a - b`, modulo 256 |
| `3'b010` | AND | Bitwise `a & b` |
| `3'b011` | OR | Bitwise `a \| b` |
| `3'b100` | XOR | Bitwise `a ^ b` |
| `3'b101` | PASS_B | `b` |
| `3'b110`, `3'b111` | Reserved | `8'd0` |

These selectors are local to the ALU; they are not CPU instruction encodings.
The ALU has no clock, reset, or internal state. Carry and signed overflow
are not exposed. Its `zero` output is combinational; the CPU's stored
zero flag will be defined when instruction execution is implemented.

## Register file

`rtl/regfile8.sv` stores eight 8-bit registers. Two independent combinational
read ports select registers through 3-bit addresses. One write port updates
the selected register on a rising clock edge when `write_en` is high.

The active-high synchronous reset clears all eight registers and takes
priority over a write. Without reset or an enabled write, the contents are
preserved. All registers, including register zero, are writable. If a read
port selects the register being written, it reflects the new value after
the clocked update and combinational propagation.

## Program counter

`rtl/pc8.sv` stores an 8-bit instruction address. On each rising clock edge,
active-high synchronous reset clears the PC, `load_en` loads `load_addr`, or
`inc_en` increments the PC, in that priority order. Without an active control,
the PC holds its value. Incrementing 255 wraps to zero.

## Simulation

The local Icarus executables are `C:\iverilog\bin\iverilog.exe` and
`C:\iverilog\bin\vvp.exe`. Run the ALU testbench from the repository root in
PowerShell:

```powershell
New-Item -ItemType Directory -Path 'build' -Force | Out-Null
& 'C:\iverilog\bin\iverilog.exe' -g2012 -Wall -s tb_alu8 -o 'build\tb_alu8.vvp' 'rtl\alu8.sv' 'sim\tb_alu8.sv'
if ($LASTEXITCODE -ne 0) { throw 'ALU testbench compilation failed' }
& 'C:\iverilog\bin\vvp.exe' 'build\tb_alu8.vvp'
if ($LASTEXITCODE -ne 0) { throw 'ALU tests failed' }
```

Expected success message:

```text
ALU tests passed (12 checks)
```

`sim/tb_alu8.sv` checks every ALU selector, addition wraparound, subtraction
wraparound, zero results, and the combinational `zero` output. Each case waits
1 ns before checking the outputs and uses `$fatal` on a mismatch. Generated
simulation output belongs in `build/` and is ignored by Git.

Run the register file testbench from the same directory:

```powershell
New-Item -ItemType Directory -Path 'build' -Force | Out-Null
& 'C:\iverilog\bin\iverilog.exe' -g2012 -Wall -s tb_regfile8 -o 'build\tb_regfile8.vvp' 'rtl\regfile8.sv' 'sim\tb_regfile8.sv'
if ($LASTEXITCODE -ne 0) { throw 'Register file testbench compilation failed' }
& 'C:\iverilog\bin\vvp.exe' 'build\tb_regfile8.vvp'
if ($LASTEXITCODE -ne 0) { throw 'Register file tests failed' }
```

Expected success message:

```text
Register file tests passed
```

`sim/tb_regfile8.sv` checks reset clearing every register, writes to all eight
registers, independent read addresses, disabled writes, reads before and after
a write to the selected register, and preservation of other registers. It also
checks that writes do not occur on a falling edge, and that reset only takes
effect on a rising edge and has priority over a write. Clock edges are advanced
explicitly with `clock_cycles`, which holds the clock low for 1 ns and then
high for 1 ns per cycle. Combinational reads are checked after `#1` without
advancing the clock. These delays are testbench timing choices.

Run the program counter testbench from the same directory:

```powershell
New-Item -ItemType Directory -Path 'build' -Force | Out-Null
& 'C:\iverilog\bin\iverilog.exe' -g2012 -Wall -s tb_pc8 -o 'build\tb_pc8.vvp' 'rtl\pc8.sv' 'sim\tb_pc8.sv'
if ($LASTEXITCODE -ne 0) { throw 'PC testbench compilation failed' }
& 'C:\iverilog\bin\vvp.exe' 'build\tb_pc8.vvp'
if ($LASTEXITCODE -ne 0) { throw 'PC tests failed' }
```

Expected success message:

```text
PC tests passed
```

`sim/tb_pc8.sv` checks synchronous reset, incrementing, holding with both
enables disabled, address loading, reset and load priority, and wraparound
from 255 to zero. It also checks that changing inputs or applying a falling
clock edge does not update the PC. Clock edges are advanced explicitly with
the same `clock_cycles` task used in the register file testbench.
