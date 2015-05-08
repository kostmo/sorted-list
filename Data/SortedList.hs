
-- | This module defines a type for sorted lists, together
--   with several functions to create and use values of that
--   type. Many operations are optimized to take advantage
--   of the list being sorted.
module Data.SortedList (
    -- * Type
    SortedList
    -- * List conversions
  , toSortedList
  , fromSortedList
    -- * Construction
  , singleton
  , repeat
  , replicate
  , iterate
    -- * Deconstruction
  , uncons
    -- * Inserting
  , insert
    -- * Sublists
  , take
  , drop
  , splitAt
  , filter
    -- * Queries
  , elemOrd
    -- * Others
  , nub
  ) where

import Prelude hiding
  ( take, drop, splitAt, filter
  , repeat, replicate, iterate
    )
import qualified Data.List as List
import Data.Monoid ((<>))
import Data.Foldable (toList)

-- | Type of sorted lists. Any (non-bottom) value of this type
--   is a sorted list.
newtype SortedList a = SortedList [a]

instance Show a => Show (SortedList a) where
  show = show . fromSortedList

-- | Decompose a sorted list into its minimal element and the rest.
--   If the list is empty, it returns 'Nothing'.
uncons :: SortedList a -> Maybe (a, SortedList a)
uncons (SortedList []) = Nothing
uncons (SortedList (x:xs)) = Just (x, SortedList xs)

-- | Create a 'SortedList' by sorting a regular list.
toSortedList :: Ord a => [a] -> SortedList a
toSortedList = SortedList . List.sort

-- | Create a list from a 'SortedList'. The returned list
--   is guaranteed to be sorted.
fromSortedList :: SortedList a -> [a]
fromSortedList (SortedList xs) = xs

mergeSortedLists :: Ord a => [a] -> [a] -> [a]
mergeSortedLists xs [] = xs
mergeSortedLists [] ys = ys
mergeSortedLists (x:xs) (y:ys) =
  if x <= y
     then x : mergeSortedLists xs (y:ys)
     else y : mergeSortedLists (x:xs) ys

instance Ord a => Monoid (SortedList a) where
  mempty = SortedList []
  mappend (SortedList xs) (SortedList ys) = SortedList $ mergeSortedLists xs ys

-- | /O(1)/. Create a sorted list with only one element.
singleton :: a -> SortedList a
singleton x = SortedList [x]

-- | An infinite list with all its elements equal to the given
--   argument.
repeat :: a -> SortedList a
repeat = SortedList . List.repeat

-- | Replicate a given number of times a single element.
replicate :: Int -> a -> SortedList a
replicate n = SortedList . List.replicate n

-- | Create a sorted list by repeatedly applying the same
--   function to an element, until the image by that function
--   is stricly less than its argument. In other words:
--
-- > iterate f x = [x, f x, f (f x), ... ]
--
--   With the list ending whenever
--   @f (f (... (f (f x)) ...)) < f (... (f (f x)) ...)@.
--   If this never happens, the list will be infinite.
iterate :: Ord a => (a -> a) -> a -> SortedList a
iterate f x = SortedList $ x : go x (f x)
  where
    go prev fprev =
      if prev <= fprev
         then fprev : go fprev (f fprev)
         else []

-- | /O(n)/. Insert a new element in a sorted list.
insert :: Ord a => a -> SortedList a -> SortedList a
insert x xs = singleton x <> xs

-- | Extract the prefix with the given length from a sorted list.
take :: Int -> SortedList a -> SortedList a
take n = fst . splitAt n

-- | Drop the given number of elements from a sorted list, starting
--   from the smallest and following ascending order.
drop :: Int -> SortedList a -> SortedList a
drop n = snd . splitAt n

-- | Split a sorted list in two sublists, with the first one having
--   length equal to the given argument, except when the length of the
--   list is less than that.
splitAt :: Int -> SortedList a -> (SortedList a, SortedList a)
splitAt n (SortedList xs) =
  let (ys,zs) = List.splitAt n xs
  in  (SortedList ys, SortedList zs)

-- | /O(n)/. Extract the elements of a list that satisfy the predicate.
filter :: (a -> Bool) -> SortedList a -> SortedList a
filter f (SortedList xs) = SortedList $ List.filter f xs

-- | /O(n)/. An efficient implementation of 'elem', using the 'Ord'
--   instance of the elements in a sorted list. It only traverses
--   the whole list if the requested element is greater than all
--   the elements in the sorted list.
elemOrd :: Ord a => a -> SortedList a -> Bool
elemOrd a (SortedList l) = go l
    where
      go (x:xs) =
        case compare a x of
          GT -> go xs
          EQ -> True
          _  -> False
      go _ = False

-- | /O(n)/. Remove duplicate elements from a sorted list.
nub :: Eq a => SortedList a -> SortedList a
nub (SortedList l) = SortedList $ go l
  where
    go (x:y:xs) = if x == y then go (x:xs) else x : go (y:xs)
    go xs = xs

instance Foldable SortedList where
  {-# INLINE foldr #-}
  foldr f e (SortedList xs) = foldr f e xs
  {-# INLINE toList #-}
  toList = fromSortedList
  minimum (SortedList xs) =
    case xs of
      x : _ -> x
      _ -> error "SortedList.minimum: empty list"
  maximum (SortedList xs) =
    case xs of
      [] -> error "SortedList.maximum: empty list"
      _ -> last xs
