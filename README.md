---
description: Open-Source ASIC project for a wishbone-compatible dual port 2kb DFFRAM
author: WhisperingRock
tags: ["open-source", "asic", "verilator", "icarus", "yosys", "librelane", ,"openroad","DFFRAM", "wishbone"]
---

## Note
- The DFFRAM 256x32 macros are too large to store in github. 
  - Navigate to the [Openlane DFFRAM repo](https://github.com/efabless/OL-DFFRAM)
 to download and extract it into `macros/dffram256x32`. 
- Don't forget to copy the DFFRAM in `hdl/sim` and copy it into your top level `rtl` dir 
to start using in simulation.


## :toolbox: Toolset
| Phase | Verilator | Icarus | Yosys | Librelane | Openroad |
| ---      | --- | --- | --- | --- | --- |
| Lint     | &check; |&check; |
| SVA      | &check; | :heavy_division_sign: |
| Formal   ||| &check; |
| Coverage | &check; |
| DRC Check|||| &check; |
| LVS Check|||| &check; |
| STA Check|||| &check; |
|Annt Check|||| &check; |
|Gate-Level|| &check; |
|Design Area|||| &check; |
|Chip Visuals||||| &check; |

:heavy_division_sign: - Icarus doesn't support concurrent SVA

##  Workflow

## Current Design

##  Task Management
- [ ] DESIGN : First design pass
