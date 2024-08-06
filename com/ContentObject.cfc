<cfcomponent displayname="ContentObjectComponent">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="public" output="yes">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.DSN.Application#">
		<cfscript>
			this.DSN = Arguments.DSN;
			this.PageToolStruct = StructNew();
			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="js" returntype="any" access="public" output="no">
		<cfargument name="Request" type="any" required="yes">
		<cfscript>
			if(structKeyExists(Arguments.Request,'Protocol')) Arguments.Protocol = Arguments.Request.Protocol;
			Application.system.js(argumentCollection=Arguments);
		</cfscript>
	</cffunction>

	<cffunction name="css" returntype="any" access="public" output="no">
		<cfargument name="Request" type="any" required="yes">
		<cfscript>
			if(structKeyExists(Arguments.Request,'Protocol')) Arguments.Protocol = Arguments.Request.Protocol;
			Application.system.css(argumentCollection=Arguments);
		</cfscript>
	</cffunction>

	<cffunction name="jsGeoInfo" returntype="any" access="public" output="yes">
		<cfargument name="geoInfo" type="any" required="yes">
		<cfscript>
			var s = createObject('java','java.lang.StringBuffer').init('');
			if(Arguments.geoInfo.data.recordCount) {
				s.append(chr(13));
				s.append('<script type="text/javascript">' & chr(13));
				s.append('StoreLocator={Latitude:' & Arguments.geoInfo.data.Latitude[1] & ',Longitude:' & Arguments.geoInfo.data.Longitude[1] & '};' & chr(13));
				s.append('$(document).ready(function() {' & chr(13));
				s.append("$('##zipcode').val('" & Arguments.geoInfo.storeLocator.zipcode & "');" & chr(13));
				s.append("$('##city').val('" & Arguments.geoInfo.storeLocator.city & "');" & chr(13));
				s.append("$('##state').val('" & Arguments.geoInfo.storeLocator.state & "');" & chr(13));
				s.append("$('##radius').val('" & Arguments.geoInfo.storeLocator.radius & "');" & chr(13));
//				s.append("$('.formSubmit').click();" & chr(13));
				s.append('});' & chr(13));
				s.append('</script>' & chr(13));
				Application.System.addHtmlHeader(s.toString());
			}
		</cfscript>
	</cffunction>

	<cffunction name="GenericContent" returntype="any" access="public" output="yes">
		<cfargument name="VirtualInfo" type="any" required="yes">
		<cfscript>
			var tmp = '';

			if(NOT isSimpleValue(Arguments.VirtualInfo)) {
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\css\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.css')) this.css('/assets/cnt/css/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.css');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\css\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm')) this.css('/assets/cnt/css/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\js\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.js')) this.css('/assets/cnt/js/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.js');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\js\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm')) this.css('/assets/cnt/js/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\' & Arguments.VirtualInfo.MapAsset)) Application.System.include('/assets/cnt/' & Arguments.VirtualInfo.MapAsset);
			} else {
				tmp = Arguments.VirtualInfo;
				Arguments.VirtualInfo = structNew();
				Arguments.VirtualInfo.MapAsset = tmp;
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\css\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.css')) this.css('/assets/cnt/css/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.css');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\css\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm')) this.css('/assets/cnt/css/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\js\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.js')) this.css('/assets/cnt/js/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.js');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\js\' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm')) this.css('/assets/cnt/js/' & listFirst(Arguments.VirtualInfo.MapAsset, '.') & '.cfm');
				if(fileExists(Application.Settings.RootPath & '\assets\cnt\' & Arguments.VirtualInfo.MapAsset)) Application.System.include('/assets/cnt/' & Arguments.VirtualInfo.MapAsset);
			}
		</cfscript>
	</cffunction>

	<cffunction name="childView" returntype="any" access="public" output="yes">
		<cfargument name="name" type="any" required="no" default="">
		<cfscript>
			if(Arguments.name EQ '' AND structKeyExists(Request,'CatalogData')) {
				if(structKeyExists(Request.CatalogData, 'childView')) Arguments.name = Request.CatalogData.childView[1];
				switch(Request.virtualInfo.tableName) {
					case 'Categories' :
						if(structKeyExists(Request.CatalogData, 'CT_childView')) Arguments.name = Request.CatalogData.CT_childView[1];
						break;
					case 'SubCategories' :
						if(structKeyExists(Request.CatalogData, 'SCT_childView')) Arguments.name = Request.CatalogData.SCT_childView[1];
						break;
					case 'Packages' :
						if(structKeyExists(Request.CatalogData, 'PKG_childView')) Arguments.name = Request.CatalogData.PKG_childView[1];
						break;
					case 'Products' :
						if(structKeyExists(Request.CatalogData, 'PRD_childView')) Arguments.name = Request.CatalogData.PRD_childView[1];
						break;
					case 'Items' :
						if(structKeyExists(Request.CatalogData, 'ITM_childView')) Arguments.name = Request.CatalogData.ITM_childView[1];
						break;
					default :
						if(structKeyExists(Request.CatalogData, 'childView')) Arguments.name = Request.CatalogData.childView[1];
						break;
				}
			}
			if(Arguments.name EQ '') return;

			if(fileExists(Application.Settings.rootPath & '\childViews\' & Arguments.name & '\css\index.css')) this.css(Request=Request,filename='/childViews/' & Arguments.name & '/css/index.css');
			if(fileExists(Application.Settings.rootPath & '\childViews\' & Arguments.name & '\css\index.cfm')) this.css(Request=Request,filename='/childViews/' & Arguments.name & '/css/index.cfm');
			if(fileExists(Application.Settings.rootPath & '\childViews\' & Arguments.name & '\js\index.js')) this.js(Request=Request,filename='/childViews/' & Arguments.name & '/js/index.js');
			if(fileExists(Application.Settings.rootPath & '\childViews\' & Arguments.name & '\js\index.css')) this.js(Request=Request,filename='/childViews/' & Arguments.name & '/js/index.cfm');
			if(fileExists(Application.Settings.rootPath & '\childViews\' & Arguments.name & '\index.cfm')) Application.System.include('/childViews/' & Arguments.name & '/index.cfm');
		</cfscript>
	</cffunction>

	<cffunction name="objects" returntype="any" access="public" output="yes">
		<cfargument name="Request" type="any" required="yes">
		<cfargument name="name" type="any" required="no" default="">
		<cfargument name="scope" type="any" required="no">
		<cfargument name="params" type="any" required="no">
		<cfscript>
			var oName = trim(Arguments.name);
			var assetId = '';
			var assetFound = false;
			var scopeAbbr = '';
			
			if(structKeyExists(Arguments,'Scope')) {
				switch(lCase(Arguments.Scope)) {
					case 'static' : scopeAbbr = ''; break;
					case 'category' : scopeAbbr = 'ct'; break;
					case 'subcategory' : scopeAbbr = 'sct'; break;
					case 'package' : scopeAbbr = 'pkg'; break;
					case 'product' : scopeAbbr = 'prd'; break;
					case 'item' : scopeAbbr = 'itm'; break;
					default : scopeAbbr = ''; break;
				}
				if(structKeyExists(Request,'CatalogData') AND structKeyExists(Request.CatalogData, scopeAbbr & '_AssetId')) assetId = Request.CatalogData[scopeAbbr & '_AssetId'][1];
			}

			if(oname GT '') {
				if(assetId GT '') {
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\' & assetId & '\css\index.css')) this.css(Request=Arguments.Request,filename='/contentObjects/' & oName & '/' & assetId & '/css/index.css');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\' & assetId & '\css\index.cfm')) this.css(Request=Arguments.Request,filename='/contentObjects/' & oName & '/' & assetId & '/css/index.cfm');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\' & assetId & '\js\index.js')) this.js(Request=Arguments.Request,filename='/contentObjects/' & oName & '/' & assetId & '/js/index.js');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\' & assetId & '\js\index.cfm')) this.js(Request=Arguments.Request,filename='/contentObjects/' & oName & '/' & assetId & '/js/index.cfm');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\' & assetId & '\index.cfm')) {
						Application.System.include('/contentObjects/' & oName & '/' & assetId & '/index.cfm');
						assetFound = true;
					}
				}
				if((assetId EQ '') OR NOT assetFound) {
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\css\index.css')) this.css(Request=Arguments.Request,filename='/contentObjects/' & oName & '/css/index.css');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\css\index.cfm')) this.css(Request=Arguments.Request,filename='/contentObjects/' & oName & '/css/index.cfm');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\js\index.js')) this.js(Request=Arguments.Request,filename='/contentObjects/' & oName & '/js/index.js');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\js\index.cfm')) this.js(Request=Arguments.Request,filename='/contentObjects/' & oName & '/js/index.cfm');
					if(fileExists(Application.Settings.rootPath & '\contentObjects\' & oName & '\index.cfm')) Application.System.include('/contentObjects/' & oName & '/index.cfm');
				}
			}
			if(structKeyExists(Arguments,'params')) {
				for(item in Arguments.params) Request.params[item] = Arguments.params[item];
			}
		</cfscript>
	</cffunction>

	<cffunction name="pageTools" returntype="any" access="public" output="yes">
		<cfargument name="Tools" type="any" required="yes">
		<cfargument name="FlushCache" type="any" required="no" default="false">
		<cfscript>
			var i = 1;
			var key = "";
			
			for(i=1; i LTE listLen(Arguments.Tools); i=i+1) {
				key = listGetAt(Arguments.Tools, i);
				if((NOT StructKeyExists(this.PageToolStruct, key)) OR Arguments.FlushCache) StructInsert(this.PageToolStruct, key, Application.Database.getPageTool(key), true);
				writeOutput(Application.System.proccessDirectives(this.PageToolStruct[key]));
			}
		</cfscript>
	</cffunction>

	<cffunction name="img" returntype="any" access="public" output="yes">
		<cfargument name="catalogData" type="any" required="no">
		<cfargument name="scope" type="any" required="no">
		<cfargument name="src" type="any" required="no">
		<cfargument name="protocol" type="any" required="no">
		<cfargument name="id" type="any" required="no">
		<cfargument name="name" type="any" required="no">
		<cfscript>
			var s = createObject('java','java.lang.StringBuffer').init('');
			var extList = ['jpg','png','gif'];
			var i = 0;
			var t = 0;
			var assetId = '';
			var PKG_AssetId = '';
			var PRD_AssetId = '';
			var ITM_AssetId = '';
			var scopeAbbr = '';
			var tParams = {
				src = '',
				width = '',
				height = '',
				cursor = '',
				style = '',
				alt = '',
				onclick = ''
			};
			var itype = '';
			var conical = '.';
			var prefix = '';
			if(Application.Settings.defaultConical NEQ 'www') conical = '.' & Application.Settings.defaultConical & '.';
			if(NOT structKeyExists(Arguments,'Protocol') AND structKeyExists(Request,'Protocol')) Arguments.Protocol = Request.Protocol;

			if(NOT structKeyExists(Arguments,'src')) return;
			itype = lCase(listLast(Arguments.src,'.'));

			if(structKeyExists(Arguments,'params') AND isStruct(Arguments.params)) {
				if(structKeyExists(Arguments.params,'width')) tParams.width = Arguments.params.width;
				if(structKeyExists(Arguments.params,'height')) tParams.height = Arguments.params.height;
				if(structKeyExists(Arguments.params,'cursor')) tParams.cursor = Arguments.params.cursor;
				if(structKeyExists(Arguments.params,'style')) tParams.cursor = Arguments.params.style;
				if(structKeyExists(Arguments.params,'alt')) tParams.alt = Arguments.params.alt;
				if(structKeyExists(Arguments.params,'onclick')) tParams.onclick = Arguments.params.onclick;
			} else {
				if(structKeyExists(Arguments,'width')) tParams.width = Arguments.width;
				if(structKeyExists(Arguments,'height')) tParams.height = Arguments.height;
				if(structKeyExists(Arguments,'cursor')) tParams.cursor = Arguments.cursor;
				if(structKeyExists(Arguments,'style')) tParams.cursor = Arguments.style;
				if(structKeyExists(Arguments,'alt')) tParams.alt = Arguments.alt;
				if(structKeyExists(Arguments,'onclick')) tParams.onclick = Arguments.onclick;
			}

			if(structKeyExists(Arguments,'Scope')) {
				switch(lCase(Arguments.Scope)) {
					case 'category' : scopeAbbr = 'ct'; break;
					case 'subcategory' : scopeAbbr = 'sct'; break;
					case 'package' : scopeAbbr = 'pkg'; break;
					case 'product' : scopeAbbr = 'prd'; break;
					case 'item' : scopeAbbr = 'itm'; break;
					default : scopeAbbr = ''; break;
				}
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.catalogData, scopeAbbr & '_AssetId')) AssetId = Arguments.catalogData[scopeAbbr & '_AssetId'][1];
			}
			if(structKeyExists(Arguments,'Mapped')) assetId = Arguments.Mapped;

			if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'CT_AssetId')) prefix = Arguments.CatalogData['CT_AssetId'][1];
			if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'SCT_AssetId')) prefix = Arguments.CatalogData['SCT_AssetId'][1];
			if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'PKG_AssetId')) prefix = Arguments.catalogData['PKG_AssetId'][1];
			if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.catalogData, 'PRD_AssetId')) prefix = Arguments.catalogData['PRD_AssetId'][1];
			if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.catalogData, 'ITM_AssetId')) prefix = Arguments.catalogData['ITM_AssetId'][1];

			if(NOT structKeyExists(Arguments,'Mapped') AND (scopeAbbr EQ '')) {
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'CT_AssetId')) AssetId = Arguments.CatalogData['CT_AssetId'][1];
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'SCT_AssetId')) AssetId = Arguments.CatalogData['SCT_AssetId'][1];
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.CatalogData, 'PKG_AssetId')) {
					assetId = Arguments.catalogData['PKG_AssetId'][1];
					PKG_AssetId = Arguments.catalogData['PKG_AssetId'][1];
				}
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.catalogData, 'PRD_AssetId')) {
					assetId = Arguments.catalogData['PRD_AssetId'][1];
					PRD_AssetId = Arguments.catalogData['PRD_AssetId'][1];
				}
				if(structKeyExists(Arguments,'catalogData') AND structKeyExists(Arguments.catalogData, 'ITM_AssetId')) {
					assetId = Arguments.catalogData['ITM_AssetId'][1];
					ITM_AssetId = Arguments.catalogData['ITM_AssetId'][1];
				}
			}

			if(trim(tParams.cursor GT '')) tParams.style = tParams.style & ' cursor:' & trim(tParams.cursor) & ';';

			if((assetId NEQ '') OR (PKG_AssetId NEQ '') OR (ITM_AssetId NEQ '')) {
				if((PKG_AssetId NEQ '') AND (ITM_AssetId NEQ '')) {
					tParams.src = '/assets/img/' & PKG_AssetId & '/' & ITM_AssetId & '/' & Arguments.src;
					prefix = PKG_AssetId & '-' & ITM_AssetID;
				} else if(PKG_AssetId NEQ '') {
					tParams.src = '/assets/img/' & PKG_AssetId & '/' & Arguments.src;
					prefix = PKG_AssetId;
				} else if(ITM_AssetId NEQ '') {
					tParams.src = '/assets/img/' & ITM_AssetId & '/' & Arguments.src;
					prefix = ITM_AssetId;
				} else if(assetId NEQ 'banners') {
					tParams.src = '/assets/img/' & assetId & '/' & Arguments.src;
					prefix = listFirst(assetId,'/');
				} else {
					tParams.src = '/assets/banners/' & Arguments.src;
					prefix = 'Oreck-Banners';
				}
			} else if(structKeyExists(Arguments,'mapped')) {
				if(Arguments.mapped EQ 'banners') {
					tParams.src = '/assets/banners/';
					prefix = 'Oreck-Banners';
				} else {
					tParams.src = '/assets/img/' & Arguments.mapped;
					prefix = listFirst(assetId,'/');
				}
				if(Arguments.mapped NEQ '') tParams.src = tParams.src & '/';
				tParams.src = tParams.src & Arguments.src;
			} else {
				tParams.src = '/assets/img/global/' & Arguments.src;
				prefix = 'Oreck-Images';
			}

			tParams.src = replace(tParams.src,'//','/','ALL');
			if(NOT fileExists(Application.Settings.rootPath & tParams.src)) {
				for(i=1; i LTE arrayLen(extList); i++) {
					tParams.src = replaceNoCase(tParams.src,'.' & listLast(tParams.src,'.'), '.' & extList[i]);
					if(fileExists(Application.settings.rootPath & tParams.src)) break;
				}
			}
			if(NOT fileExists(Application.settings.rootPath & tParams.src)) return;

