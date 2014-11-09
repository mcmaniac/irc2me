{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}

module Irc2me.ProtoBuf.Streams.Helper where

import Control.Lens
import Control.Monad.Reader

import Data.Foldable
import Data.Maybe
import Data.Monoid
import Data.ProtocolBuffers

import Data.Serialize
import Data.ProtocolBuffers.Internal

import qualified Data.ByteString as B

import Irc2me.Database.Tables.Accounts
import Irc2me.ProtoBuf.Messages.Client
import Irc2me.ProtoBuf.Messages.Server
import Irc2me.ProtoBuf.Streams.StreamT

--------------------------------------------------------------------------------
-- messages

getMessage :: (Monad m, Decode a) => StreamT (First String) m a
getMessage = withChunks $ \chunks ->

  handleChunks chunks $ runGetPartial getVarintPrefixedBS

 where

  handleChunks (chunk : rest) f

    -- skip empty chunks
    | B.null chunk = handleChunks rest f

    | otherwise =

      -- parse chunk
      case f chunk of

        Fail err _ -> throwS "getMessage" $ "Unexpected error: " ++ show err

        Partial f' -> handleChunks rest f'

        Done bs chunk' -> do
          -- try to parse current message
          case runGet decodeMessage bs of
            Left err  -> throwS "getMessage" $ "Failed to parse message: " ++ show err
            Right msg -> return (chunk' : rest, msg)

  handleChunks [] f =

    case f B.empty of
      Done bs _ | Right msg <- runGet decodeMessage bs ->
        return ([], msg)
      _ -> throwS "getMessage" "Unexpected end of input."

sendMessage :: Encode a => a -> Stream ()
sendMessage msg = withHandle $ \h -> do

  let encoded = runPut $ encodeMessage msg
  liftIO $ B.hPut h $ runPut $ putVarintPrefixedBS encoded

--------------------------------------------------------------------------------
-- Server response state

data ServerReaderState = ServerReaderState
  { connectionAccount :: Maybe AccountID
  , clientMessage     :: ClientMessage
  }

type ServerResponseT = StreamT (First String) (ReaderT ServerReaderState IO)
type ServerResponse  = ServerResponseT ServerMessage

getServerResponse
  :: ServerReaderState -> ServerResponse -> Stream ServerMessage
getServerResponse state resp =
  liftMonadTransformer (runReaderT `flip` state) resp

withAccount :: (AccountID -> ServerResponse) -> ServerResponse
withAccount f = do
  macc <- lift $ asks connectionAccount
  case macc of
    Nothing -> throwS "withAccount" "Login required"
    Just acc -> f acc

getClientMessage :: ServerResponseT ClientMessage
getClientMessage = lift $ asks clientMessage

messageField
  :: (HasField a)
  => Getter ClientMessage a
  -> ServerResponseT (FieldType a)
messageField lns = do
  msg <- getClientMessage
  return $ msg ^. lns . field

guardMessageField
  :: (HasField a, FieldType a ~ Maybe t)
  => Getter ClientMessage a
  -> ServerResponseT ()
guardMessageField lns = do
  msg <- getClientMessage
  guard $ isJust $ msg ^. lns . field

guardMessageFieldValue
  :: (HasField a, Eq (FieldType a))
  => Getter ClientMessage a
  -> FieldType a
  -> ServerResponseT ()
guardMessageFieldValue lns val = do
  msg <- getClientMessage
  guard $ (msg ^. lns . field) == val

requireMessageField
  :: (HasField a, FieldType a ~ Maybe t)
  => Getter ClientMessage a
  -> ServerResponseT t
requireMessageField lns = do
  msg <- getClientMessage
  case msg ^. lns . field of
    Just t  -> return t
    Nothing -> mzero

requireMessageFieldValue
  :: (HasField a, FieldType a ~ Maybe t, Eq t)
  => Getter ClientMessage a
  -> t
  -> ServerResponseT ()
requireMessageFieldValue lns val = do
  msg <- getClientMessage
  case msg ^. lns . field of
    Just t | t == val -> return ()
    _                 -> mzero

------------------------------------------------------------------------------
-- Folds

foldOn, guardFoldOn
  :: (Foldable f, HasField field, FieldType field ~ f a)
  => Getter ClientMessage field
  -> Fold a b
  -> ServerResponseT [b]

foldOn lns fld = do
  msg <- getClientMessage
  return $ (msg ^. lns.field) ^.. folded . fld

guardFoldOn lns fld = do
  lis <- foldOn lns fld
  guard $ not $ null lis
  return lis

foldROn, guardFoldROn
  :: (Foldable f, HasField field, FieldType field ~ f a)
  => Getter ClientMessage field
  -> ReifiedFold a b
  -> ServerResponseT [b]

foldROn lns rfld = foldOn lns (runFold rfld)

guardFoldROn lns rfld = do
  lis <- foldROn lns rfld
  guard $ not $ null lis
  return lis