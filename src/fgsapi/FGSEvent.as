package fgsapi
{
	import flash.events.Event;
	
	public final class FGSEvent extends Event
	{
		public static const ISALLOWED_LINKS: String = "isAllowedLinks";		
		public static const ISRUNNING_LOCAL: String = "isRunningLocal";		
		public static const ISBANNER_CLOSED: String = "isBannerClosed";		
		public static const ISBANNER_STARTED: String = "isBannerStarted";		
		public var data: Object;
		
		public function FGSEvent(type:String, data: Object, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}
		override public function clone():Event
		{
			return new FGSEvent (type, data, bubbles, cancelable);
		}
	}
}
