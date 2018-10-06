let
    URL = "https://api.fda.gov/device/510k.json?&search=applicant:ge",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"advisory_committee_description", "statement_or_summary", "product_code", "applicant", "decision_code", "decision_date", "device_name", "advisory_committee", "expedited_review_flag", "review_advisory_committee", "k_number", "date_received", "clearance_type", "decision_description"}, {"advisory_committee_description", "statement_or_summary", "product_code", "applicant", "decision_code", "decision_date", "device_name", "advisory_committee", "expedited_review_flag", "review_advisory_committee", "k_number", "date_received", "clearance_type", "decision_description"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded Column1",{"decision_code", "expedited_review_flag", "advisory_committee"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"date_received", type date}, {"decision_date", type date}}),
    #"Added Custom" = Table.AddColumn(#"Changed Type", "decision_duration", each [decision_date]-[date_received]),
    #"Changed Type1" = Table.TransformColumnTypes(#"Added Custom",{{"decision_duration", type duration}})
in
    #"Changed Type1"