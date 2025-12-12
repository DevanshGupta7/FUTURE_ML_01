let
    Source = Superstore,

    ChangedTypes = Table.TransformColumnTypes(Source, {{"Order Date", type date}, {"Sales", type number}, {"Region", type text}, {"Category", type text}}),

    StartDate = DateTime.Date(StartDateParam),
    EndDate = DateTime.Date(EndDateParam),
    CategoryFilter = CategoryParam,

    DateFiltered = Table.SelectRows(ChangedTypes, each [Order Date] >= StartDate and [Order Date] <= EndDate),

    CategoryFiltered = if Text.Lower(Text.From(CategoryFilter)) = "all" then DateFiltered else Table.SelectRows(DateFiltered, each [Category] = CategoryFilter),

    Grouped = Table.Group(
        CategoryFiltered,
        {"Region"},
        {{"TotalSales", each List.Sum([Sales]), type number}}
    ),

    Sorted = Table.Sort(Grouped, {{"TotalSales", Order.Descending}}),

    Result = Table.RenameColumns(Sorted, {{"Region", "Region"}, {"TotalSales", "Sales"}})
in
    Result