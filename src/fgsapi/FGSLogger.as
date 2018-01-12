package fgsapi
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.system.Security;

	import flash.utils.getDefinitionByName;

	[SWF(width='540',height='440',frameRate='30',backgroundColor='0x000000')]
	public class FGSLogger extends Sprite
	{		
		// API settings
		internal static var Enabled:Boolean = false;
		internal static var UseSSL:Boolean = false;
		internal static var ApiVersion:String = "v111";
		internal static var ServerVersion:String = "v1";
		internal static var isVersionChecked:Boolean = false;
		internal static var newVersionLoaded:Boolean = false;
		internal static var LastestVersion:String = "v1.2";
		internal static var Debug_InitWarning:String = "First, you have to call 'Log' method to connect to the server.";
		
		// User Settings
		internal static var ServerId:String = "";
		internal static var GUID:String = "";
		internal static var gID:String = "";
		internal static var WebRef:String = "";
		private static var _SID:String = "";
		private static var _EnabledDebug:Boolean = false;
		private static var dispatcher:EventDispatcher = new EventDispatcher();
		private static var _BlockText:String = "";
		internal static var _CheckForBlockLinks:Boolean = true;
		internal static var _IgnoreNetworkReachable:Boolean = true;
		internal static var _EnableBanner:Boolean = true;
		internal static var isLocal:Boolean = false;
		internal static var _root:DisplayObject;
		
		internal static var _instance:FGSLogger;
		internal static var _Stage:Stage;

		
		/**
		 * Check for blocking links.
		 */	
		public static function get EnableBlockLinksChecking():Boolean { 
			return _CheckForBlockLinks; 
		};
		public static function set EnableBlockLinksChecking(value:Boolean):void { 
			_CheckForBlockLinks = value; 
		};
		
		/**
		 * While cheking blocking links API gets domain list from server, If you are ignoring network reachable to the server for any reason like no internet connection or 
		 * allownetworking state, your game always will work. GameInit() will be Invoked by FGSEvent.ISALLOWED_LINKS 
		 */	
		public static function get IgnoreNetworkReachable():Boolean { 
			return _IgnoreNetworkReachable; 
		};
		public static function set IgnoreNetworkReachable(value:Boolean):void { 
			_IgnoreNetworkReachable = value; 
		};
		
		/**
		 * Set Blocked Screen Text.
		 */	
		public static function get BlockText():String { 
			return _BlockText; 
		};
		public static function set BlockText(value:String):void { 
			_BlockText = value; 
		};
		
		/**
		 * API gets Session Id.
		 */	
		public static function get SID():String { 
			return _SID; 
		};
		/**
		 * API enables to view Log.
		 */		
		public static function get EnabledDebug():Boolean {
			return _EnabledDebug;
		}
		public static function set EnabledDebug(value:Boolean):void {
			_EnabledDebug=value;
			return;
		}
		
		public function FGSLogger() {
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			FUtils.DebugLog("GDApi constructor.");
			
			addEventListener(Event.ADDED_TO_STAGE,function(e:Event):void{
				if (stage==null) {
					FUtils.DebugLog("GDApi Stage is null");				
				} else {
					FUtils.DebugLog("GDApi Stage is created");								
				}
				_Stage = stage;				
			});			
		}
		
		
		/**
		 * FGS Logger initializes the API.  You must do this first before anything else!
		 * @param	gID			Your game id from FlashGameSubmitter
		 * @param	guid		Your game guid from FlashGameSubmitter
		 * @param	root		Should be root to detect the page
		 */		
		public static function Log(_gID:String = "", _guid:String = "", __root:DisplayObject = null):void
		{					
			_root = __root;
			var _loaderurl:String=_root.loaderInfo.loaderURL;
			if(!_loaderurl) {				
				trace("Warning: It looks like you are using the Log.");
				trace("FGSLog call to use the structure: ");
				trace("FGSLogger.Log(_gID, _guid, root);");
			}
			
			if(_gID.length !=32) {
				FUtils.DebugLog("GameId is wrong.");				
				return;				
			}		
			
			gID = _gID;
			var _tGuid:Array = _guid.toLowerCase().split("-");
			ServerId = _tGuid.splice(5, 1);
			GUID = _tGuid.join("-");
			_SID = SessionId.getId();
			Enabled = true;
			
			/*
			try { // try/catch is using for AIR.
				Security.loadPolicyFile("http://"+GUID+".s1.submityourgame.com/crossdomain.xml?gid="+gID+"&ver="+ApiVersion);					
			} catch(e) {
			}*/			
			
			if((gID.length == 0 || GUID == "" || ServerId == ""))
			{
				FUtils.DebugLog("Please check GameId or GUId. FGSAPI will not run.");				
				Enabled = false;
				return;
			}
			
			WebRef = FindUrl(_loaderurl);
			
			if(WebRef == null || WebRef == "")
			{
				FUtils.DebugLog("We couldn't find refer address. FGSAPI will not run.");				
				Enabled = false;
				return;
			}
			
		
			// Load the security context
		//	Security.loadPolicyFile((UseSSL ? "https://" : "http://") + GUID + "."+ ServerId +".submityourgame.com"+"/crossdomain.xml");
			//Security.loadPolicyFile((UseSSL ? "https://" : "http://") + GUID + "."+ ServerId +".submityourgame.com"+"/crossdomain.xml?gid="+_gID+"&ver="+ApiVersion);
			
			// Check the URL is http / https
			if(WebRef.indexOf("http://") != 0 && WebRef.indexOf("https://") != 0) 
			{
				// Sandbox exceptions for testing
				if(Security.sandboxType != "localWithNetwork" && Security.sandboxType != "localTrusted" && Security.sandboxType != "remote")
				{
					FUtils.DebugLog("Sandboxtype isn't localWithNetwork or localTrusted or remote. FGSAPI will not run.");				
					Enabled = false;
					return;
				}
			}
							
			/*
			var OldFGS:Class = Object(_root.root).getDefinitionByName("fgs.FGSLogger") as Class;			
			FChannel.DebugLog("Is Banner Enabled: "+ OldFGS.EnableBanner );
					
			if (OldFGS.EnableBanner) {
				_EnableBanner = false;			
			} else {				
				_EnableBanner = true;			
			}
			*/
			FBanner.addEventListener("bannerStarted",BannerStarted);
			FBanner.addEventListener("bannerClosed",BannerClosed);
			FBanner.init();
					
			return;
		}
		
		private static function BannerClosed(e:Event):void
		{
			dispatchEvent(new FGSEvent(FGSEvent.ISBANNER_CLOSED, true));			
		}
		
		private static function BannerStarted(e:Event):void
		{
			dispatchEvent(new FGSEvent(FGSEvent.ISBANNER_STARTED, true));			
		}
				
		/**
		 * FGS Show Banner. 
		 */		
		public static function ShowBanner():void 
		{
			if(!Enabled){
				FUtils.DebugLog(Debug_InitWarning)
				return;
			}
			FBanner.ShowAd();
		}
		
		/**
		 * FGS Close Banner. 
		 */		
		public static function CloseBanner():void 
		{
			if(!Enabled){
				FUtils.DebugLog(Debug_InitWarning)
				return;
			}
			FBanner.CloseBanner();
		}
		
		
		/**
		 * Sets the API to use SSL-only for all communication
		 */
		public static function SetSSL():void
		{
			UseSSL = true;
			FUtils.DebugLog("Enabled SSL requests.");
		}
		
		/**
		 * Attempts to detect the page url
		 * @param	url		The callback url if page cannot be detected
		 */
		private static function FindUrl(_url:String):String
		{
			var url:String;
			
			if(ExternalInterface.available)
			{
				try
				{
					url = String(ExternalInterface.call("window.location.href.toString"));
				}
				catch(s:Error)
				{
					url = _url;
				}
			}
			else if(_url.indexOf("http://") == 0 || _url.indexOf("https://") == 0)
			{
				url = _url;
			}
			
			if(url == null  || url == "" || url == "null")
			{
				url = "http://localhost/";
			}
			
			if(url.indexOf("http://") != 0 && url.indexOf("https://") != 0)
				url = "http://localhost/";
			
			return url;
		}
		
		public static function PlayGame():void 
		{		
			/**
			 * FGS Logger sends how many times 'PlayGame' is called. If you invoke 'PlayGame' many times, it increases 'PlayGame' counter and sends this counter value. 
			 * We no longer support this feature
			 * */
		}
		public static function CustomLog(_key:String):void 
		{
			/**
			 * FGS Logger sends how many times 'CustomLog' that is called related to given by _key name. If you invoke 'CustomLog' many times, it increases 'CustomLog' counter and sends this counter value. 
			 * We no longer support this feature
			 * */
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