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

    return f'{code:03b}'

def write_to_file(list, filename):
    with open(filename, "w") as f:
        if f.write('\n'.join(str(i) for i in list)):
            print("[SUCCESS] Data writen to {}".format(filename))


def create_mem_layouts(filename):

    node_mem = []
    link_mem = []
    l_node_id = []
    node_addr = []
    
    addr = 0
    link_addr_base = 0


    with open(filename, "r") as f:
        data = json.load(f)


    
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
                ch_value, *_ = to_floating_point(float(ch['value']))
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
    feature_list = []
    col = len(data.columns)
    row = len(data.index)
    for r in range(0, row):
        for c in range(0, col):
            feature = data.iat[r, c]
            feature_list.append(format(feature, "032b"))
            #print("{} ---> {}".format(data.iat[r, c], format(feature, "032b")))

    #print(feature_list)
    return feature_list
