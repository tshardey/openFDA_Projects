let
    URL = "https://api.fda.gov/drug/label.json?&search=openfda.manufacturer_name:teva",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"effective_time", "inactive_ingredient", "purpose", "keep_out_of_reach_of_children", "warnings", "questions", "when_using", "spl_product_data_elements", "openfda", "version", "dosage_and_administration", "stop_use", "spl_unclassified_section", "do_not_use", "package_label_principal_display_panel", "spl_medguide", "indications_and_usage", "set_id", "id", "spl_medguide_table", "active_ingredient", "dosage_and_administration_table", "spl_unclassified_section_table", "precautions_table", "precautions", "general_precautions_table", "description", "general_precautions"}, {"effective_time", "inactive_ingredient", "purpose", "keep_out_of_reach_of_children", "warnings", "questions", "when_using", "spl_product_data_elements", "openfda", "version", "dosage_and_administration", "stop_use", "spl_unclassified_section", "do_not_use", "package_label_principal_display_panel", "spl_medguide", "indications_and_usage", "set_id", "id", "spl_medguide_table", "active_ingredient", "dosage_and_administration_table", "spl_unclassified_section_table", "precautions_table", "precautions", "general_precautions_table", "description", "general_precautions"}),
    #"Extracted Values" = Table.TransformColumns(#"Expanded Column1", {"inactive_ingredient", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors" = Table.ReplaceErrorValues(#"Extracted Values", {{"inactive_ingredient", null}}),
    #"Extracted Values1" = Table.TransformColumns(#"Replaced Errors", {"purpose", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors1" = Table.ReplaceErrorValues(#"Extracted Values1", {{"purpose", null}}),
    #"Extracted Values2" = Table.TransformColumns(#"Replaced Errors1", {"keep_out_of_reach_of_children", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors2" = Table.ReplaceErrorValues(#"Extracted Values2", {{"keep_out_of_reach_of_children", null}}),
    #"Extracted Values3" = Table.TransformColumns(#"Replaced Errors2", {"warnings", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors3" = Table.ReplaceErrorValues(#"Extracted Values3", {{"warnings", null}}),
    #"Extracted Values4" = Table.TransformColumns(#"Replaced Errors3", {"questions", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors4" = Table.ReplaceErrorValues(#"Extracted Values4", {{"questions", null}}),
    #"Extracted Values5" = Table.TransformColumns(#"Replaced Errors4", {"when_using", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors5" = Table.ReplaceErrorValues(#"Extracted Values5", {{"when_using", null}}),
    #"Extracted Values6" = Table.TransformColumns(#"Replaced Errors5", {"spl_product_data_elements", each Text.Combine(List.Transform(_, Text.From), ":"), type text}),
    #"Expanded openfda" = Table.ExpandRecordColumn(#"Extracted Values6", "openfda", {"is_original_packager", "generic_name", "pharm_class_cs", "brand_name", "manufacturer_name", "substance_name", "product_type", "route", "application_number", "pharm_class_epc"}, {"openfda.is_original_packager", "openfda.generic_name", "openfda.pharm_class_cs", "openfda.brand_name", "openfda.manufacturer_name", "openfda.substance_name", "openfda.product_type", "openfda.route", "openfda.application_number", "openfda.pharm_class_epc"}),
    #"Extracted Values7" = Table.TransformColumns(#"Expanded openfda", {"openfda.is_original_packager", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values8" = Table.TransformColumns(#"Extracted Values7", {"openfda.generic_name", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values9" = Table.TransformColumns(#"Extracted Values8", {"openfda.pharm_class_cs", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors6" = Table.ReplaceErrorValues(#"Extracted Values9", {{"openfda.pharm_class_cs", null}}),
    #"Extracted Values10" = Table.TransformColumns(#"Replaced Errors6", {"openfda.brand_name", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values11" = Table.TransformColumns(#"Extracted Values10", {"openfda.manufacturer_name", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values12" = Table.TransformColumns(#"Extracted Values11", {"openfda.substance_name", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values13" = Table.TransformColumns(#"Extracted Values12", {"openfda.product_type", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values14" = Table.TransformColumns(#"Extracted Values13", {"openfda.route", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values15" = Table.TransformColumns(#"Extracted Values14", {"openfda.application_number", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors7" = Table.ReplaceErrorValues(#"Extracted Values15", {{"openfda.application_number", null}}),
    #"Extracted Values16" = Table.TransformColumns(#"Replaced Errors7", {"openfda.pharm_class_epc", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors8" = Table.ReplaceErrorValues(#"Extracted Values16", {{"openfda.pharm_class_epc", null}}),
    #"Extracted Values17" = Table.TransformColumns(#"Replaced Errors8", {"dosage_and_administration", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values18" = Table.TransformColumns(#"Extracted Values17", {"stop_use", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors9" = Table.ReplaceErrorValues(#"Extracted Values18", {{"stop_use", null}}),
    #"Extracted Values19" = Table.TransformColumns(#"Replaced Errors9", {"spl_unclassified_section", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values20" = Table.TransformColumns(#"Extracted Values19", {"do_not_use", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors10" = Table.ReplaceErrorValues(#"Extracted Values20", {{"do_not_use", null}}),
    #"Extracted Values21" = Table.TransformColumns(#"Replaced Errors10", {"package_label_principal_display_panel", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values22" = Table.TransformColumns(#"Extracted Values21", {"spl_medguide", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors11" = Table.ReplaceErrorValues(#"Extracted Values22", {{"spl_medguide", null}}),
    #"Extracted Values23" = Table.TransformColumns(#"Replaced Errors11", {"indications_and_usage", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Extracted Values24" = Table.TransformColumns(#"Extracted Values23", {"spl_medguide_table", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors12" = Table.ReplaceErrorValues(#"Extracted Values24", {{"spl_medguide_table", null}}),
    #"Extracted Values25" = Table.TransformColumns(#"Replaced Errors12", {"active_ingredient", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors13" = Table.ReplaceErrorValues(#"Extracted Values25", {{"active_ingredient", null}}),
    #"Extracted Values26" = Table.TransformColumns(#"Replaced Errors13", {"dosage_and_administration_table", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors14" = Table.ReplaceErrorValues(#"Extracted Values26", {{"dosage_and_administration_table", null}}),
    #"Removed Columns" = Table.RemoveColumns(#"Replaced Errors14",{"spl_unclassified_section_table", "precautions_table", "general_precautions_table"}),
    #"Extracted Values27" = Table.TransformColumns(#"Removed Columns", {"precautions", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors15" = Table.ReplaceErrorValues(#"Extracted Values27", {{"precautions", null}}),
    #"Extracted Values28" = Table.TransformColumns(#"Replaced Errors15", {"description", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors16" = Table.ReplaceErrorValues(#"Extracted Values28", {{"description", null}}),
    #"Extracted Values29" = Table.TransformColumns(#"Replaced Errors16", {"general_precautions", each Text.Combine(List.Transform(_, Text.From)), type text}),
    #"Replaced Errors17" = Table.ReplaceErrorValues(#"Extracted Values29", {{"general_precautions", null}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Replaced Errors17",{{"effective_time", type date}}),
    #"Replaced Errors18" = Table.ReplaceErrorValues(#"Changed Type", {{"openfda.substance_name", null}}),
    #"Replaced Errors19" = Table.ReplaceErrorValues(#"Replaced Errors18", {{"openfda.route", null}}),
    #"Replaced Errors20" = Table.ReplaceErrorValues(#"Replaced Errors19", {{"spl_unclassified_section", null}}),
    #"Replaced Errors21" = Table.ReplaceErrorValues(#"Replaced Errors20", {{"dosage_and_administration", null}}),
    #"Replaced Errors22" = Table.ReplaceErrorValues(#"Replaced Errors21", {{"indications_and_usage", null}})
in
    #"Replaced Errors22"