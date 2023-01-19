from abc import ABCMeta, abstractmethod

import urllib
import urllib2
import json
import hashlib
import M2Crypto
import base64


class NotifyBase:
    __metaclass__ = ABCMeta

    @abstractmethod
    def invokeService(self, authObject):pass

    @abstractmethod
    def sendResponse(self, resp):pass

    @staticmethod
    def chunk_split(body, chunk_len=64, end="\n"):
        data = ""
        for i in xrange(0, len(body), chunk_len):
            data += body[i:min(i + chunk_len, len(body))] + end
        return data

    @staticmethod
    def rsa_verify(pem, data, sign, algo='sha1'):
        pem = NotifyBase.chunk_split(pem)
        pem = "-----BEGIN PUBLIC KEY-----\n" + pem + "-----END PUBLIC KEY-----\n"
        bio = M2Crypto.BIO.MemoryBuffer(pem)
        rsa = M2Crypto.RSA.load_pub_key_bio(bio)
        pubkey = M2Crypto.EVP.PKey(md=algo)
        pubkey.assign_rsa(rsa)
        pubkey.verify_init()
        pubkey.verify_update(data)
        signature = base64.b64decode(sign)
        return pubkey.verify_final(signature)