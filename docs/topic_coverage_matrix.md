# UVM topic coverage matrix

This matrix is the completeness contract for the series. “Code evidence” means
the topic is represented by project or focused reference code; it does not claim
every focused file is a standalone simulation test. Executed results are listed
only in the [verification report](verification_report.md).

## Foundations and architecture

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| UVM responsibility split and data flow | [00](../lessons/00_architecture/README.md) | [Environment](../tb/uvm/mini_bus_env.svh) |
| Static hierarchy versus dynamic objects | [00](../lessons/00_architecture/README.md) | [Package](../tb/pkg/mini_bus_uvm_pkg.sv) |
| `uvm_object` and `uvm_component` | [01](../lessons/01_objects_components/README.md) | [Item](../tb/uvm/mini_bus_item.svh), [agent](../tb/uvm/mini_bus_agent.svh) |
| Factory registration and construction | [01](../lessons/01_objects_components/README.md), [09](../lessons/09_factory/README.md) | [All UVM classes](../tb/uvm) |
| Test/environment/config ownership | [16](../lessons/16_test_env_configuration/README.md) | [Tests](../tb/uvm/mini_bus_tests.svh), [config example](../examples/configuration/agent_config_example.sv) |
| Component hierarchy and topology | [01](../lessons/01_objects_components/README.md), [16](../lessons/16_test_env_configuration/README.md) | [Environment](../tb/uvm/mini_bus_env.svh) |

## Transactions and stimulus

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| Sequence items and semantic fields | [02](../lessons/02_transactions_constraints/README.md) | [Item](../tb/uvm/mini_bus_item.svh) |
| Hard, soft, inline, `inside`, `dist` constraints | [02](../lessons/02_transactions_constraints/README.md) | [Item/derived item](../tb/uvm/mini_bus_item.svh) |
| Randomization failure and lifecycle | [02](../lessons/02_transactions_constraints/README.md) | [Random sequence](../tb/uvm/mini_bus_sequences.svh) |
| Copy, clone, compare, print, pack, record | [02](../lessons/02_transactions_constraints/README.md), [20](../lessons/20_services_utilities/README.md) | [Item methods](../tb/uvm/mini_bus_item.svh) |
| Sequence/sequencer request handshake | [03](../lessons/03_sequences_sequencers/README.md) | [Sequences](../tb/uvm/mini_bus_sequences.svh), [driver](../tb/uvm/mini_bus_driver.svh) |
| Sequencer arbitration and priority | [18](../lessons/18_advanced_sequences/README.md) | [Response/control example](../examples/sequence_control/response_example.sv) |
| `lock`, `grab`, cancellation | [18](../lessons/18_advanced_sequences/README.md) | [Advanced sequence reference](../lessons/18_advanced_sequences/README.md) |
| Driver response and ID routing | [18](../lessons/18_advanced_sequences/README.md) | [Response example](../examples/sequence_control/response_example.sv) |
| Layered versus virtual sequences | [18](../lessons/18_advanced_sequences/README.md) | [Virtual coordination](../examples/virtual_sequences/coordination_example.sv) |
| Multi-sequencer orchestration | [11](../lessons/11_virtual_sequences/README.md) | [Virtual coordination](../examples/virtual_sequences/coordination_example.sv) |

## Transactors and agents

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| Virtual interface and config handoff | [04](../lessons/04_driver_virtual_interface/README.md), [10](../lessons/10_config_db/README.md) | [Top](../tb/top/tb_top.sv), [driver](../tb/uvm/mini_bus_driver.svh) |
| Clocking blocks and race avoidance | [04](../lessons/04_driver_virtual_interface/README.md) | [Interface](../tb/interfaces/mini_bus_if.sv) |
| Driver request/completion timing | [04](../lessons/04_driver_virtual_interface/README.md) | [Driver](../tb/uvm/mini_bus_driver.svh) |
| Passive monitor and reconstruction | [05](../lessons/05_monitor_analysis/README.md) | [Monitor](../tb/uvm/mini_bus_monitor.svh) |
| Analysis publication and handle ownership | [05](../lessons/05_monitor_analysis/README.md), [17](../lessons/17_tlm_interfaces_fifos/README.md) | [Monitor](../tb/uvm/mini_bus_monitor.svh) |
| Active/passive agent | [06](../lessons/06_agent/README.md) | [Agent](../tb/uvm/mini_bus_agent.svh) |
| Typed agent configuration | [16](../lessons/16_test_env_configuration/README.md) | [Config example](../examples/configuration/agent_config_example.sv) |
| Reset-safe transactors | [21](../lessons/21_reset_error_regression/README.md) | [Interface/driver](../tb/interfaces/mini_bus_if.sv) |

