package fgsapi
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	
	import fgsapi.json.JSONDecoder;
	import fgsapi.json.JSONEncoder;
		
	internal final class FChannel
	{
		private static var StatsURL:String;
		internal static var StatsURLHead:String;
		
		private static var urlLoader:URLLoader = new URLLoader();
		private static var urlRequest:URLRequest = new URLRequest();
		private static var postObj:URLVariables = new URLVariables();;
		private static var callbackParam:String;
				
		internal static function Init():void
		{
			//Pool = new Vector.<PRequest>();
			StatsURLHead = (FGSLogger.UseSSL ? "https://" : "http://") + FGSLogger.GUID + "."+ FGSLogger.ServerId +".submityourgame.com";
			StatsURL = StatsURLHead + "/"+FGSLogger.ServerVersion+"/";
			
			urlLoader.addEventListener("ioError", Fail);
			urlLoader.addEventListener("networkError", Fail);
			urlLoader.addEventListener("verifyError", Fail);
			urlLoader.addEventListener("diskError", Fail);
			urlLoader.addEventListener("securityError", Fail);
			urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
			urlLoader.addEventListener("complete", Complete);
			
			postObj.gid = FGSLogger.gID;
			postObj.ref = FGSLogger.WebRef; 
			postObj.sid = FGSLogger.SID;
			postObj.ver = FGSLogger.ApiVersion;
			
			urlRequest.contentType = "application/x-www-form-urlencoded";
			urlRequest.url = StatsURL;
			urlRequest.method = URLRequestMethod.POST;
			
			var chanTimer:Timer = new Timer(30000);
			chanTimer.addEventListener(TimerEvent.TIMER, TimerHandler);
			chanTimer.start();			
		}
		
		private static function TimerHandler(event:Event):void
		{	
			if (FGSLogger.Enabled) {
				var actionArray:Object = FGSLogger.Ping();				
				if (LogRequest.Pool.length>0) {
					actionArray = LogRequest.Pool.shift();
				}
				postObj.cbp = callbackParam;
				try {
					postObj.act = new JSONEncoder( actionArray ).getString();
					urlRequest.data = postObj;
					urlLoader.load(urlRequest);
					DebugLog('Send action: '+postObj.act);
				} 
				catch (e:Error) {
					DebugLog('JSON Error: '+e.message);					
				}
			}
		}
		
		private static function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			DebugLog('Response: '+request.data);			
						
			switch (e.type) {
				case Event.COMPLETE:
					if (request.data!=null && request.data!='') 
					{
						try {
							var vars:Object = new JSONDecoder( request.data,true ).getValue();
							LogRequest.doResponse(vars);
							callbackParam = vars.cbp;
						}
						catch (e:Error) {
							DebugLog('JSON Error: '+e.message);					
							FGSLogger.Visit();
						}
					}
					break;
			}
			
		}
		
		private static function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			FGSLogger.Visit();
			DebugLog('Fail: '+e+' : '+request.data);			
		}
		
		private static function HTTPStatusIgnore(e:Event):void
		{
		}
		
		internal static function DebugLog(...parameters):void {	
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call("console.log",parameters);					
				}
				catch(s:Error)
				{
				}
			}				
			trace("FGSAPI Debug @ ",parameters);
		}
		
		internal static function CallJSFunction(methodFunction:String,...parameters):void {	
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.call(methodFunction,parameters);					
				}
				catch(s:Error)
				{
				}
			}				
		}	
		internal static function RegisterJSCallBackFunction(method:String,methodFunction:Function):void {	
			if(ExternalInterface.available)
			{
				try
				{
					ExternalInterface.addCallback(method, methodFunction);
					DebugLog(method+" RegisterJSCallBackFunction is attached.");
				}
				catch(s:Error)
				{
					DebugLog("RegisterJSCallBackFunction :"+s.message);
				}
			}
		}		
	}
}