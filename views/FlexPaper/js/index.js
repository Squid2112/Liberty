var swfVersionStr = "10.0.0";
var xiSwfUrlStr = "/assets/swf/playerProductInstall.swf";
var flashvars = { 
	SwfFile : escape("/assets/swf/71909_1_0_BB2000.swf"),
	Scale : 0.6, 
	ZoomTransition : "easeOut",
	ZoomTime : 0.5,
	ZoomInterval : 0.1,
	FitPageOnLoad : true,
	FitWidthOnLoad : false,
	PrintEnabled : true,
	FullScreenAsMaxWindow : false,
	ProgressiveLoading : true,
	PrintToolsVisible : true,
	ViewModeToolsVisible : true,
	ZoomToolsVisible : true,
	FullScreenVisible : true,
	NavToolsVisible : true,
	CursorToolsVisible : true,
	SearchToolsVisible : true,
	localeChain: "en_US"
};

var params = { };

params.quality = "high";
params.bgcolor = "#ffffff";
params.allowscriptaccess = "sameDomain";
params.allowfullscreen = "true";
var attributes = {};
attributes.id = "FlexPaperViewer";
attributes.name = "FlexPaperViewer";

$(document).ready(function() {
	swfobject.embedSWF("/assets/swf/FlexPaperViewer.swf","flashContent",$(document).width()-50,$(document).height()-50,swfVersionStr,xiSwfUrlStr,flashvars,params,attributes);
	swfobject.createCSS("#flashContent","display:block;text-align:left;");
});