module Basics where

import Turtle (Shell, Line, stream)
import qualified Turtle as TU
import qualified Control.Foldl as F
import qualified System.Process as P
import qualified Data.Text as T

infixl 1 <*=
(<*=) :: Monad m => m a -> (a -> m b) -> m a
a <*= f' = a >>= tee f'

tee :: Monad m => (a -> m b) -> a -> m a
tee = (>>= ($>))

cmd :: FilePath -> Text -> Shell Line -> Shell Line
cmd c args = cmd' c $ words args

cmd' :: FilePath -> [Text] -> Shell Line -> Shell Line
cmd' c args = stream $ P.proc c (T.unpack <$> args)

collect :: MonadIO m => Shell a -> m [a]
collect = flip TU.fold F.list

