<CFOUTPUT>
<CFIF Find("@",URL.CODE,1) GT 0>
  <CFSET MASK="0">
  <CFIF URL.N GT 0><CFSET MASK=RepeatString("0",URL.N)></CFIF>
  <CFLOOP INDEX="I" FROM="#URL.S#" TO="#URL.E#" STEP="#URL.X#">
    <CFSWITCH EXPRESSION="#UCase(URL.F)#">
      <CFCASE VALUE="N"><CFSET NUM=I></CFCASE>
      <CFCASE VALUE="L"><CFSET NUM=NumberFormat(I, MASK)></CFCASE>
      <CFCASE VALUE="R"><CFSET NUM=I & MASK></CFCASE>
    </CFSWITCH>
    [<A HREF="javascript:loadURL('#Replace(URL.CODE,"@",NUM,"ALL")#');">#NUM#</A>]<BR>
  </CFLOOP>
<CFELSE>
[<A HREF="javascript:loadURL('#URL.CODE#');">LINK</A>]
</CFIF>
</CFOUTPUT>