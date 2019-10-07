module Main where

import System.Environment
import System.Exit
import System.IO

import qualified Language.Carriage.Evaluator as Evaluator


main = do
    args <- getArgs
    case args of
        ["run", fileName] -> do
            text <- readFile fileName
            putStrLn $ show $ reverse $ Evaluator.run text
            return ()
        _ -> do
            abortWith "Usage: carriage run <carriage-program-text-filename>"

abortWith msg = do
    hPutStrLn stderr msg
    exitWith (ExitFailure 1)
