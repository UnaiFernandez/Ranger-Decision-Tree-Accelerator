exponent_bits = 8
mantissa_bits = 20
integer_bits  = 15
fraction_bits = 16

def to_signed(number):
    rounded_number = number * (2^16)
    integer_bin= format(int(abs(rounded_number)), "0{}b".format(31))

    if number < 0:
        sign = "1"
        integer = ''.join('1' if bit == '0' else '0' for bit in integer_bin)
    else:
        sign = "0"
        integer = integer_bin

    formatted_num_bin = sign + integer
    formatted_num = format(int(formatted_num_bin, 2), "0{}x".format(8))

    return formatted_num, formatted_num_bin, integer


def to_fixed_point(number, i_bits, fr_bits):
    integer_bin= format(int(abs(number)), "0{}b".format(i_bits))
    fraction = get_fraction(number)

    if number < 0:
        sign = "1"
        integer = ''.join('1' if bit == '0' else '0' for bit in integer_bin)
        #integer = format((int(integer_bin, 2) + 1), "0{}b".format(i_bits)) # 2's complement
    else:
        sign = "0"
        integer = integer_bin


    if i_bits == 0:
        formatted_num_bin = sign + format(fraction, "0{}b".format(fr_bits))
    else:
        formatted_num_bin = sign + integer + format(fraction, "0{}b".format(fr_bits))

    formatted_num = format(int(formatted_num_bin, 2), "0{}x".format(8))

    return formatted_num, formatted_num_bin, integer, fraction


def get_fraction(number):
    cont = 0
    num = number % 1
    bin = 0

    while cont < fraction_bits:
        if num == 1:
            bin = bin << 1
            bin = bin | 0
        else:
            res = num * 2
            num = res % 1
            bin = bin << 1
            bin = bin | int(res)
            cont += 1

    return bin


def to_floating_point(number, exp_bits, m_bits):
    exponent, num = get_exponent(number, exp_bits)
    #print("Number: {} Exp: {}".format(num, exponent))

    mantissa = get_mantissa(num, m_bits)

    #print(str(exponent*(2**m_bits))+" "+str(mantissa))
    #formatted_num = format(exponent, "0{}x".format(exp_bits)) \
     #       + format(mantissa*2, "0{}x".format(m_bits))

    if number < 0:
        num = (1*(2**31)) + (exponent*(2**m_bits)) + mantissa;
        sign = "1"
    else:
        num = ((exponent*(2**m_bits)) + mantissa);
        sign = "0"

    formatted_num = format(num, "0{}x".format(8))
    formatted_num_bin = format(num, "0{}b".format(32))

    return formatted_num, formatted_num_bin, sign, exponent, mantissa


def get_exponent(number, exp_bits):
    exp = 0
    num = abs(number)

    while num < 1 or num >= 2:
        num = abs(number)
        num = num / (2**(exp))
        if num < 1 and num != 0:
            exp -= 1
        elif num >= 2:
            exp += 1
        elif num == 0:
            return 0, 0

    exp = exp + (2**(exp_bits - 1) - 1)
    return exp, num


def get_mantissa(number, m_bits):
    cont = 0
    num = number % 1
    bin = 0

    while cont < m_bits:
        if num == 1:
            bin = bin << 1
            bin = bin | 0
        else:
            res = num * 2
            num = res % 1
            bin = bin << 1
            bin = bin | int(res)
            cont += 1

    return bin


def to_fixed_point_new(number, i_bits, fr_bits, signed=True):
    scale = 1 << fr_bits

    if signed:
        total_bits = 1 + i_bits + fr_bits   # 1 bit de signo
        min_val = -(1 << i_bits)
        max_val = (1 << i_bits) - (1 / scale)
    else:
        total_bits = i_bits + fr_bits
        min_val = 0
        max_val = (1 << i_bits) - (1 / scale)

    if not (min_val <= number <= max_val):
        raise ValueError(f"Fuera de rango para este formato: [{min_val}, {max_val}]")

    fixed = round(number * scale)

    if signed and fixed < 0:
        fixed = (1 << total_bits) + fixed   # complemento a 2

    mask = (1 << total_bits) - 1
    fixed &= mask

    binary = format(fixed, f"0{total_bits}b")
    hexa = format(fixed, f"0{(total_bits + 3)//4}X")

    return hexa, binary, fixed


#a1f, a1, inte = to_fixed_point_new(0.672, 0, 10, False)
#b1f, b1, inteb = to_fixed_point_new(0.925, 0, 10, False)
#print("A:")
#print(a1)
#print(a1f)
#print(inte)
#print("B:")
#print(b1)
#print(b1f)
#print(inteb)
#a1f, a1, inte = to_fixed_point_new(-43.354, 15, 16, True)
#b1f, b1, inteb = to_fixed_point_new(11.225, 15, 16, True)
#print("A:")
#print(a1)
#print(a1f)
#print(inte)
#print("B:")
#print(b1)
#print(b1f)
#print(inteb)
#print(fra)
#print(a2)
#print(b1)
#print(b2)
#d1, a, b = to_fixed_point(8.5)
#d2, a, b = to_fixed_point(2.3)
#print(d1)
#print(d2)
