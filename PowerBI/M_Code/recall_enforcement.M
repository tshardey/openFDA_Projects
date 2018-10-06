let
    URL = "https://api.fda.gov/device/enforcement.json?&search=recalling_firm:baxter",
    relative = "&limit=100&skip=",
    other = [ApiKeyName="api_key"],  
    
    //Get total number of results
    TotalNumber = let
                    Source = Json.Document(Web.Contents(URL, other)),
                    #"meta" = Source[meta],
                    results = #"meta"[results],
                    total1 = results[total]
                in
                    total1,

    //Find number of calls and Round up
    APICalls = Number.RoundUp(TotalNumber /100),
    
    CAllUPIURL = (x as text) => 
        let
            Source = Json.Document(Web.Contents(URL & relative & x, other)),
            results = Source[results]
        in
            results,

    //List.Generate - To create the dynamic URL 
    LG=List.RemoveNulls(List.Generate(
                        ()=>[i=-1, newURL = null], 
                        each [i] < APICalls,
                        each [i=[i]+1, newURL = Number.ToText(100*i)],
                        each try CAllUPIURL([newURL]) otherwise null
            )),
    #"List Combine" = List.Combine(LG),
    #"Converted to Table" = Table.FromList(#"List Combine", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"country", "reason_for_recall", "code_info", "product_quantity", "center_classification_date", "distribution_pattern", "state", "product_description", "report_date", "classification", "openfda", "recall_number", "recalling_firm", "initial_firm_notification", "event_id", "product_type", "termination_date", "recall_initiation_date", "postal_code", "voluntary_mandated", "status"}, {"country", "reason_for_recall", "code_info", "product_quantity", "center_classification_date", "distribution_pattern", "state", "product_description", "report_date", "classification", "openfda", "recall_number", "recalling_firm", "initial_firm_notification", "event_id", "product_type", "termination_date", "recall_initiation_date", "postal_code", "voluntary_mandated", "status"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded Column1",{"state", "openfda"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"termination_date", type date}, {"recall_initiation_date", type date}}),
    #"Removed Columns1" = Table.RemoveColumns(#"Changed Type",{"postal_code", "country"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Removed Columns1",{{"report_date", type date}, {"center_classification_date", type date}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type1", "initial_to_termination", each [termination_date]-[recall_initiation_date]),
    #"Changed Type2" = Table.TransformColumnTypes(#"Added Custom",{{"initial_to_termination", type duration}}),
    #"Removed Duplicates" = Table.Distinct(#"Changed Type2", {"recall_number"})
in
    #"Removed Duplicates"