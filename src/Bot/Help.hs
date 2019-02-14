{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Bot.Help
  ( helpCommand
  ) where

import Bot.Replies
import Command
import Data.List
import qualified Data.Map as M
import qualified Data.Text as T
import Transport
import Reaction
import Text.InterpolatedString.QM

helpCommand :: CommandTable -> Reaction Message T.Text
helpCommand commandTable =
  ifR
    T.null
    (replyAvaliableCommands commandTable)
    (replyHelpForCommand commandTable)

replyHelpForCommand :: CommandTable -> Reaction Message T.Text
replyHelpForCommand commandTable =
  cmapR (`M.lookup` commandTable) $
  replyOnNothing "Cannot find such command FeelsBadMan" $
  cmapR fst $ Reaction replyMessage

replyAvaliableCommands :: CommandTable -> Reaction Message T.Text
replyAvaliableCommands commandTable =
  cmapR (const $ availableCommandsReply commandTable) $ Reaction replyMessage

availableCommandsReply :: CommandTable -> T.Text
availableCommandsReply commandTable =
  let commandList =
        T.concat $
        intersperse (T.pack ", ") $
        map (\x -> T.concat [T.pack "!", x]) $ M.keys commandTable
   in [qm|Available commands: {commandList}|]
