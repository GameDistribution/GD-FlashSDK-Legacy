package fgsapi
{

	import flash.external.ExternalInterface;
	
		
	internal final class FUtils
	{
	
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