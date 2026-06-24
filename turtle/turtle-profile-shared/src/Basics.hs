{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}

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
import qualified Text.Parsec as PC
import Data.Char (isSpace)

infixl 1 <*=
(<*=) :: Monad m => m a -> (a -> m b) -> m a
a <*= f' = a >>= tee f'

tee :: Monad m => (a -> m b) -> a -> m a
tee = (>>= ($>))

cmd :: FilePath -> [String] -> Shell Line -> Shell Line
cmd c args = stream $ P.proc c args

iCmd :: Shell Line
iCmd = getLine >>= (parseCmd >>> \case
  Left e -> error $ T.pack e
  Right (c, args) -> cmd c args mempty)

iCmd' :: IO ()
iCmd' = getLine >>= (parseCmd >>> \case
  Left e -> putStrLn e
  Right (c, args) -> TU.sh $ cmd c args mempty >>= TU.echo)

parseCmd :: Text -> Either String (String, [String])
parseCmd = first show . PC.runParser parseCommand () ""

data ReplCommand
  = RunCommand String [String]
  | MetaCommand Meta
  deriving Show

data Meta
  = Quit
  deriving Show

repl :: IO ()
repl = getCommand >>= \case
    MetaCommand Quit -> pure ()
    RunCommand c args
        -> handle
             (\(_ :: TU.ExitCode) -> mempty)
             (TU.sh run)
        *> repl
      where
        run  =  either (TU.echo . ("Err: " <>)) TU.echo
            =<< streamWithErr (P.proc c args) mempty
  where
    getCommand = (putText "> " *> getLine <&> parseInteractiveCommand) >>= \case
        Left e -> putTextLn (show e) *> getCommand
        Right v -> pure v
    parseInteractiveCommand
        = (`PC.parse` "")
        $ PC.choice
            [ metaCommand
            , uncurry RunCommand <$> parseCommand
            ]
      where
        metaCommand = PC.string ":q" $> MetaCommand Quit

parseCommand :: PC.Stream s Identity Char
           => PC.ParsecT s u Identity ([Char], [[Char]])
parseCommand = do
    c <- some PC.letter
    args <- PC.optionMaybe $ do
      void $ some PC.space
      cmdArg `PC.sepBy` some PC.space
    pure (c, fromMaybe [] args)
  where
    cmdArg  =  quotedArg '"'
           <|> quotedArg '\''
           <|> some (PC.satisfy $ not . isSpace)
    quotedArg q = do
        void $ PC.char q
        many (escaped <|> PC.noneOf [q]) <* PC.char q
      where
        escaped = PC.char '\\' *> PC.choice escapes
          where
            escapes = [PC.char q, PC.char '\\']

collect :: MonadIO m => Shell a -> m [a]
collect = flip TU.fold F.list

sendFile :: (Word8, Word8, Word8, Word8) -> Int -> FilePath -> IO ()
sendFile ip port file = TU.runManaged $ do
    sock <- TU.managed withSocket
    liftIO $ do
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

