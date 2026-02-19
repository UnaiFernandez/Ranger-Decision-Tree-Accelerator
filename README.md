# RANGER - FPGA-based Energy-efficient Decision Tree Ensemble Accelerator

The growing complexity of artificial intelligence techniques and the increasing size of modern datasets have led to a substantial rise in energy consumption in conventional implementations optimized for CPUs and GPUs. Field Programmable Gate Arrays represent a promising alternative, as they enable customized hardware acceleration that improves both latency and performance while maintaining high energy efficiency. This paper presents an FPGA-based architecture for accelerating tree ensemble inference, with emphasis on energy efficiency and resource optimization. The  proposed system integrates a Python-based training workflow that generates a flexible configuration file, enabling adaptable deployment across varying numbers of trees and datasets characteristics. The architecture exploits fine-grained parallelism by executing decision trees concurrently and aggregating their predictions through a hardware-based majority voting scheme. Experimental evaluation on a Zynq-based platform demonstrates low resource utilization, requiring less than 4% flip-flops and 16% LUTs, while  BRAM becomes the main limiting factor, reaching 70\% for a 64-tree configuration.
The total power dissipation is approximately 1.6 W of which only 0.2 W corresponds to the programmable logic implementing the accelerator.
Finally, we found competitive inference latency compared to related FPGA implementations. These results confirm the suitability of the design for energy-constrained embedded AI applications.

## Directory structure
- **ranger:** Hardware implementation files
- **model:** 
- **AXI_test:** 
## Dependencies

The needed libraries are listed in [deps.txt](model/deps.txt) file.

## Datasets
All the datasets used for the project can be found in [model/datasets](model/datasets) directory.

> Note: To use custom datasets to train the model, the last column in the dataset has to cointain the target.

## Execution instructions
### Train decision tree

Trains the decision tree using the specified dataset, and creates the memory layouts of the system.

```bash
python3 model/src/forest.py
```

## Author
Unai Fernandez
## License
