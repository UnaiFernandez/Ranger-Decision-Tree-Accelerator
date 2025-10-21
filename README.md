# RANGER - (El titulo principal)

## Directory structure
- **ranger:** Hardware implementation files
    - **src:** VHLD source files
    - **test:** Module test files
    - **bin:** Module binaries
    - **memory_files:** txt files containing memory layout for the system.
- **model:** 
    - **datasets:**
    - **src:**
## Dependencies

The needed libraries are listed in [deps.txt](model/deps.txt) file.

## Datasets
All the datasets used for the project can be found in [model/datasets](model/datasets) directory.

> Note: To use custom datasets to train the model, the last column in the dataset has to cointain the target.
## Configuration file
### Todo:
add a file to configure the python script. or a prompt.
## Ranger (vhdl)

- Classes: 64
- Trees: 255
- Mem nodes depth: 255
- Internal mem depth: 255
- data mem depth: 512
- clock: 125 MHz (8 ns) (*This would be ideal to compare the results*)

## Model (python)
## Execution instructions
## Build and simulate system

Compiles all the VHDL files and simulates the system in the specified time.

```bash
$ make
```

To check the simulation results, open *.ghw* file in **GTKWave**.

### Train decision tree

Trains the decision tree using the specified dataset, and creates the memory layouts of the system.

```bash
make tree
```

### Clean

```bash
$ make clean
```

## Results
Used FPGA resources:

|      | 16 trees | 32 trees | 64 trees | 128 trees |
|------|----------|----------|----------|-----------|
| LUTs |          |          |          |           |
| FF   |          |          |          |           |
| I/O  |          |          |          |           |
| BRAM |          |          |          |           |

Power consumption:

## Author
Unai Fernandez
## License
