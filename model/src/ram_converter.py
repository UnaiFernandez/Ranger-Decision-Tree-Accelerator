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
        print("[SUCCESS] Data writen to {}".format(filename))

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

def create_mem_bin_layouts(t_dict):
    node_mem = []
    l_node_id = []
    node_addr = []

    addr = 0
    data = t_dict



    for node in data:
        node_id = int(node['node_id'])
        try:
            feature = int(node['feature'])
            right_addr = find_node(data, node['right_child'])
            threshold, threshold_bin, *_ = to_floating_point(float(node['threshold']), 8, 23)
            node_info = f'{right_addr:016b}'+f'{feature*2:016b}'
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
        link_mem.append(f'{node_addr[n]:016b}')

    return node_mem

def create_mem_hex_layouts( t_dict):
    node_mem = []
    l_node_id = []
    node_addr = []

    addr = 0

    #with open(filename, "r") as f:
    #    data = json.load(f)
    data = t_dict



    for node in data:
        node_id = int(node['node_id'])
        try:
            feature = int(node['feature'])
            right_addr = find_node(data, node['right_child'])
            threshold, *_ = to_floating_point(float(node['threshold']), 8, 23)
            node_info = f'{right_addr:04x}'+f'{feature*2:04x}'
            node_mem.append(node_info)
            node_mem.append(threshold)
        except:
            c = int(node['class'])
            hex_info = f'{0:04x}'+f'{(c*2)+1:04x}'
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




def create_mem_layouts(filename, t_dict):

    node_mem = []
    link_mem = []
    l_node_id = []
    node_addr = []

    addr = 0
    link_addr_base = 0


    #with open(filename, "r") as f:
    #    data = json.load(f)
    data = t_dict



    for node in data:
        node_id = int(node['node_id'])
        try:
            feature = int(node['feature'])
            hex_info = f'{link_addr_base:016b}'+f'{feature*2:016b}'

            #print("Node ID: {} link_base: {} feature: {} leaf: {}".format(
            #        node_id, link_addr_base, feature, 0))

            node_mem.append(hex_info)
            node_addr.append(addr)
            link_addr_base = link_addr_base + len(node['childs'])
            for ch in node['childs']:
                addr += 1
                ch_node_id = int(ch['node_id'])
                ch_comp = get_code(ch['cond'])
                ch_value, *_ = to_floating_point(float(ch['value']), 8, 20)
                #ch_value, *_ = to_floating_point(float(ch['value']))
                hex_val = ch_value+ch_comp
                #f_val = (-1)**(sign) * (1 + mantissa) * (2**(exp-127))
            #    print("Value: {} --> {} cmd: {}".format(
            #       float(ch['value']), ch_value, ch_comp))
                node_mem.append(hex_val)
                l_node_id.append(ch_node_id)

        except:
            c = int(node['class'])
            hex_info = f'{link_addr_base:016b}'+f'{(c*2)+1:016b}'
            node_mem.append(hex_info)
            node_addr.append(addr)

            #print("Node ID: {} link_base: {} class: {} leaf: {}".format(
            #        node_id, link_addr_base, c, 1))

        addr += 1

    #print("link_mem: {}".format(node_addr))
    #print("link_mem: {}".format(l_node_id))

    for n in l_node_id:
        link_mem.append(f'{node_addr[n]:016b}')

    return node_mem, link_mem


def create_data_mem(data):
    threshold_list = []
    threshold_list_bin = []
    col = len(data[0])
    row = len(data)
    for r in range(0, row):
        for c in range(0, col):
            threshold, threshold_bin, *_ = to_floating_point(float(data[r, c]), 8, 23)
            threshold_list.append(threshold);
            threshold_list_bin.append(threshold_bin);

    return threshold_list, threshold_list_bin
