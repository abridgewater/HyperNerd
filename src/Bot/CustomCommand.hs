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

deleteCustomCommand :: CommandTable a -> CommandHandler T.Text
deleteCustomCommand builtinCommands sender name =
    do customCommand  <- customCommandByName name
       builtinCommand <- return $ M.lookup name builtinCommands

       if isJust customCommand
       then do _ <- deleteEntities "CustomCommand" (Filter (PropertyEquals "name" $ PropertyText name) All)
               replyToSender sender $ T.pack $ printf "Command '%s' has been removed" name
       else if isJust builtinCommand
            then replyToSender sender $ T.pack $ printf "Command '%s' is builtin and can't be removed like that" name
            else replyToSender sender $ T.pack $ printf "Command '%s' does not exist" name

dispatchCustomCommand :: Sender -> Command T.Text -> Effect ()
dispatchCustomCommand _ command =
    do customCommand <- customCommandByName $ commandName command
       maybe (return ())
             (say . customCommandMessage)
             customCommand

-- TODO(#170): There is no way to update a custom command
