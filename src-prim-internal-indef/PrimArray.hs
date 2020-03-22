{-# language DataKinds #-}
{-# language KindSignatures #-}
{-# language MagicHash #-}
{-# language RankNTypes #-}
{-# language TypeApplications #-}
{-# language UnboxedTuples #-}

module PrimArray
  ( R
  , M
  , uninitialized#
  ) where

import Representation (R,width)
import Internal
import GHC.Exts
import Data.Kind (Type)

type M = MutablePrimArray @R

uninitialized# :: forall (s :: Type) (a :: TYPE R).
     Int#
  -> State# s
  -> (# State# s, M s a #)
uninitialized# i s = case width of
  I# w -> case newByteArray# (i *# w) s of
    (# s', x #) -> (# s', MutablePrimArray x #)
