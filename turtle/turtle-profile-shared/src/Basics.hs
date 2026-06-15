{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Basics where

import Turtle (Shell, Line, stream, streamWithErr)
import qualified Turtle as TU
import qualified Control.Foldl as F
import qualified System.Process as P
import qualified Data.Text as T
import Control.Exception (handle, bracket)
import qualified Network.Socket as N
import qualified Network.Socket.ByteString as N
import qualified Data.ByteString as BS

infixl 1 <*=
(<*=) :: Monad m => m a -> (a -> m b) -> m a
a <*= f' = a >>= tee f'

tee :: Monad m => (a -> m b) -> a -> m a
tee = (>>= ($>))

cmd :: FilePath -> Text -> Shell Line -> Shell Line
cmd c args = cmd' c $ words args

cmd' :: FilePath -> [Text] -> Shell Line -> Shell Line
cmd' c args = stream $ P.proc c (T.unpack <$> args)

iCmd :: Shell Line
iCmd = liftIO getLine >>= \case
  (T.words -> (c:args)) -> cmd' (T.unpack c) args mempty
  _ -> mempty

iCmd' :: IO ()
iCmd' = getLine >>= viewCmd

repl :: IO ()
repl = do
    inpt <- putText "> " *> getLine
    case inpt of
        ":q" -> pure ()
        (T.words -> (c:args))
            -> handle
                 (\(_ :: TU.ExitCode) -> putTextLn "Command failed")
                 (TU.sh run)
            *> repl
          where
            run  =  either (TU.echo . ("Err: " <>)) TU.echo
                =<< streamWithErr
                      (P.proc (T.unpack c) (T.unpack <$> args))
                      mempty
        _ -> repl

viewCmd :: Text -> IO ()
viewCmd (T.words -> (c:args)) =
  TU.sh $ cmd' (T.unpack c) args mempty >>= TU.echo
viewCmd _ = pure ()

collect :: MonadIO m => Shell a -> m [a]
collect = flip TU.fold F.list

sendFile :: (Word8, Word8, Word8, Word8) -> Int -> FilePath -> IO ()
sendFile ip port file =
    withSocket $ \sock -> do
        N.connect
          sock
          (N.SockAddrInet (fromIntegral port) (N.tupleToHostAddress ip))

        bs <- BS.readFile file

        N.sendAll sock bs
  where
    withSocket =
      bracket
        (N.socket N.AF_INET N.Stream N.defaultProtocol)
        N.close

