let 
    URL = "https://api.fda.gov/device/registrationlisting.json?&search=registration.owner_operator.firm_name:stryker",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"proprietary_name", "registration", "pma_number", "k_number", "products"}, {"proprietary_name", "registration", "pma_number", "k_number", "products"}),
    #"Extracted Values" = Table.TransformColumns(#"Expanded Column1", {"proprietary_name", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    #"Expanded registration" = Table.ExpandRecordColumn(#"Extracted Values", "registration", {"status_code", "iso_country_code", "registration_number", "owner_operator", "name", "fei_number", "initial_importer_flag", "us_agent", "reg_expiry_date_year"}, {"status_code", "iso_country_code", "registration_number", "owner_operator", "name", "fei_number", "initial_importer_flag", "us_agent", "reg_expiry_date_year"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded registration",{"iso_country_code"}),
    #"Expanded owner_operator" = Table.ExpandRecordColumn(#"Removed Columns", "owner_operator", {"owner_operator_number", "firm_name"}, {"owner_operator_number", "firm_name"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded owner_operator",{"us_agent"}),
    #"Expanded products" = Table.ExpandListColumn(#"Removed Columns1", "products"),
    #"Expanded products1" = Table.ExpandRecordColumn(#"Expanded products", "products", {"owner_operator_number", "created_date", "exempt", "product_code", "openfda"}, {"owner_operator_number.1", "created_date", "exempt", "product_code", "openfda"}),
    #"Expanded openfda" = Table.ExpandRecordColumn(#"Expanded products1", "openfda", {"device_name", "device_class", "regulation_number"}, {"openfda.device_name", "openfda.device_class", "openfda.regulation_number"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Expanded openfda",{{"created_date", type date}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Changed Type1",{{"created_date", type date}}),
    #"Removed Columns2" = Table.RemoveColumns(#"Changed Type",{"exempt"})
in
    #"Removed Columns2"