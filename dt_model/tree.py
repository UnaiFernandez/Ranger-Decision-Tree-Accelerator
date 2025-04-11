from dt_utils import create_data, create_model, classify, get_metrics, export_to_json
import numpy as np
import pandas as pd

def main():

    Y_test = pd.read_csv("play_tenis_test.csv")
    

    x_train = "tenis_train.csv"
    y_train = "play_tenis_train.csv"
    tree = create_model(x_train, y_train)

    pred = classify(tree, "tenis_test.csv")
    get_metrics(tree, pred, Y_test)

    export_to_json("dt.json", tree)

if __name__ == "__main__":
    main()
