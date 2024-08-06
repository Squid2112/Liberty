<cfcomponent displayname="GeoInfoCRUDComponent">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.GlobalDSN#">
		<cfscript>
			this.DSN = Arguments.DSN;

			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="GetbyZipcode" returntype="any" access="remote" output="yes">
		<cfargument name="Zipcode" type="any" required="yes">
		<cfscript>
			var qryResult = "";
			var result = {
				AreaCode = "",
				CityName = "",
				CityLatitide = 0.0,
				CityLongitude = 0.0,
				CountyFips = "",
				CountyName = "",
				Dst = "",
				ID = 0,
				Latitude = 0.0,
				MsaCode = "",
				StateAbbr = "",
				StateFips = "",
				StateName = "",
				StateLatitude = "",
				StateLongitude = "",
				TimeZone = "",
				UTC = 0.0,
				Zipcode = "",
				ZipType = ""
			};
			if(trim(Arguments.Zipcode) EQ "") return(result);
		</cfscript>

		<cfquery name="qryResult" datasource="Global">
			SELECT TOP 1 *
			FROM Zipcodes AS Z
			WHERE Zipcode = <cfqueryparam cfsqltype="cfsqlvarchar" value="#Arguments.Zipcode#">
		</cfquery>
		
		<cfscript>
			if(qryResult.RecordCount) {
				result = {
					AreaCode = qryResult.AreaCode[1],
					CityName = qryResult.CityName[1],
					CityLatitide = qryResult.City_Latitude[1],
					CityLongitude = qryResult.City_Longitude[1],
					CountyFips = qryResult.CountyFips[1],
					CountyName = qryResult.CountyName[1],
					Dst = qryResult.Dst[1],
					ID = qryResult.ID[1],
					Latitude = qryResult.Latitude[1],
					MsaCode = qryResult.MsaCode[1],
					StateAbbr = qryResult.StateAbbr[1],
					StateFips = qryResult.StateFips[1],
					StateName = qryResult.StateName[1],
					StateLatitude = qryResult.State_Latitude[1],
					StateLongitude = qryResult.State_Longitude[1],
					TimeZone = qryResult.TimeZone[1],
					UTC = qryResult.UTC[1],
					Zipcode = qryResult.Zipcode[1],
					ZipType = qryResult.ZipType[1]
				};
			}

			return(result);
		</cfscript>
	</cffunction>	

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>