# Tools

| Tool | License | Category | Description |
|---|---|---|---|
| [Yosys](https://github.com/YosysHQ/yosys) | ISC | Synthesis and formal | Open-source framework for RTL synthesis and formal verification. |
| [sv-elab](https://github.com/povik/sv-elab) | ISC | SystemVerilog frontend | Elaborates SystemVerilog into a word-level netlist, built on Slang. Formerly yosys-slang, and part of Yosys since v0.67. PR #317 adds SVA support. |
| [ACL2](https://github.com/acl2/acl2) | BSD-3-Clause | Theorem prover | Theorem prover and programming language built on Common Lisp. The community books under `books/` carry their own licenses. |
| [SV](https://github.com/acl2/acl2/tree/master/books/centaur/sv) / [FGL](https://github.com/acl2/acl2/tree/master/books/centaur/fgl) / [VeSCMul](https://github.com/acl2/acl2/tree/master/books/projects/vescmul) | MIT-style | Formal verification | ACL2 libraries for formally verifying SystemVerilog designs. SV models the RTL, FGL proves bit-level properties, and VeSCMul checks multipliers. |
| [Slang](https://github.com/MikePopoloski/slang) | MIT | SystemVerilog frontend | SystemVerilog compiler and language services library written in C++. |
| [OpenTimer](https://github.com/OpenTimer/OpenTimer) | MIT | Static timing analysis | Open-source static timing analyzer for VLSI designs. |
| [OpenSTA](https://github.com/parallaxsw/OpenSTA) | GPL-3.0 | Static timing analysis | Gate-level static timing analyzer. |
| [Claude](https://www.anthropic.com/claude) | Proprietary | AI assistant | Anthropic's LLM, used to drive the command-line tools above. |
| [sv2v](https://github.com/zachjs/sv2v) | BSD-3-Clause | Converter | Converts SystemVerilog to Verilog-2005 for tools that only read plain Verilog. |

Links:
- [sv-elab PR #317](https://github.com/povik/sv-elab/pull/317)
- [SV/FGL/VeSCMul paper](https://arith2025.org/proceedings/215900a149.pdf)
