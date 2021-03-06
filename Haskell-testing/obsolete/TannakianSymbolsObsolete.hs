{-# LANGUAGE NoImplicitPrelude #-}

module TannakianSymbolsObsolete (
    module TannakianSymbolsObsolete,
    module Algebra
  ) where

import Data.List as List
import qualified Data.Map as Map
import Data.Map (Map)

import qualified Prelude
import Prelude hiding ((+),(-),(*),(^),(/), negate)

import Algebra


--TODO: Optimize

type TannakianSymbol m = Map m Int

data TS m = Symbol (TannakianSymbol m) deriving (Ord)

charFunction :: (Ord m) => TS m -> (m -> Int)
charFunction (Symbol ts) n = Map.findWithDefault 0 n ts

listSymbol :: (Ord m) => [(m, Int)] -> TS(m)
listSymbol x = Symbol $ Map.fromListWith (Prelude.+) x

symbolList :: (Ord m) => TS(m) -> [(m, Int)]
symbolList (Symbol a) = Map.assocs a

toMap :: TS m -> TannakianSymbol m
toMap (Symbol a) = a

instance (Ord m) => CAdd (TS m) where
    Symbol a + Symbol b = Symbol $ Map.unionWith (Prelude.+) a b
    negate (Symbol a) = Symbol $ Map.map (Prelude.negate) a
    zero = Symbol $ Map.empty

instance (Ord m, CMult m) => CMult (TS m) where
    Symbol a * Symbol b = Symbol $ Map.fromListWith (Prelude.+) [(x*y,n Prelude.*m)| (x,n) <- Map.assocs a, (y,m) <- Map.assocs b]
    e = Symbol $ Map.fromList [(e, 1)]

instance (Ord m) => CIntDiv (TS m) where
    (Symbol x) / n = Symbol $ Map.map (`quot` n) x

instance (Ord m, CMult m) => LambdaRing (TS m) where
    psi k (Symbol x) = Symbol $ Map.mapKeysWith (Prelude.+) (^k) x

instance (Ord m, Eq m) => Eq (TS m) where
    x == y = all (\x -> (snd x) == 0) (Map.assocs $ toMap (x - y))

instance (Ord m, Show m) => Show (TS m) where
    show (Symbol ts) = showSet(upper) ++ "/" ++ showSet(lower) where
        upper = Map.filter ( > 0) ts
        lower = Map.map (Prelude.negate) $ Map.filter ( < 0) ts
        expand :: (Map m Int) -> [m]
        expand x = concat $ map (uncurry $ flip replicate) (Map.assocs x)
        showSet :: (Show m) => (Map m Int) -> String
        showSet x
            | Map.null x = "Ø"
            | otherwise = "{" ++ (intercalate ", " $ (map show (expand x))) ++ "}"


-- Can't be a functor because functors must accept all data types. We require Ord (because Map & functor is fucking stupid)

-- OBSOLETE CODE:

--instance Functor TS where
--    fmap f (Symbol x) = Symbol $ Map.mapKeysWith (Prelude.+) f x

{-instance (Read m) => Read (TS m) where
    readPrec = parens 
        (do
            Read.expectP (L.Punc "{")
              (readNext False)
        )
        where 
            readRest negative = do 
                L.Punc c <- lexP
                case c of
                    "," -> readNext negative
                    "}" -> (if negative then return zero else expectP (L.Punc "/{")
                            readNext True)
                    _ -> pfail
            
            readNext negative = do 
                x <- parens readPrec
                xs <- readRest negative
                return x + xs-}

{-readTS :: (Ord m, Read m) => [Char] -> TS m
readTS string = (upperlower !! 0) - (upperlower !! 1) where
    upperlower = map readMap (splitRegex (mkRegex "/") string)
    readMap "Ø" = zero
    readMap s = listSymbol $ zip (map read (splitRegex (mkRegex ",") (filter (not . (liftM2 ((||)) (== '{') (== '}'))) s) )) (repeat 1)-}
