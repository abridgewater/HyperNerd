{-# LANGUAGE ViewPatterns #-}

module Bot.Calc
  ( calcCommand
  ) where

import Bot.Replies
import Data.Char (isDigit)
import Data.Either.Extra
import qualified Data.Text as T
import Reaction
import Safe
import Transport

data Expr
  = NumberExpr Int
  | PlusExpr Expr
             Expr
  deriving (Eq, Show)

data Token
  = NumberToken Int
  | PlusToken
  deriving (Eq, Show)

tokenize :: T.Text -> Either String [Token]
tokenize (T.uncons -> Just (' ', xs)) = tokenize xs
tokenize (T.uncons -> Just ('+', xs)) = (PlusToken :) <$> tokenize xs
-- TODO(#568): Minusation operation is not supported by !calc
tokenize (T.uncons -> Just ('-', _)) =
  Left "https://github.com/tsoding/HyperNerd/issues/568"
-- TODO(#569): Multiplication operation is not supported by !calc
tokenize (T.uncons -> Just ('*', _)) =
  Left "https://github.com/tsoding/HyperNerd/issues/569"
-- TODO(#570): Division operation is not supported by !calc
tokenize (T.uncons -> Just ('/', _)) =
  Left "https://github.com/tsoding/HyperNerd/issues/570"
-- TODO(#574): !calc does not support fractional numbers
tokenize (T.uncons -> Just ('.', _)) =
  Left "https://github.com/tsoding/HyperNerd/issues/574"
-- TODO(#571): Parenthesis are not supported by !calc
-- TODO(#573): !calc does not support negative numbers
-- TODO(#567): !calc Int overflow is not reported as an error
tokenize xs@(T.uncons -> Just (x, _))
  | x `elem` ['(', ')'] = Left "https://github.com/tsoding/HyperNerd/issues/571"
  | isDigit x = do
    token <- NumberToken <$> maybeToEither "Error 😡" (readMay $ T.unpack digits)
    (token :) <$> tokenize rest
  where
    (digits, rest) = T.span isDigit xs
tokenize (T.uncons -> Nothing) = return []
tokenize _ = Left "Error 😡"

parseExpr :: [Token] -> Either String Expr
parseExpr [NumberToken x] = Right $ NumberExpr x
parseExpr (NumberToken x:PlusToken:rest) =
  PlusExpr (NumberExpr x) <$> parseExpr rest
parseExpr _ = Left "Error 😡"

interpretExpr :: Expr -> Int
interpretExpr (NumberExpr x) = x
interpretExpr (PlusExpr a b) = interpretExpr a + interpretExpr b

calc :: T.Text -> Either String Int
calc text = do
  tokens <- tokenize text
  expr <- parseExpr tokens
  return $ interpretExpr expr

calcCommand :: Reaction Message T.Text
calcCommand =
  cmapR calc $ replyLeft $ cmapR (T.pack . show) $ Reaction replyMessage
