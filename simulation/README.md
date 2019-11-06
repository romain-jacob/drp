# DRP simulation

| **Author** |**Last modified**|
|:---:|:---:|
|Romain Jacob  |16-10-2019|

Simulate the sending and receiving packet over Bolt and a Blink-scheduled network. The purpose of this simulation is to 

For simplicity, the procedure for admitting flows is not modelled: All flows are directly admitted right from the start of the simulation.

The entire simulation is controlled via the `main.m` script. At the top (`%% Initialization` block), one can set the simulation horizon (in seconds) and the random generator seed. 
- The result reported in [1] did not use a controled seed, thus cannot be strictly reproduced.
- The result reported in [2] uses `seed=2222`.

The `initialization.m` script sets all the other simulation parameters (hardware constants, design parameters, etc.). 

The `flowSetDefinition.m` script contains the definition of the control and data flows which are used in the simulation. The current version of the file contains the flow set used in [1] and [2].

The `plotTimeSimulation.m` script generates the plots presented in [1]. The actual plots to produced is controlled in the `%% Plot selection` block at the top.  
Furthermore, the script stores the simulation flow data in the `flow_data.csv` file for further processing (all time data expressed in seconds).

[1] DRP paper
[2] Thesis
