{-# LANGUAGE OverloadedStrings #-}
module Bot.Variable ( expandVariables
                    , addVariable
                    , deleteVariable
                    ) where

import           Command
import qualified Data.Map as M
import qualified Data.Text as T
import           Effect
import           Entity
import           Property

data Variable = Variable { variableName :: T.Text
                         , variableValue :: T.Text
                         } deriving Show

instance IsEntity Variable where
    toProperties variable =
        M.fromList [ ("name", PropertyText $ variableName variable)
                   , ("value", PropertyText $ variableValue variable)
                   ]
    fromProperties properties =
        do name <- extractProperty "name" properties
           value <- extractProperty "value" properties
           return $ Variable name value

-- TODO: expandVariables is not implemented
expandVariables :: T.Text -> Effect T.Text
expandVariables = return

-- TODO: addVariable is not implemented
addVariable :: CommandHandler T.Text
addVariable _ _ = return ()

-- TODO: deleteVariable is not implemented
deleteVariable :: CommandHandler T.Text
deleteVariable _ _ = return ()
