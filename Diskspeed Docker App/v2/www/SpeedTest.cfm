<CFPARAM name="FORM.FastTest" default="0">

<cfdump var=#form#>

<CFFILE action="read" file="#PersistDir#/storage.json" variable="json">
<CFSET HW=DeserializeJSON(json)>

<CFSET Key=ListFirst(FORM.Drive,"|")>
<CFSET PortNo=ListLast(FORM.Drive,"|")>

<CFSET Info=HW[Key].Ports[PortNo]>
<cfdump var=#Info#>

