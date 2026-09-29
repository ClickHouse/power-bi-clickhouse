// Sort + FirstN folds to ORDER BY ... LIMIT.
(source) =>
let
    top3 = Table.Buffer(Table.FirstN(Table.Sort(source[events], {{"id", Order.Descending}}), 3))
in
    [
        Ids = Text.Combine(List.Transform(top3[id], Text.From), ",")
    ]