/*
			if(structKeyExists(Arguments,'protocol')) {
				if(structKeyExists(Arguments,'catalogData') AND Arguments.catalogData.recordCount) {
					if(listFindNoCase(Arguments.catalogData.columnList,'CT_BREADCRUMB_LABEL') AND (trim(Arguments.catalogData.CT_BREADCRUMB_LABEL[1]) NEQ ''))
						prefix = trim(replaceNoCase(Arguments.catalogData.CT_BREADCRUMB_LABEL[1],'oreck','','ALL'));
					if(listFindNoCase(Arguments.catalogData.columnList,'SCT_BREADCRUMB_LABEL') AND (trim(Arguments.catalogData.SCT_BREADCRUMB_LABEL[1]) NEQ ''))
						prefix = trim(replaceNoCase(Arguments.catalogData.SCT_BREADCRUMB_LABEL[1],'oreck','','ALL'));
					if(listFindNoCase(Arguments.catalogData.columnList,'PKG_BREADCRUMB_LABEL') AND (trim(Arguments.catalogData.PKG_BREADCRUMB_LABEL[1]) NEQ ''))
						prefix = trim(replaceNoCase(Arguments.catalogData.PKG_BREADCRUMB_LABEL[1],'oreck','','ALL'));
				}
			}
			if((prefix EQ '') AND (assetId NEQ '')) prefix = listFirst(assetId,'/');
			prefix = reReplace(prefix,'[^\w^-]','','ALL');
			if(prefix EQ '') prefix = 'Oreck-Media';
			for(t=1; (listLen(prefix,'-') GT 4) AND (t LTE 15); t++) prefix = listDeleteAt(prefix,2,'-');
			if(structKeyExists(Arguments,'Protocol')) tParams.src = Arguments.Protocol & '://' & replace(prefix,' ','-','ALL') & conical & Application.Settings.rootDomain & tParams.src;
*/

			prefix='media';
			if(structKeyExists(Arguments,'Protocol')) tParams.src = Arguments.Protocol & '://' & prefix & conical & Application.Settings.rootDomain & tParams.src;

			switch(itype) {
				case 'jpg' :
					s.append('<img');
					if(structKeyExists(Arguments,'id')) s.append(' id="' & Arguments.id & '"');
					if(structKeyExists(Arguments,'name')) s.append(' name="' & Arguments.name & '"');
					s.append(' src="' & trim(tParams.src) & '" ');
					if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
					if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
					s.append(' alt="' & trim(tParams.alt) & '"');
					if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
					if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
					s.append(' />');
					break;

				case 'gif' :
					s.append('<img');
					if(structKeyExists(Arguments,'id')) s.append(' id="' & Arguments.id & '"');
					if(structKeyExists(Arguments,'name')) s.append(' name="' & Arguments.name & '"');
					s.append(' src="' & trim(tParams.src) & '" ');
					if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
					if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
					s.append(' alt="' & trim(tParams.alt) & '"');
					if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
					if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
					s.append(' />');
					break;

				case 'png' :
					if(structKeyExists(Arguments,'alpha')) {
						Application.System.alphaPng(argumentCollection=tParams);
						return;
					} else {
						s.append('<img');
						if(structKeyExists(Arguments,'id')) s.append(' id="' & Arguments.id & '"');
						if(structKeyExists(Arguments,'name')) s.append(' name="' & Arguments.name & '"');
						s.append(' src="' & trim(tParams.src) & '" ');
						if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
						if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
						s.append(' alt="' & trim(tParams.alt) & '"');
						if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
						if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
						s.append(' />');
					}
					break;

				default :
					return;
					break;
			}
			writeOutput(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="a" returntype="any" access="public" output="yes">
		<cfargument name="href" type="any" required="yes">
		<cfargument name="scope" type="any" required="no">
		<cfscript>
			if(structKeyExists(Arguments,'Scope')) {
				switch(lCase(Arguments.Scope)) {
					case 'static' : scopeAbbr = ''; break;
					case 'category' : scopeAbbr = 'ct'; break;
					case 'subcategory' : scopeAbbr = 'sct'; break;
					case 'package' : scopeAbbr = 'pkg'; break;
					case 'product' : scopeAbbr = 'prd'; break;
					case 'item' : scopeAbbr = 'itm'; break;
					default : scopeAbbr = ''; break;
				}
				if(structKeyExists(Request.CatalogData, scopeAbbr & '_AssetId')) AssetId = Request.CatalogData[scopeAbbr & '_AssetId'][1];
			}
			if(structKeyExists(Arguments,'Mapped')) AssetId = Arguments.Mapped;
		</cfscript>
	</cffunction>

	<cffunction name="url" returntype="any" access="public" output="yes">
		<cfargument name="assetId" type="any" required="no">
		<cfargument name="scope" type="any" required="no">
		<cfargument name="categoryId" type="any" required="no">
		<cfargument name="subCategoryId" type="any" required="no">
		<cfargument name="packageId" type="any" required="no">
		<cfargument name="productId" type="any" required="no">
		<cfargument name="itemId" type="any" required="no">
		<cfargument name="uriType" type="any" required="no">
		<cfargument name="labelType" type="any" required="no">
		<cfargument name="text" type="any" required="no">
		<cfargument name="title" type="any" required="no">
		<cfscript>
			var urlParams = { url='##', text='', title='' };
			var params = structNew();
			var i = 0;
			var label = '';
			var labels = arrayNew(1);
			var key = '';

			if(structKeyExists(Arguments,'text')) urlParams.text = Arguments.text;
			if(structKeyExists(Arguments,'title')) urlParams.text = Arguments.title;
			if(structKeyExists(Arguments,'uriType')) params.uriType = Arguments.uriType;
			if(structKeyExists(Arguments,'labelType')) params.labelType = Arguments.labelType;

			if(structKeyExists(Arguments,'categoryId')) {
				params.categoryId = Arguments.categoryId;
				result = Application.CatalogCRUD.getCategoryURI(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'subCategoryId')) {
				params.subCategoryId = Arguments.subCategoryId;
				result = Application.CatalogCRUD.getSubCategoryURI(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'packageId')) {
				params.packageId = Arguments.packageId;
				result = Application.CatalogCRUD.getPackageURI(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'productId')) {
				params.productId = Arguments.productId;
				result = Application.CatalogCRUD.getProductURI(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'itemId')) {
				params.itemId = Arguments.itemId;
				result = Application.CatalogCRUD.getItemUri(argumentCollection=params);
			}

			if(result.recordCount) {
				if(structKeyExists(Arguments,'labelType')) {
					labels = listToArray(Arguments.labelType,',',false);
					for(i=1; i LTE arrayLen(labels); i++) {
						label = replace(labels[i],' ','','ALL') & '_Label';
						if(structKeyExists(result,'label')) urlParams[label] = result[label][1];
					}
				}
				if(arrayLen(labels) AND (urlParams.text EQ '') AND structKeyExists(Arguments,'labelType')) {
					key = replace(labels[1],' ','','ALL') & '_Label';
				 	if(structKeyExists(result,key)) urlParams.text = result[key][1];
				}
				if(structKeyExists(result,'uri')) urlParams.url = '/' & replace(result.uri[1],' ','-','ALL');
			}

			writeOutput('<a href="' & urlParams.url & '" title="' & urlParams.title & '">' & urlParams.text & '</a>');
			return;
		</cfscript>
	</cffunction>

	<cffunction name="uri" returntype="any" access="public" output="yes">
		<cfargument name="assetId" type="any" required="no">
		<cfargument name="scope" type="any" required="no">
		<cfargument name="categoryId" type="any" required="no">
		<cfargument name="subCategoryId" type="any" required="no">
		<cfargument name="packageId" type="any" required="no">
		<cfargument name="productId" type="any" required="no">
		<cfargument name="itemId" type="any" required="no">
		<cfargument name="uriType" type="any" required="no">
		<cfargument name="labelType" type="any" required="no">
		<cfscript>
			var urlParams = { uri='##', text='', title='' };
			var params = structNew();
			var i = 0;
			var label = '';
			var labels = arrayNew(1);
			var key = '';

			if(structKeyExists(Arguments,'text')) urlParams.text = Arguments.text;
			if(structKeyExists(Arguments,'title')) urlParams.text = Arguments.title;
			if(structKeyExists(Arguments,'uriType')) params.uriType = Arguments.uriType;
			if(structKeyExists(Arguments,'labelType')) params.labelType = Arguments.labelType;

			if(structKeyExists(Arguments,'categoryId')) {
				params.categoryId = Arguments.categoryId;
				result = Application.CatalogCRUD.getCategoryUri(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'subCategoryId')) {
				params.subCategoryId = Arguments.subCategoryId;
				result = Application.CatalogCRUD.getSubCategoryUri(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'packageId')) {
				params.packageId = Arguments.packageId;
				result = Application.CatalogCRUD.getPackageUri(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'productId')) {
				params.productId = Arguments.productId;
				result = Application.CatalogCRUD.getProductUri(argumentCollection=params);
			}
			if(structKeyExists(Arguments,'itemId')) {
				params.itemId = Arguments.itemId;
				result = Application.CatalogCRUD.getItemUri(argumentCollection=params);
			}

			if(result.recordCount) {
				if(structKeyExists(Arguments,'labelType')) {
					labels = listToArray(Arguments.labelType,',',false);
					for(i=1; i LTE arrayLen(labels); i++) {
						label = replace(labels[i],' ','','ALL') & '_Label';
						urlParams[label] = result[label][1];
					}
				}
				if((urlParams.text EQ '') AND structKeyExists(Arguments,'labelType')) {
					key = replace(labels[1],' ','','ALL') & '_Label';
					if(structKeyExists(result,key)) urlParams.text = result[key][1];
				}
				if(structKeyExists(result,'uri')) urlParams.uri = '/' & replace(result.uri[1],' ','-','ALL');
			}
			return(urlParams);
		</cfscript>
	</cffunction>

	<cffunction name="breadCrumbs" returntype="any" access="public" output="yes">
		<cfargument name="Visitor" type="any" required="yes">
		<cfargument name="catalogData" type="any" required="no">
		<cfscript>
			Application.Navigation.showBreadCrumbs(argumentCollection=Arguments);
		</cfscript>
	</cffunction>

	<cffunction name="writeCatalogLabel" returntype="any" access="public" output="no">
		<cfargument name="scope" type="any" required="yes">
		<cfargument name="labels" type="any" required="yes">
		<cfargument name="labelType" type="any" required="yes">

		<cfscript>
			switch(lcase(Arguments.scope)) {
				case 'category' : Arguments.scope = 'CAT'; break;
				case 'subcategory' : Arguments.scope = 'SCT'; break;
				case 'package' : Arguments.scope = 'PKG'; break;
				case 'product' : Arguments.scope = 'PRD'; break;
				case 'item' : Arguments.scope = 'ITM'; break;
				default : Arguments.scope = ''; break;
			}

			if(structKeyExists(Arguments.labels, Arguments.scope) AND structKeyExists(Arguments.labels[Arguments.scope], Arguments.labelType)) return(Arguments.labels[Arguments.scope][Arguments.labelType]);
			if(structKeyExists(Arguments.labels, Arguments.scope) AND structKeyExists(Arguments.labels[Arguments.scope], 'Name')) return(Arguments.labels[Arguments.scope]['Name']);
			return('* ' & Arguments.scope & '.' & Arguments.labelType & '*');
		</cfscript>
	</cffunction>

	<cffunction name="remoteImg" returntype="any" access="public" output="yes">
		<cfargument name="scope" type="any" required="no">
		<cfargument name="src" type="any" required="no">
		<cfscript>
			var s = createObject('java','java.lang.StringBuffer').init('');
			var assetId = '';
			var PKG_AssetId = '';
			var PRD_AssetId = '';
			var ITM_AssetId = '';
			var scopeAbbr = '';
			var tParams = {
				src = '',
				width = '',
				height = '',
				cursor = '',
				style = '',
				alt = '',
				onclick = ''
			};
			var itype = '';

			if(NOT structKeyExists(Arguments,'src')) return;
			itype = lCase(listLast(Arguments.src,'.'));

			if(structKeyExists(Arguments,'params') AND isStruct(Arguments.params)) {
				if(structKeyExists(Arguments.params,'width')) tParams.width = Arguments.params.width;
				if(structKeyExists(Arguments.params,'height')) tParams.height = Arguments.params.height;
				if(structKeyExists(Arguments.params,'cursor')) tParams.cursor = Arguments.params.cursor;
				if(structKeyExists(Arguments.params,'style')) tParams.cursor = Arguments.params.style;
				if(structKeyExists(Arguments.params,'alt')) tParams.alt = Arguments.params.alt;
				if(structKeyExists(Arguments.params,'onclick')) tParams.onclick = Arguments.params.onclick;
			} else {
				if(structKeyExists(Arguments,'width')) tParams.width = Arguments.width;
				if(structKeyExists(Arguments,'height')) tParams.height = Arguments.height;
				if(structKeyExists(Arguments,'cursor')) tParams.cursor = Arguments.cursor;
				if(structKeyExists(Arguments,'style')) tParams.cursor = Arguments.style;
				if(structKeyExists(Arguments,'alt')) tParams.alt = Arguments.alt;
				if(structKeyExists(Arguments,'onclick')) tParams.onclick = Arguments.onclick;
			}

			if(structKeyExists(Arguments,'Scope')) {
				switch(lCase(Arguments.Scope)) {
					case 'category' : scopeAbbr = 'ct'; break;
					case 'subcategory' : scopeAbbr = 'sct'; break;
					case 'package' : scopeAbbr = 'pkg'; break;
					case 'product' : scopeAbbr = 'prd'; break;
					case 'item' : scopeAbbr = 'itm'; break;
					default : scopeAbbr = ''; break;
				}
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.catalogData, scopeAbbr & '_AssetId')) AssetId = Request.catalogData[scopeAbbr & '_AssetId'][1];
			}
			if(structKeyExists(Arguments,'Mapped')) assetId = Arguments.Mapped;

			if(NOT structKeyExists(Arguments,'Mapped') AND (scopeAbbr EQ '')) {
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.CatalogData, 'CT_AssetId')) AssetId = Request.CatalogData['CT_AssetId'][1];
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.CatalogData, 'SCT_AssetId')) AssetId = Request.CatalogData['SCT_AssetId'][1];
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.CatalogData, 'PKG_AssetId')) {
					assetId = Request.catalogData['PKG_AssetId'][1];
					PKG_assetId = assetId;
				}
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.catalogData, 'PRD_assetId')) {
					assetId = Request.catalogData['PRD_AssetId'][1];
					PRD_AssetId = assetId;
				}
				if(structKeyExists(Request,'catalogData') AND structKeyExists(Request.catalogData, 'ITM_AssetId')) {
					assetId = Request.catalogData['ITM_AssetId'][1];
					ITM_AssetId = assetId;
				}
			}

			if(trim(tParams.cursor GT '')) tParams.style = tParams.style & ' cursor:' & trim(tParams.cursor) & ';';

			if((assetId NEQ '') OR (PKG_AssetId NEQ '') OR (ITM_AssetId NEQ '')) {
				if((PKG_AssetId NEQ '') AND (ITM_AssetId NEQ '')) {
					tParams.src = '/assets/img/' & PKG_AssetId & '/' & ITM_AssetId & '/' & Arguments.src;
				} else if(PKG_AssetId NEQ '') {
					tParams.src = '/assets/img/' & PKG_AssetId & '/' & Arguments.src;
				} else if(ITM_AssetId NEQ '') {
					tParams.src = '/assets/img/' & ITM_AssetId & '/' & Arguments.src;
				} else {
					tParams.src = '/assets/img/' & assetId & '/' & Arguments.src;
				}
			} else if(structKeyExists(Arguments,'mapped')) {
				tParams.src = '/assets/img/' & Arguments.mapped;
				if(Arguments.mapped NEQ '') tParams.src = tParams.src & '/';
				tParams.src = tParams.src & Arguments.src;
			} else {
				tParams.src = '/assets/img/global/' & Arguments.src;
			}
			tParams.src = replace(tParams.src,'//','/','ALL');

			switch(itype) {
				case 'jpg' :
					s.append('<img src="' & trim(tParams.src) & '" ');
					if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
					if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
					s.append(' alt="' & trim(tParams.alt) & '"');
					if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
					if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
					s.append(' />');
					break;

				case 'gif' :
					s.append('<img src="' & trim(tParams.src) & '" ');
					if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
					if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
					s.append(' alt="' & trim(tParams.alt) & '"');
					if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
					if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
					s.append(' />');
					break;

				case 'png' :
					if(structKeyExists(Arguments,'alpha')) {
						Application.System.alphaPng(argumentCollection=tParams);
						return;
					} else {
						s.append('<img src="' & trim(tParams.src) & '" ');
						if(tParams.width NEQ '') s.append(' width="' & trim(tParams.width) & '"');
						if(tParams.height NEQ '') s.append(' height="' & trim(tParams.height) & '"');
						s.append(' alt="' & trim(tParams.alt) & '"');
						if(tParams.style NEQ '') s.append(' style="' & trim(tParams.style) & '"');
						if(tParams.onclick NEQ '') s.append(' onclick="' & trim(tParams.onclick) & '"');
						s.append(' />');
					}
					break;

				default :
					return;
					break;
			}
			writeOutput(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="paymentsLowAs" returntype="any" access="public" output="no">
		<cfargument name="packageId" type="any" required="yes">
		<cfargument name="price" type="any" required="yes">
		<cfargument name="details" type="any" required="no">
		<cfscript>
			var s = createObject('java','java.lang.StringBuffer').init('');
			var i = 0;
			var item = '';
			var result = '';
			var packIndex = 0;
			var payments = 0;
			var payDown = 0;
			var payPacks = Application.catalogCRUD.getPaymentPackages(packageId=val(Arguments.packageId));
			var paym = '';

			if(val(Arguments.packageId) AND payPacks.recordCount) {
				for(i=1; i LTE payPacks.recordCount; i++) {
					if(find('CCM',payPacks.AS400payMethodCode[i])) {
						if(val(payPacks.payments[i]) AND (payPacks.payments[i] GT payments)) {
							payments = payPacks.payments[i];
							packIndex = i;
						}
					}
				}
			}
			if(packIndex) {
				if(val(payPacks.PercentageDown[packIndex])) payDown = payPacks.PercentageDown[packIndex];
				s.append('<span class="category-payments">');
				s.append('Payments as low as $');
				s.append('<strong>');
				paym = trim(numberFormat((Arguments.price - (Arguments.price * payDown * 0.01)) / (payPacks.payments[packIndex]-1), '___,___.____'));
				s.append(left(paym,len(paym)-2));
				s.append('</strong>');
				s.append(' per month.');
				if(structKeyExists(Arguments,'details')) s.append('<a href="/Payment-Information">details &raquo;</a>');
				s.append('</span>');
			}
			return(s.toString());
		</cfscript>
	</cffunction>

	<cffunction name="OnMissingMethod" returntype="any" access="public" output="yes">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>

</cfcomponent>
