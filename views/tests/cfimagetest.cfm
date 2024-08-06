<!---
<cffile action="readbinary" file="#expandPath('/')#assets/img/house/DSCN0180_thumb.jpg" variable="pic" />
<cfsavecontent variable="testImage1">
	<cfcontent type="image/jpeg; charset=8859_1">
	<cfoutput>#toString(pic)#</cfoutput>
</cfsavecontent>

<cfsavecontent variable="testImage2">
	<cfcontent type="image/jpeg; charset=8859_1">
	<cfoutput>#toString(pic)#</cfoutput>
</cfsavecontent>

<cfoutput>#testImage1#</cfoutput>
<cfoutput>#testImage2#</cfoutput>

<cfscript>
	myImage = imageRead(expandPath('/') & 'assets/img/house/DSCN0180_thumb.jpg');
	writeDump(myImage);
</cfscript>
--->

<cfimage action="writetobrowser" source="#expandPath('/')#assets/img/house/DSCN0180_thumb.jpg" format="jpg">

<!---
<cffile action="readbinary" file="#ExpandPath('/')#newsBG.gif" variable="pic"/>
<cfcontent type="image/gif; charset=8859_1">
<cfscript>
    context = getPageContext();
    context.setFlushOutput(false);
    response = context.getResponse().getResponse();
    out = response.getOutputStream();
    response.setContentType("image/gif");
    response.setContentLength(arrayLen(pic));
    out.write(pic);
    out.flush();  
    out.close();
</cfscript>
--->