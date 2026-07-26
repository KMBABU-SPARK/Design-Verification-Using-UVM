# D Flip-Flop Using SystemVerilog Interface

This example demonstrates how to connect a **D Flip-Flop (DFF)** using a **SystemVerilog interface**. The interface groups all DUT signals together, making the design cleaner and easier to reuse.

---

## Interface

```systemverilog
`timescale 1ns/1ps

interface dff_if;
  logic clk;    // Clock signal
  logic rst;    // Active-high reset
  logic din;    // Data input
  logic dout;   // Data output
endinterface
```

### Signals

| Signal | Direction | Description |
|---------|-----------|-------------|
| `clk` | Input | Clock signal |
| `rst` | Input | Active-high reset |
| `din` | Input | Data input |
| `dout` | Output | Registered output |

---

## D Flip-Flop Module

```systemverilog
module dff (dff_if vif);

  always @(posedge vif.clk)
  begin
    if (vif.rst == 1'b1)
      vif.dout <= 1'b0;
    else
      vif.dout <= vif.din;
  end

endmodule
```

---

## Working

- The D Flip-Flop samples the input **`din`** on every **positive edge** of the clock.
- If **`rst`** is asserted (`1`), the output is cleared to **`0`**.
- Otherwise, the value of **`din`** is stored in **`dout`**.

### Behaviour

| Clock Edge | Reset (`rst`) | `din` | `dout` |
|------------|---------------|-------|--------|
| ↑ | 1 | X | 0 |
| ↑ | 0 | 0 | 0 |
| ↑ | 0 | 1 | 1 |
| ↑ | 0 | Previous Value | Updated to `din` |

---

## Key Points

- Uses a **SystemVerilog interface** to bundle related signals.
- Interface is passed directly to the DUT.
- Non-blocking assignment (`<=`) is used for sequential logic.
- Output changes only on the **positive edge** of the clock.
- Reset is **synchronous** because it is checked only inside `@(posedge clk)`.

---

## Note

The commented code in the original source demonstrates a more advanced interface using:

- Parameterized interface
- Modports (`dut` and `tb`)
- Active-low asynchronous reset (`rst_n`)

The active implementation shown above is a simplified version suitable for beginners learning SystemVerilog interfaces.
