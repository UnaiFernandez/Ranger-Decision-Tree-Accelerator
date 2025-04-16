exponent_bits = 8
mantissa_bits = 20


def to_ieee754_format(number):
    if number < 0:
        sign = 1
    else:
        sign = 0

    exponent, num = get_exponent(number)
    #print("Number: {} Exp: {}".format(num, exponent))

    mantissa = get_mantissa(num)

    formatted_num = f'{sign:01b}' + f'{exponent:08b}' + f'{mantissa:020b}'

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