## TLM, checking, and synchronization

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| TLM port/export/imp | [17](../lessons/17_tlm_interfaces_fifos/README.md) | [TLM example](../examples/tlm/tlm_fifo_example.sv) |
| Blocking put/get/peek/transport | [17](../lessons/17_tlm_interfaces_fifos/README.md) | [TLM example](../examples/tlm/tlm_fifo_example.sv) |
| Nonblocking `try_*`/`can_*` | [17](../lessons/17_tlm_interfaces_fifos/README.md) | [TLM lesson](../lessons/17_tlm_interfaces_fifos/README.md) |
| Analysis fanout and multiple imps | [17](../lessons/17_tlm_interfaces_fifos/README.md) | [Environment](../tb/uvm/mini_bus_env.svh) |
| TLM FIFO and analysis FIFO | [17](../lessons/17_tlm_interfaces_fifos/README.md) | [TLM example](../examples/tlm/tlm_fifo_example.sv) |
| Predictive reference model | [07](../lessons/07_tlm_scoreboard/README.md) | [Scoreboard](../tb/uvm/mini_bus_scoreboard.svh) |
| In-order and out-of-order matching | [07](../lessons/07_tlm_scoreboard/README.md) | [Scoreboard](../tb/uvm/mini_bus_scoreboard.svh) |
| False-pass prevention | [07](../lessons/07_tlm_scoreboard/README.md), [21](../lessons/21_reset_error_regression/README.md) | [Scoreboard checks](../tb/uvm/mini_bus_scoreboard.svh) |
| `uvm_event`, barrier, pool | [20](../lessons/20_services_utilities/README.md) | [Services example](../examples/services/sync_services_example.sv) |

## Phases, factory, configuration, and services

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| Common phases and traversal | [08](../lessons/08_phases_objections/README.md) | [Components](../tb/uvm) |
| Objections and end-of-test drain | [08](../lessons/08_phases_objections/README.md) | [Tests](../tb/uvm/mini_bus_tests.svh) |
| Runtime subphases and domains | [19](../lessons/19_advanced_phasing/README.md) | [Advanced phasing lesson](../lessons/19_advanced_phasing/README.md) |
| Drain time, ready-to-end, phase jump | [19](../lessons/19_advanced_phasing/README.md) | [Advanced phasing lesson](../lessons/19_advanced_phasing/README.md) |
| Type and instance factory overrides | [09](../lessons/09_factory/README.md) | [Boundary test](../tb/uvm/mini_bus_tests.svh) |
| `config_db` scope, precedence, tracing | [10](../lessons/10_config_db/README.md) | [Top/tests](../tb/top/tb_top.sv) |
| `resource_db` comparison | [10](../lessons/10_config_db/README.md) | [Config lesson](../lessons/10_config_db/README.md) |
| Reporting severity/verbosity/action/ID | [14](../lessons/14_reporting_callbacks_debug/README.md), [20](../lessons/20_services_utilities/README.md) | [All components](../tb/uvm) |
| Callbacks and report catchers | [14](../lessons/14_reporting_callbacks_debug/README.md) | [Callback example](../examples/callbacks/driver_callback_example.sv) |
| Command-line processor | [20](../lessons/20_services_utilities/README.md) | [Services lesson](../lessons/20_services_utilities/README.md) |
| Timeout and causal debug | [14](../lessons/14_reporting_callbacks_debug/README.md), [19](../lessons/19_advanced_phasing/README.md) | [Run scripts](../scripts) |

## Coverage, assertions, RAL, and signoff

| Topic | Detailed lesson | Code evidence |
|---|---|---|
| Covergroups, bins, crosses, sampling | [12](../lessons/12_coverage_sva/README.md) | [Coverage subscriber](../tb/uvm/mini_bus_coverage.svh) |
| SVA implication, sampling, reset | [12](../lessons/12_coverage_sva/README.md) | [Protocol SVA](../tb/assertions/mini_bus_sva.sv) |
| Coverage closure and exclusions | [12](../lessons/12_coverage_sva/README.md), [21](../lessons/21_reset_error_regression/README.md) | [Verification plan](verification_plan.md) |
| RAL reg/field/block/map | [13](../lessons/13_ral/README.md) | [RAL example](../examples/ral/mini_reg_model.sv) |
| Adapter and explicit predictor | [13](../lessons/13_ral/README.md) | [RAL adapter](../examples/ral/mini_reg_model.sv) |
| Frontdoor/backdoor and mirror semantics | [13](../lessons/13_ral/README.md) | [RAL example](../examples/ral/mini_reg_model.sv) |
| Reset contract and recovery | [21](../lessons/21_reset_error_regression/README.md) | [RTL/SVA](../rtl/mini_bus_memory.sv) |
| Negative/error injection policy | [21](../lessons/21_reset_error_regression/README.md) | [Boundary test](../tb/uvm/mini_bus_tests.svh) |
| Reproducible regression and result classes | [21](../lessons/21_reset_error_regression/README.md) | [Scripts](../scripts), [report](verification_report.md) |
| Interview explanation and debugging | [15](../lessons/15_interview_practice/README.md) | [80-question bank](../lessons/15_interview_practice/questions_and_answers.md) |
