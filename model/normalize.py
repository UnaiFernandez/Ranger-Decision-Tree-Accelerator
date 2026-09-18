import numpy as np
import sys
import pandas as pd


if len(sys.argv) < 1:
    print("[ERROR] Few arguments!")
    exit(1)
else:
    filename = sys.argv[1]

print(filename)

data = pd.read_csv(filename, sep = ",", header=None)


# Separar features con target
x = data.iloc[:, :-1]
y = data.iloc[:, -1]
print(type(y))

print(y)

max_y = max(y)
min_y = min(y)

print(max_y)
print(min_y)

y_norm = []

for num in y:
    temp = round((num - min_y)/(max_y - min_y), 4)
    y_norm.append(temp)

y_norm = pd.Series(y_norm)

print(y_norm)
print(type(data))

x[x.shape[1]] = y_norm.values
print(data)
print(type(x))
print(x)

x.to_csv("output.data", index=False, header=False)
