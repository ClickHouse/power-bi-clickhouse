// Text functions as FOLDED custom columns (unlike TextFunctions, which checks values on an
// already-fetched scalar): base-Sql92 foldings (Upper/Lower/Length/Start/End/Replace) plus
// the Text.PositionOf override, including its not-found -> -1 contract.
(source) =>
let
    t = Table.Buffer(Table.SelectRows(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(
        Table.AddColumn(source[text],
            "up",  each Text.Upper([s]), type text),
            "lo",  each Text.Lower([s]), type text),
            "len", each Text.Length([s]), Int64.Type),
            "l5",  each Text.Start([s], 5), type text),
            "r5",  each Text.End([s], 5), type text),
            "rep", each Text.Replace([s], "o", "0"), type text),
            "posF", each Text.PositionOf([s], "World"), Int64.Type),
            "posN", each Text.PositionOf([s], "zzz"), Int64.Type),
        each [rid] = 1)){0}
in
    [
        Upper = t[up], Lower = t[lo], Len = t[len],
        Left5 = t[l5], Right5 = t[r5], Replaced = t[rep],
        PosFound = t[posF], PosNotFound = t[posN]
    ]
