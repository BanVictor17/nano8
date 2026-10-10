# nano8

A custom 8-bit, multi-cycle processor for the Tang Nano 9K FPGA board.

## Status

An 8-bit combinational ALU and its testbench are implemented. All 12 directed
test cases pass with Icarus Verilog. No CPU instructions have been implemented,
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

Address widths, instruction width, and instruction encoding have not been
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
