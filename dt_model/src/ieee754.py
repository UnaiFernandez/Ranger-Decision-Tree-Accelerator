exponent_bits = 8
mantissa_bits = 20
integer_bits  = 15
fraction_bits = 16


def to_fixed_point(number):
    if number < 0:
        sign = "1"
    else:
        sign = "0"

    integer = int(abs(number))
    fraction = int((number % 1)*10000)

    formatted_num = sign + format(integer, "0{}b".format(integer_bits)) + \
           format(fraction, "0{}b".format(fraction_bits))

    return formatted_num, integer, fraction


def to_floating_point(number):
    if number < 0:
        sign = "1"
    else:
        sign = "0"

    exponent, num = get_exponent(number)
    #print("Number: {} Exp: {}".format(num, exponent))

    mantissa = get_mantissa(num)

    formatted_num = sign + format(exponent, "0{}b".format(exponent_bits)) \
            + format(mantissa, "0{}b".format(mantissa_bits))

    return formatted_num, sign, exponent, mantissa


def get_exponent(number):
    exp = 0
    num = abs(number)

    while num < 1 or num >= 2:
        num = abs(number)
        num = num / (2**(exp))       
        if num < 1:
            exp -= 1
        elif num >= 2:
            exp += 1

    exp = exp + (2**(exponent_bits - 1) - 1)
    return exp, num


def get_mantissa(number):
    cont = 0
    num = number % 1
    bin = 0

    while cont < mantissa_bits:
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
