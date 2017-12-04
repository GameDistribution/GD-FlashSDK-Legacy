package fgsapi
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.SecurityDomain;
	import flash.text.TextField;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	
	internal final class FBanner
	{
		private static var BannerServerURL:String = "bn.submityourgame.com";
		private static var StatsURL:String;
		private static var urlLoader:URLLoader = new URLLoader();
		private static var urlRequest:URLRequest = new URLRequest();
		private static const dispatcher:EventDispatcher = new EventDispatcher();		
		
		internal static var _bannerWidth:int=500;
		internal static var _bannerHeight:int=300;
		internal static var _bannerTop:int=0;
		internal static var _bannerLeft:int=0;
		internal static var _BannerTimeOut:int = 50;
		internal static var _bannerText:String = '';
		internal static var _bannerActive:Boolean = false;
		internal static var _bannerBGColor:String = '000000';		
		internal static var _bannerAutoSize:Boolean=false;
		internal static var _MidRoll:Boolean=false;
		internal static var _EnableBanner:Boolean=true;
		internal static var _HtmlBanner:Boolean=false;
		internal static var _MappedId:String = '';
		internal static var _AId:String = '';
		internal static var _UId:String = '';	
		internal static var _isJSInjected:Boolean=false;
		internal static var _CurrentFrameRate:Number = 0.0;		
		
		private static var blankScreen:MovieClip;
		private static var bannerTimer:Timer = new Timer(1000);
		private static var midRollTimer:Timer;
		private static var bannerIndex:int=0;
		private static var loader:Loader;
		private static var waitText:TextField;
		private static var bannerConfig:XML;
		private static var _bannerTopSpace:int=0;		
		private static var _bannerBottomSpace:int=0;
		private static var loaderBar:Shape;
		internal static var SitesCounter:int = 0;
		private static var _ShowBannerTimerText:Boolean=true;
		private static var minuteTimer:Timer;
		//private static var playBTN:playButton;
		private static var GoogleAds:*;
		
		internal static function showBanner():void {
			Security.allowDomain("*");
			Security.allowInsecureDomain("*");
				
			var referURL:String = FindRefer();
			
			if (referURL!="null") {
				
				StatsURL = (FGSLogger.UseSSL ? "https://" : "http://") + FGSLogger.ServerId +"." + BannerServerURL + "/" + FGSLogger.gID + ".xml?ver="+FGSLogger.ApiVersion+"&url="+referURL;
				
				urlLoader.addEventListener("ioError", Fail);
				urlLoader.addEventListener("networkError", Fail);
				urlLoader.addEventListener("verifyError", Fail);
				urlLoader.addEventListener("diskError", Fail);
				urlLoader.addEventListener("securityError", Fail);
				urlLoader.addEventListener("httpStatus", HTTPStatusIgnore);
				urlLoader.addEventListener("complete", Complete);
				
				urlRequest.contentType = "application/x-www-form-urlencoded";
				urlRequest.url = StatsURL;
				urlRequest.method = URLRequestMethod.POST;
				try {
					urlLoader.load(urlRequest);
				} catch (e:Error) {
					dispatchEvent(new Event("bannerClosed"));			
					FChannel.DebugLog("showBanner error: "+e.message);				
				}
			
			}
		}
		 
		private static function loadBanner(url:String):void {
			if (FGSLogger._EnableBanner) {
				var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain), (FGSLogger.isLocal?null:SecurityDomain.currentDomain)); // Use For Running
				//context.allowCodeImport = true;
				loader = new Loader();			
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
				loader.contentLoaderInfo.addEventListener(Event.UNLOAD, onUnloadLoader);
				loader.contentLoaderInfo.addEventListener(Event.INIT, initHandler);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
				loader.load(new URLRequest((FGSLogger.UseSSL ? "https://" : "http://") + url),context);
				_bannerActive = true;
			} else {
				_bannerActive = false;				
			}
		}
		
		protected static function onUnloadLoader(event:Event):void
		{			
			loader = null;
		}
				
		protected static function TimerComplete(event:TimerEvent):void
		{
			_bannerActive = false;
			FChannel.DebugLog("_root.stage.numChildren:"+FGSLogger._root.stage.numChildren);			
			try {
				loader.unloadAndStop(true);			
								
				if (blankScreen!=null) {
					FGSLogger._root.stage.removeChild(blankScreen);
					blankScreen = null;
				}
				FChannel.DebugLog("Removed : banner stage");							
				
			} catch (e:Error) {
				FChannel.DebugLog('Banner Error: '+e.message);					
			}
			FChannel.DebugLog("_root.stage.numChildren:"+FGSLogger._root.stage.numChildren);			
			FChannel.DebugLog("Banner removed.");
			dispatchEvent(new Event("bannerClosed"));;
			_MidRoll = false;			
		}
		
		protected static function TimerHandler(event:TimerEvent):void
		{
			FChannel.DebugLog("Banner time out: "+bannerTimer.currentCount.toString() );
		}
		
		private static function onLoaderComplete(event:Event):void {
			var loaderInfo:LoaderInfo = event.target as LoaderInfo;	
			FChannel.DebugLog("getQualifiedClassName: " + getQualifiedClassName( event.target.content ) );
			
			if (getQualifiedClassName( event.target.content ) == "GoogleAds") {
				GoogleAds=event.target.content;
				GoogleAds.contentId = FGSLogger.gID;
				if (_MappedId!="") {
					GoogleAds.mappedId = _MappedId;					
				}
				if (_AId!="") {
					GoogleAds.fg_aid = _AId;					
				}
				if (_UId!="") {
					GoogleAds.fg_uid = _UId;					
				}
				
				if (_bannerAutoSize) {			
					GoogleAds.bandBGLoading.x = 0;
					GoogleAds.bandBGLoading.y = _bannerTopSpace;	
					GoogleAds._bannerWidth=FGSLogger._root.stage.stageWidth-5;	
					GoogleAds._bannerHeight=FGSLogger._root.stage.stageHeight-_bannerTopSpace-_bannerBottomSpace;	
				} else {
					GoogleAds.bandBGLoading.x = _bannerLeft;
					GoogleAds.bandBGLoading.y = _bannerTop;	
					GoogleAds._bannerWidth=_bannerWidth;	
					GoogleAds._bannerHeight=_bannerHeight;					
				}
				
				
				GoogleAds.addEventListener("onAFGClosed",onAFGClosed);			
				GoogleAds.addEventListener("onAFGShowed",onAFGShowed);	
				GoogleAds.addEventListener("onAFGManagerLoaded",onAFGManagerLoaded);					
				_ShowBannerTimerText = false;
			} else {
				_ShowBannerTimerText = true;				
			}
			
			drawBackground(loaderInfo.content);	
			blankScreen.addChildAt(GoogleAds.bandBGLoading,blankScreen.numChildren-1);
			
		}

		private static function onAFGManagerLoaded(e:Event):void
		{
			FChannel.DebugLog("AFG Time: ",GoogleAds._remainingTime);
			e.target.removeEventListener("onAFGManagerLoaded",onAFGManagerLoaded);

			blankScreen.visible = true;			
		}
				
		private static function onAFGShowed(e:Event):void
		{			
			FChannel.DebugLog("AFG Showed");					
			e.target.removeEventListener("onAFGShowed",onAFGShowed);
		}
		
		private static function onAFGClosed(e:Event):void
		{			
			e.currentTarget.removeEventListener("onAFGClosed",onAFGClosed);
			CloseBanner();
			FChannel.DebugLog("AFG Closed");
		}
		
		private static function initHandler(event:Event):void {
			var loader:Loader = Loader(event.target.loader);
			var info:LoaderInfo = LoaderInfo(loader.contentLoaderInfo);
			FChannel.DebugLog("Banner initHandler: loaderURL=" + info.loaderURL + " url=" + info.url);
		}
		
		private static function ioErrorHandler(event:IOErrorEvent):void {
			FChannel.DebugLog("Banner ioErrorHandler: " + event);
			_bannerActive = false;
			dispatchEvent(new Event("bannerClosed"));			
		}				
		
		private static function drawBackground(banner:DisplayObject):void {
			
			FChannel.DebugLog("Drawing banner background.");		
			
			Mouse.show();
			
			blankScreen = new MovieClip();
			blankScreen.opaqueBackground = uint("0x"+_bannerBGColor);
			blankScreen.alpha = 1;			
			blankScreen.visible = false;			
			
			var rectangle:Shape = new Shape; // initializing the variable named rectangle
			rectangle.graphics.beginFill(uint("0x"+_bannerBGColor)); 
			rectangle.graphics.drawRect(0, 0, FGSLogger._root.stage.stageWidth,FGSLogger._root.stage.stageHeight); // (x spacing, y spacing, width, height)
			rectangle.graphics.endFill();				
			blankScreen.addChild(rectangle);
			
			FGSLogger._root.addEventListener(Event.RESIZE, function(e:Event):void{
				rectangle.graphics.drawRect(0, 0, FGSLogger._root.stage.stageWidth,FGSLogger._root.stage.stageHeight); 				
			});
			
			bannerIndex=FGSLogger._root.stage.numChildren;
			
			try {
				_bannerLeft = (FGSLogger._root.stage.stageWidth-_bannerWidth)/2;
				_bannerTop = (FGSLogger._root.stage.stageHeight-_bannerHeight-_bannerTopSpace-_bannerBottomSpace)/2;
				
				if (_bannerAutoSize) {			
					banner.x = 2;
					banner.y = _bannerTopSpace;
					banner.width = FGSLogger._root.stage.stageWidth-5;
					banner.height = FGSLogger._root.stage.stageHeight-_bannerTopSpace-_bannerBottomSpace;				
				} else {
					banner.x = _bannerLeft;
					banner.y = _bannerTop+_bannerTopSpace;
					banner.width = _bannerWidth;
					banner.height = _bannerHeight;				
				}				
				
				blankScreen.addChild(banner);
			} catch (e:Error) {
				
			}
			
			
			
			bannerTimer.repeatCount = _BannerTimeOut;
			bannerTimer.addEventListener(TimerEvent.TIMER, TimerHandler);
			bannerTimer.addEventListener(TimerEvent.TIMER_COMPLETE, TimerComplete);
			bannerTimer.reset();
			bannerTimer.start();						
			
			// Add SkipButton into Player Canvas
			/*
			playBTN = new playButton();
			playBTN.x=10;
			playBTN.y=FGSLogger._root.stage.stageHeight-playBTN.height-10;						
			playBTN.playBG.x+=3;
			playBTN.visible=true;
			blankScreen.addChild(playBTN);
			
			var minuteTimer:Timer = new Timer(1000,10); 
			minuteTimer.addEventListener(TimerEvent.TIMER, function(event:TimerEvent):void  
			{ 
				playBTN.playBG.x += int(playBTN.playBG.width/(event.target as Timer).repeatCount);
				//playBTN.playBTNLayer.playTitle.text = 'Play'+((event.target as Timer).repeatCount-(event.target as Timer).currentCount)+')';
			}); 
			minuteTimer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void {
				playBTN.playBG.x = 0;
				playBTN.addEventListener(MouseEvent.CLICK, function():void {
					trace("PlayButton Clicked");
					if (GoogleAds!=null && GoogleAds.destroy!=null) {
						GoogleAds.destroy();
					}
					CloseBanner();
				});			
			}); 
			
			// starts the timer ticking 
			minuteTimer.start();
			*/
			
			FGSLogger._root.stage.addChild(blankScreen);			
		}				

		private static function Complete(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			FChannel.DebugLog('Response: '+request.data);
			
			XML.ignoreWhitespace = true; 
			bannerConfig = new XML(request.data);
			
			var showAfterTime:int = 0;
			if (bannerConfig!=null && String(bannerConfig.cfg.f)!="false" && String(bannerConfig.row[0])!=null && String(bannerConfig.row[0].sat)!=null) {
				showAfterTime=int(bannerConfig.row[0].sat);
				if (showAfterTime>0) {
					midRollTimer = new Timer(showAfterTime*60000);
					midRollTimer.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void {
						_MidRoll=true;		
						ReShowBanner();
						FChannel.DebugLog("Midroll Banner State: "+_MidRoll);
					});
					midRollTimer.start();
				} else {
					_MidRoll=false;
					FChannel.DebugLog("Midroll Banner State: "+_MidRoll);
				}
			}
			
			ReShowBanner(true);	
		}	
				
		internal static function ShowTestBanner():void {
			FChannel.DebugLog("Trying to show test banner...");
			dispatchEvent(new Event("bannerStarted"));
			if (loader) loader.unloadAndStop(true);
			_bannerWidth=300;
			_bannerHeight=250;
			_bannerAutoSize=false;
			loadBanner("www.gamedistribution.com/swf/testbanner.swf");
		}		
		
		internal static function ReShowBanner(isPreRoll:Boolean=false):void {
			try {
				dispatchEvent(new Event("bannerStarted"));
				// To prevent second time showing banner
				if (!_bannerActive) {
					if (String(bannerConfig.cfg.f)=='false') {			
						dispatchEvent(new Event("bannerClosed"));				
					} else {				
						// Read Banner Config from XML
						if ( (isPreRoll && String(bannerConfig.row[0].pre)=='1') || _MidRoll) {
							//_MidRoll = false;
							FChannel.DebugLog("Midroll Banner State: "+_MidRoll);
							_bannerText = String(bannerConfig.row[0].bgt);
							_bannerBGColor = String(bannerConfig.row[0].bgc);
							_bannerWidth = int(bannerConfig.row[0].wid);
							_bannerHeight = int(bannerConfig.row[0].hei);
							_BannerTimeOut = int(bannerConfig.row[0].tim);
							_bannerAutoSize = (bannerConfig.row[0].aut=='1');
							_EnableBanner = (bannerConfig.row[0].act=='1');						
							_HtmlBanner = (bannerConfig.row[0].htmlbanner=='1');						
							_MappedId = String(bannerConfig.row[0].mappedid);						
							_AId = String(bannerConfig.row[0].aid);						
							_UId = String(bannerConfig.row[0].uid);						
							
							if (_EnableBanner && bannerConfig.row[1]) {
								for (SitesCounter=0; SitesCounter < bannerConfig.row[1].b.length(); SitesCounter++) {
									if (parseDomain(FGSLogger.WebRef)==String(bannerConfig.row[1].b[SitesCounter])) {
										_EnableBanner = false;
									}
								}						
							}						
							if (!_EnableBanner) {
								dispatchEvent(new Event("bannerClosed"));				
							}

							if (_HtmlBanner && jsInjectGD()) {				
								FChannel.RegisterJSCallBackFunction("jsGDO",jsGDO);
								FChannel.RegisterJSCallBackFunction("jsPauseGame",jsPauseGame);
								FChannel.RegisterJSCallBackFunction("jsResumeGame",jsResumeGame);				
								FChannel.RegisterJSCallBackFunction("jsOnAdsStarted",jsOnAdsStarted);				
								FChannel.RegisterJSCallBackFunction("jsOnAdsClosed",jsOnAdsClosed);				
								FChannel.RegisterJSCallBackFunction("jsOnAdsError",jsOnAdsError);				
								FChannel.RegisterJSCallBackFunction("jsOnAdsReady",jsOnAdsReady);				
								if (_MidRoll) {
									FChannel.CallJSFunction("jsShowBanner");				
								}								
							} else {
								// Load Banner and Show							
								loadBanner(String(bannerConfig.row[0].url));								
							}
							
						} else {
							dispatchEvent(new Event("bannerClosed"));				
							FChannel.DebugLog("Midroll Banner State: "+_MidRoll);							
						}
					}			
				} else {
					dispatchEvent(new Event("bannerClosed"));				
				}
			} catch (e:Error) {
				_bannerActive = false;
				dispatchEvent(new Event("bannerClosed"));				
				FChannel.DebugLog("Banner XML error: "+e.message);
			}
		}
		
		public static function jsPauseGame():String {
			try {
				_CurrentFrameRate = FGSLogger._root.stage.frameRate;
				FGSLogger._root.stage.frameRate=0.01;
				SoundMixer.soundTransform = new SoundTransform(0);
			} catch (e:Error) {
				FChannel.DebugLog("jsPauseGame: "+e.getStackTrace());				
			}
			return "{frameRate:\""+FGSLogger._root.stage.frameRate+"\"}";			
		}
		
		public static function jsResumeGame():String {
			FGSLogger._root.stage.frameRate=_CurrentFrameRate;
			SoundMixer.soundTransform = new SoundTransform(1);
			return "{frameRate:\""+FGSLogger._root.stage.frameRate+"\"}";			
		}
		
		public static function jsOnAdsStarted():void {
			//dispatchEvent(new Event(GDEvent.BANNER_STARTED));
		}
		
		public static function jsOnAdsClosed():void {
			dispatchEvent(new Event("bannerClosed"));
		}
		
		public static function jsOnAdsError():void {
			dispatchEvent(new Event("bannerClosed"));
		}
		
		public static function jsOnAdsReady():void {
			if (_EnableBanner) {
				FChannel.CallJSFunction("jsShowBanner");
			}
		}
		
		public static function jsGDO():String {
			return "{GDApi:\""+FGSLogger.ApiVersion+"\",GUID:\""+FGSLogger.GUID+"\",GID:\""+FGSLogger.gID+"\"}";
		}
		
		internal static function jsInjectGD():Boolean {
			//return false;
			
			if(ExternalInterface.available)
			{
				try
				{
					var script_js:XML =						
						<script>
						<![CDATA[
							(function()
							{
								(function(i,s,o,g,r,a,m)
									{
										i['FamobiGameObject']=r;
										i[r]=i[r]||function(){(i[r].q=i[r].q||[]).push(arguments)};
										i[r].l=1*new Date();
										a=s.createElement(o);
										m=s.getElementsByTagName(o)[0];
										a.async=1;
										a.src=g;
										m.parentNode.insertBefore(a,m);
									})(window,document,'script','http://vcheck.submityourgame.com/js/fgo.min.js','fgo');
								fgo("]]>{FGSLogger.GUID}<![CDATA[","]]>{FGSLogger.gID}<![CDATA[","]]>{_AId}<![CDATA[");
							})
						]]>						
						</script>;						
					ExternalInterface.call(script_js);
					_isJSInjected = true;
					FChannel.DebugLog('jsInjectGD: true');
					return true;
				}
				catch(s:Error)
				{
					FChannel.DebugLog('jsInjectGD: false');
					return false;
				}
			}	
			
			return false;
		}	
		
		internal static function CloseBanner():void {
			bannerTimer.stop();
			TimerComplete(null);
		}		
		
		private static function Fail(e:Event):void
		{
			var request:URLLoader = e.target as URLLoader;
			FChannel.DebugLog('Fail: '+e+' : '+request.data);
			dispatchEvent(new Event("bannerClosed"));			
		}
		
		private static function HTTPStatusIgnore(e:Event):void
		{
		}	
		
		private static function parseDomain(WebRef:String):String {
			var WebArray:Array = WebRef.replace('http://','').split('/');
			return WebArray[0];			
		}	
		
		internal static function FindRefer():String {
			if(ExternalInterface.available)
			{
				try
				{
					return (String(ExternalInterface.call("window.location.href.toString")));
				}
				catch(s:Error)
				{
					return "null";
				}
			}	
			
			return "null";
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