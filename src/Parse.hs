module Parse (readOne, readMany, ReadtableKey(..)) where

import           Control.Applicative.Alternative (asum)
import           Control.Monad.Reader
import           Text.Parsec                     (ParsecT, runParserT)
import           Text.ParserCombinators.Parsec   hiding (Parser, spaces)
import           Types

data ReadtableKey = Between String String | Prefix String
type ReadTable = [(ReadtableKey, String)]

type Parser a = ParsecT String () (Reader ReadTable) a


{- Whitespace -}
spaces = skipMany1 space

comment :: Parser ()
comment = do
  char ';'
  skipMany (noneOf "\n")


{- Expression -}
expr :: ReadTable -> Parser LispVal
expr readtable =
  e
  where e = p <|> symbol <|> number <|> string' <|> list
        p = readTableParser readtable

        {- Lists -}
        list = do
          char '('
          contents <- sepBy e spaces
          char ')'
          return $ List contents

        {- Strings -}
        literalString =
          String <$> many1 (noneOf ('\"' : readtableKeys))
          where readtableKeys = concatMap extractPrefix $ filter isPrefix $ map fst readtable
                isPrefix (Prefix _) = True
                isPrefix _          = False
                extractPrefix (Prefix s) = s


        string' = do
          char '"'
          xs <- many (p <|> literalString)
          char '"'
          return $ List (Symbol "string-append" : xs)


        {- Symbols -}
        symbolChar = oneOf "!#$%&|*+-/:<=>?@^_."

        symbolStr = do
          first <- letter <|> symbolChar
          rest  <- many (letter <|> digit <|> symbolChar)
          return $ first:rest

        symbol = do
          sym <- symbolStr
          return $ case sym of
            "true"  -> Bool True
            "false" -> Bool False
            "nil"   -> Nil
            _       -> Symbol sym

        {- Numbers -}
        number =
          (Number . read) <$> many1 digit

{- Parsing -}
readTableParser :: ReadTable -> Parser LispVal
readTableParser readtable =
  asum $ map makeParser readtable
  where makeParser (Prefix s, sym) = do
          string s
          e <- expr readtable
          return $ List [Symbol sym, e]

        makeParser (Between start end, sym) = do
          string start
          contents <- sepBy (expr readtable) spaces
          string end
          return $ List (Symbol sym:contents)


exprSurroundedByWhitespace = do
  readtable <- ask
  skipMany space
  e <- expr readtable
  skipMany space
  return e

readOne :: ReadTable -> String -> LispM LispVal
readOne = parseSyntaxError exprSurroundedByWhitespace

readMany :: ReadTable -> String -> LispM [LispVal]
readMany = parseSyntaxError $ many exprSurroundedByWhitespace

parseSyntaxError :: Parser a -> ReadTable -> String -> LispM a
parseSyntaxError p readtable code =
  case runReader (runParserT p () "lisp" code) readtable of
    Left e  -> throwWithStack $ SyntaxError e
    Right v -> return v

