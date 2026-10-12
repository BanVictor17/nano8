# Instruction encoding

This document defines the base instruction set for nano8. Instruction words
are 16 bits wide; register values are 8 bits wide. The decoder and CPU
execution logic have not been implemented yet.

## Operands and formats

Register instructions use two operands. The first register is the destination
and, for arithmetic and logic operations, also the first source. For example,
`ADD R0, R1` means `R0 = R0 + R1`. All eight registers are writable.

| Format | Bits 15:12 | Bits 11:9 | Bits 8:6 | Bits 5:0 |
| --- | --- | --- | --- | --- |
| Register | Opcode | Destination `rd` | Source `rs` | Reserved, zero |

| Format | Bits 15:12 | Bits 11:9 | Bit 8 | Bits 7:0 |
| --- | --- | --- | --- | --- |
| Immediate | Opcode | Destination `rd` | Reserved, zero | Immediate `imm` |

| Format | Bits 15:12 | Bits 11:0 |
| --- | --- | --- |
| No operands | Opcode | Reserved, zero |

An encoding is valid only when its opcode is in the base set and all reserved
bits for its format are zero. Opcodes 8 through 14 are currently invalid.
Opcodes 8, 9, 10, and 11 are reserved for later JMP, JZ, LOAD, and STORE stages;
their operand formats will be defined when those stages are introduced.

## Base instruction set

`Z` is the planned stored zero flag. It is separate from the ALU's
combinational `zero` output. The following table specifies the behavior that
the CPU control logic will implement.

| Opcode, decimal | Instruction | Format | Effect | Z update |
| --- | --- | --- | --- | --- |
| 0 | `NOP` | No operands | Preserve registers | Preserve |
| 1 | `LDI rd, imm` | Immediate | `R[rd] = imm` | Preserve |
| 2 | `MOV rd, rs` | Register | `R[rd] = R[rs]` | Preserve |
| 3 | `ADD rd, rs` | Register | `R[rd] = R[rd] + R[rs]` | Result equals zero |
| 4 | `SUB rd, rs` | Register | `R[rd] = R[rd] - R[rs]` | Result equals zero |
| 5 | `AND rd, rs` | Register | `R[rd] = R[rd] & R[rs]` | Result equals zero |
| 6 | `OR rd, rs` | Register | `R[rd] = R[rd] \| R[rs]` | Result equals zero |
| 7 | `XOR rd, rs` | Register | `R[rd] = R[rd] ^ R[rs]` | Result equals zero |
| 15 | `HALT` | No operands | Stop instruction execution | Preserve |

ADD and SUB retain only the low eight result bits, giving modulo-256
arithmetic. There are no carry or signed-overflow flags. Register writes and
Z updates will occur on the execution clock edge. Instruction opcodes and ALU
operation selectors have different encodings: ADD has instruction opcode 3
and ALU selector 0.

The CPU will halt on an invalid instruction without writing registers,
memory, or flags. The halt lasts until reset. Reset will clear the registers,
PC, instruction register, and stored Z flag and restart instruction fetching.
The exact PC update timing will be defined with the control FSM.

## Manual encoding examples

SystemVerilog concatenation places the first field in the most significant
bits. Every expression below has exactly 16 bits.

| Instruction | Encoding expression | Decimal word |
| --- | --- | --- |
| `NOP` | `{4'd0, 12'd0}` | 0 |
| `LDI R0, 10` | `{4'd1, 3'd0, 1'b0, 8'd10}` | 4106 |
| `LDI R1, 3` | `{4'd1, 3'd1, 1'b0, 8'd3}` | 4611 |
| `ADD R0, R1` | `{4'd3, 3'd0, 3'd1, 6'd0}` | 12352 |
| `HALT` | `{4'd15, 12'd0}` | 61440 |

These are encoding examples. The instruction ROM still contains its read
timing test words; no CPU program is executing yet.

## Decoder contract

The decoder will be combinational. It will extract the raw fields as follows:

- `opcode = instr[15:12]`
- `rd = instr[11:9]`
- `rs = instr[8:6]`
- `imm = instr[7:0]`

The raw fields overlap across formats. `rs` is meaningful for register
instructions; `imm` is meaningful for LDI. Unused raw outputs are ignored.
`valid` will indicate that the opcode is recognized and its reserved bits are
zero. The decoder itself will not write registers or advance the PC.
