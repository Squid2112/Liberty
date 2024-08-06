<cfcomponent displayname="TreesComponent" hint="Trees Component">
	<cfsetting showdebugoutput="No" enablecfoutputonly="No">

	<cffunction name="init" displayname="init" returntype="any" access="remote" output="No">
		<cfargument name="TableName" type="any" required="Yes">
		<cfargument name="DSN" type="any" required="no" default="#Application.Settings.applicationDSN#">
		<cfscript>
			var result = "";

			this.DSN = Arguments.DSN;
			this.TableName = trim(Arguments.TableName);
			this.NodeStack = CreateObject("component", "com.System.StacksObject").init();
			this.RightStack = CreateObject("component", "com.System.StacksObject").init();
			this.EmptyQuery = QueryNew("ID,ParentID,LeftID,RightID,Title,Description,NodeTable,NodeID_columnName,NodeID_value","integer,integer,integer,integer,varchar,varchar,varchar,varchar,integer");
		</cfscript>

		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM sys.objects WITH (NOLOCK)
			WHERE
				object_id = OBJECT_ID(N'[dbo].[#this.TableName#]')
				AND type in (N'U')
		</cfquery>

		<cfif NOT result.RecordCount>
			<cfquery datasource="#this.DSN#">
				CREATE TABLE [dbo].[#this.TableName#](
					[ID] [int] IDENTITY(1,1) NOT NULL,
					[ParentID] [int] NOT NULL,
					[LeftID] [int] NOT NULL,
					[RightID] [int] NOT NULL,
					[Title] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					[Description] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					[NodeTable] [varchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					[NodeID_columnName] [varchar](200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
					[NodeID_value] [int] NULL,
				CONSTRAINT [PK_#this.TableName#] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
			</cfquery>
		</cfif>

		<cfreturn this>
	</cffunction>

	<cffunction name="clear" displayname="clear" returntype="Any" access="remote" output="No">
		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			DELETE FROM #this.TableName#
		</cfquery>
		<cfreturn this>
	</cffunction>

	<cffunction name="getLevel" displayname="getLevel" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="yes">

		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT COUNT(ParentID) AS Lvl
				FROM (SELECT DISTINCT ParentID WITH (NOLOCK)
					FROM #this.TableName# WITH (NOLOCK)
					WHERE
						(LeftID < (SELECT RightID FROM #this.TableName# WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(Arguments.ID)#">)) AND
						(RightID >= (SELECT RightID FROM #this.TableName# WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(Arguments.ID)#">))
				) AS DT
		</cfquery>
		<cfreturn result.Lvl>
	</cffunction>

	<cffunction name="getRoots" displayname="getRoots" returntype="any" access="remote" output="No">
		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="0">
			ORDER BY LeftID ASC
		</cfquery>
		<cfreturn result>
	</cffunction>

	<cffunction name="addNode" displayname="addNode" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="yes" default="0">
		<cfargument name="NodeTable" type="any" required="yes">
		<cfargument name="NodeID_columnName" type="any" required="yes">
		<cfargument name="NodeID_value" type="any" required="yes">
		<cfargument name="Title" type="any" required="Yes">
		<cfargument name="Description" type="any" required="No" default="">

		<cfscript>
			var node = "";
			var adjacent = "";
			var adjRightID = 0;
			var result = "";
			var m2 = "";
			var m1 = "";
			var NewNode = "";
			var tn = 0;
		</cfscript>

		<cfquery name="node" datasource="#this.DSN#">
			SELECT ID
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#val(Arguments.ID)#">
		</cfquery>

		<cfset tn = IIF(node.RecordCount, DE(node.id), DE(0))>

		<cfquery name="adjacent" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE
				Title <= <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Title)#">
				AND ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#tn#">
			ORDER BY Title DESC, ID DESC
		</cfquery>

		<cfif adjacent.RecordCount>
			<cfset adjRightID = adjacent.RightID[1]>
		<cfelse>
			<cfquery name="adjacent" datasource="#this.DSN#">
				SELECT *
				FROM #this.TableName# WITH (NOLOCK)
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#tn#">
			</cfquery>
			<cfif adjacent.RecordCount>
				<cfset adjRightID = adjacent.LeftID[1]>
			<cfelse>
				<cfset adjRightID = 0>
			</cfif>
		</cfif>

		<cfquery name="m2" datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET
				RightID = RightID + 2
			WHERE RightID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">
		</cfquery>

		<cfquery name="m1" datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET
				LeftID = LeftID + 2
			WHERE LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">
		</cfquery>

		<cfquery name="NewNode" datasource="#this.DSN#">
			INSERT INTO #this.TableName# (
				ParentID,
				LeftID,
				RightID,
				Title,
				Description,
				NodeTable,
				NodeID_columnName,
				NodeID_value
			) VALUES (
				<cfqueryparam cfsqltype="cf_sql_integer" value="#tn#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#(adjRightID+1)#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#(adjRightID+2)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Title)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.Description)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.NodeTable)#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(Arguments.NodeID_columnName)#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#trim(Arguments.NodeID_value)#">
			)

			SELECT Scope_Identity() AS ID
		</cfquery>

		<cfreturn NewNode.ID>
	</cffunction>

	<cffunction name="removeNode" displayname="removeNode" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="yes">
		
		<cfscript>
			var start = "";
			var adjRightID = 0;
			var subTractor = 0;
			var nodes = "";
			var rnodes = "";
			var m1 = "";
			var m2 = "";
		</cfscript>
	
		<cfquery name="start" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
			ORDER BY LeftID ASC
		</cfquery>
	
		<cfif start.RecordCount>
			<cfset adjRightID = start.RightID>
			<cfquery name="nodes" datasource="#this.DSN#">
				SELECT *
				FROM #this.TableName# WITH (NOLOCK)
				WHERE
					LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#Start.LeftID#">
					AND RightID < <cfqueryparam cfsqltype="cf_sql_integer" value="#Start.RightID#">
			</cfquery>
			<cfset subTractor = (nodes.RecordCount * 2) + 2>
			
			<cfquery name="rnodes" datasource="#this.DSN#">
				DELETE FROM #this.TableName#
				WHERE
					ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#start.ID#">
					OR (
						LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#Start.LeftID#">
						AND RightID < <cfqueryparam cfsqltype="cf_sql_integer" value="#Start.RightID#">
					)
			</cfquery>
		
			<cfquery name="m1" datasource="#this.DSN#">
				UPDATE #this.TableName#
				SET RightID = RightID - <cfqueryparam cfsqltype="cf_sql_integer" value="#subTractor#">
				WHERE RightID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">
			</cfquery>
			<cfquery name="m2" datasource="#this.DSN#">
				UPDATE #this.TableName#
				SET LeftID = LeftID - <cfqueryparam cfsqltype="cf_sql_integer" value="#subTractor#">
				WHERE LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">
			</cfquery>
		</cfif>
		<cfreturn Arguments.ID>
	</cffunction>

	<cffunction name="getNode" displayname="getNode" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>
		<cfif NOT result.RecordCount>
			<cfreturn Duplicate(this.EmptyQuery)>
		</cfif>
		<cfreturn result>
	</cffunction>

	<cffunction name="updateNode" displayname="updateNode" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="Yes">
		<cfargument name="Title" type="any" required="No">
		<cfargument name="Description" type="any" required="No">
		<cfargument name="NodeTable" type="any" required="no">
		<cfargument name="NodeID_columnName" type="any" required="no">
		<cfargument name="NodeID_value" type="any" required="no">
	
		<cfscript>
			var result = "";
			var delim = "";
		</cfscript>	

		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET
				<cfif StructKeyExists(Arguments, "Title")>Title = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Title#"><cfset delim=","></cfif>
				<cfif StructKeyExists(Arguments, "Description")>#delim# Description = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.Description#"><cfset delim=","></cfif>
				<cfif StructKeyExists(Arguments, "NodeTable")>#delim# NodeTable = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.NodeTable#"><cfset delim=","></cfif>
				<cfif StructKeyExists(Arguments, "NodeID_columnName")>#delim# NodeID_columnName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.NodeID_columnName#"><cfset delim=","></cfif>
				<cfif StructKeyExists(Arguments, "NodeID_value")>#delim# NodeID_value = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.NodeID_value#"></cfif>
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>

		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>
		<cfif result.RecordCount>
			<cfreturn Duplicate(this.EmptyQuery)>
		</cfif>
		<cfreturn result>
	</cffunction>

	<cffunction name="getBranch" displayname="getBranch" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfscript>
			var root = "";
			var result = "";
			var i = 0;
			var offset = 0;
		</cfscript>
		
		<cfquery name="root" datasource="#this.DSN#">
			SELECT LeftID, RightID
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>

		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE
				LeftID BETWEEN <cfqueryparam cfsqltype="cf_sql_integer" value="#root.LeftID[1]#"> AND <cfqueryparam cfsqltype="cf_sql_integer" value="#root.RightID[1]#">
			ORDER BY LeftID ASC
		</cfquery>

		<cfscript>
			offset = (Root.LeftID  - 1);
			for(i=1; i LTE result.RecordCount; i=i+1) {
				result.LeftID[i] = result.LeftID[i] - offset;
				result.RightID[i] = result.RightID[i] - offset;
			}
			return(result);
		</cfscript>
	</cffunction>

	<cffunction name="getBranchSize" displayname="getBranchSize" returntype="any" access="remote" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfset var result = "">
		<cfquery name="result" datasource="#this.DSN#">
			SELECT LeftID, RightID
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>
		<cfreturn ((result.RightID - result.LeftID - 1) / 2)>
	</cffunction>

	<cffunction name="addBranch" displayname="addBranch" returntype="any" access="remote">
		<cfargument name="ParentID" type="any" required="yes">
		<cfargument name="Branch" type="any" required="yes">

		<cfscript>
			var node = "";
			var idx = 1;
			var NodeID = 0;
			var BranchSize = Arguments.Branch.RecordCount;
			this.RightStack.Clear();
			this.NodeStack.Clear();
		</cfscript>

		<cfquery name="node" datasource="#this.DSN#">
			SELECT ID
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>
		
		<cfscript>
			this.NodeStack.Push(node.ID);
			for(idx=1; idx LTE BranchSize; idx=idx+1) {
				while((this.RightStack.Size GT 0) AND (Arguments.Branch.RightID[idx] GT this.RightStack.Peek())) {
					this.RightStack.Pop();
					this.NodeStack.Pop();
				}
				NodeID = this.addNode(this.NodeStack.Peek(), Arguments.Branch.NodeTable[idx], Arguments.NodeID_columnName[idx], Arguments.NodeID_value[idx], Arguments.Branch.Title[idx], Arguments.Branch.Description[idx]);

				if(((Arguments.Branch.RightID[idx] - Arguments.Branch.LeftID[idx] - 1) / 2) GT 0) {
					this.NodeStack.Push(NodeID);
					this.RightStack.Push(Arguments.Branch.RightID[idx]);
				}
			}
			return(node.ID);
		</cfscript>
	</cffunction>

	<cffunction name="moveBranch" displayname="moveBranch" returntype="any" access="remote">
		<cfargument name="SourceID" type="any" required="yes">
		<cfargument name="DestID" type="any" required="yes">

		<cfscript>
			var adjacent = "";
			var adjRightID = 0;
			var SrcNode = this.getNodeById(Arguments.SourceID);
			var DstNode = this.getNodeById(Arguments.DestID);
			var offset = 10000000;
			var SrcSize = ((SrcNode.RightID[1] + 1) - SrcNode.LeftID[1]);
		</cfscript>

		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET
				LeftID = ((LeftID - <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.LeftID[1]#">) + <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#"> + 1),
				RightID = ((RightID - <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.LeftID[1]#">) + <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#"> + 1)
			WHERE
				LeftID >= <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.LeftID[1]#">
				AND RightID <= <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.RightID[1]#">
		</cfquery>

		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.DestID#">
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.SourceID#">
		</cfquery>
		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET #this.TableName#.LeftID = (#this.TableName#.LeftID - <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcSize#">)
			WHERE
				(#this.TableName#.LeftID < <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">)
				AND (#this.TableName#.LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.RightID[1]#">)
		</cfquery>
		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET #this.TableName#.RightID = (#this.TableName#.RightID - <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcSize#">)
			WHERE
				(#this.TableName#.LeftID < <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">)
				AND (#this.TableName#.RightID > <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcNode.RightID[1]#">)
		</cfquery>

		<cfquery name="adjacent" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE
				(LeftID < <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">)
				AND (Title <= <cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(SrcNode.Title[1])#">)
				AND (ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#DstNode.ID[1]#">)
			ORDER BY Title DESC, ID DESC
		</cfquery>

		<cfif adjacent.RecordCount GT 0>
			<cfset adjRightID = adjacent.RightID[1]>
		<cfelse>
			<cfquery name="adjacent" datasource="#this.DSN#">
				SELECT *
				FROM #this.TableName# WITH (NOLOCK)
				WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.DestID#">
			</cfquery>
			<cfif adjacent.RecordCount NEQ 0>
				<cfset adjRightID = adjacent.LeftID[1]>
			<cfelse>
				<cfset adjRightID = 0>
			</cfif>
		</cfif>

		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET RightID = (RightID + <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcSize#">)
			WHERE
				(LeftID < <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">)
				AND (RightID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">)
		</cfquery>
		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET LeftID = (LeftID + <cfqueryparam cfsqltype="cf_sql_integer" value="#SrcSize#">)
			WHERE
				(LeftID < <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">)
				AND (LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#adjRightID#">)
		</cfquery>

 		<cfset DstNode = this.getNodeById(Arguments.DestID)>
		<cfquery datasource="#this.DSN#">
			UPDATE #this.TableName#
			SET
				LeftID = ((LeftID - <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">) + <cfqueryparam cfsqltype="cf_sql_integer" value="#DstNode.LeftID[1]#">),
				RightID = ((RightID - <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">) + <cfqueryparam cfsqltype="cf_sql_integer" value="#DstNode.LeftID[1]#">)
			WHERE LeftID > <cfqueryparam cfsqltype="cf_sql_integer" value="#offset#">
		</cfquery>
		<cfreturn SrcNode.RightID[1]>
	</cffunction>

	<cffunction name="branchToXML" access="remote" returntype="any" output="Yes">
		<cfargument name="ID" type="any" required="Yes">

 		<cfscript>
			var Tree = this.getBranch(Arguments.ID);
			var TreeSize = Tree.RecordCount;
			var idx=0;
			var outString = "";
			var branchParent = 0;

			this.RightStack.Clear();

			if(TreeSize EQ 0) return outString;

			for(idx=1; idx LTE TreeSize; idx=idx+1) {
				while(this.RightStack.Size AND (Tree.LeftID[idx] GT this.RightStack.Peek())) {
					outString = outString & "</node>";
					this.RightStack.Pop();
				}

				if(((Tree.RightID[idx] - Tree.LeftID[idx] - 1) / 2) GT 0) {
					outString = outString & '<node id="' & Tree.ID[idx] & '" parentid="' & Tree.ParentID[idx] & '" id="' & Tree.Title[idx] & '" left="' & Tree.LeftID[idx] & '" right="' & Tree.RightID[idx] & '">';
					this.RightStack.Push(Tree.RightID[idx]);
				} else {
					outString = outString & '<node id="' & Tree.ID[idx] & '" parentid="' & Tree.ParentID[idx] & '" id="' & Tree.Title[idx] & '" left="' & Tree.LeftID[idx] & '" right="' & Tree.RightID[idx] & '" />';
				}
			}

			while(this.RightStack.Size) {
				outString = outString & "</node>";
				this.RightStack.Pop();
			}
			return(outString);
		</cfscript>
	</cffunction>

	<cffunction name="getNodesOfThisParent" access="remote" returntype="any" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfquery name="tNode" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
		</cfquery>
		<cfquery name="result" datasource="#this.DSN#">
			SELECT *
			FROM #this.TableName# WITH (NOLOCK)
			WHERE ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#tNode.ParentID#">
			ORDER BY Title ASC
		</cfquery>
		<cfif result.RecordCount GT 0>
			<cfreturn result>
		</cfif>
		<cfreturn tNode>
	</cffunction>

	<cffunction name="getChildNodes" access="remote" returntype="any" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfquery name="result" datasource="#this.DSN#">
			SELECT Tree.*
			FROM #this.TableName# Tree WITH (NOLOCK)
			WHERE Tree.ParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#Arguments.ID#">
			ORDER BY Tree.Title ASC
		</cfquery>
		<cfreturn result>
	</cffunction>

	<cffunction name="getExtChildNodes" access="remote" returntype="any" output="No">
		<cfargument name="ID" type="any" required="Yes">
		<cfset var result = "">

		<cfquery name="result" datasource="#this.DSN#">
			SELECT
				Tree.ID,
				Tree.ParentID,
				Tree.LeftID,
				Tree.RightID,
				Tree.Title AS Text,
				Tree.Description,
				Tree.NodeTable,
				Tree.NodeID_columnName,
				Tree.NodeID_value,
				CASE WHEN (((Tree.RightID - Tree.LeftID - 1) / 2) > 0) THEN 'folder' ELSE 'file' END AS cls,
				CASE WHEN (((Tree.RightID - Tree.LeftID - 1) / 2) <= 0) THEN 'true' ELSE 'false' END AS leaf
			FROM #this.TableName# Tree WITH (NOLOCK)
			WHERE Tree.ParentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.ID#">
			ORDER BY Tree.Title ASC
		</cfquery>
		<cfreturn result>
	</cffunction>

	<cffunction name="getExtCatelogChildNodes" access="remote" returntype="any" output="No">
		<cfargument name="ID" type="any" required="Yes">
		<cfset var result = "">

		<cfquery name="result" datasource="#this.DSN#">
			SELECT
				Tree.ID,
				Tree.ParentID,
				Tree.LeftID,
				Tree.RightID,
				Tree.Title AS Text,
				Tree.Description,
				Tree.NodeTable,
				Tree.NodeID_columnName,
				Tree.NodeID_value,
				CASE
					WHEN Tree.NodeTable = 'Categories' THEN 'category-icon-class'
					WHEN Tree.NodeTable = 'SubCategories' THEN 'subcategory-icon-class'
					WHEN Tree.NodeTable = 'Packages' THEN 'package-icon-class'
					WHEN Tree.NodeTable = 'Products' THEN 'product-icon-class'
					WHEN Tree.NodeTable = 'Items' THEN 'item-icon-class'
				END AS cls,

--				CASE WHEN (((Tree.RightID - Tree.LeftID - 1) / 2) > 0) THEN 'folder' ELSE 'file' END AS cls,

				CASE WHEN (((Tree.RightID - Tree.LeftID - 1) / 2) <= 0) THEN 'true' ELSE 'false' END AS leaf
			FROM #this.TableName# Tree WITH (NOLOCK)
			WHERE Tree.ParentID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#Arguments.ID#">
			ORDER BY Tree.Title ASC
		</cfquery>
		<cfreturn result>
	</cffunction>

	<cffunction name="branchToJSON" access="remote" returntype="any" output="No">
		<cfargument name="ID" type="any" required="Yes">

		<cfscript>
			var Tree = this.getChildNodes(Arguments.ID);
			var TreeSize = Tree.RecordCount;
			var idx=0;
			var outString = "[";
			var branchParent = 0;

			this.RightStack.Clear();

			if(TreeSize EQ 0) return("[]");

			for(idx=1; idx LTE TreeSize; idx=idx+1) {
				while(this.RightStack.Size AND (Tree.LeftID[idx] GT this.RightStack.Peek())) this.RightStack.Pop();

				if(((Tree.RightID[idx] - Tree.LeftID[idx] - 1) / 2) GT 0) {
					outString = outString & "{'text':'" & Tree.Title[idx] & "','id':'" & Tree.ID[idx] & "','cls':'folder'}";
					this.RightStack.Push(Tree.RightID[idx]);
				} else {
					outString = outString & "{'text':'" & Tree.Title[idx] & "','id':'" & Tree.ID[idx] & "','leaf':true,'cls':'file'}";
				}
				if(idx LT TreeSize) outString = outString & ",";
			}

			while(this.RightStack.Size) this.RightStack.Pop();

			return(outString & "]");
		</cfscript>
	</cffunction>

</cfcomponent>