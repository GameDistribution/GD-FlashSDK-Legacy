package fgsapi
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.external.ExternalInterface;
		
	internal final class FBanner
	{
		private static const dispatcher:EventDispatcher = new EventDispatcher();		
		
		internal static var _AId:String = '';
		internal static var _UId:String = '';	
		internal static var _isJSInjected:Boolean=false;


		public static function init():void {
			FUtils.RegisterJSCallBackFunction("jsGDO",jsGDO);			
			FUtils.RegisterJSCallBackFunction("jsOnAdsStarted",jsOnAdsStarted);				
			FUtils.RegisterJSCallBackFunction("jsOnAdsClosed",jsOnAdsClosed);				
			FUtils.RegisterJSCallBackFunction("jsOnAdsError",jsOnAdsError);		
			FUtils.RegisterJSCallBackFunction("jsOnAdsLoaded",jsOnAdsLoaded);				
			jsInjectGD();		
			
		}	
		
		public static function ShowAd():void {
			FUtils.CallJSFunction("jsShowBanner");
		}
		
		public static function jsOnAdsStarted():void {
			dispatchEvent(new Event("bannerStarted"));
		}
		
		public static function jsOnAdsClosed():void {
			dispatchEvent(new Event("bannerClosed"));
		}
		
		public static function jsOnAdsError():void {
			dispatchEvent(new Event("bannerClosed"));
		}
		
		public static function jsOnAdsLoaded():void {
			//dispatchEvent(new Event("bannerClosed"));
		}
		
		public static function jsGDO():String {
			return "{GDApi:\""+FGSLogger.ApiVersion+"\",GUID:\""+FGSLogger.GUID+"\",GID:\""+FGSLogger.gID+"\"}";
		}
		
		public static function jsInjectGD():Boolean {
			//return false;		
			if(ExternalInterface.available)
			{
				var today:Date = new Date();		
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
									})(window,document,'script','//flash.api.gamedistribution.com/fgo.min.js','fgo');

									fgo("]]>{FGSLogger.gID}<![CDATA[","]]>{FGSLogger.GUID}<![CDATA[");
							})
						]]>						
						</script>;						
					ExternalInterface.call(script_js);
					_isJSInjected = true;
					FUtils.DebugLog('jsInjectGD: true');
					return true;
				}
				catch(s:Error)
				{
					FUtils.DebugLog('jsInjectGD: false');
					return false;
				}
			}	
			
			return false;
		}	
		
		internal static function CloseBanner():void {
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