import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn
import time
from sklearn.datasets import load_iris, load_digits, fetch_california_housing

from ram_converter import *
import dt_utils

import sys


if len(sys.argv) < 3:
    print("[ERROR] Few arguments!")
    exit(1)
elif len(sys.argv) == 2:
    train_size = 0.8
    classification = True
else:
    train_size = float(sys.argv[2])
    if sys.argv[3] == "r":
        classification = False
    else:
        classification = True

dataset = sys.argv[1]
test_size = 1-train_size


if dataset == "datasets/california":
    california = fetch_california_housing()
    X = california.data
    y = california.target
    x_train, x_test, y_train, y_test = sklearn.model_selection.train_test_split(X, y, test_size=0.02)
else:
    x_train, x_test, y_train, y_test = dt_utils.split_dataset(dataset, train_size=train_size)

#print(x_test)

dt_utils.y_min = min(y_train)
dt_utils.y_max = max(y_train)

print("MAX: " + str(dt_utils.y_max) + " MIN: " + str(dt_utils.y_min))



# Training model
num_instances = 128
avg_nodes = 0
max_nodes = 0

start_train = time.time()

if classification:
    rf = dt_utils.train_rf_classifier(x_train, y_train, num_instances)
else:
    rf = dt_utils.train_rf_regression(x_train, y_train, num_instances)

stop_train = time.time()
total_train = stop_train - start_train

# Testing model
start = time.time()
y_pred = rf.predict(x_test)
y_pred = np.round(y_pred, 2)
stop = time.time()
total = stop - start

# Export data to mem layouts
forest_bin = []
forest_hex = []
for i in range(num_instances):
    clf = rf.estimators_[i]
    dt_hex_ram = dt_utils.export_to_hex_ram(clf, classification)
    dt_bin = create_mem_bin_layouts_new_format(dt_hex_ram)
    dt_hex = create_mem_hex_layouts_new_format(dt_hex_ram)
    node_number_hex = format(len(dt_hex), "0{}x".format(6)) + format(i+1, "0{}x".format(2))
    node_number_bin = format(len(dt_bin), "0{}b".format(24)) + format(i+1, "0{}b".format(8))
    dt_bin.insert(0, node_number_bin)
    dt_hex.insert(0, node_number_hex)
    forest_bin.append(dt_bin)
    forest_hex.append(dt_hex)

    avg_nodes += len(dt_bin)-1
    if len(dt_bin)-1 >= max_nodes:
        max_nodes = len(dt_bin)-1 

#print(x_test)

data_mem, data_mem_bin = create_data_mem(x_test)

num_features = len(x_test[0])


if isinstance(y_test, np.ndarray):
    print("¡Sí! y_test es un numpy.ndarray")
else:
    y_test = y_test.to_numpy()

#if classification:
num_labels = len(y_test)
print(num_labels)
#Copy classes to memory
for i in range(len(y_test)):
    #data_mem.append(format(y_test[i], "0{}x".format(8)))
    # Calculate hex value
    y_test_hex, y_test_bin, y_test_fixed = to_fixed_point_new(y_test[i], 15, 16, True)
    #print("Y_TEST: " + str(y_test[i]), "HEX: " + str(y_test_hex))
    data_mem.append(y_test_hex)

#else:
#    num_labels = (len(y_test) << 1) | 0

data_mem.insert(0, format(num_features, "0{}x".format(8)))
data_mem_bin.insert(0, format(num_features, "0{}b".format(32)))



# Wirte mem layouts to files
forest_bin = mat_to_array(forest_bin)
forest_hex = mat_to_array(forest_hex)
forest_hex.insert(0, format(num_labels, "0{}x".format(8)))
forest_bin.insert(0, format(num_labels, "0{}b".format(32)))

if classification:
    accuracy = dt_utils.accuracy_score(y_test, y_pred)
else:
    accuracy = 0

num_elems_hex = format(len(forest_hex)+len(data_mem), "0{}x".format(8))
forest_hex.insert(0, num_elems_hex)

write_to_file(forest_bin + data_mem_bin, "../ranger/memory_content/random_forest_bin.txt")
write_to_file(forest_hex + data_mem, "../ranger/memory_content/random_forest_hex.txt")
write_to_file(forest_hex + data_mem, "./conf/"+dataset.split("/")[1])


print("\nSETTINGS")
print("-------------------------------------------------------")
print("Dataset:                     {}".format(dataset))
print("Training size:               {}".format(train_size))
print("Testing size:                {}".format(round(test_size, 2)))
print("\nTRAINING")
print("-------------------------------------------------------")
print("Number of trees:             {}".format(num_instances))
print("Avg. node number:            {}".format(avg_nodes/num_instances))
print("Max node number:             {}".format(max_nodes))
print("Len config file:             {}".format(len(forest_hex) + len(data_mem)))
print("Feature number:              {}".format(num_features))
print("Total time:                  {} ms".format(round(total_train*1000, 2)))
# numero de trees
print("\nTEST RESULTS")
print("-------------------------------------------------------")
print("Total time:                  {} ms".format(round(total*1000, 2)))
time_to_process = round((total * 1000000) / len(x_test), 2)
print("Average inference time:      {} us".format(time_to_process))

print(f'Accuracy:                    {accuracy * 100:.2f}%')

#conf_matrix = confusion_matrix(y_test, y_pred)
#print(f'\nConfusion matrix:\n {conf_matrix}')

print("y test: {}".format(y_test[0:30]))
print("y pred: {}".format(y_pred[0:30]))


plt.figure(figsize=(6, 6))
plt.scatter(y_test, y_pred, s=8, alpha=0.4)
plt.plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--')
plt.xlabel("Real")
plt.ylabel("Predicho")
plt.title("Real vs Predicho")
plt.show()

plt.figure(figsize=(6, 6))
plt.plot(y_test)
plt.plot(y_pred)
plt.xlabel("Real")
plt.ylabel("Predicho")
plt.title("Real vs Predicho")
plt.show()
