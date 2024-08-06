<!-- http://benalman.com/projects/jquery-dotimeout-plugin/ -->
(function($){var a={},c="doTimeout",d=Array.prototype.slice;$[c]=function(){return b.apply(window,[0].concat(d.call(arguments)))};$.fn[c]=function(){var f=d.call(arguments),e=b.apply(this,[c+f[0]].concat(f));return typeof f[0]==="number"||typeof f[1]==="number"?this:e};function b(l){var m=this,h,k={},g=l?$.fn:$,n=arguments,i=4,f=n[1],j=n[2],p=n[3];if(typeof f!=="string"){i--;f=l=0;j=n[1];p=n[2]}if(l){h=m.eq(0);h.data(l,k=h.data(l)||{})}else{if(f){k=a[f]||(a[f]={})}}k.id&&clearTimeout(k.id);delete k.id;function e(){if(l){h.removeData(l)}else{if(f){delete a[f]}}}function o(){k.id=setTimeout(function(){k.fn()},j)}if(p){k.fn=function(q){if(typeof p==="string"){p=g[p]}p.apply(m,d.call(n,i))===true&&!q?o():e()};o()}else{if(k.fn){j===undefined?e():k.fn(j===false);return true}else{e()}}}})(jQuery);

$.doTimeout(600000, function(){
	$.ajax({
		type:'get',
		cache:false,
		url:'/com/Ajax/VisitorAjax.cfc?method=ping',
		success: function(data,textStatus,httpRequest) { },
		error: function(XMLHttpRequest, textStatus, errorThrown) { }
	});
	return(true);
});

var digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

function base64Encode(text){
	if(/([^\u0000-\u00ff])/.test(text)) throw new Error('Can\'t base64 encode non-ASCII characters.');
	var i=0, cur, prev, byteNum, result=[];

	while(i < text.length) {
		cur = text.charCodeAt(i);
		byteNum = i % 3;

		switch(byteNum) {
			case 0: //first byte
				result.push(digits.charAt(cur >> 2));
				break;

			case 1: //second byte
				result.push(digits.charAt((prev & 3) << 4 | (cur >> 4)));
				break;

			case 2: //third byte
				result.push(digits.charAt((prev & 0x0f) << 2 | (cur >> 6)));
				result.push(digits.charAt(cur & 0x3f));
				break;
		}
		prev = cur;
		i++;
	}

	if(byteNum == 0) {
		result.push(digits.charAt((prev & 3) << 4));
		result.push("==");
	} else if (byteNum == 1){
		result.push(digits.charAt((prev & 0x0f) << 2));
		result.push('=');
	}
	return result.join('');
}

function base64Decode(text){
	text = text.replace(/\s/g,'');

	if(!(/^[a-z0-9\+\/\s]+\={0,2}$/i.test(text)) || text.length % 4 > 0) throw new Error('Not a base64-encoded string.');
	var cur, prev, digitNum, i=0, result=[];
	
	text = text.replace(/=/g,'');

	while(i < text.length) {
		cur = digits.indexOf(text.charAt(i));
		digitNum = i % 4;
		switch(digitNum) {
			//case 0: first digit - do nothing, not enough info to work with
			case 1: //second digit
				result.push(String.fromCharCode(prev << 2 | cur >> 4));
				break;

			case 2: //third digit
				result.push(String.fromCharCode((prev & 0x0f) << 4 | cur >> 2));
				break;

			case 3: //fourth digit
				result.push(String.fromCharCode((prev & 3) << 6 | cur));
				break;
		}
		prev = cur;
		i++;
	}
	return result.join('');
}

String.prototype.toHexTrig = function() {
	var result = new String('');
	for(var i=0; i<this.length; i++) {
		var char36 = Number(this.charCodeAt(i)).toString(36);
		if(char36.length < 2) char36 = '0' + char36;
		result += char36;
	}
	return(result);
}

String.prototype.fromHexTrig = function() {
	var result = new String('');
	for(var i=0; i<this.length; i+=2) {
		var char36 = this.charAt(i) + this.charAt(i+1);
		var nchar = String.fromCharCode(parseInt(char36,36));
		result += nchar;
	}
	return(result);
}