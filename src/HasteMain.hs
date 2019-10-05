module Main where

import Haste.DOM (withElems, getValue, setProp)
import Haste.Events (onEvent, MouseEvent(Click))

import qualified Language.Carriage.Evaluator as Evaluator


main = withElems ["prog", "result", "run-button"] driver

driver [progElem, resultElem, runButtonElem] =
    onEvent runButtonElem Click $ \_ -> do
        Just prog <- getValue progElem
        setProp resultElem "textContent" $ show $ Evaluator.run prog
