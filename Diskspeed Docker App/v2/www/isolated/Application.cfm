<cfsetting enablecfoutputonly="true" requesttimeout="600">
<cfapplication clientmanagement="false" sessionmanagement="true" name="DiskSpeed" applicationtimeout="#CreateTimeSpan(1,0,0,0)#" sessiontimeout="#CreateTimeSpan(1,0,0,0)#">
<CFINCLUDE TEMPLATE="../CustomTags.cfm">
<CFINCLUDE TEMPLATE="../environment.cfm">
<CFOBJECT name="Utils" component="CustomTags">
