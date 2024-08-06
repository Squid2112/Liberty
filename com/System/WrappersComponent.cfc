<cfcomponent displayname="WrappersObjectComponent" hint="Provides wrappers for functions not implemented in core CF script">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfreturn this>
	</cffunction>

	<cffunction name="htmlhead" access="public" returntype="void" output="yes">
		<cfargument name="Text" type="string" required="yes">
		<cfhtmlhead text="#Arguments.Text#">
	</cffunction>

	<cffunction name="headers" access="public" returntype="void" output="yes">
		<cfargument name="name" type="string" required="yes">
		<cfargument name="value" type="string" required="yes">
		<cfargument name="charSet" type="string" required="no" default="UTF-8">
		<cfargument name="headerType" type="string" required="no" default="">
		<cfargument name="statusCode" type="string" required="no" default="">
		<cfargument name="statusText" type="string" required="no" default="">
		<cfheader name="#Arguments.name#" value="#Arguments.value#" charset="#Arguments.charSet#">
	</cffunction>

	<cffunction name="include" access="public" returntype="void" output="yes">
		<cfargument name="template" type="any" required="yes">
		<cfinclude template="#Arguments.template#">
	</cffunction>

	<cffunction name="setCookie" access="public" returntype="any" output="yes">
		<cfargument name="CGI" type="any" required="yes">
		<cfargument name="Name" type="any" required="yes">
		<cfargument name="Value" type="any" required="yes">
 		<cfcookie domain="#Arguments.CGI.SERVER_NAME#" name="#Arguments.Name#" value="#Arguments.Value#" expires="never">
	</cffunction>

	<cffunction name="deleteCookie" access="public" returntype="any" output="yes">
		<cfargument name="CGI" type="any" required="yes">
		<cfargument name="Cookie" type="any" required="yes">
		<cfargument name="Name" type="any" required="no" default="">

		<cfset var theCookie = "">
		<cfif Arguments.Name EQ "">
			<cfloop collection="#Arguments.Cookie#" item="theCookie">
				<cfif NOT listFindNoCase("UUID,CFID,CFTOKEN,JSESSIONID",theCookie)>
					<cfcookie domain="#Arguments.CGI.SERVER_NAME#" name="#theCookie#" value="" expires="now">
					<cfset structDelete(Arguments.Cookie,"#theCookie#",false)>
				</cfif>
			</cfloop>
		<cfelse>
			<cfcookie domain="#cgi.SERVER_NAME#" name="#Arguments.Name#" value="" expires="now">
			<cfset structDelete(Cookie, "#Arguments.Name#", false)>
		</cfif>
	</cffunction>

	<cffunction name="cfmFileRead" returntype="any" access="public" output="no">
		<cfargument name="cfmFile" type="any" required="yes">
		<cfset var result = "">
		<cfsavecontent variable="result"><cfinclude template="#Arguments.cfmFile#"></cfsavecontent>
		<cfreturn result>
	</cffunction>

	<cffunction name="abort" returntype="any" access="public" output="no">
		<cfabort>
	</cffunction>

	<cffunction name="dsnExists" access="public" returntype="boolean" output="no">
		<cfargument name="DSN" type="string" required="yes">
		<cftry>
			<cfquery name="test" datasource="#Arguments.DSN#">
				SELECT * FROM INFORMATION_SCHEMA.TABLES
			</cfquery>
			<cfcatch type="any">
				<cfreturn false>
			</cfcatch>
		</cftry>
		<cfreturn false>
	</cffunction>

	<cffunction name="onMissingMethod" access="public" returntype="any" output="no">
		<cfreturn Arguments>
	</cffunction>

</cfcomponent>