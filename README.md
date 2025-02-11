
# Optimizing GPF scheduler with Differential Evolution on 5G HetNet simulated scenarios
This is a repository regarding the paper "Optimizing GPF scheduler with Differential Evolution on  5G HetNet simulated scenarios". This document shows the usage of **Differential Evolution** (DE) aiming to optimize the Generalized Proportional Fair (**GPF**) **Scheduler** on a simulated **5G** Heterogeneous Network (**HetNet**).

# 1. Simulator
The simulator used in this paper is the **Vienna 5G System Level Simulator**, which allows scenario modeling and performs a Monte Carlo simulation for a given 5G network. Learn more at: https://www.tuwien.at/etit/tc/en/vienna-simulators/vienna-5g-simulators/
# 2. User modifications
The Differential Evolution Parameters are present in ```DE.py``` and the Simulation Parameters are present in ```HetNetDE.m```

## 2.1 Differential Evolution parameters
 1.  **Population Size**. Changing the population size will yield more points in the search space to look for optimization. **0 < n (integer)**.  
 ```popSize = n;```
2. **Max. Generations**. **0 < n (integer)**.  
```maxGenerations = n;```
3. **Differential Weight**. **0 < n < 1 (float)**.  
	```F = n;```
4. **Crossover Rate**. **0 < n < 2 (float)**.  
	```CR = n;```
5. **Number of Users**. **0 < n  (integer)**.  
	```usr = 4*n;```
6. **Population dist.** The initial points in the search space are equidistant or random?  
	>n == 0, random (default).
	>n == 1, equidistant.
	
	```typePop = n;```

## 2.2 Scenario parameters
 1.  **Slots per Chunk**. Changes the simulation's "granularity".  **0 < n (integer)**.  
	```params.time.slotsPerChunk = 100;```
> [!TIP]
> Setting that number over 100 raises simulation time and doesn't yield more precise results.

>  [!WARNING]
> Values lower than 10 give bad results (although running the simulation faster).
2. **Frequency**.  
	```params.carrierDL.centerFrequencyGHz = 2;```
3. **Bandwidth**.  
	```params.transmissionParameters.DL.bandwidthHz = 10e6;```
	
# 3. Seeds
The random processes in the programs use seeds for productivity sake. This modifications is seen in ```networkGeometry.UniformDistribution``` , ```networkGeometry.MovementFunctions``` , and ```networkGeometry.UniformCluster```. To change the seeds open those files and change the value inside the ```rng(n)``` function.

# Submited, but not published
The mentioned paper was submitted to the **43rd Brazilian Symposium on Computer Networks and Distributed Systems (SBRC)** and it's currently in the review phase. If accepted further details will be added to that readme file.
