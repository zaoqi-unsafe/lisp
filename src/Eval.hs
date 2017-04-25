module Eval where

import           Control.Exception
import           Env
import           Parse
import           System.Console.Repl
import           Types


{- Eval -}
eval :: Env -> LispVal -> IO LispVal
eval env val =
  case val of
    String _ ->
      return val

    Bool _ ->
      return val

    Number _ ->
      return val

    List [] ->
      return val

    Nil ->
      return val

    Symbol s ->
      getVar env s


    List (func : args) -> do
      evaluatedFunc <- eval env func
      if isMacro evaluatedFunc then
        apply env evaluatedFunc args >>= eval env
      else
        evalMany env args >>= apply env evaluatedFunc


    badForm ->
      throw (BadSpecialForm badForm)


evalMany env = traverse (eval env)
evalBody env body = last <$> evalMany env body

evalString, evalFile :: Env -> String -> IO ()
evalString env string =
  withCatch $
    readOne string >>= eval env >>= print

evalFile env file =
  withCatch $ do
     readFile file >>= readMany >>= evalMany env
     return ()

withCatch action =
  catch action (printError :: LispError -> IO ())




{- Apply -}
apply :: Env -> LispVal -> [LispVal] -> IO LispVal
apply env PrimitiveFunc { purity = p } args =
  case p of
    Pure func ->
      return $ func args
    Impure func ->
      func env args

apply env (Func isMacro params varargs body closure) args = do
  envWithArgs <- bindVars closure $ zipParamsArgs params varargs args
  evalBody envWithArgs body

zipParamsArgs :: [String] -> Bool -> [LispVal] -> [(String, LispVal)]
zipParamsArgs params varargs args =
  if varargs then
    let
      (normalargs, varargs) = splitAt (length params - 1) args
    in
      zip (init params) normalargs ++ [(last params, List varargs)]
  else
    zip params args



{- Fn -}
makeFn :: Bool -> [LispVal] -> [LispVal] -> Env -> IO LispVal
makeFn isMacro params body env =
  return $ Func isMacro stringParams varargs body env
  where stringParams = filter (/= ".") $ map extractString params
        extractString (Symbol s) = s
        varargs = case drop (length params - 2) params of
          [Symbol ".", Symbol vararg] -> True
          _                           -> False

makeFunc = makeFn False
makeMacro = makeFn True
