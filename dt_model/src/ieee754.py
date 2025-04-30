exponent_bits = 8
mantissa_bits = 20
integer_bits  = 15
fraction_bits = 16


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
    if number < 0:
        sign = "1"
    else:
        sign = "0"

    exponent, num = get_exponent(number, exp_bits)
    #print("Number: {} Exp: {}".format(num, exponent))

    mantissa = get_mantissa(num, m_bits)

    formatted_num = sign + format(exponent, "0{}b".format(exp_bits)) \
            + format(mantissa, "0{}b".format(m_bits))

    return formatted_num, sign, exponent, mantissa


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


#d1, a, b = to_fixed_point(8.5)
#d2, a, b = to_fixed_point(2.3)
#print(d1)
#print(d2)
