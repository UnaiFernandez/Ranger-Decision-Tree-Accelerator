from sklearn import tree, metrics, preprocessing
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import json

from ram_converter import *

y_min = 0
y_max = 0

def split_dataset(fname, train_size):
    data = pd.read_csv(fname, sep = ",", header=None)

    str_to_int = preprocessing.LabelEncoder()
    for column in data:
        if pd.api.types.is_string_dtype(data[column]):
            data[column] = str_to_int.fit_transform(data[column])



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


def train_rf_classifier(x_train, y_train, num_instances):

    classifier = RandomForestClassifier(n_estimators=num_instances,
                                        random_state=42,
                                        min_samples_split=20,
                                        max_depth=8)

    classifier.fit(x_train, y_train)

    #print(forest[-1])
    #print(create_mem_bin_layouts("prueba.txt", forest[-1]))
    return classifier

def train_rf_regression(x_train, y_train, num_instances):

    regression = RandomForestRegressor(n_estimators=num_instances,
                                        random_state=42,
                                       #min_samples_split=20,
                                        max_depth=8)

    regression.fit(x_train, y_train)

    #print(forest[-1])
    #print(create_mem_bin_layouts("prueba.txt", forest[-1]))
    return regression

def create_model(x_train, y_train):

    clf = tree.DecisionTreeClassifier(min_samples_split=20, max_depth=8) #min_samplessplit (default) = 2
    clf = clf.fit(x_train, y_train)
    tree.plot_tree(clf, class_names=True)

    r = tree.export_text(clf)

    plt.show()
    return clf


def classify(clf, x_test):
    prediction = clf.predict(x_test)

    return prediction

def get_metrics(clf, pred, X_test, Y_test):

    print(
	f"Classification report for classifier {clf}:\n"
	f"{metrics.classification_report(Y_test, pred)}\n"
    )


def export_to_hex_ram(clf, classif):
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
        if is_leaves[i] == False:
            node_info['node_id'] = str(i)
            node_info['feature'] = str(feature[i])
            node_info['addr'] = addr
            node_info['threshold'] = str(threshold[i])

            #TODO: Normalize data, and fixed-point representation Q0.10
            #left child
            if is_leaves[children_left[i]]:
                if classif == False:
                    n_val_left = normalize(clf.tree_.value[children_left[i]][0, 0], y_min, y_max)
                    node_info['left_child'] = str((n_val_left << 1) | 1)
                    #print("LEFT: " + str(clf.tree_.value[children_left[i]][0, 0]) + " NORM: " + node_info['left_child'])
                else:
                    node_info['left_child'] = str((cl[children_left[i]] << 1) | 1)
            else:
                node_info['left_child'] = str((children_left[i] << 1) | 0)
            
            if is_leaves[children_right[i]]:
                if classif == False:
                    n_val_right = normalize(clf.tree_.value[children_right[i]][0, 0], y_min, y_max)
                    node_info['right_child'] = str((n_val_right << 1) | 1)
                else:
                    node_info['right_child'] = str((cl[children_right[i]] << 1) | 1)
            else:
                node_info['right_child'] = str((children_right[i] << 1) | 0)

            #node_info['left_child'] = str(children_left[i])
            #node_info['right_child'] = str(children_right[i])
            addr += 2
            #print(node_info)
            tree_dict.append(node_info)

    return tree_dict


def normalize(number, n_min, n_max):

    n_norm = (number - n_min) / (n_max - n_min)    
    n_norm = max(0.0, min(1.0, n_norm))    
    return int(round(n_norm * 1023))

