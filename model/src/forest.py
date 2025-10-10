import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn
import time
from sklearn.datasets import load_iris

from ram_converter import *
from dt_utils import *


#iris = load_iris()
#X = iris.data
#y = iris.target
#x_train, x_test, y_train, y_test = train_test_split(X, y, test_size=0.4)

#x_train, x_test, y_train, y_test = split_dataset("datasets/iris.data", train_size=0.6)
x_train, x_test, y_train, y_test = split_dataset("datasets/heart_attack.data", train_size=0.8)
#x_train, x_test, y_train, y_test = split_dataset("datasets/car.data", train_size=0.8)
#x_train, x_test, y_train, y_test = split_dataset("datasets/obesity.data", train_size=0.8)
#x_train, x_test, y_train, y_test = split_dataset("datasets/wdbc.data", train_size=0.8)
#x_train, x_test, y_train, y_test = split_dataset("datasets/tennis.data", train_size=0.8)

print("[-] Training model")
num_instances = 16

start_train = time.time()
rf = train_forest(x_train, y_train, num_instances)
stop_train = time.time()  
total_train = stop_train - start_train
print("[-] Testing Random Forest")

start = time.time()
y_pred = rf.predict(x_test)
stop = time.time()  
total = stop - start

print("[-] Exporting data to files")
forest = []
for i in range(num_instances):
    clf = rf.estimators_[i]
    dt = export_to_dict_bin(clf)
    dt_bin = create_mem_bin_layouts("filename", dt)
    node_number = format(len(dt_bin), "0{}b".format(24)) + format(i+1, "0{}b".format(8))
    dt_bin.insert(0, node_number)
    forest.append(dt_bin)

    #print("DT {}".format(i))
    #print("nodes: {}".format(len(dt_bin) - 1))

data_mem = create_data_mem(x_test)

num_features = len(x_test[0])
#print("Num features: {}".format(num_features))

data_mem.insert(0, format(num_features, "0{}b".format(32)))
    
#forest[0].insert(0, format(num_instances, "0{}b".format(32)))

# File layout
# 
# Num instances
# Node number
# node
# node ...
# Node number
# ...
# Feature number
# data
# data
# ...

print("[-] Writing memory layouts to txt files")
forest = mat_to_array(forest)
write_to_file(forest + data_mem, "../ranger/memory_content/random_forest.txt")


print("\nTRAINING")
print("-------------------------------------------------------")
print("Total time:                  {} ms".format(round(total_train*1000, 2)))
# numero de trees
print("\nTEST RESULTS")
print("-------------------------------------------------------")
print("Total time:                  {} ms".format(round(total*1000, 2)))
time_to_process = round((total * 1000000) / len(x_test), 2)
print("Average inference time:      {} us".format(time_to_process))

accuracy = accuracy_score(y_test, y_pred)
print(f'Accuracy:                    {accuracy * 100:.2f}%')

conf_matrix = confusion_matrix(y_test, y_pred)
print(f'\nConfusion matrix:\n {conf_matrix}')

print("y test: {}".format(y_test.to_numpy()[0:15]))
print("y pred: {}".format(y_pred[0:15]))
