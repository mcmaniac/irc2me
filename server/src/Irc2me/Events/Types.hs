{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}

{-# OPTIONS -fno-warn-orphans #-} -- for Show instance of SendServerMessage

module Irc2me.Events.Types where

import Data.Map (Map)
import qualified Data.Map as M

-- lens
import Control.Lens

-- local
import Control.Concurrent.Event

import Irc2me.Backends.IRC.Helper
import Irc2me.Frontend.Messages
import Irc2me.Frontend.Connection.Types
import Irc2me.Database.Tables.Accounts
import Irc2me.Database.Tables.Networks

------------------------------------------------------------------------------
-- Event types
--

data AccountEvent = AccountEvent { _eventAccountId :: AccountID, _event :: Event }
  deriving (Show)

data Event
  = ClientConnectedEvent  ClientConnection
  | ClientMessageEvent    ClientConnection ClientMessage
  | NewIrcConnectionEvent NetworkID IrcConnection
  | ChatMessageEvent      NetworkID ChatMessage
  deriving (Show)

type EventRW m = EventT RW AccountEvent m
type EventWO m = EventT WO AccountEvent m

-- orphan Show instances

instance Show (ServerMessage -> IO ()) where
  show _ = "(ServerMessage -> IO ())"

deriving instance Show ClientConnection

------------------------------------------------------------------------------
-- Event loop state type
--

data EventLoopState = EventLoopState
  { _elsAccounts :: Map AccountID AccountState
  }

data AccountState = AccountState
  { _connectedClients       :: [ClientConnection]
  , _connectedIrcNetworks   :: Map NetworkID IrcConnection
  }

instance AsEmpty AccountState where
  _Empty = nearly (AccountState [] M.empty) $ \as ->
    null   (_connectedClients     as) &&
    M.null (_connectedIrcNetworks as)

makeLenses ''EventLoopState
makeLenses ''AccountState
