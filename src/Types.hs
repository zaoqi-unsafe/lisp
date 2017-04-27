module Types where

import           Control.Exception
import           Data.IORef
import           Data.Typeable
import           Text.ParserCombinators.Parsec (ParseError)


-- Env
type Env = IORef [(String, IORef LispVal)]


-- Error
type Expected = LispVal
type Got = LispVal

data LispError = UnboundVar String
               | SyntaxError ParseError
               | BadSpecialForm LispVal
               | NumArgs Integer [LispVal]
               | TypeMismatch Expected Got
               | NotAFunction LispVal
               | Default String
              deriving (Typeable)

instance Exception LispError

instance Show LispError where
  show (UnboundVar var) =
    "Unbound Var: " ++ var
  show (SyntaxError parseError) =
    "Syntax Error: " ++ show parseError
  show (BadSpecialForm specialForm) =
    "Unrecognized special form: " ++ show specialForm
  show (NotAFunction val) =
    "Not a function: " ++ show val


-- Val
data Purity = Pure ([LispVal] -> LispVal)
            | Impure (Env -> [LispVal] -> IO LispVal)


data LispVal = Symbol String
             | List [LispVal]
             | Number Integer
             | String String
             | Bool Bool
             | Nil
             | PrimitiveFunc { isMacro :: Bool, purity :: Purity }
             | Func { isMacro' :: Bool,
                      params   :: [String],
                      varargs  :: Bool,
                      body     :: [LispVal],
                      closure  :: Env }

instance Eq LispVal where
  Symbol a == Symbol b =
    a == b
  Number a == Number b =
    a == b
  List a == List b =
    a == b
  Bool a == Bool b =
    a == b
  Nil == Nil =
    True
  _ == _ =
    False


instance Show LispVal where
  show val =
    case val of
      Symbol s               -> s
      List list              -> "(" ++ showListContents list  ++ ")"
      Number n               -> show n
      String s               -> "\"" ++ s ++ "\""
      Bool True              -> "true"
      Bool False             -> "false"
      Nil                    -> "nil"
      PrimitiveFunc { isMacro = isMacro }      -> "<primitive " ++ (if isMacro then "macro" else "function") ++ ">"
      Func {params = params, varargs = varargs, body = body} ->
        "(lambda " ++ showParams params varargs ++ " " ++ showListContents body  ++ ")"


showListContents =
  unwords . map show

showParams params varargs
  | varargs && (length params == 1) =
    head params

  | varargs =
    "(" ++ unwords (init params) ++ " . " ++ last params ++ ")"

  | otherwise =
    "(" ++ unwords params ++ ")"

