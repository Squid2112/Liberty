<cfcomponent output="false"	hint="I provide a utility wrapper for XML objects.">
	<cfset this.XDOMVersion = "1.0" />

	<cffunction name="init" access="public" returntype="any" output="false" hint="I initialize the component.">
		<cfargument name="collection" type="any" required="false" default="#arrayNew(1)#" hint="I am either a ColdFusion XML object or an array of XML nodes from a given object." />

		<cfset var local = {} />
		<cfset variables.collection = [] />

		<cfif this.isXDOMCollection(arguments.collection)>
			<cfset variables.collection = arguments.collection.get() />
		<cfelseif isArray(arguments.collection)>
			<cfloop index="local.collectionItem" array="#arguments.collection#">
				<cfif isXmlNode(local.collectionItem)>
					<cfset arrayAppend(variables.collection, local.collectionItem) />
				</cfif>
			</cfloop>
		<cfelseif isSimpleValue(arguments.collection)>
			<cfif !reFind("^\s*<", arguments.collection)>
				<cfset arguments.collection = fileRead(arguments.collection) />
			</cfif>
			<cfset variables.collection = xmlParse("<xdomRootNodeForParsing>#arguments.collection#</xdomRootNodeForParsing>").xmlRoot.xmlChildren />
		<cfelseif isXmlDoc(arguments.collection)>
			<cfset variables.collection = [arguments.collection.xmlRoot] />
		<cfelseif isXmlNode(arguments.collection)>
			<cfset variables.collection = [arguments.collection] />
		</cfif>
		<cfset variables.prevCollection = "" />
		<cfreturn this />
	</cffunction>

	<cffunction name="append" access="public" returntype="any" output="false" hint="I append the given collection to all elements of the current collection.">
		<cfargument name="collection" type="any" required="true" hint="I am the collection being merged into the current collection." />
		<cfargument name="returnAppendedElements" type="boolean" required="false" default="false" hint="By default, this function will return the current collection. However, with this argument, we can get it to return the collection of newly appended elements." />
		<cfset var local = {} />
		<cfset local.incomingCollection = this.normalizeXDOMCollection(arguments.collection) />
		<cfset local.appendedElements = [] />

		<cfloop index="local.collectionItem" array="#variables.collection#">
			<cfloop index="local.incomingCollectionItem" array="#local.incomingCollection.get()#">
				<cfif (isXmlAttribute(local.incomingCollectionItem ) && isXmlElem(local.collectionItem))>
					<cfset local.collectionItem.xmlAttributes[local.incomingCollectionItem.xmlName] = local.incomingCollectionItem.xmlValue />
				<cfelseif (isXmlAttribute(local.incomingCollectionItem) && isXmlAttribute(local.collectionItem))>
					<cfset local.parentNodes = xmlSearch(local.collectionItem, "..") />
					<cfset local.parentNodes[1].xmlAttributes[local.incomingCollectionItem.xmlName] = local.incomingCollectionItem.xmlValue />
				<cfelseif (isXmlElem(local.incomingCollectionItem) && isXmlElem(local.collectionItem))>
					<cfset arrayAppend(local.collectionItem.xmlChildren,this.importXmlTree(this.getXmlDoc(local.collectionItem),local.incomingCollectionItem)) />
					<cfset arrayAppend(local.appendedElements,local.collectionItem.xmlChildren[arrayLen(local.collectionItem.xmlChildren)]) />
				</cfif>
			</cfloop>
		</cfloop>	

		<cfif arguments.returnAppendedElements>
			<cfreturn this.normalizeXDOMCollection(local.appendedElements).setPrevCollection(this) />
		</cfif>

		<cfreturn this />
	</cffunction>

	<cffunction name="end" access="public" returntype="any" output="false" hint="I return the previous collection or void.">
		<cfif this.isXDOMCollection(variables.prevCollection)>
			<cfreturn variables.prevCollection />
		<cfelse>
			<cfreturn />
		</cfif>		
	</cffunction>

	<cffunction name="flattenCompoundCollection" access="public" returntype="array" output="false" hint="I take an array of arrays (of nodes) and flatten it into a single array.">
		<cfargument name="compoundCollection" type="array" required="true" hint="I am the array of arrays being flattened." />
		<cfset var local = {} />
		<cfset local.flattenedCollection = [] />
		<cfset local.inUseFlag = "xdomNodeBeingMerged" />

		<cfloop index="local.collection" array="#arguments.compoundCollection#">
			<cfloop index="local.collectionItem" array="#local.collection#">
				<cfif isXmlElem(local.collectionItem)>
					<cfif !structKeyExists(local.collectionItem.xmlAttributes,local.inUseFlag)>
						<cfset local.collectionItem.xmlAttributes[local.inUseFlag] = "true" />
						<cfset arrayAppend(local.flattenedCollection,local.collectionItem) />
					</cfif>				
				<cfelse>
					<cfset local.parentNodes = xmlSearch(local.collectionItem,"..") />
					<cfif !structKeyExists(local.parentNodes[1].xmlAttributes,"#local.inUseFlag##hash( local.collectionItem.xmlName)#")>
						<cfset local.parentNodes[1].xmlAttributes["#local.inUseFlag##hash(local.collectionItem.xmlName)#"] = "true" />
						<cfset arrayAppend(local.flattenedCollection,local.collectionItem) />
					</cfif>
				</cfif>
			</cfloop>
		</cfloop>

		<cfloop index="local.collectionItem" array="#local.flattenedCollection#">
			<cfif isXmlElem(local.collectionItem)>
				<cfset structDelete(local.collectionItem.xmlAttributes,local.inUseFlag) />
			<cfelse>
				<cfset local.parentNodes = xmlSearch(local.collectionItem,"..") />
				<cfset structDelete(local.parentNodes[1].xmlAttributes,"#local.inUseFlag##hash(local.collectionItem.xmlName)#") />
			</cfif>
		</cfloop>
		<cfreturn local.flattenedCollection />
	</cffunction>

	<cffunction name="get" access="public" returntype="any" output="false" hint="I return the nodes in the current collection.">
		<cfargument name="index" type="numeric" required="false" default="0" hint="I am the index of the node to return. If zero, the entire collection will be returned." />
		<cfif arguments.index>
			<cfreturn variables.collection[arguments.index] />
		<cfelse>
			<cfreturn variables.collection />
		</cfif>
	</cffunction>

	<cffunction name="getAttributeArray" access="public" returntype="array" output="false" hint="I return an array of the values held in the given attribute accross the collection.">
		<cfargument name="attribute" type="string" required="true" hint="I am the attribute for which we are collecting values." />
		<cfset var local = {} />
		<cfset local.values = [] />

		<cfloop index="local.collectionItem" array="#variables.collection#">
			<cfif structKeyExists(local.collectionItem.xmlAttributes, arguments.attribute)>
				<cfset arrayAppend(local.values,local.collectionItem.xmlAttributes[arguments.attribute]) />
			</cfif>
		</cfloop>
		<cfreturn local.values />
	</cffunction>

	<cffunction name="getAttributeList" access="public" returntype="string" output="false" hint="I return a list of the values held in the given attribute accross the collection.">
		<cfargument name="attribute" type="string" required="true" hint="I am the attribute for which we are collecting values." />
		<cfargument name="delimiter" type="string" required="false" default="," hint="I am the delimiter used in the attribute value list." />
		<cfreturn arrayToList(this.getAttributeArray(arguemnts.attribute), arguments.delimiter) />
	</cffunction>

	<cffunction name="getValueArray" access="public" returntype="array" output="false" hint="I return an array of the value of the nodes aggregated in the collection. If the nodes are attributes, it returns the value. If the nodes are elements, it returns the text.">
		<cfset var local = {} />
		<cfset local.values = [] />

		<cfloop index="local.collectionItem" array="#variables.collection#">
			<cfif isXmlElem(local.collectionItem)>
				<cfset arrayAppend(local.values,local.collectionItem.xmlText) />
			<cfelse>
				<cfset arrayAppend(local.values,local.collectionItem.xmlValue) />
			</cfif>
		</cfloop>
		<cfreturn local.values />
	</cffunction>
	
	
	<cffunction name="getValueList" access="public" returntype="string" output="false" hint="I return a list of the value of the nodes aggregated in the collection. If the nodes are attributes, it returns the value. If the nodes are elements, it returns the text.">
		<cfargument name="delimiter" type="string" required="false" default="," hint="I am the delimiter used in the value list." />
		<cfreturn arrayToList(this.getValueArray(),arguments.delimiter) />
	</cffunction>

	<cffunction name="getXmlDoc" access="public" returntype="any" output="false" hint="I get the XML document for the given XML node.">
		<cfargument name="node" type="any" required="true" hint="I am the node for which we are getting the XML document object." />

		<cfset var local = {} />
		<cfset local.docNodes = xmlSearch(arguments.node, "/*/.." ) />
		<cfreturn local.docNodes[1] />		
	</cffunction>

	<cffunction name="find_" access="public" returntype="any" output="false" hint="I look for the given XPath on each of the nodes in the current collection.">
		<cfargument name="xpath" type="string" required="true" hint="I am the XPath query to apply to each node in the current collection." />
		<cfset var local = {} />
		<cfset local.compoundCollection = [] />

		<cfloop index="local.collectionItem" array="#variables.collection#">
			<cfset local.nodes = xmlSearch(local.collectionItem, arguments.xpath) />
			<cfset arrayAppend(local.compoundCollection,local.nodes) />
		</cfloop>

		<cfset local.newCollection = this.normalizeXDOMCollection(this.flattenCompoundCollection(local.compoundCollection)) />
		<cfset local.newCollection.setPrevCollection(this) />

		<cfreturn local.newCollection />
	</cffunction>

	<cffunction name="importXmlTree" access="public" returntype="any" output="false" hint="I import the given tree into the given node.">
		<cfargument name="xmlDoc" type="any" required="true" hint="I am a node of tree into which the other tree is being imported." />
		<cfargument name="xmlTree" type="any" required="true" hint="I am the XML tree being imported." />

		<cfset var local = {} />
		<cfset local.node = xmlElemNew( arguments.xmlDoc, arguments.xmlTree.xmlName ) />
		<cfset structAppend( local.node.xmlAttributes, arguments.xmlTree.xmlAttributes ) />
		<cfset local.node.xmlText = arguments.xmlTree.xmlText />

		<cfloop index="local.xmlTreeChild" array="#arguments.xmlTree.xmlChildren#">
			<cfset arrayAppend(local.node.xmlChildren,this.importXmlTree( arguments.xmlDoc,local.xmlTreeChild)) />
		</cfloop>
		<cfreturn local.node />
	</cffunction>

	<cffunction name="isXDOMCollection" access="public" returntype="boolean" output="false" hint="I determine if the given value is an XDom collection.">
		<cfargument name="value" type="any" required="true" hint="I am the value being tested." />
		<cfreturn (isStruct(arguments.value) && structKeyExists(arguments.value,"XDOMVersion") && structKeyExists(arguments.value,"isXDomCollection") && structKeyExists(arguments.value,"get")) />
	</cffunction>

	<cffunction name="normalizeXDOMCollection" access="public" returntype="any" output="false" hint="I take a collection and convert it to an XDom collection if it is not already.">
		<cfargument name="collection" type="any" required="true" hint="I am the collection being normalized." />

		<cfif this.isXDOMCollection(arguments.collection)>
			<cfreturn arguments.collection />
		<cfelse>
			<cfreturn createObject("component","XDOM" ).init(arguments.collection) />
		</cfif>		
	</cffunction>

	<cffunction name="remove" access="public" returntype="any" output="false" hint="I remove all the node in the current collection from their parent document.">
		<cfset var local = {} />
		<cfset local.deleteFlag = "xdomDeleteFlag" />

		<cfloop index="local.collectionItem" array="#variables.collection#">
			<cfset local.parentNodes = xmlSearch(local.collectionItem, ".." ) />
			<cfif isXmlAttribute(local.collectionItem)>
				<cfset structDelete(local.parentNodes[ 1 ].xmlAttributes, local.collectionItem.xmlName) />
			<cfelseif isXmlElem(local.collectionItem)>
				<cfset local.collectionItem.xmlAttributes[local.deleteFlag] = "true" />
				<cfloop index="local.childIndex" from="1" to="#arrayLen(local.parentNodes[1].xmlChildren)#" step="1">
					<cfif structKeyExists(local.parentNodes[1].xmlChildren[local.childIndex].xmlAttributes,local.deleteFlag)>
						<cfset arrayDeleteAt(local.parentNodes[1].xmlChildren,local.childIndex) />
						<cfset structDelete(local.collectionItem.xmlAttributes,local.deleteFlag) /> 
						<cfbreak />
					</cfif> 
				</cfloop>
			</cfif>
		</cfloop>		

		<cfreturn this />		
	</cffunction>

	<cffunction name="setPrevCollection" access="public" returntype="any" output="false" hint="I set the previous collection (for use with end()).">
		<cfargument name="collection" type="any" required="true" hint="I am the previous collection." />
		<cfset variables.prevCollection = arguments.collection />
		<cfreturn this />
	</cffunction>
	
	<cfset this.find = this.find_  />
	<cfset structDelete(this, "find_") />
	
</cfcomponent>