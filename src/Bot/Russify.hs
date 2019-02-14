{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}

module Bot.Russify
  ( russifyCommand
  ) where

import Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as B
import Data.FileEmbed
import qualified Data.Map.Lazy as M
import Data.Maybe
import qualified Data.Text as T
import Data.Text.Encoding
import Effect
import Reaction
import Transport

russifyCommand :: Reaction Message T.Text
russifyCommand = cmapR russify $ liftR say ignore

mazarusha :: M.Map T.Text T.Text
mazarusha =
  fromMaybe M.empty $
  decode $
  B.fromStrict $ encodeUtf8 $(embedStringFile "./resources/mazarusha.json")

russifyChar :: Char -> T.Text
russifyChar x = fromMaybe (T.pack [x]) $ M.lookup (T.pack [x]) mazarusha

russify :: T.Text -> T.Text
russify = T.concatMap russifyChar
