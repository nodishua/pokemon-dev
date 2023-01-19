import math

class RSAUtil:
    keylen = 64
    primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]

    @staticmethod
    def encrypt(string, e, n): pass

    @staticmethod
    def decrypt(string, d, n):
        bln = RSAUtil.keylen * 2 - 1
        bitlen = math.ceil(bln / 8)
        arr = string.split(' ')

        data = ''
        for i in arr:
            v = RSAUtil.__hex2dec(i)
            v = pow(v, int(d), int(n))
            data += RSAUtil.__int2byte(v)

        return data

    @staticmethod
    def __int2byte(num):
        bit = ''
        while cmp(num, 0) > 0:
            asc = num % 256
            bit = chr(asc) + bit
            num = num / 256

        return bit

    @staticmethod
    def __hex2dec(num):
        char = '0123456789abcdef'
        num = num.lower()
        nlen = len(num)
        nsum = 0
        i = nlen - 1
        for x in xrange(0, nlen):
            index = char.index(num[i])
            nsum += index * (16 ** x)
            i -= 1

        return nsum