<cfcomponent displayname="ExtJSONComponent" hint="Ext JSON output library">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" access="remote" returntype="JSON" output="No">
		<cfreturn this>
	</cffunction>

	<cffunction name="CFToJSON" access="remote" returntype="string" output="false" hint="Converts a ColdFusion object into a JSON object. Will return strings in the form of: new XXX().">
		<cfargument name="Data" type="any" required="true" hint="Can be any core ColdFusion data type.">
		<cfscript>
			if(IsQuery(ARGUMENTS.Data)) {
				return(this.QueryToJSON(ARGUMENTS.Data));
			} else if(IsStruct(ARGUMENTS.Data)) {
				return(this.StructToJSON(ARGUMENTS.Data));
			} else if(IsArray(ARGUMENTS.Data)) {
				return(this.ArrayToJSON(ARGUMENTS.Data));
			} else if (IsSimpleValue(ARGUMENTS.Data)) {
				return(this.StringToJSON(ARGUMENTS.Data));
			} else {
				return(this.StringToJSON("Unkown data type"));
			}
		</cfscript>
	</cffunction>

	<cffunction name="ArrayToJSON" access="public" returntype="string" hint="Converts a ColdFusion array to a JSON object. Will return strings in the form of: new Array().">
		<cfargument name="Data" type="array" required="true">
		<cfscript>
			var LOCAL = StructNew();
			LOCAL.ResponseBuffer = CreateObject("java", "java.lang.StringBuffer");
			LOCAL.ResponseBuffer.Append("[");
			for (LOCAL.Index = 1; LOCAL.Index LTE ArrayLen(ARGUMENTS.Data); LOCAL.Index = (LOCAL.Index + 1)) {
				if(LOCAL.Index GT 1) {
					LOCAL.ResponseBuffer.Append(",");
				}
				LOCAL.ResponseBuffer.Append(this.CFToJSON(ARGUMENTS.Data[LOCAL.Index]));
			}
			LOCAL.ResponseBuffer.Append("]");
			return(LOCAL.ResponseBuffer.ToString());
		</cfscript>
	</cffunction>

	<cffunction name="QueryToJSON" access="remote" returntype="string" output="false" hint="Converts a query to JSON for an array of structures. Will return strings in the form of 'new Array(new Object(), new Object()....);'">
		<cfargument name="Data" type="query" required="true">
		<cfscript>
			var LOCAL = StructNew();
			LOCAL.ColumnList = ListToArray(ARGUMENTS.Data.ColumnList);
			LOCAL.ResponseBuffer = CreateObject("java", "java.lang.StringBuffer");
			
//			LOCAL.ResponseBuffer.Append("[");
			for(LOCAL.RowIndex = 1; LOCAL.RowIndex LTE ARGUMENTS.Data.RecordCount; LOCAL.RowIndex = (LOCAL.RowIndex + 1)) {
				LOCAL.ResponseBuffer.Append( "{" );
				for(LOCAL.ColumnIndex = 1; LOCAL.ColumnIndex LTE ArrayLen(LOCAL.ColumnList); LOCAL.ColumnIndex = (LOCAL.ColumnIndex + 1)) {
					LOCAL.Key = LOCAL.ColumnList[LOCAL.ColumnIndex];
					LOCAL.ResponseBuffer.Append(LCase(LOCAL.Key) & ":" & this.CFToJSON(ARGUMENTS.Data[LOCAL.Key][LOCAL.RowIndex]));
					if(LOCAL.ColumnIndex LT ListLen(ARGUMENTS.Data.ColumnList)) {
						LOCAL.ResponseBuffer.Append(",");
					}
				}
				LOCAL.ResponseBuffer.Append("}");
				if(LOCAL.RowIndex LT ARGUMENTS.Data.RecordCount) {
					LOCAL.ResponseBuffer.Append(",");
				}
			}
//			LOCAL.ResponseBuffer.Append("]");
			return(LOCAL.ResponseBuffer.ToString());
		</cfscript>	
	</cffunction>

	<cffunction name="StringToJSON" access="remote" returntype="string" output="false" hint="Converts a ColdFusion string to JSON object. Will return strings in the form of: new String().">
		<cfargument name="Data" type="string" required="yes">
		<cfif IsDate(ARGUMENTS.Data)>
			<cfreturn ("new Date('" & DateFormat( ARGUMENTS.Data, "mm/dd/yyyy" ) & " " & TimeFormat( ARGUMENTS.Data, "hh:mm:ss.l TT" ) & "')")>
		<cfelseif REFindNoCase("^(true|false|yes|no)$", ARGUMENTS.Data)>
			<cfreturn LCase(ARGUMENTS.Data)>
		<cfelse>
			<cfreturn ("'" & JSStringFormat(ARGUMENTS.Data) & "'")>	
		</cfif>
	</cffunction>

	<cffunction name="StructToJSON" access="remote" returntype="string" output="false" hint="Converts a ColdFusion struct of SIMPLE values to JSON object. Will return strings in the form of: new Object({})">
		<cfargument name="Data" type="struct" required="true">
		<cfscript>
			var LOCAL = StructNew();
			LOCAL.ResponseBuffer = CreateObject("java", "java.lang.StringBuffer");
			LOCAL.ResponseBuffer.Append("{");
			LOCAL.KeyCount = StructCount(ARGUMENTS.Data);
			LOCAL.KeyIndex = 1;
			for(LOCAL.Key in ARGUMENTS.Data) {
				LOCAL.ResponseBuffer.Append(LCase(LOCAL.Key) & ":" & this.CFToJSON(ARGUMENTS.Data[LOCAL.Key]));
				if(LOCAL.KeyIndex LT LOCAL.KeyCount) {
					LOCAL.ResponseBuffer.Append(",");
				}
				LOCAL.KeyIndex = (LOCAL.KeyIndex + 1);
			}
			LOCAL.ResponseBuffer.Append("}");
			return(LOCAL.ResponseBuffer.ToString());
		</cfscript>		
	</cffunction>	
	
</cfcomponent>