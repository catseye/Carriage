module Language.Carriage.Evaluator where

explode = error "BOOM"

data Elem = Int Integer
          | Fn ([Elem] -> [Elem])
          | Sym Char
instance Show Elem where
    show (Int i) = show i
    show (Fn _)  = "<fn>"
    show (Sym c) = show [c]
 
pop (e:s) = (e, s)
push s e = (e:s)

pick 0 ((Sym _):_) = explode
pick 0 (e:_) = e
pick n (_:s) = pick (n-1) s

slice _ 0 _ = []
slice p k s = slice' p (reverse s)
    where
        slice' 0 s = take (fromIntegral k) s
        slice' n (_:s) = slice' (n-1) s

ci " " = id
ci "\n" = id
ci "1" = \s -> push s $ Int 1
ci "$" = snd . pop
ci "#" = \s -> push s $ Int $ fromIntegral $ length s
ci "~" = (\s ->
    let
        (Int a, s') = pop(s)
    in
        push s' $ pick a s')
ci "\\" = (\s ->
    let
        (a, s') = pop(s)
        (b, s'') = pop(s')
    in
        push (push s'' a) b)
ci "+" = (\s ->
    let
        (Int a, s') = pop(s)
        (Int b, s'') = pop(s')
    in
        push s'' $ Int (a + b))
ci "-" = (\s ->
    let
        (Int a, s') = pop(s)
        (Int b, s'') = pop(s')
    in
        push s'' $ Int (b - a))
ci "@" = (\s ->
    let
        (Int k, s') = pop(s)
        (Int p, s'') = pop(s')
        fn = ci $ map (\(Sym c) -> c) $ slice p k s''
    in
        push s'' (Fn fn))
ci "!" = \s -> let (Fn f, s') = pop(s) in f s'
ci [] = id
ci [_] = explode
ci (sym:rest) = \x -> (ci rest) ((ci [sym]) x)

di = reverse . map (\x -> Sym x) . filter (\x -> x /= ' ')

run prog = (ci prog) (di prog)
