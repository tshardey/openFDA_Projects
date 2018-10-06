let
    URL = "https://api.fda.gov/device/event.json?&search=device.manufacturer_d_name:%22cardinal%20health%22",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"report_to_fda", "event_type", "report_number", "type_of_report", "product_problem_flag", "date_received", "date_of_event", "reporter_occupation_code", "source_type", "device_date_of_manufacturer", "device", "health_professional", "patient", "date_report", "event_key", "mdr_report_key", "number_devices_in_event", "date_manufacturer_received", "remedial_action", "adverse_event_flag", "manufacturer_state", "manufacturer_country", "single_use_flag", "mdr_text", "number_patients_in_event", "distributor_name"}, {"report_to_fda", "event_type", "report_number", "type_of_report", "product_problem_flag", "date_received", "date_of_event", "reporter_occupation_code", "source_type", "device_date_of_manufacturer", "device", "health_professional", "patient", "date_report", "event_key", "mdr_report_key", "number_devices_in_event", "date_manufacturer_received", "remedial_action", "adverse_event_flag", "manufacturer_state", "manufacturer_country", "single_use_flag", "mdr_text", "number_patients_in_event", "distributor_name"}),
    #"Extracted Values" = Table.TransformColumns(#"Expanded Column1", {"type_of_report", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    #"Extracted Values1" = Table.TransformColumns(#"Extracted Values", {"source_type", each Text.Combine(List.Transform(_, Text.From), ","), type text}),
    #"Expanded device" = Table.ExpandListColumn(#"Extracted Values1", "device"),
    #"Expanded device1" = Table.ExpandRecordColumn(#"Expanded device", "device", {"manufacturer_d_address_1", "baseline_510_k__flag", "manufacturer_d_address_2", "device_event_key", "device_sequence_number", "manufacturer_d_state", "manufacturer_d_zip_code", "manufacturer_d_city", "lot_number", "manufacturer_d_postal_code", "manufacturer_d_zip_code_ext", "model_number", "date_received", "device_report_product_code", "device_operator", "device_availability", "baseline_510_k__number", "other_id_number", "generic_name", "manufacturer_d_name", "manufacturer_d_country", "brand_name", "openfda", "expiration_date_of_device", "device_age_text", "device_evaluated_by_manufacturer", "catalog_number", "baseline_510_k__exempt_flag", "implant_flag", "date_removed_flag"}, {"manufacturer_d_address_1", "baseline_510_k__flag", "manufacturer_d_address_2", "device_event_key", "device_sequence_number", "manufacturer_d_state", "manufacturer_d_zip_code", "manufacturer_d_city", "lot_number", "manufacturer_d_postal_code", "manufacturer_d_zip_code_ext", "model_number", "date_received.1", "device_report_product_code", "device_operator", "device_availability", "baseline_510_k__number", "other_id_number", "generic_name", "manufacturer_d_name", "manufacturer_d_country", "brand_name", "openfda", "expiration_date_of_device", "device_age_text", "device_evaluated_by_manufacturer", "catalog_number", "baseline_510_k__exempt_flag", "implant_flag", "date_removed_flag"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded device1",{"manufacturer_d_address_1", "baseline_510_k__flag", "manufacturer_d_address_2", "device_sequence_number", "manufacturer_d_state", "manufacturer_d_zip_code", "manufacturer_d_city", "manufacturer_d_postal_code", "manufacturer_d_zip_code_ext", "baseline_510_k__number", "other_id_number", "manufacturer_d_country", "openfda", "device_age_text", "device_evaluated_by_manufacturer", "baseline_510_k__exempt_flag", "date_removed_flag", "patient", "event_key", "number_devices_in_event", "remedial_action", "manufacturer_state", "manufacturer_country", "number_patients_in_event", "distributor_name"}),
    #"Expanded mdr_text" = Table.ExpandListColumn(#"Removed Columns", "mdr_text"),
    #"Expanded mdr_text1" = Table.ExpandRecordColumn(#"Expanded mdr_text", "mdr_text", {"mdr_text_key", "text_type_code", "patient_sequence_number", "text"}, {"mdr_text_key", "text_type_code", "patient_sequence_number", "text"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded mdr_text1",{"report_to_fda", "text_type_code", "patient_sequence_number"}),
    #"Removed Duplicates" = Table.Distinct(#"Removed Columns1", {"report_number"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Duplicates",{{"date_manufacturer_received", type date}, {"date_report", type date}}),
    #"Removed Columns2" = Table.RemoveColumns(#"Changed Type",{"implant_flag"}),
    #"Changed Type1" = Table.TransformColumnTypes(#"Removed Columns2",{{"expiration_date_of_device", type date}, {"date_received.1", type date}}),
    #"Removed Columns3" = Table.RemoveColumns(#"Changed Type1",{"device_event_key"}),
    #"Changed Type2" = Table.TransformColumnTypes(#"Removed Columns3",{{"device_date_of_manufacturer", type date}, {"date_of_event", type date}, {"date_received", type date}}),
    #"Removed Columns4" = Table.RemoveColumns(#"Changed Type2",{"reporter_occupation_code", "model_number", "catalog_number", "date_received.1"}),
    #"Sorted Rows" = Table.Sort(#"Removed Columns4",{{"date_received", Order.Descending}})
in
    #"Sorted Rows"