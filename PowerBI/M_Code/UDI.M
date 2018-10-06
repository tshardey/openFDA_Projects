let
    URL = "https://api.fda.gov/device/udi.json?&search=company_name:fresenius",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"has_donation_id_number", "mri_safety", "record_status", "is_rx", "is_labeled_as_nrl", "commercial_distribution_status", "device_description", "has_serial_number", "storage", "sterilization", "is_direct_marking_exempt", "is_labeled_as_no_nrl", "is_single_use", "identifiers", "is_otc", "version_or_model_number", "has_manufacturing_date", "brand_name", "is_combination_product", "is_kit", "product_codes", "is_pm_exempt", "device_count_in_base_package", "has_lot_or_batch_number", "customer_contacts", "catalog_number", "company_name", "has_expiration_date", "is_hct_p", "gmdn_terms", "publish_date"}, {"has_donation_id_number", "mri_safety", "record_status", "is_rx", "is_labeled_as_nrl", "commercial_distribution_status", "device_description", "has_serial_number", "storage", "sterilization", "is_direct_marking_exempt", "is_labeled_as_no_nrl", "is_single_use", "identifiers", "is_otc", "version_or_model_number", "has_manufacturing_date", "brand_name", "is_combination_product", "is_kit", "product_codes", "is_pm_exempt", "device_count_in_base_package", "has_lot_or_batch_number", "customer_contacts", "catalog_number", "company_name", "has_expiration_date", "is_hct_p", "gmdn_terms", "publish_date"}),
    #"Expanded storage" = Table.ExpandListColumn(#"Expanded Column1", "storage"),
    #"Expanded storage1" = Table.ExpandRecordColumn(#"Expanded storage", "storage", {"high", "low", "type"}, {"storage.high", "storage.low", "storage.type"}),
    #"Expanded storage.high" = Table.ExpandRecordColumn(#"Expanded storage1", "storage.high", {"unit", "value"}, {"storage.high.unit", "storage.high.value"}),
    #"Expanded storage.low" = Table.ExpandRecordColumn(#"Expanded storage.high", "storage.low", {"unit", "value"}, {"storage.low.unit", "storage.low.value"}),
    #"Expanded sterilization" = Table.ExpandRecordColumn(#"Expanded storage.low", "sterilization", {"is_sterilization_prior_use", "is_sterile"}, {"sterilization.is_sterilization_prior_use", "sterilization.is_sterile"}),
    #"Expanded identifiers" = Table.ExpandListColumn(#"Expanded sterilization", "identifiers"),
    #"Expanded identifiers1" = Table.ExpandRecordColumn(#"Expanded identifiers", "identifiers", {"issuing_agency", "id", "type"}, {"identifiers.issuing_agency", "identifiers.id", "identifiers.type"}),
    #"Expanded product_codes" = Table.ExpandListColumn(#"Expanded identifiers1", "product_codes"),
    #"Expanded product_codes1" = Table.ExpandRecordColumn(#"Expanded product_codes", "product_codes", {"code", "name"}, {"product_codes.code", "product_codes.name"}),
    #"Expanded gmdn_terms" = Table.ExpandListColumn(#"Expanded product_codes1", "gmdn_terms"),
    #"Expanded gmdn_terms1" = Table.ExpandRecordColumn(#"Expanded gmdn_terms", "gmdn_terms", {"name", "definition"}, {"gmdn_terms.name", "gmdn_terms.definition"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Expanded gmdn_terms1",{{"publish_date", type date}, {"is_hct_p", type logical}, {"has_expiration_date", type logical}}),
    #"Removed Columns" = Table.RemoveColumns(#"Changed Type",{"customer_contacts"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Removed Columns",{{"has_lot_or_batch_number", type logical}, {"is_kit", type logical}, {"is_pm_exempt", type logical}, {"is_otc", type logical}, {"has_manufacturing_date", type logical}, {"is_combination_product", type logical}, {"is_direct_marking_exempt", type logical}, {"is_labeled_as_no_nrl", type logical}, {"is_single_use", type logical}, {"sterilization.is_sterilization_prior_use", type logical}, {"sterilization.is_sterile", type logical}, {"storage.low.value", Int64.Type}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type1",{{"storage.high.unit", "storage.unit"}}),
    #"Removed Columns1" = Table.RemoveColumns(#"Renamed Columns",{"storage.low.unit"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Removed Columns1",{{"storage.high.value", Int64.Type}, {"is_rx", type logical}, {"is_labeled_as_nrl", type logical}, {"has_serial_number", type logical}, {"has_donation_id_number", type logical}})
in
    #"Changed Type2"