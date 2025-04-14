import json
from ieee754 import *

file = "dt.json"


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



with open(file, "r") as f:
    data = json.load(f)

addr = 0
link_mem = []
node_mem = []
l_node_id = []
node_addr = []
link_addr = 0
link_addr_base = 0
new_link_addr_base = 0

for node in data:
    node_id = int(node['node_id'])
    try:
        feature = int(node['feature'])
        feat_c = f"feature: {feature}"
        new_link_addr_base = new_link_addr_base + len(node['childs'])
        hex_info = f'{link_addr_base:016b}'+f'{feature*2:016b}'
        print("node ID: {node_id} link_addr_base: {l}, {feat_c} -----> 0x{addr} {h}".format(node_id=node_id, addr=f'{addr:04X}', feat_c=feat_c, l=link_addr_base, h=hex_info))
        node_mem.append(hex_info)
        node_addr.append(addr)
        for ch in node['childs']:
            addr += 1
            ch_node_id = int(ch['node_id'])
            ch_comp = get_code(ch['cond'])
            ch_value, sign, exp, mantissa = to_ieee754_format(float(ch['value']))
            hex_val = ch_value+ch_comp
            f_val = (-1)**(sign) * (1 + mantissa) * (2**(exp-127))
            print("value: {val}, cmd: {cmd}                      -----> 0x{addr} {h}".format(val=f_val, cmd=ch_comp, addr=f'{addr:04X}', h=hex_val))
            node_mem.append(hex_val)
            l_node_id.append(ch_node_id)
           
    except:
        c = int(node['class'])
        feat_c = f"class: {c}  "
        hex_info = f'{link_addr_base:016b}'+f'{(c*2)+1:016b}'
        node_mem.append(hex_info)
        node_addr.append(addr)
        print("node ID: {node_id}link_addr_base: {l}, {feat_c} -----> 0x{addr} {h}".format(node_id=node_id, addr=f'{addr:04X}', feat_c=feat_c, l=link_addr_base, h=hex_info))

    link_addr_base = new_link_addr_base
    addr += 1

#print("link_mem: {}".format(node_addr))
#print("link_mem: {}".format(l_node_id))

for n in l_node_id:
    link_mem.append(f'{node_addr[n]:016b}')
    
write_to_file(node_mem, "node_mem_content.txt")
write_to_file(link_mem, "link_mem_content.txt")
#print("link_mem: {}".format(link_mem))
