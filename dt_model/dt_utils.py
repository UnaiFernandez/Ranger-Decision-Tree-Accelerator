from sklearn import tree, metrics, preprocessing
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import json

def create_data(fname="wdbc.data"):
    data = np.loadtxt(fname, delimiter=",")

    train = data[:data.shape[0]//4*3, :]
    test = data[data.shape[0]//4*3:, :]

    X_train = train[:, 2:]
    X_test = test[:, 2:]

    Y_train = train[:, 1:2]
    Y_test = test[:, 1:2]

    np.savetxt("x_train.csv", X_train, delimiter=",")
    np.savetxt("x_test.csv", X_test, delimiter=",")

    np.savetxt("y_train.csv", Y_train, delimiter=",")
    np.savetxt("y_test.csv", Y_test, delimiter=",")


def create_model(x_train, y_train):
    X = pd.read_csv(x_train)
    Y = pd.read_csv(y_train)
    #X = np.loadtxt(x_train, delimiter=",")
    #Y = np.loadtxt(y_train, delimiter=",")

    str_to_int = preprocessing.LabelEncoder()
    X = X.apply(str_to_int.fit_transform)
    Y = Y.apply(str_to_int.fit_transform)

    clf = tree.DecisionTreeClassifier()
    clf = clf.fit(X, Y)
    #tree.plot_tree(clf, class_names=True)

    r = tree.export_text(clf)

    #plt.show()
    return clf


def classify(clf, x_test):
    X_test = pd.read_csv(x_test)
    #X_test = np.loadtxt(x_test, delimiter=",")
    str_to_int = preprocessing.LabelEncoder()
    X_test = X_test.apply(str_to_int.fit_transform)

    prediction = clf.predict(X_test)

    return prediction

def get_metrics(clf, pred, Y_test):
    str_to_int = preprocessing.LabelEncoder()
    Y_test = Y_test.apply(str_to_int.fit_transform)


    print(
	f"Classification report for classifier {clf}:\n"
	f"{metrics.classification_report(Y_test, pred)}\n"
    )

def export_to_json(filename, clf):
    tree_dict = []
    n_nodes = clf.tree_.node_count
    children_left = clf.tree_.children_left
    children_right = clf.tree_.children_right
    feature = clf.tree_.feature
    threshold = clf.tree_.threshold
    values = clf.tree_.value

    node_depth = np.zeros(shape=n_nodes, dtype=np.int64)
    is_leaves = np.zeros(shape=n_nodes, dtype=bool)

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
            node_info['class'] = str(i)
        else:
            node_info['node_id'] = str(i)
            node_info['feature'] = str(feature[i])
            childs = []
            c = {}
            c['node_id'] = str(children_left[i])
            c['cond'] = "<="
            c['value'] = str(threshold[i])
            childs.append(c)
            c = {}
            c['node_id'] = str(children_right[i])
            c['cond'] = ">"
            c['value'] = str(threshold[i])
            childs.append(c)
            node_info['childs'] = childs

        tree_dict.append(node_info)
    json_file_content = json.dumps(tree_dict, indent=4)

    with open(filename, "w") as f:
        if f.write(json_file_content+"\n"):
            print("[SUCCESS] Exported to {filename}".format(filename=filename))
        else:
            print("[ERROR] Exporting to JSON.")
