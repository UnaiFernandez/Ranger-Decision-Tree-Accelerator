# DT\_vhdl

Digital system implementation for FPGA in VHDL to inference decision trees.

## Build and simulate system

Compiles all the VHDL files and simulates the system in the specified time.

```bash
$ make
```

To check the simulation results, open *.ghw* file in **GTKWave**.

## Train decision tree

Trains the decision tree using the specified dataset, and creates the memory layouts of the system.

```bash
make tree
```

## Clean

```bash
$ make clean
```


