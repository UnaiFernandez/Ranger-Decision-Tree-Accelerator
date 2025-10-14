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
The needed libraries are listed in x file.
- numpy 
- pandas
- matplotlib
- json
- sklearn (metrics, treem preprocessing, ensemble, model\_selection, datasets)
## Datasets
- Heart attack
- Diabetes
- Iris
## Configuration file
### Todo:
add a file to configure the python script. or a prompt.
## Ranger (vhdl)
## Model (python)
## Execution instructions
## Results
## Author
Unai Fernandez
## License


----------------------------------------------------
## OLD

Random forest architecture implementation on FPGA. 

## Params

HW accelerator (FPGA):

- Classes: 64
- Trees: 255
- Mem nodes depth: 255
- Internal mem depth: 255
- data mem depth: 512

------------
- clock: 125 MHz (8 ns) (*This would be ideal to compare the results*)

Training script:

Datasets:

- Iris
- MNIST
- Diabetes
- Heart attack
- Lung Cancer
- Anemia


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


