<cfcomponent displayname="DatabaseObjectComponent" output="no">
 	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="no">
		<cfargument name="DSN" type="any" required="no" default="#application.Settings.DSN.Application#">
		<cfscript>
			this.DSN = Arguments.DSN;
			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="saveWebRequest" returntype="any" access="public" output="no">
		<cfscript>
			var browserMetrics = '';
			
			try {
				browserMetrics = {
					url = Arguments.url,
					browserStart = Arguments.browserStart,
					browserEnd = Arguments.browserEnd,
					serverStart = Arguments.serverStart,
					serverEnd = Arguments.serverEnd
				};
			} catch(Any E) {
				Application.mail.send(to=arrayToList(Application.Settings.emailAddresses.errors),subject='ERROR: saveWebRequest',obj=cfcatch);
			}
		</cfscript>

		<cftry>
			<cfquery datasource="WebMetrics">
				INSERT INTO browserRequests (
					URL,
					browserStart,
					browserEnd,
					browserElapsed,
					serverStart,
					serverEnd,
					serverElapsed,
					Stamp
				) VALUES (
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(left(urlDecode(browserMetrics.url),1000))#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#browserMetrics.browserStart#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#browserMetrics.browserEnd#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#(browserMetrics.browserEnd-browserMetrics.browserStart)#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#browserMetrics.serverStart#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#browserMetrics.serverEnd#">,
					<cfqueryparam cfsqltype="cf_sql_decimal" value="#(browserMetrics.serverEnd-browserMetrics.serverStart)#">,
					<cfqueryparam cfsqltype="cf_sql_timestamp" value="#Now()#">
				)
			</cfquery>
			<cfcatch type="any">
				<cfset Application.mail.send(to=arrayToList(Application.Settings.emailAddresses.errors),subject='ERROR: saveWebRequest/record insert',obj=cfcatch)>
			</cfcatch>
		</cftry>
	</cffunction>

	<cffunction name="getPageContents" returntype="any" access="public" output="no">
		<cfargument name="ContentID" type="any" required="no">
		<cfargument name="VirtualUriId" type="any" required="no">
		<cfargument name="ViewName" type="any" required="no">
		<cfargument name="VirtualPath" type="any" required="no">
		<cfargument name="ViewTemplate" type="any" required="no">
		<cfargument name="Template" type="any" required="no">
		<cfargument name="Scope" type="any" required="no">
		<cfargument name="Area" type="any" required="no">
		<cfargument name="Position" type="any" required="no">
		<cfset var result = "">

		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT PGC.*
				FROM PageContents AS PGC WITH (NOLOCK)
				WHERE
					1 = <cfqueryparam cfsqltype="cf_sql_integer" value="1">
					<cfif structKeyExists(Arguments,"ContentId")>AND PGC.ContentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(Arguments.ContentID)#"></cfif>
					<cfif structKeyExists(Arguments,"VirtualUriId")>AND PGC.VirtualUriId = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(Arguments.VirtualUriId)#"></cfif>
					<cfif structKeyExists(Arguments,"ViewName")>AND PGC.ViewName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.ViewName)#"></cfif>
					<cfif structKeyExists(Arguments,"VirtualPath")>AND PGC.VirtualPath = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.VirtualPath)#"></cfif>
					<cfif structKeyExists(Arguments,"ViewTemplate")>AND PGC.ViewTemplate = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.ViewTemplate)#"></cfif>
					<cfif structKeyExists(Arguments,"Template")>AND PGC.Template = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Template)#"></cfif>
					<cfif structKeyExists(Arguments,"Scope")>AND PGC.Scope = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Scope)#"></cfif>
					<cfif structKeyExists(Arguments,"Area")>AND PGC.Area = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Area)#"></cfif>
					<cfif structKeyExists(Arguments,"Position")>AND PGC.Position = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Position)#"></cfif>
			</cfquery>
		</cftransaction>
		<cfreturn result>
	</cffunction>

	<cffunction name="getVirtualPath" returntype="any" access="public" output="no">
		<cfargument name="path" type="any" required="yes">
		<cfscript>
			var vResult = {
				VirtualPath = Arguments.path,
				ViewName = 'Main',
				ViewTemplate = 'index.cfm',
				MapAsset = '',
				ContentType = 'cfm',
				isConical = false,
				doRedirect = false,
				keycode = '',
				Active = true,
				RecordCount = 0
			};
		</cfscript>

		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT *
				FROM VirtualPaths (NOLOCK)
				WHERE
					VirtualPath = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.path#">
					AND Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			</cfquery>
		</cftransaction>

		<cfscript>
			if(result.RecordCount) vResult = { VirtualPath=Arguments.path, ViewName=result.ViewName[1], ViewTemplate=result.ViewTemplate[1], MapAsset=result.MapAsset[1], ContentType=result.ContentType[1], isConical=result.isConical[1], Redirect=result.doRedirect[1], keycode=result.Keycode[1], Active=result.Active[1], RecordCount=result.RecordCount };
			return(vResult);
		</cfscript>
	</cffunction>

	<cffunction name="getVirtualURI" returntype="any" access="public" output="no">
		<cfargument name="vInfo" type="any" required="yes">
		<cfscript>
			var searchTerm = listLast(reReplace(Arguments.vInfo.VirtualPath, '-|_', ' ', 'ALL'), '/');
			var vResult = Arguments.vInfo;
			var result = '';
			var target = '';
			var caught = false;
			var keyTable = '';
			vResult.keyCode = '';
		</cfscript>

		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT
					VU.*,
					CU.CategoryID,
					CU.suppressTopBanner AS CT_suppressTopBanner,
					CU.suppressBottomBanner AS CT_suppressBottomBanner,
					CU.suppressLeftBanner AS CT_suppressLeftBanner,
					CU.suppressRightBanner AS CT_suppressRightBanner,
					CUK.Keycode AS CT_Keycode,
					SCU.SubCategoryID,
					SCU.suppressTopBanner AS SCT_suppressTopBanner,
					SCU.suppressBottomBanner AS SCT_suppressBottomBanner,
					SCU.suppressLeftBanner AS SCT_suppressLeftBanner,
					SCU.suppressRightBanner AS SCT_suppressRightBanner,
					SCUK.Keycode AS SCT_Keycode,
					PU.packageId,
					PU.suppressTopBanner AS PKG_suppressTopBanner,
					PU.suppressBottomBanner AS PKG_suppressBottomBanner,
					PU.suppressLeftBanner AS PKG_suppressLeftBanner,
					PU.suppressRightBanner AS PKG_suppressRightBanner,
					PUK.Keycode AS PKG_Keycode,
					PRU.productId,
					IU.ItemID,
					VUK.Keycode AS Keycode
				FROM dbo.VirtualURIs AS VU WITH (NOLOCK)
					LEFT OUTER JOIN dbo.VirtualUriKeycodes AS VUK WITH (NOLOCK) ON VUK.VirtualUriId = VU.VirtualUriId
					LEFT OUTER JOIN dbo.CategoryURIs AS CU WITH (NOLOCK) ON CU.VirtualURIid = VU.VirtualURIid
					LEFT OUTER JOIN dbo.CategoryUriKeycodes AS CUK WITH (NOLOCK) ON CUK.CategoryUriId = CU.CategoryURIID
					LEFT OUTER JOIN dbo.SubCategoryURIs AS SCU WITH (NOLOCK) ON SCU.VirtualURIid = VU.VirtualURIid
					LEFT OUTER JOIN dbo.SubCategoryUriKeycodes AS SCUK WITH (NOLOCK) ON SCUK.SubCategoryURIID = SCU.SubCategoryURIID
					LEFT OUTER JOIN dbo.PackageURIs AS PU WITH (NOLOCK) ON PU.VirtualURIid = VU.VirtualURIid
					LEFT OUTER JOIN dbo.PackageUriKeycodes AS PUK WITH (NOLOCK) ON PUK.PackageUriId = PU.PackageURIID
					LEFT OUTER JOIN dbo.ProductURIs AS PRU WITH (NOLOCK) ON PRU.VirtualURIid = VU.VirtualURIid
					LEFT OUTER JOIN dbo.ItemURIs AS IU WITH (NOLOCK) ON IU.VirtualURIid = VU.VirtualURIid
				WHERE
					VU.URI = <cfqueryparam cfsqltype="cf_sql_varchar" value="#searchTerm#">
					AND VU.Active = <cfqueryparam cfsqltype="cf_sql_bit" value="1">
			</cfquery>
		</cftransaction>

		<cfscript>
			if(NOT result.recordCount) return(Arguments.vInfo);

			vResult = {
				VirtualURIid=result.VirtualURIid[1],
				URI=result.URI[1],
				URL=result.URL[1],
				TableName=result.tableName[1],
				FieldName=result.fieldName[1],
				FieldValue=result.fieldValue[1],
				VirtualPath=request.vPath,
				ViewName=result.viewName,
				ViewTemplate=result.viewTemplate[1],
				MapAsset=result.mapAsset[1],
				ContentType=result.contentType[1],
				isConical=result.isConical[1],
				doRedirect=result.doRedirect[1],
				RedirectType=result.redirectType[1],
				isDefault=result.isDefault[1],
				isCatalog=result.isCatalog[1],
				Active=result.active[1],
				recordCount=result.recordCount,
				keyCode = '',
				suppressTopBanner = val(result.CT_suppressTopBanner[1]) + val(result.SCT_suppressTopBanner[1]) + val(result.PKG_suppressTopBanner[1]),
				suppressBottomBanner = val(result.CT_suppressBottomBanner[1]) + val(result.SCT_suppressBottomBanner[1]) + val(result.PKG_suppressBottomBanner[1]),
				suppressLeftBanner = val(result.CT_suppressLeftBanner[1]) + val(result.SCT_suppressLeftBanner[1]) + val(result.PKG_suppressLeftBanner[1]),
				suppressRightBanner = val(result.CT_suppressRightBanner[1]) + val(result.SCT_suppressRightBanner[1]) + val(result.PKG_suppressRightBanner[1])
			};

			vResult.url = {
				ct = iif(result.TableName[1] EQ 'Categories', DE(result.fieldValue[1]), DE(result.categoryId[1])),
				sct = iif(result.tableName[1] EQ 'SubCategories', DE(result.fieldValue[1]), DE(result.subcategoryId[1])),
				pkg = iif(result.tableName[1] EQ 'Packages', DE(result.fieldValue[1]), DE(result.packageId[1])),
				prd = iif(result.tableName[1] EQ 'Products', DE(result.fieldValue[1]), DE(result.productId[1])),
				itm = iif(result.tableName[1] EQ 'Items', DE(result.fieldValue[1]), DE(result.itemId[1]))
			};
			if(result.CT_Keycode[1] GT '') vResult.keycode = result.CT_Keycode[1];
			if(result.SCT_Keycode[1] GT '') vResult.keycode = result.SCT_Keycode[1];
			if(result.PKG_Keycode[1] GT '') vResult.keycode = result.PKG_Keycode[1];
			if(result.keycode[1] GT '') vResult.keycode = result.keycode[1];

			Request.dataTarget = duplicate(target);
			return(vResult);
		</cfscript>
	</cffunction>

	<cffunction name="getPageTool" returntype="any" access="public" output="no">
		<cfargument name="ToolName" type="any" required="yes">
		<cfset var result="">

		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT PT.ToolMarkup
				FROM PageTools AS PT WITH (NOLOCK)
				WHERE PT.ToolName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.ToolName#">
			</cfquery>
		</cftransaction>
		<cfreturn result.ToolMarkup>
	</cffunction>

	<cffunction name="getMetaTags" returntype="any" access="public" output="no">
		<cfargument name="Template" type="any" required="no" default="global">
		<cfset var result = "">

		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT TOP (1) *
				FROM MetaTags WITH (NOLOCK)
				WHERE Template = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Template#">
			</cfquery>
		</cftransaction>

		<cfif NOT result.RecordCount>
			<cftransaction isolation="read_uncommitted">
				<cfquery name="result" datasource="#this.DSN#">
					SELECT TOP (1) *
					FROM MetaTags WITH (NOLOCK)
					WHERE Template = <cfqueryparam cfsqltype="cf_sql_varchar" value="global">
				</cfquery>
			</cftransaction>
		</cfif>

		<cfreturn result>
	</cffunction>

	<cffunction name="getCartItemAssetIds" returntype="any" access="public" output="no">
		<cfscript>
			return(Application.catalogCRUD.getCartItemAssetIds(argumentCollection=arguments));
		</cfscript>
	</cffunction>

	<cffunction name="getVirtualMapping" returntype="any" access="public" output="no">
		<cfargument name="source" type="any" required="yes">
		<cfset var result = "">
		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#" cachedwithin="#createTimeSpan(0,1,0,0)#">
				SELECT VM.*
				FROM VirtualMapping AS VM WITH (NOLOCK)
				WHERE VM.source = <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.source)#">
			</cfquery>
		</cftransaction>
		<cfreturn result>
	</cffunction>

	<cffunction name="getPromoPackageExclusions" returntype="any" access="public" output="no">
		<cfargument name="packageList" type="any" required="no">
		<cfset var result = "">
		<cftransaction isolation="read_uncommitted">
			<cfquery name="result" datasource="#this.DSN#">
				SELECT PPE.*
				FROM PromoPackageExclusions AS PPE WITH (NOLOCK)
				<cfif structKeyExists(Arguments,"packageList")>
					WHERE PPE.PackageId IN (#Arguments.packageList#)
				</cfif>
			</cfquery>
		</cftransaction>
		<cfreturn result>
	</cffunction>

	<cffunction name="OnMissingMethod" returntype="any" access="public" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>
