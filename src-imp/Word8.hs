{-# language MagicHash #-}
{-# language RankNTypes #-}
{-# language TypeApplications #-}
{-# language TypeInType #-}

module Word8
  ( R
  , width
  , write#
  ) where

import GHC.Exts
import Data.Kind (Type)
import Internal (MutablePrimArray(..))

type R = 'Word8Rep

width :: Int
width = 1

write# :: forall (s :: Type) (a :: TYPE 'Word8Rep).
  MutablePrimArray s a -> Int# -> a -> State# s -> State# s
write# (MutablePrimArray a) i w = writeWord8Array# a i
  (extendWord8# (unsafeCoerce# w))
