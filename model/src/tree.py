from dt_utils import *
from ram_converter import *
import pandas as pd
import time

def main():
    x_train, x_test, y_train, y_test = split_dataset("datasets/iris_2.data", 0.8)
    print(x_test)
    print("[-] Training decision tree")
    tree = create_model(x_train, y_train)

    print("[-] Testing decision tree")
    start = time.time()
    pred = classify(tree, x_test)
    stop = time.time()
    total = stop - start
    get_metrics(tree, pred, x_test, y_test)

    print("-------------------------------------------------------")
    print("total time:                                     {} ms\n".format(round(total*1000, 2)))

    print("[-] Exporting data to json")
    t_dict = export_to_dict(tree)
    t_dict_bin = export_to_dict_bin(tree)
    #export_to_json("dt.json", t_dict)

    print("[-] Creating memory layouts")
    node_mem, link_mem = create_mem_layouts("dt.json", t_dict)
    bin_node_mem = create_mem_bin_layouts("dt.json", t_dict_bin)
    #data_mem = create_data_mem(x_test)

    print(bin_node_mem)

    #TODO: Add dt_id correctly
    node_count = format(len(bin_node_mem), "0{}b".format(24)) + format(1, "0{}b".format(8))
    
    #span = format(len(x_test.columns), "0{}b".format(32))

    print("[-] Writing memory layouts to txt files")
    write_to_file(bin_node_mem, "../ranger/memory_content/prueba_bin_node_mem_content.txt")
    write_to_file(node_mem, "bin_dt/memory_content/node_mem_content.txt")
    write_to_file(link_mem, "bin_dt/memory_content/link_mem_content.txt")
    write_to_file(data_mem, "bin_dt/memory_content/data_mem_content.txt")
    bin_node_mem.insert(0, node_count)
    write_to_file(bin_node_mem + data_mem, "bin_dt/memory_content/mixed.txt")


if __name__ == "__main__":
    main()
