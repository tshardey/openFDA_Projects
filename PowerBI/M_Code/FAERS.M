let
    URL = "https://api.fda.gov/drug/event.json?&search=reportduplicate.duplicatesource:concordia",
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
    #"Expanded Column1" = Table.ExpandRecordColumn(#"Converted to Table", "Column1", {"reporttype", "receiptdateformat", "receiver", "companynumb", "safetyreportversion", "receivedateformat", "primarysource", "seriousnessother", "duplicate", "transmissiondateformat", "fulfillexpeditecriteria", "safetyreportid", "sender", "receivedate", "patient", "transmissiondate", "serious", "reportduplicate", "receiptdate", "primarysourcecountry", "seriousnesshospitalization"}, {"reporttype", "receiptdateformat", "receiver", "companynumb", "safetyreportversion", "receivedateformat", "primarysource", "seriousnessother", "duplicate", "transmissiondateformat", "fulfillexpeditecriteria", "safetyreportid", "sender", "receivedate", "patient", "transmissiondate", "serious", "reportduplicate", "receiptdate", "primarysourcecountry", "seriousnesshospitalization"}),
    #"Expanded receiver" = Table.ExpandRecordColumn(#"Expanded Column1", "receiver", {"receivertype", "receiverorganization"}, {"receivertype", "receiverorganization"}),
    #"Expanded primarysource" = Table.ExpandRecordColumn(#"Expanded receiver", "primarysource", {"qualification", "reportercountry"}, {"qualification", "reportercountry"}),
    #"Expanded sender" = Table.ExpandRecordColumn(#"Expanded primarysource", "sender", {"senderorganization", "sendertype"}, {"senderorganization", "sendertype"}),
    #"Expanded patient" = Table.ExpandRecordColumn(#"Expanded sender", "patient", {"patientonsetage", "reaction", "patientonsetageunit", "patientsex", "drug", "summary"}, {"patientonsetage", "reaction", "patientonsetageunit", "patientsex", "drug", "summary"}),
    #"Expanded reportduplicate" = Table.ExpandRecordColumn(#"Expanded patient", "reportduplicate", {"duplicatesource", "duplicatenumb"}, {"duplicatesource", "duplicatenumb"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded reportduplicate",{"summary"}),
    #"Expanded reaction" = Table.ExpandListColumn(#"Removed Columns", "reaction"),
    #"Expanded reaction1" = Table.ExpandRecordColumn(#"Expanded reaction", "reaction", {"reactionmeddraversionpt", "reactionmeddrapt"}, {"reactionmeddraversionpt", "reactionmeddrapt"}),
    #"Expanded drug" = Table.ExpandListColumn(#"Expanded reaction1", "drug"),
    #"Expanded drug1" = Table.ExpandRecordColumn(#"Expanded drug", "drug", {"activesubstance", "drugbatchnumb", "drugadministrationroute", "drugcharacterization", "medicinalproduct", "openfda"}, {"activesubstance", "drugbatchnumb", "drugadministrationroute", "drugcharacterization", "medicinalproduct", "openfda"}),
    #"Removed Columns1" = Table.RemoveColumns(#"Expanded drug1",{"drugbatchnumb", "drugadministrationroute", "drugcharacterization", "openfda"}),
    #"Expanded activesubstance" = Table.ExpandRecordColumn(#"Removed Columns1", "activesubstance", {"activesubstancename"}, {"activesubstancename"}),
    #"Removed Duplicates" = Table.Distinct(#"Expanded activesubstance", {"reactionmeddrapt"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Duplicates",{{"receivedate", type date}, {"transmissiondate", type date}, {"receiptdate", type date}, {"reporttype", Int64.Type}, {"receiptdateformat", Int64.Type}, {"receivertype", Int64.Type}, {"safetyreportversion", Int64.Type}, {"qualification", Int64.Type}, {"seriousnessother", Int64.Type}, {"duplicate", Int64.Type}, {"fulfillexpeditecriteria", Int64.Type}, {"patientonsetage", Int64.Type}, {"patientsex", Int64.Type}, {"seriousnesshospitalization", Int64.Type}})
in
    #"Changed Type"