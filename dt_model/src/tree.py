from dt_utils import *
from ram_converter import *
import pandas as pd
import time 

def main():

    print("[-] Training decision tree")
    x_train = "dt_model/datasets/x_train.csv"
    y_train = "dt_model/datasets/y_train.csv"
    tree = create_model(x_train, y_train)

    print("[-] Testing decision tree")
    start = time.time()
    pred, X_test = classify(tree, "dt_model/datasets/x_test.csv")
    stop = time.time()
    total = stop - start
    Y_test = pd.read_csv("dt_model/datasets/y_test.csv", header=None)
    get_metrics(tree, pred, X_test, Y_test)

    print("-------------------------------------------------------")
    print("total time:                                     {} ms\n".format(round(total*1000, 2)))
    print("[-] Exporting data to json")
    t_dict = export_to_dict(tree)
    t_dict_bin = export_to_dict_bin(tree)
    #export_to_json("dt.json", t_dict)

    print("[-] Creating memory layouts")
    node_mem, link_mem = create_mem_layouts("dt.json", t_dict)
    bin_node_mem = create_mem_bin_layouts("dt.json", t_dict_bin)
    data_mem = create_data_mem(X_test)

    print("[-] Writing memory layouts to txt files")
    write_to_file(node_mem, "memory_content/node_mem_content.txt")
    write_to_file(bin_node_mem, "memory_content/bin_node_mem_content.txt")
    write_to_file(link_mem, "memory_content/link_mem_content.txt")
    write_to_file(data_mem, "memory_content/data_mem_content.txt")


if __name__ == "__main__":
    main()
