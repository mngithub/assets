package  {
	
	import flash.display.MovieClip;
	import fl.video.VideoPlayer;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.AsyncErrorEvent;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	
	public class stream extends MovieClip {
		
		var ns:NetStream;
		var nc:NetConnection;
		var vdo:VideoPlayer;
		
		public function stream() {
			// constructor code
			vdo = new VideoPlayer()
			this.addChild(vdo);
			
			nc = new NetConnection();
			nc.connect("rtmp://edge2.psitv.tv/liveedge/");
			nc.addEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus);
			
			
			
			//runSWF();
		}
		
		private function onConnectionStatus(e:NetStatusEvent):void
		{
			if (e.info.code == "NetConnection.Connect.Success")
			{
				ns = new NetStream(nc);
				ns.addEventListener(AsyncErrorEvent.ASYNC_ERROR, function onError(e:Event) : void  {
										//trace("error")
									});
									
									
				vdo.attachNetStream(ns);
				vdo.width = 1280;
				vdo.height = 720;
				
				//ns.play("rtmp://live3.netdesignhost.com/oishibandbattlelive/oishibandbattlelive");
				//ns.play("C:/Users/Terdthai/Downloads/SampleVideo_1080x720_1mb.mp4");
				//stopSWF();
				
				//ns.play("rtmp://live3.netdesignhost.com/omdlive/omdlive");
				ns.play("mp4:292277314577_600");
			}else{
				nc.close();
			}
		}		
		public function runSWF() {
			try
			{
				ns.resume();
			} catch (e:Error) {}
		}
		
		public function stopSWF() {
			try
			{
				ns.pause();
			} catch (e:Error) {}
		}
	}
	
}
