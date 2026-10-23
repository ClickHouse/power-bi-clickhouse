// Aggregate function coverage (from the DirectQuery function list): Sum/Min/Max/Average/Count.
(source) =>
let
    n = source[numbers]
in
    [
        SumI32   = List.Sum(n[i32]),
        MinI16   = List.Min(n[i16]),
        MaxI16   = List.Max(n[i16]),
        AvgF64   = List.Average(n[f64]),
        CountAll = List.Count(n[rid]),
        SumDec   = List.Sum(n[dec92])
    ]
