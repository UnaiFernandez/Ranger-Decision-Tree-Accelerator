import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn
import time

from ram_converter import *
from dt_utils import *



#x_train, x_test, y_train, y_test = split_dataset("datasets/iris.data", 0.8)
x_train, x_test, y_train, y_test = split_dataset("datasets/car.data", train_size=0.8)

print("[-] Training model")
num_instances = 3
rf = train_forest(x_train, y_train, num_instances)

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
    node_number = format(len(dt_bin), "0{}b".format(24)) + format(i, "0{}b".format(8))
    dt_bin.insert(0, node_number)
    forest.append(dt_bin)

data_mem = create_data_mem(x_test)
    
forest[0].insert(0, format(num_instances, "0{}b".format(32)))

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
write_to_file(forest + data_mem, "../ranger/memory_content/prueba.txt")




print("\nTEST RESULTS")
print("-------------------------------------------------------")
print("total time:                  {} ms".format(round(total*1000, 2)))
time_to_process = round((total * 1000000) / len(x_test), 2)
print("instance processing time:    {} us".format(time_to_process))

accuracy = accuracy_score(y_test, y_pred)
print(f'Accuracy:        {accuracy * 100:.2f}%')

conf_matrix = confusion_matrix(y_test, y_pred)
print(f'\nConfusion matrix: {conf_matrix}')
