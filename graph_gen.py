from random import random
import math
import sys

def gen_graph(N, scarcity=0):
    res = {i : [] for i in range(1, N+1)}
    for i in range(1,N):
        if scarcity <= 0:
            amount_of_nb = math.ceil(random() * N / (math.ceil(math.log2(N))))
        else:
            amount_of_nb = math.ceil(random() * N / scarcity)
        for j in range(amount_of_nb):
            edge = math.ceil(random() * N)
            if i != j:
                res[i].append(edge)
                res[edge].append(i)
    for i in range(1,len(res)+1):
        tmp = set(res[i])
        res[i] = list(tmp)
        for j in res[i]:
            if j == i:
                res[i].remove(j)
    return res

def format(X):
    res = "["
    for i in range(1,len(X)+1):
        res += "{" + str(i) + "," + str(X[i]) + "},"
    res = res[0:len(res)-1] + "]."
    return res

if len(sys.argv) > 2:
    print(format(gen_graph(int(sys.argv[1]), int(sys.argv[2]))))
else:
    print(format(gen_graph(int(sys.argv[1]))))