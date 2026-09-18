import json
from ieee754 import *


def get_code(sign):
    if sign == "=":
        code = 1
    elif sign == ">":
        code = 2
    elif sign == "<":
        code = 4
    elif sign == "<=":
        code = 5
    elif sign == ">=":
        code = 3

    #return f'{code:03b}'
    return code*2

def write_to_file(list, filename):
    with open(filename, "w") as f:
        for i in list:
            f.write("".join(str(i) + "\n"))
        #print("[SUCCESS] Data writen to {}".format(filename))

def mat_to_array(mat):
    l = []
    for dt in mat:
        for i in dt:
            l.append(i)

    return l



def find_node(data, id):
    addr = 0
    for node in data:
        if node['node_id'] == id:
            addr = node['addr']
    return addr


def create_mem_bin_layouts_new_format( t_dict):
    node_mem = []
    l_node_id = []
    node_addr = []

    addr = 0

    data = t_dict



    for node in data:
        node_id = int(node['node_id'])
        try:
            feature = int(node['feature'])
            if int(node['right_child']) & 1:
                right_addr = int(node['right_child'])
            else:
                right_addr = (find_node(data, str(int(node['right_child']) >> 1)) << 1) | 0
            if int(node['left_child']) & 1:
                left_addr = int(node['left_child'])
            else:
                left_addr = (find_node(data, str(int(node['left_child']) >> 1)) << 1) | 0
            #right_addr = find_node(data, node['right_child'])
            #left_addr = find_node(data, node['left_child'])
            #threshold, threshold_bin, *_ = to_floating_point(float(node['threshold']), 8, 23)
            threshold, threshold_bin, *_ = to_fixed_point_new(float(node['threshold']), 15, 16, True)
            node_info = (left_addr << 21) | (right_addr << 10) | feature
            node_info = f'{node_info:032b}'
            #node_info = f'{right_addr:04x}'+f'{feature:04x}'
            node_mem.append(node_info)
            node_mem.append(threshold_bin)
        except:
            c = int(node['class'])
            hex_info = f'{0:016b}'+f'{(c*2)+1:016b}'
            node_mem.append(hex_info)
            node_addr.append(addr)

            #print("Node ID: {} link_base: {} class: {} leaf: {}".format(
            #        node_id, link_addr_base, c, 1))

        addr += 1

    #print("link_mem: {}".format(node_addr))
    #print("link_mem: {}".format(l_node_id))

    for n in l_node_id:
        link_mem.append(f'{node_addr[n]:04x}')

    return node_mem

def create_mem_hex_layouts_new_format( t_dict):
    node_mem = []
    l_node_id = []
    node_addr = []

    addr = 0

    data = t_dict


    for node in data:
        node_id = int(node['node_id'])
        try:
            feature = int(node['feature'])
            if int(node['right_child']) & 1:
                right_addr = int(node['right_child'])
            else:
                right_addr = (find_node(data, str(int(node['right_child']) >> 1)) << 1) | 0
            if int(node['left_child']) & 1:
                left_addr = int(node['left_child'])
            else:
                left_addr = (find_node(data, str(int(node['left_child']) >> 1)) << 1) | 0
            #right_addr = find_node(data, node['right_child'])
            #left_addr = find_node(data, node['left_child'])
            #threshold, *_ = to_floating_point(float(node['threshold']), 8, 23)
            threshold, *_ = to_fixed_point_new(float(node['threshold']), 15, 16, True)
            node_info = (left_addr << 21) | (right_addr << 10) | feature
            node_info = f'{node_info:08x}'
            #node_info = f'{right_addr:04x}'+f'{feature:04x}'
            node_mem.append(node_info)
            node_mem.append(threshold)
        except:
            c = int(node['class'])
            hex_info = f'{0:04x}'+f'{(c*2)+1:04x}'
            print("hex_info: " + str(hex_info))
            node_mem.append(hex_info)
            node_addr.append(addr)

            #print("Node ID: {} link_base: {} class: {} leaf: {}".format(
            #        node_id, link_addr_base, c, 1))

        addr += 1

    #print("link_mem: {}".format(node_addr))
    #print("link_mem: {}".format(l_node_id))

    for n in l_node_id:
        link_mem.append(f'{node_addr[n]:04x}')

    return node_mem

def create_data_mem(data):
    threshold_list = []
    threshold_list_bin = []
    col = len(data[0])
    row = len(data)
    for r in range(0, row):
        for c in range(0, col):
            #threshold, threshold_bin, *_ = to_floating_point(float(data[r, c]), 8, 23)
            #print(float(data[r, c]))
            threshold, threshold_bin, *_ = to_fixed_point_new(float(data[r, c]), 15, 16, True)
            #print(str(data[r, c]) + "HEX: " + str(threshold))
            threshold_list.append(threshold);
            threshold_list_bin.append(threshold_bin);

    return threshold_list, threshold_list_bin
