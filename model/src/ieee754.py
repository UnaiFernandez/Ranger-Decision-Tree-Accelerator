exponent_bits = 8
mantissa_bits = 20
integer_bits  = 14
fraction_bits = 14


def to_fixed_point(number):
    integer_bin= format(int(abs(number)), "0{}b".format(integer_bits))
    fraction = get_fraction(number)

    if number < 0:
        sign = "1"
        integer = ''.join('1' if bit == '0' else '0' for bit in integer_bin)
        #integer = format((int(integer_bin, 2) + 1), "0{}b".format(integer_bits)) # 2's complement
    else:
        sign = "0"
        integer = integer_bin


    formatted_num = sign + integer + \
           format(fraction, "0{}b".format(fraction_bits))

    return formatted_num, integer, fraction


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

#a1, *_ = to_fixed_point(1.5)
#a2, *_ = to_fixed_point(-1.5)
#
#b1, *_ = to_floating_point(1.5, exponent_bits, mantissa_bits)
#b2, *_ = to_floating_point(-1.5, exponent_bits, mantissa_bits)
#
#print(a1)
#print(a2)
#print(b1)
#print(b2)
#d1, a, b = to_fixed_point(8.5)
#d2, a, b = to_fixed_point(2.3)
#print(d1)
#print(d2)
