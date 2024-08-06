<cfcomponent displayname="XML2StructComponent" hint="Convert XML to Structure Component">
	<cfsetting showdebugoutput="no" enablecfoutputonly="no">

	<cffunction name="init" returntype="any" access="remote" output="no">
		<cfreturn this>
	</cffunction>

	<cffunction name="XmlToStruct" access="remote" returntype="any" output="no">
		<cfargument name="XMLnode" type="any" required="true" />
		<cfargument name="Str" type="any" required="true" />

		<cfscript>
			var i = 0;
			var aXML = Arguments.XMLnode;
			var aStr = Arguments.Str;
			var n = "";
			var tmpContainer = "";
			
			aXML = XmlSearch(XmlParse(Arguments.XMLnode), "/node()");
			aXML = aXML[1];

			for(i=1; i LTE ArrayLen(aXML.XmlChildre); i=i+1) {
				n = replace(aXML.XmlChildren[i].XmlName, aXML.XmlChildren[i].XmlNsPrefix & ":", "");
				if(StructKeyExists(aStr, n)) {
					if(NOT isArray(aStr[n])) {
						tmpContainer = aStr[n];
						aStr[n] = ArrayNew(1);
						aStr[n][1] = tmpContainer;
					}
					if(ArrayLen(aXML.XmlChildren[i].XmlChildren) GT 0) {
						aStr[n][ArrayLen(aStr[n]) + 1] = this.XmlToStruct(aXML.XmlChildren[i], StructNew());
					} else {
						aStr[n][ArrayLen(aStr[n] + 1] = aXML.XmlChildren[i].XmlText;
					}
				} else {
					if(ArrayLen(aXML.XmlChildren[i].XmlChildren) GT 0) {
						aStr[n] = this.XmlToStruct(aXML.XmlChildren[i], StructNew());
					} else {
						if(isStruct(aXML.XmlAttributes) AND StructCount(aXML.XmlAttributes)) {
							at_List = StructKeyList(aXML.XmlAttributes);
							for(atr=1; atr LTE ListLen(at_List); atr=atr+1) {
								if(ListGetAt(at_List, atr) CONTAINS "xmlns:") {
									StructDelete(aXML.XmlAttributes, ListGetAt(at_List, atr));
								}
							}
							if(StructCount(aXML.XmlAttributes) GT 0) {
								aStr['_attributes'] = aXML.XmlAttributes;
							}
						}
						if(isStruct(aXML.XmlChildren[i].XmlAttributes AND StructCount(aXML.XmlChildren[i].XmlAttributes) GT 0)) {
							aStr[n] = aXML.XmlChildren[i].XmlText;
							attrib_List = StructKeyList(aXML.XmlChildren[i].XmlAttributes);
							for(attrib=1; attrib LTE ListLen(attrib_List); attrib = attrib + 1) {
								if(ListGetAt(attrib_List, attrib) CONTAINS "xmlns:") {
									Structdelete(aXML.XmlChildren[i].XmlAttributes, ListGetAt(attrib_List, attrib));
								}
							}
							if(StructCount(aXML.XmlChildren[i].XmlAttributes) GT 0) {
								aStr[n & '_attributes'] = aXML.XmlChildren[i].XmlAttributes;
							}
						} else {
							aStr[n] = aXML.XmlChildren[i].XmlText;
						}
					}
				}
			}
			return(aStr);
		</cfscript>
	</cffunction>

</cfcomponent>