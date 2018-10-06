let
    URL = "https://api.fda.gov/device/recall.json?&search=firm_fei_number:1417572+3002806460+2025695+1036337",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"other_submission_description", "res_event_number", "firm_fei_number", "k_numbers", "openfda", "product_code", "root_cause_description", "pma_numbers", "event_date_terminated", "product_res_number"}, {"other_submission_description", "res_event_number", "firm_fei_number", "k_numbers", "openfda", "product_code", "root_cause_description", "pma_numbers", "event_date_terminated", "product_res_number"}),
    #"Extracted Values" = Table.TransformColumns(#"Expanded Column1", {"k_numbers", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Expanded openfda" = Table.ExpandRecordColumn(#"Extracted Values", "openfda", {"device_name", "registration_number", "device_class", "medical_specialty_description", "regulation_number"}, {"openfda.device_name", "openfda.registration_number", "openfda.device_class", "openfda.medical_specialty_description", "openfda.regulation_number"}),
    #"Extracted Values1" = Table.TransformColumns(#"Expanded openfda", {"openfda.registration_number", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Removed Columns" = Table.RemoveColumns(#"Extracted Values1",{"openfda.registration_number", "pma_numbers"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"event_date_terminated", type date}}),
    #"Removed Duplicates" = Table.Distinct(#"Changed Type", {"product_res_number"})
in
    #"Removed Duplicates"