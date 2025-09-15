import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sklearn

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.ensemble import RandomForestClassifier
from sklearn import tree, metrics, preprocessing

from ram_converter import *

def split_dataset(fname, train_size):
    print("[-] Reading data from {}".format(fname))
    print("     - Training size: {}%".format(train_size * 100))
    print("     - Testing size: {}%".format((1 - train_size) * 100))

    data = pd.read_csv(fname, sep = ",", header=None)
    print(data)
    
    str_to_int = preprocessing.LabelEncoder()
    for column in data:
        if pd.api.types.is_string_dtype(data[column]):
            data[column] = str_to_int.fit_transform(data[column])


    print(data)

    # Separar features con target
    x = data.iloc[:, :-1]
    y = data.iloc[:, -1]

    # Separar en sets de training y test
    # test_size, es el porcentaje del dataset
    # random state, es un random number generator de 0 a 42
    X_train, X_test, y_train, y_test = train_test_split(x, y, train_size=train_size, random_state=42)

    # Se escalan los features para que esten en una escala similar.
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)

    return X_train, X_test, y_train, y_test


def train_model(x_train, y_train):
    classifier = RandomForestClassifier(n_estimators=10, random_state=42, min_samples_split=20, max_depth=5)
    classifier.fit(X_train, y_train)

    forest = []
    for i in range(3):
        clf = classifier.estimators_[i]
        tree.plot_tree(clf, class_names=True)
        dt = export_to_dict_bin(clf)
        forest.append(dt)

    plt.show()
    
    print(forest[-1])
    print(create_mem_bin_layouts("prueba.txt", forest[-1]))
    return classifier

def export_to_dict_bin(clf):
    tree_dict = []
    n_nodes = clf.tree_.node_count
    children_left = clf.tree_.children_left
    children_right = clf.tree_.children_right
    feature = clf.tree_.feature
    threshold = clf.tree_.threshold
    values = clf.tree_.value
    cl = clf.tree_.value.argmax(axis=2).flatten()

    node_depth = np.zeros(shape=n_nodes, dtype=np.int64)
    is_leaves = np.zeros(shape=n_nodes, dtype=bool)

    addr = 0
    stack = [(0, 0)]  # start with the root node id (0) and its depth (0)
    while len(stack) > 0:
        # `pop` ensures each node is only visited once
        node_id, depth = stack.pop()
        node_depth[node_id] = depth

        # If the left and right child of a node is not the same we have a split
        # node
        is_split_node = children_left[node_id] != children_right[node_id]
        # If a split node, append left and right children and depth to `stack`
        # so we can loop through them
        if is_split_node:
            stack.append((children_left[node_id], depth + 1))
            stack.append((children_right[node_id], depth + 1))
        else:
            is_leaves[node_id] = True

    for i in range(n_nodes):
        node_info = {}
        if is_leaves[i]:
            node_info['node_id'] = str(i)
            node_info['class'] = str(cl[i])
            node_info['addr'] = addr
        else:
            node_info['node_id'] = str(i)
            node_info['feature'] = str(feature[i])
            node_info['addr'] = addr
            node_info['threshold'] = str(threshold[i])
            node_info['left_child'] = str(children_left[i])
            node_info['right_child'] = str(children_right[i])
            addr += 1
        addr += 1
        tree_dict.append(node_info)

    return tree_dict
#X_train, X_test, y_train, y_test = split_dataset("datasets/iris.data", 0.8)
X_train, X_test, y_train, y_test = split_dataset("datasets/car.data", 0.2)

rf = train_model(X_train, y_train)

y_pred = rf.predict(X_test)

accuracy = accuracy_score(y_test, y_pred)
print(f'Accuracy: {accuracy * 100:.2f}%')


