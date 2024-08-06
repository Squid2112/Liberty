<cfcomponent displayname="ObjectComponent" output="no">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfscript>
			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>