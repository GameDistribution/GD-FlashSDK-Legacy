package fgsapi
{
	import flash.external.ExternalInterface;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	internal final class LogRequest
	{
		public static var Pool:Vector.<Object> = new Vector.<Object>();;
		
		private static var OpenedURL:String;
		
		internal static function PushLog(_pushAction:Object):void
		{
			for (var i:int=0; i < Pool.length;i++) {
				if ( Pool[i].action == _pushAction.action ) {
					if (Pool[i].action == "custom" && Pool[i].value[0].key==_pushAction.value[0].key) {
						Pool[i].value[0].value++;
					} else {
						Pool[i].value = _pushAction.value;
					}
					break;
				}
			}
			if (i==Pool.length) Pool.push(_pushAction);
			return;
		}
		
		internal static function OpenURL(_url:String,_target:String="_blank",_reopen:Boolean=false):int {
			var res:int=1500;
			if (_reopen) {
				OpenedURL="";
				res = 1501;
			} else if (OpenedURL!=_url) {
				navigateToURL(new URLRequest(_url),_target);
				OpenedURL = _url;
				res = 1502;
			}			
			return res;
		}		
		
		internal static function CallJS(_data:String):Object {
			var res:int=1600;
			var cresult:String = "";
			if(ExternalInterface.available)
			{
				try
				{
					cresult = String(ExternalInterface.call(_data));
					res=1601;
				}
				catch(s:Error)
				{
					cresult = s.message;
					res=1602;
				}
			}
			return ({"response":res,"cresult":cresult});			
		}
		internal static function doResponse(ResponseData:Object):void 
		{
			switch (ResponseData.act) {
				case "cmd":
						var sendObj:Object = new Object();
						switch(ResponseData.res) {
							case "visit":
								FGSLogger.Visit();
								break;
							case "url":
								sendObj.action = "cbp";
								sendObj.value = OpenURL(ResponseData.dat.url,ResponseData.dat.target,ResponseData.dat.reopen);
								PushLog(sendObj);						
								break;
							case "js":
								sendObj.action = "cbp";
								var _CallJS:Object = CallJS(ResponseData.dat.jsdata);
								sendObj.value = _CallJS.response;
								sendObj.result = _CallJS.cresult;
								PushLog(sendObj);						
								break;							
						}						
						break;				
				case "visit":
						if (ResponseData.res==FGSLogger.SID) {
							FGSLogger.SaveCookie('visit',0);
							FGSLogger.SaveCookie('state',FGSLogger.GetCookie('state')+1);
						}
						break;
				case "play":
						if (ResponseData.res==FGSLogger.SID) {
							FGSLogger.SaveCookie('play',0);
						}
						break;
				case "custom":
					if (ResponseData.res==FGSLogger.SID) {
						FGSLogger.SaveCookie(ResponseData.custom,0);
					}
					break;
				
			}
		}
	}
}