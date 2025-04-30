from dt_utils import *
from ram_converter import *
import pandas as pd

def main():

    print("[-] Training decision tree")
    x_train = "datasets/tenis_train.csv"
    y_train = "datasets/play_tenis_train.csv"
    tree = create_model(x_train, y_train)

    print("[-] Testing decision tree")
    pred, X_test = classify(tree, "datasets/tenis_test.csv")
    print(X_test)
    Y_test = pd.read_csv("datasets/play_tenis_test.csv")
    get_metrics(tree, pred, X_test, Y_test)

    print("-------------------------------------------------------")
    print("[-] Exporting data to json")
    export_to_json("dt.json", tree)

    print("[-] Creating memory layouts")
    node_mem, link_mem = create_mem_layouts("dt.json")
    data_mem = create_data_mem(X_test)

    print("[-] Writing memory layouts to txt files")
    write_to_file(node_mem, "../memory_content/node_mem_content.txt")
    write_to_file(link_mem, "../memory_content/link_mem_content.txt")
    write_to_file(data_mem, "../memory_content/data_mem_content.txt")


if __name__ == "__main__":
    main()
