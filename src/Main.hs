module Main where

import           Bot
import           Control.Exception
import           Control.Monad
import           Control.Monad.Free
import           Data.Foldable
import           Data.Ini
import qualified Data.Text as T
import           Data.Time
import           Data.Traversable
import qualified Database.SQLite.Simple as SQLite
import           Effect
import           Hookup
import           Irc.Commands ( ircPong
                              , ircNick
                              , ircPass
                              , ircJoin
                              , ircPrivmsg
                              )
import           Irc.Identifier (idText)
import           Irc.Message (IrcMsg(Ping, Privmsg), cookIrcMsg)
import           Irc.RawIrcMsg (RawIrcMsg, parseRawIrcMsg, asUtf8, renderRawIrcMsg)
import           Irc.UserInfo (userNick)
import           Network.HTTP.Simple
import qualified SqliteEntityPersistence as SEP
import           System.Environment
import           Text.Printf

-- TODO(#15): utilize rate limits
-- See https://github.com/glguy/irc-core/blob/6dd03dfed4affe6ae8cdd63ede68c88d70af9aac/bot/src/Main.hs#L32

data Config = Config { configNick :: T.Text
                     , configPass :: T.Text
                     , configChannel :: T.Text
                     } deriving Show

data EffectState =
    EffectState { esIrcConn :: Connection
                , esSqliteConn :: SQLite.Connection
                , esTimeouts :: [(Int, Effect ())]
                }

maxIrcMessage :: Int
maxIrcMessage = 512

config :: T.Text -> T.Text -> T.Text -> Config
config nick password channel =
    Config { configNick = nick
           , configPass = password
           , configChannel = T.pack $ printf "#%s" channel
           }

configFromFile :: FilePath -> IO Config
configFromFile filePath =
    do ini <- readIniFile filePath
       let lookupParam section key = ini >>= lookupValue (T.pack section) (T.pack key)
       let nick = lookupParam "User" "nick"
       let password = lookupParam "User" "password"
       let channel = lookupParam "User" "channel"
       either (ioError . userError) return $ liftM3 config nick password channel

twitchConnectionParams :: ConnectionParams
twitchConnectionParams =
    ConnectionParams { cpHost = "irc.chat.twitch.tv"
                     , cpPort = 443
                     , cpTls = Just TlsParams { tpClientCertificate = Nothing
                                              , tpClientPrivateKey = Nothing
                                              , tpServerCertificate = Nothing
                                              , tpCipherSuite = "HIGH"
                                              , tpInsecure = False
                                              }
                     , cpSocks = Nothing
                     }

withConnection :: ConnectionParams -> (Connection -> IO a) -> IO a
withConnection params body =
    bracket (connect params) close body

authorize :: Config -> Connection -> IO ()
authorize conf conn =
    do sendMsg conn (ircPass $ configPass conf)
       sendMsg conn (ircNick $ configNick conf)
       sendMsg conn (ircJoin (configChannel conf) Nothing)

readIrcLine :: Connection -> IO (Maybe IrcMsg)
readIrcLine conn =
    do mb <- recvLine conn maxIrcMessage
       for mb $ \xs ->
           case parseRawIrcMsg (asUtf8 xs) of
             Just msg -> return $! cookIrcMsg msg
             Nothing -> fail "Server sent invalid message!"

sendMsg :: Connection -> RawIrcMsg -> IO ()
sendMsg conn msg = send conn (renderRawIrcMsg msg)

applyEffect :: Config -> EffectState -> Effect () -> IO ()
applyEffect _ _ (Pure r) = return r
applyEffect conf effectState (Free (Say text s)) =
    do sendMsg (esIrcConn effectState) (ircPrivmsg (configChannel conf) text)
       applyEffect conf effectState s
applyEffect conf effectState (Free (LogMsg msg s)) =
    do putStrLn $ T.unpack msg
       applyEffect conf effectState s
applyEffect conf effectState (Free (Now s)) =
    do timestamp <- getCurrentTime
       applyEffect conf effectState (s timestamp)

applyEffect conf effectState (Free (CreateEntity name properties s)) =
    do entityId <- SEP.createEntity (esSqliteConn effectState) name properties
       applyEffect conf effectState (s entityId)
applyEffect conf effectState (Free (GetEntityById name entityId s)) =
    do entity <- SEP.getEntityById (esSqliteConn effectState) name entityId
       applyEffect conf effectState (s entity)
applyEffect conf effectState (Free (GetRandomEntity name s)) =
    do entity <- SEP.getRandomEntity (esSqliteConn effectState) name
       applyEffect conf effectState (s entity)
applyEffect conf effectState (Free (HttpRequest request s)) =
    do response <- httpLBS request
       applyEffect conf effectState (s response)
-- TODO(#90): applyEffect for Timeout is not implemented
applyEffect conf effectState (Free (Timeout _ _ s)) =
    applyEffect conf effectState s

ircTransport :: Bot -> Config -> EffectState -> IO ()
ircTransport b conf effectState =
    -- TODO(#17): check unsuccessful authorization
    do authorize conf ircConn
       SQLite.withTransaction sqliteConn $ applyEffect conf effectState $ b Join
       eventLoop b conf effectState
    where ircConn = esIrcConn effectState
          sqliteConn = esSqliteConn effectState


eventLoop :: Bot -> Config -> EffectState -> IO ()
eventLoop b conf effectState =
    do mb <- readIrcLine ircConn
       for_ mb $ \msg ->
           do print msg
              case msg of
                Ping xs -> sendMsg ircConn (ircPong xs)
                Privmsg userInfo _ msgText -> SQLite.withTransaction sqliteConn
                                                $ applyEffect conf effectState (b $ Msg (idText $ userNick $ userInfo) msgText)
                _ -> return ()
              eventLoop b conf effectState
    where ircConn = esIrcConn effectState
          sqliteConn = esSqliteConn effectState

mainWithArgs :: [String] -> IO ()
mainWithArgs [configPath, databasePath] =
    do conf <- configFromFile configPath
       withConnection twitchConnectionParams
         $ \ircConn -> SQLite.withConnection databasePath
         $ \sqliteConn -> do SEP.prepareSchema sqliteConn
                             ircTransport bot conf
                               $ EffectState { esIrcConn = ircConn
                                             , esSqliteConn = sqliteConn
                                             , esTimeouts = []
                                             }
mainWithArgs _ = error "./HyperNerd <config-file> <database-file>"

main :: IO ()
main = getArgs >>= mainWithArgs
