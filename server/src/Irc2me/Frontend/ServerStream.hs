{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RankNTypes #-}

module Irc2me.Frontend.ServerStream
  ( -- * StreamT
    Stream, StreamT
  , runStream, runStreamT
    -- * Streams
  , serverStream
  ) where

import Control.Applicative
import Control.Concurrent
import Control.Monad
import Control.Monad.Trans

-- lens
import Control.Lens
import Data.Text.Lens

-- text
import qualified Data.Text.Encoding as TE

-- local

import Control.Concurrent.Event

import Irc2me.Database.Query
import Irc2me.Database.Tables.Accounts

import Irc2me.Events.Types as Events

import Irc2me.Frontend.Connection.Types
import Irc2me.Frontend.Messages
import Irc2me.Frontend.Messages.Authentication
import Irc2me.Frontend.Streams.StreamT as Stream
import Irc2me.Frontend.Streams.Helper  as Stream

serverStream :: Stream ()
serverStream = do

  account <- authenticate <|> throwUnauthorized

  withClientConnection $ \con -> do

    let send :: MonadIO m => ServerMessage -> m ()
        send = Stream.sendMessage con

        raise = raiseEvent . AccountEvent account

    send responseOkMessage

    -- notify event handler of new connection
    tid <- liftIO myThreadId
    let cc = ClientConnection tid send

    raise $ ClientConnectedEvent cc

    forever $ do
      msg <- getMessage

      let cc' = cc & ccSend .~ send . addResponseId msg
      raise $ ClientMessageEvent cc' msg

 where
  addResponseId msg response =
    response & serverResponseID .~ (msg ^. clResponseID)

authenticate :: Stream AccountID
authenticate = do

  msg <- getMessage
  let login = msg ^. authLogin    . from packed
      pw    = msg ^. authPassword & TE.encodeUtf8

  -- run database query
  maccount <- showS "authenticate" $ runQuery $ selectAccountByLogin login
  case maccount of

    Just account -> do

      ok <- showS "authenticate" $ runQuery $ checkPassword account pw
      if ok then
        return account
       else
        throwS "authenticate" $ "Invalid password for user: " ++ login

    Nothing -> throwS "authenticate" $ "Invalid login: " ++ login

throwUnauthorized :: Stream a
throwUnauthorized = do

  withClientConnection $ \con ->
    sendMessage con $ responseErrorMessage $ Just "Invalid login/password."

  throwS "unauthorized" "Invalid login/password."
