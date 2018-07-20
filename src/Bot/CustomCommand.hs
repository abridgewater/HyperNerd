{-# LANGUAGE OverloadedStrings #-}
module Bot.CustomCommand ( addCustomCommand
                         , deleteCustomCommand
                         , dispatchCustomCommand
                         ) where

import           Bot.Replies
import           Command
import qualified Data.Map as M
import           Data.Maybe
import qualified Data.Text as T
import           Effect
import           Entity
import           Events
import           Text.Printf

data CustomCommand = CustomCommand { customCommandName :: T.Text
                                   , customCommandMessage :: T.Text
                                   }

instance IsEntity CustomCommand where
    toProperties customCommand =
        M.fromList [ ("name", PropertyText $ customCommandName customCommand)
                   , ("message", PropertyText $ customCommandMessage customCommand)
                   ]
    fromEntity entity = do name <- extractProperty "name" entity
                           message <- extractProperty "message" entity
                           return CustomCommand { customCommandName = name
                                                , customCommandMessage = message
                                                }

customCommandByName :: T.Text -> Effect (Maybe CustomCommand)
customCommandByName name =
    do entities <- selectEntities "CustomCommand" (Filter (PropertyEquals "name" $ PropertyText name) All)
       return (listToMaybe entities >>= fromEntity)

addCustomCommand :: CommandTable a -> CommandHandler (T.Text, T.Text)
addCustomCommand builtinCommands sender (name, message) =
    do customCommand  <- customCommandByName name
       builtinCommand <- return $ M.lookup name builtinCommands
       if isJust customCommand || isJust builtinCommand
       then replyToUser (senderName sender)
              $ T.pack
              $ printf "Command '%s' already exists" name
       else do _ <- createEntity "CustomCommand" CustomCommand { customCommandName = name
                                                               , customCommandMessage = message
                                                               }
               replyToUser (senderName sender) $ T.pack $ printf "Add command '%s'" name

-- TODO: Bot.CustomCommand.deleteCustomCommand is not implemented
deleteCustomCommand :: CommandHandler T.Text
deleteCustomCommand sender _ = replyToUser (senderName sender) "Not implemented yet"

dispatchCustomCommand :: Sender -> Command T.Text -> Effect ()
dispatchCustomCommand _ command =
    do customCommand <- customCommandByName $ commandName command
       maybe (return ())
             (say . customCommandMessage)
             customCommand
