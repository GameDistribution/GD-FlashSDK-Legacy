package gd
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.Security;

	internal final class FBlocker
	{
		private static var BlockerServerURL:String = "bl.submityourgame.com";
		private static var StatsURL:String;
		
		private static var urlLoader:URLLoader = new URLLoader();
		private static var urlRequest:URLRequest = new URLRequest();
		
		public static var SitesCounter:int = 0;
		public static var SiteBlocked:Boolean=false;
		
		private static const dispatcher:EventDispatcher = new EventDispatcher();		
		
		internal static function CheckBlocker():void
		{
			Security.allowDomain("*")
			StatsURL = (FGSLogger.UseSSL ? "https://" : "http://") + FGSLogger.ServerId +"." + BlockerServerURL + "/" + FGSLogger.gID + ".xml";
			
			urlLoader.addEventListener("ioError", Fail);
			urlLoader.addEventListener("networkError", Fail);
			urlLoader.addEventListener("verifyError", Fail);
			urlLoader.addEventListener("diskError", Fail);
			urlLoader.addEventListener("securityError", Fail);
			urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
			urlLoader.addEventListener("complete", Complete);
			
			urlRequest.contentType = "application/x-www-form-urlencoded";
			urlRequest.url = StatsURL;
			urlRequest.method = URLRequestMethod.GET;
			
			try {
				urlLoader.load(urlRequest);
			} catch (e:Error) {
				FChannel.DebugLog("CheckBlocker error: "+e.message);
			}
			
		}			
		
		private static function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			FChannel.DebugLog('Response: '+request.data);
			
			XML.ignoreWhitespace = true; 
			var blockedSites:XML = new XML(request.data);
			
			if (String(blockedSites.row.f)=='false') {			
				SiteBlocked = false;
			} else {
				try {				
					if (blockedSites.row) {
						for (SitesCounter=0; SitesCounter < blockedSites.row.length(); SitesCounter++) {
							if (parseDomain(FGSLogger.WebRef)==String(blockedSites.row.b[SitesCounter])) {
								SiteBlocked = true;
							}
						}
					} else {
						SiteBlocked = false;					
					}
				} catch (e:Error) {
					SiteBlocked = false;
					FChannel.DebugLog("Block XML error: "+e.message);
				}				
			}
			dispatchEvent(new Event("blocksiteLoaded"));
		}	
			
		private static function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			FChannel.DebugLog('Fail: '+e+' : '+request.data);
			if (FGSLogger.IgnoreNetworkReachable) {
				SiteBlocked = false;
				dispatchEvent(new Event("blocksiteLoaded"));			
			} else {
				SiteBlocked = true;
				dispatchEvent(new Event("blocksiteFailed"));
			}
		}
		
		private static function HTTPStatusIgnore(e:Event):void
		{
		}	
		
		private static function parseDomain(WebRef:String):String {
			var WebArray:Array = WebRef.replace('http://','').split('/');
			return WebArray[0];			
		}
		
		/*
		Custom Event Listener for Static functions
		*/
		public static function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		public static function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		public static function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}
		public static function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}		
	}
}