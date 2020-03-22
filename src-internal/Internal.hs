{-# language TypeInType #-}
{-# language GADTs #-}
{-# language TypeFamilies #-}
{-# language RankNTypes #-}
{-# language TypeApplications #-}
{-# language MagicHash #-}

module Internal
  ( MutablePrimArray(..)
  ) where

import GHC.Exts
import Data.Kind (Type)

data MutablePrimArray :: forall (r :: RuntimeRep). Type -> TYPE r -> Type where
  MutablePrimArray :: forall (r :: RuntimeRep) (s :: Type) (a :: TYPE r). MutableByteArray# s -> MutablePrimArray s a
