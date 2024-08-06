<cfcomponent displayname="StacksObjectComponent" hint="Stack Component">
	<cfsetting showdebugoutput="No" enablecfoutputonly="No">

	<cffunction name="init" returntype="any" access="remote" output="No">
		<cfscript>
			this.MaxStackSize = 10000;
			this.Stack = arrayNew(1);
			this.Size = 0;
			this.Length = 0;

			return(this);
		</cfscript>
	</cffunction>

	<cffunction name="Push" returntype="any" access="remote" output="No">
		<cfargument name="value" type="any" required="Yes">
		<cfscript>
			if(this.Size LT this.MaxStackSize) {
				arrayAppend(this.Stack, Arguments.value);
				this.Size = arrayLen(this.Stack);
				this.Length = this.Size;
			}
			return(this.Size);
		</cfscript>
	</cffunction>

	<cffunction name="Pop" returntype="any" access="remote" output="No">
		<cfscript>
			var value = "";
			if(arrayLen(this.Stack)) {
				value = this.Stack[this.Size];
				arrayDeleteAt(this.Stack, this.Size);
			}
			this.Size = arrayLen(this.Stack);
			this.Length = this.Size;
			return(value);
		</cfscript>
	</cffunction>

	<cffunction name="Peek" returntype="any" access="remote" output="No">
		<cfscript>
			if((this.Size LTE 0) OR (this.Size GT arrayLen(this.Stack))) return(0);
			return(this.Stack[this.Size]);
		</cfscript>
	</cffunction>

	<cffunction name="Pull" returntype="any" access="remote" output="No">
		<cfargument name="value" type="any" required="yes">
		<cfscript>
			var idx = this.indexOf(arguments.Value);
			if(idx) arrayDeleteAt(this.Stack,idx);
			this.Size = arrayLen(this.Stack);
			this.Length = this.Size;
			return(this.Size);
		</cfscript>
	</cffunction>

	<cffunction name="Clear" returntype="any" access="remote" output="No">
		<cfscript>
			arrayClear(this.Stack);
			this.Size = 0;
			this.Length = this.Size;
		</cfscript>
	</cffunction>

	<cffunction name="getAt" returntype="any" access="remote" output="no">
		<cfargument name="idx" type="any" required="yes">
		<cfscript>
			if(Arguments.idx LTE this.Size) return(this.Stack[Arguments.idx]);
			return("");
		</cfscript>
	</cffunction>

	<cffunction name="indexOf" returntype="any" access="remote" output="no">
		<cfargument name="searchValue" type="any" required="yes">
		<cfscript>
			return(this.Stack.indexOf(Arguments.searchValue) + 1);
		</cfscript>
	</cffunction>

	<cffunction name="OnMissingMethod" access="public" returntype="any" output="no">
		<cfargument name="MissingMethodName" type="string" required="true">
		<cfargument name="MissingMethodArguments" type="struct" required="true">
		<cfreturn "">
	</cffunction>
	
</cfcomponent>