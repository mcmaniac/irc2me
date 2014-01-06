{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE PatternGuards #-}
{-# LANGUAGE ScopedTypeVariables #-}

module IRC.TLS where

import Control.Concurrent
import Control.Concurrent.STM
import Control.Monad
import Control.Exception

import Crypto.Random

import           Data.Functor
import           Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8
import           Data.Time

import Network.IRC.ByteString.Parser
import Network.TLS
import Network.TLS.Extra

import IRC.Debug
import IRC.Messages
import IRC.Types

clientParams :: Params
clientParams = defaultParamsClient
  { pConnectVersion = TLS12
  , pAllowedVersions = [SSL3, TLS10, TLS11, TLS12]
  , pCiphers = ciphersuite_all
  }

establishTLS :: Connection -> IO Bool
establishTLS con = handleExceptions $ do
  tls_cont <- getTlsContext con
  case tls_cont of
    Just _ -> return True
    Nothing -> do
      -- entropy & random gen
      gen <- cprgCreate `fmap` createEntropyPool :: IO SystemRNG

      -- create TLS context
      ctxt <- contextNewOnHandle (con_handle con)
                                 clientParams
                                 gen

      handshake ctxt

      -- create incoming buffer
      buff <- newTVarIO BS.empty

      -- receive data in background
      tid <- forkIO $ do
        let handleIOException = handle (\(_ :: IOException) -> return ())
         in handleIOException $ forever $ do
              bs <- recvData ctxt
              atomically $ modifyTVar buff (`BS.append` bs)

      atomically $ writeTVar (con_tls_context con) $ Just (ctxt, buff, tid)

      return True
 where
  -- just catch all exceptions that could possible occure
  handleExceptions = handle (\(_ :: IOException)              -> return False)
                   . handle (\(_ :: TLSError)                 -> return False)
                   . handle (\(_ :: HandshakeFailed)          -> return False)
                   . handle (\(_ :: ConnectionNotEstablished) -> return False)
                   . handle (\(_ :: Terminated)               -> return False)

--------------------------------------------------------------------------------
-- TLS initialization

initTLS
  :: Connection
  -> TLSSettings
  -> IO (Maybe [(UTCTime, IRCMsg)])

-- no TLS
initTLS con NoTLS = do
  logI con "initTLS" "Using plain text"
  sendUserAuth con
  -- nothing to resend
  return Nothing

-- start with TLS handshake immediately
initTLS con TLS = do
  logI con "initTLS" "Starting TLS handshake"
  tls_success <- establishTLS con
  if tls_success then do
    sendUserAuth con
   else do
    logE con "initTLS" "TLS handshake failed (connection closed)"
    closeConnection con
  -- nothing to resend
  return Nothing

-- enforce STARTTLS
initTLS con STARTTLS = do
  logI con "initTLS" "Use STARTTLS"
  sendSTARTTLS con
  tls_succ <- waitForTLS con
  Nothing <$ if tls_succ
    then sendUserAuth    con -- success
    else do
      logE con "initTLS" "STARTTLS failed (connection closed)"
      closeConnection con -- quit immediately

-- try to find out if server supports TLS via CAP
initTLS con OptionalSTARTTLS = do

  logI con "initTLS" "Sending CAP LS"
  sendCAPLS con
  sendUserAuth con

  ecap <- waitForCAP con []
  case ecap of
    Left resend -> do
      logI con "initTLS" "CAP failed, falling back to plain text."
      return $ Just resend
    Right cap   -> do
      if "tls" `elem` cap then do
        logI con "initTLS" "Use STARTTLS via CAP"
        sendSTARTTLS con
        -- wait for TLS, fall back to plaintext by returning the old connection on
        -- 'Nothing'
        void $ waitForTLS con
       else
        logI con "initTLS" "STARTTLS via CAP failed, falling back to plain text"
      sendCAPEnd con
      return Nothing

waitForTLS :: Connection -> IO Bool
waitForTLS con = do
  mmsg <- receive con
  case mmsg of
    Right (_time, msg@(msgCmd -> cmd))

      -- TLS success
      | cmd == "670" -> establishTLS con

      -- TLS fail
      | cmd == "691" -> return False

      -- ignore NOTICE message, FIXME: add messages to message queue
      | cmd == "NOTICE" -> waitForTLS con

      -- unknown message
      | otherwise -> do
        logE con "waitForTLS" $ "Unexpected message: " ++ show msg ++ " (TLS init failed)"
        return False

    Left l -> do
      logE con "waitForTLS" (B8.unpack l)
      return False

waitForCAP :: Connection -> [(UTCTime, IRCMsg)] -> IO (Either [(UTCTime, IRCMsg)] [ByteString])
waitForCAP con resend = do
  mmsg <- receive con
  case mmsg of
    Right (time, msg@(msgCmd -> cmd))

      | cmd == "CAP" -> return $ Right $ B8.words (msgTrail msg)

      -- tolerate NOTICE messages
      | cmd == "NOTICE" -> do
        logE con "waitForTLS" $ "Unexpected message: " ++ show msg
        waitForCAP con (resend ++ [(time,msg)])

      -- quit on any other message type
      | otherwise -> do
        logE con "waitForTLS" $ "Unexpected message: " ++ show msg ++ " (CAP LS failed)"
        return $ Left (resend ++ [(time,msg)])

    _ -> return $ Left resend
