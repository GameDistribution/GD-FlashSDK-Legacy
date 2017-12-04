package fgsapi
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
	import flash.net.SharedObject;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.utils.getDefinitionByName;

	[SWF(width='540',height='440',frameRate='30',backgroundColor='0x000000')]
	public class FGSLogger extends Sprite
	{		
		// API settings
		internal static var Enabled:Boolean = false;
		internal static var UseSSL:Boolean = false;
		internal static var ApiVersion:String = "v110";
		internal static var ServerVersion:String = "v1";
		internal static var isVersionChecked:Boolean = false;
		internal static var newVersionLoaded:Boolean = false;
		internal static var LastestVersion:String = "v1.1";
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
		 * Banner time out
		 */	
		public static function get BannerTimeOut():int { 
			return FBanner._BannerTimeOut; 
		};
		public static function set BannerTimeOut(value:int):void { 
			FBanner._BannerTimeOut = value; 
		};
		
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
		
		/**
		 * API shows banner is active or not.
		 */		
		public static function get IsBannerActive():Boolean {
			return FBanner._bannerActive;
		}
		
		public function FGSLogger() {
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
			FChannel.DebugLog("GDApi constructor.");
			
			addEventListener(Event.ADDED_TO_STAGE,function(e:Event):void{
				if (stage==null) {
					FChannel.DebugLog("GDApi Stage is null");				
				} else {
					FChannel.DebugLog("GDApi Stage is created");								
				}
				_Stage = stage;				
			});			
		}
		
		// Class Settings
		private static var Cookie:SharedObject;
		
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
				FChannel.DebugLog("GameId is wrong.");				
				return;				
			}		
			
			gID = _gID;
			var _tGuid:Array = _guid.toLowerCase().split("-");
			ServerId = _tGuid.splice(5, 1);
			GUID = _tGuid.join("-");
			_SID = SessionId.getId();
			Enabled = true;
			
			try { // try/catch is using for AIR.
				Security.loadPolicyFile("http://"+GUID+".s1.submityourgame.com/crossdomain.xml?gid="+gID+"&ver="+ApiVersion);					
			} catch(e) {
			}			
			
			if((gID.length == 0 || GUID == "" || ServerId == ""))
			{
				FChannel.DebugLog("Please check GameId or GUId. FGSAPI will not run.");				
				Enabled = false;
				return;
			}
			
			WebRef = FindUrl(_loaderurl);
			
			if(WebRef == null || WebRef == "")
			{
				FChannel.DebugLog("We couldn't find refer address. FGSAPI will not run.");				
				Enabled = false;
				return;
			}
			
			Cookie = SharedObject.getLocal("flashgamesubmitter");
			
			// Load the security context
			Security.loadPolicyFile((UseSSL ? "https://" : "http://") + GUID + "."+ ServerId +".submityourgame.com"+"/crossdomain.xml");
			//Security.loadPolicyFile((UseSSL ? "https://" : "http://") + GUID + "."+ ServerId +".submityourgame.com"+"/crossdomain.xml?gid="+_gID+"&ver="+ApiVersion);
			
			// Check the URL is http / https
			if(WebRef.indexOf("http://") != 0 && WebRef.indexOf("https://") != 0) 
			{
				// Sandbox exceptions for testing
				if(Security.sandboxType != "localWithNetwork" && Security.sandboxType != "localTrusted" && Security.sandboxType != "remote")
				{
					FChannel.DebugLog("Sandboxtype isn't localWithNetwork or localTrusted or remote. FGSAPI will not run.");				
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
			//if (_EnableBanner) {
				FBanner.addEventListener("bannerStarted",BannerStarted)
				FBanner.addEventListener("bannerClosed",BannerClosed)
				FBanner.showBanner();				
			//}
			
			/*
			* Inits
			*/
			FChannel.Init();
			
			// Log Visit
			Visit();
					
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
				
		internal static function Visit():void
		{		
			if(!Enabled){
				FChannel.DebugLog(Debug_InitWarning)
				return;
			}
			
			var sendObj:Object = new Object();
			sendObj.action = "visit";
			sendObj.value = GetCookie("visit");
			sendObj.state = GetCookie("state");
			LogRequest.PushLog(sendObj);									
		}
		
		internal static function IncPlay():int
		{
			
			FChannel.DebugLog("play increased!");
			var play:int = GetCookie("play");
			play++;
			SaveCookie("play",play);
			return play;
		}
		
		/**
		 * FGS Show Banner. 
		 */		
		public static function ShowBanner():void 
		{
			if(!Enabled){
				FChannel.DebugLog(Debug_InitWarning)
				return;
			}
			FBanner.ReShowBanner();
		}
		
		/**
		 * FGS Close Banner. 
		 */		
		public static function CloseBanner():void 
		{
			if(!Enabled){
				FChannel.DebugLog(Debug_InitWarning)
				return;
			}
			FBanner.CloseBanner();
		}
		
		/**
		 * FGS Logger sends how many times 'PlayGame' is called. If you invoke 'PlayGame' many times, it increases 'PlayGame' counter and sends this counter value. 
		 */		
		public static function PlayGame():void 
		{
			
			FChannel.DebugLog("play clicked!");
			
			if(!Enabled){
				FChannel.DebugLog(Debug_InitWarning)
				
				FChannel.DebugLog("play game not available!");
				
				return;
			}		
			var sendObj:Object = new Object();
			sendObj.action = "play";
			sendObj.value = IncPlay();
			LogRequest.PushLog(sendObj);						
		}
		
		/**
		 * FGS Logger sends how many times 'CustomLog' that is called related to given by _key name. If you invoke 'CustomLog' many times, it increases 'CustomLog' counter and sends this counter value. 
		 */		
		public static function CustomLog(_key:String):void 
		{
			if(!Enabled){
				FChannel.DebugLog(Debug_InitWarning)
				return;
			}
			
			if (_key!="play" || _key!="visit") 
			{
				var customValue:int = GetCookie(_key);
				if (customValue==0) {					
					customValue = 1;
					SaveCookie(_key,customValue);
				} 
				
				var sendObj:Object = new Object();
				sendObj.action = "custom";
				sendObj.value = new Array({key:_key, value:customValue});
				LogRequest.PushLog(sendObj);						
			}
		}
		
		internal static function Ping():Object
		{
			var sendObj:Object = new Object();
			sendObj.action = "ping";
			sendObj.value = "ping";
			return sendObj;
		}
		
		/**
		 * Sets the API to use SSL-only for all communication
		 */
		public static function SetSSL():void
		{
			UseSSL = true;
			FChannel.DebugLog("Enabled SSL requests.");
		}
		
		/**
		 * Gets a cookie value
		 * @param	key		The key (views, plays)
		 */
		internal static function GetCookie(key:String):int
		{
			if(Cookie.data[key+"_"+gID] == undefined)
			{
				return 1;
			}
			else
			{
				return int(Cookie.data[key+"_"+gID]);
			}
		}
		
		/**
		 * Saves a cookie value
		 * @param	key		The key (views, plays)
		 * @param	value 	The value
		 */
		internal static function SaveCookie(key:String, value:*):void
		{
			Cookie.data[key+"_"+gID] = value.toString();
			
			try
			{
				Cookie.flush();
			}
			catch(s:Error)
			{
				
			}
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
				
		internal static function createText(_text:String,_width:int,_x:int,_y:int,_size:int):TextField
		{
			var myTextField:TextField = new TextField();  				
			
			//myTextField.text = _text;
			myTextField.htmlText = _text;
			myTextField.width = _width;  
			myTextField.x = _x;  
			myTextField.y = _y;  
			
			myTextField.selectable = false;  
			myTextField.border = false;  
			
			myTextField.autoSize = TextFieldAutoSize.LEFT;  
			myTextField.wordWrap = true;
			
			var myFormat:TextFormat = new TextFormat();  
			myFormat.color = 0xFFFFFF;   
			myFormat.size = _size;  
			myFormat.italic = false; 
			myFormat.font = "Verdana";
			myTextField.setTextFormat(myFormat);  							
			return myTextField;
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