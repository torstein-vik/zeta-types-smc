
import functools
import itertools
import operator

class LazyList:
    def __init__(self, data = lambda n: 0, cache=True, printed=None):
        self.data = data
        self.doCache = cache
        self.cache = {}
        self.printed = printed
        
    def __getitem__(self, n):
        if n in self.cache and self.doCache:
            return self.cache[n]
        data = self.data(n)
        if hasattr(data, 'simplify_full'):
            data = data.simplify_full()
        if self.doCache:
            self.cache[n] = data
        return data
    
    def __eq__(self, other):
        print ("It's impossible to calculate if two infinite sequences are equal... returning false")
        return False
    
    def __iter__(self):
        for n in (itertools.count() if printed==None else range(self.printed)):
            yield self[n]
    
    def toList(self, length):
        return [self[i] for i in range(self.printed if length == None and self.printed != None else length)]
    
    def __add__(self, B):
        return liftBinaryOpToLazyList(operator.add)(self, B)
    
    def __mul__(self, B):
        return liftBinaryOpToLazyList(operator.mult)(self, B)
    
    def __repr__(self, length = None):
        res = ""
        for i in range((20 if self.printed == None else self.printed) if length == None else length):
            res += str(self[i]) + ", "
        return res[:-2] + ", ..."
    
    def compress(self, k):
        return LazyList(data = lambda n: self[n * k], printed = self.printed)
    
    def expand(self, k, filler = lambda n: 0):
        return LazyList(data = lambda n: self[n / k] if n % k == 0 else filler(n), printed = self.printed)
    
    def applyRecursiveTransform(self, transformCoeffIndexTriples):
        list = LazyList(cache = True, printed=self.printed)
        list.data = lambda n: sum([coeff * (1 if orIndex == "id" else self[orIndex]) * (1 if recIndex == "id" else list[recIndex]) for coeff, orIndex, recIndex in transformCoeffIndexTriples[n]])
        return list
    
    def fmap(self, f, cache = True):
        return LazyList(data = lambda n: f(self[n]), cache=cache, printed=self.printed)

    def toNearestGaussianIntegers(self):
        return self.fmap(toNearestGaussianInteger)
    
    def toNearestIntegers(self):
        return self.fmap(toNearestInteger)
    
BellTransform     = LazyList(data = lambda n: [(1, "id", "id")] if n == 0 else [(n, n, "id")] + [(-1, i, n - i) for i in range(1, n)])
BellAntiTransform = LazyList(data = lambda n: [(1, "id", "id")] if n == 0 else [(1/n, n - i, i) for i in range(n)])


def liftBinaryOpToLazyList(op, exclude = -1):
    return lambda X, Y: LazyList(data = lambda n: op(X[n], Y[n]) if n > exclude else X[n], cache=True, printed = min(X.printed, Y.printed))

def liftUnaryOpToLazyList(func, exclude = -1):
    return lambda X: LazyList(data = lambda n: func(X[n]) if n > exclude else X[n], cache=True, printed = X.printed)

def toLazyList(list):
    return LazyList(data = lambda n: list[n] if n < len(list) else 0, cache = False, printed = len(list))

def DirichletConvolution(X, Y):
    return LazyList(data = lambda n: sum(X[d] * Y[n - d] for d in range(n + 1)), cache = True, printed = min(X.printed, Y.printed))

PointwiseProduct = liftBinaryOpToLazyList(operator.mul)