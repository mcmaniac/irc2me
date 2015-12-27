{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE PatternGuards #-}

module Irc2me.Types.Message where

import Control.Applicative
import Data.Aeson
import Data.Time
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.Encoding as Text

import Network.IRC.ByteString.Parser

data OneOf a b c = First a | Second b | Third c
  deriving (Show, Eq, Ord)

--------------------------------------------------------------------------------
-- General messages

data WebSocketMessage a = WebSocketMessage
  { wsId    :: Int
  , wsMsg   :: a
  }
  deriving (Eq, Show, Ord)

--------------------------------------------------------------------------------
-- Status messages

data StatusMessage
  = StatusOK
  | StatusFailed (Maybe Text)
  deriving (Eq, Show, Ord)

--------------------------------------------------------------------------------
-- Account messages

data Account = Account
  { accountLogin    :: Text
  , accountPassword :: Maybe Text
  }
  deriving (Eq, Show, Ord)

--------------------------------------------------------------------------------
-- Chat messages

type Server = Text

type Channel = Text

data User = User
  { userNick :: Text
  , userName :: Maybe Text
  , userHost :: Maybe Text
  , userFlag :: Maybe UserFlag
  }
  deriving (Show, Eq, Ord)

data UserFlag = UserOperator | UserVoice
  deriving (Show, Read, Eq, Ord)

data MessageType
  = PRIVMSG
  | JOIN
  | PART
  | INVITE
  | QUIT
  | KICK
  | NICK
  | NOTICE
  | TOPIC
  | MOTD
  deriving (Eq, Ord, Show, Read, Enum)

data ChatMessage = ChatMessage
  { messageTime       :: UTCTime
  , messageType       :: MessageType
  , messageFrom       :: OneOf Server Channel (Maybe User)
  , messageParameters :: [Text]
  , messageText       :: Maybe Text
  }
  deriving (Show, Eq, Ord)

--------------------------------------------------------------------------------
-- Aeson instances: To JSON

instance ToJSON IRCMsg where
  toJSON (IRCMsg prefix cmd params trail) = object
    [ "user"    .= fmap (either Just (const Nothing)) prefix
    , "server"  .= fmap (either (const Nothing) (Just . Text.decodeUtf8)) prefix
    , "cmd"     .= Text.decodeUtf8 cmd
    , "params"  .= map Text.decodeUtf8 params
    , "trail"   .= Text.decodeUtf8 trail
    ]
instance ToJSON UserInfo where
  toJSON (UserInfo nick name host) = object
    [ "nick" .= Text.decodeUtf8 nick
    , "name" .= fmap Text.decodeUtf8 name
    , "host" .= fmap Text.decodeUtf8 host
    ]

instance ToJSON a => ToJSON (WebSocketMessage a) where
  toJSON (WebSocketMessage i a) = object [ "i" .= i, "d" .= a ]

instance ToJSON StatusMessage where
  toJSON StatusOK               = Null
  toJSON (StatusFailed mreason) = object [ "fail" .= mreason ]

instance ToJSON User where
  toJSON (User nick name host flag) = object
    [ "nick" .= nick
    , "name" .= name
    , "host" .= host
    , "flag" .= flag
    ]

instance ToJSON UserFlag where
  toJSON UserOperator = "@"
  toJSON UserVoice    = "+"

instance ToJSON MessageType where
  toJSON ty = toJSON $ show ty

instance ToJSON ChatMessage where
  toJSON (ChatMessage time ty from par txt) = object
    [ "time"        .= time
    , "type"        .= ty
    , fromPair
    , "parameters"  .= par
    , "text"        .= txt
    ]
   where
    fromPair = case from of
      First   server -> "server"   .= server
      Second  chan   -> "channel"  .= chan
      Third   user   -> "user"     .= user

--------------------------------------------------------------------------------
-- Aeson instances: From JSON

instance FromJSON a => FromJSON (WebSocketMessage a) where
  parseJSON (Object o) =
    WebSocketMessage
      <$> o .: "i"
      <*> o .: "d"
  parseJSON j = fail $ "Cannot parse WebSocketMessage from non-object: " ++ show j

instance FromJSON Account where
  parseJSON (Object o) =
    Account
      <$> o .:  "login"
      <*> o .:? "password"
  parseJSON j = fail $ "Cannot parse Account from non-object: " ++ show j

instance FromJSON User where
  parseJSON (Object o) =
    User <$> o .:  "nick"
         <*> o .:? "name"
         <*> o .:? "host"
         <*> o .:? "flag"
  parseJSON j = fail $ "Cannot parse User from non-object: " ++ show j

instance FromJSON UserFlag where
  parseJSON (String t) | [(flag,"")] <- reads (Text.unpack t)
    = return flag
  parseJSON j
    = fail $ "No read for UserFlag: " ++ show j

instance FromJSON MessageType where
  parseJSON (String t) | [(ty,"")] <- reads (Text.unpack t)
    = return ty
  parseJSON j
    = fail $ "No read for MessageType: " ++ show j

instance FromJSON ChatMessage where
  parseJSON (Object o) =
    ChatMessage <$> o .:  "time"
                <*> o .:  "type"
                <*> fromPair
                <*> o .:  "parameters"
                <*> o .:? "text"
   where
    fromPair =  (First  <$> o .:  "server")
            <|> (Second <$> o .:  "channel")
            <|> (Third  <$> o .:? "user")
  parseJSON j
    = fail $ "Cannot parse ChatMessage from non-object: " ++ show j
