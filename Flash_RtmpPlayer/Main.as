package  {

import flash.display.*; 
import flash.events.*;
import flash.net.*;
import flash.media.*;
import flash.system.*;
import flash.utils.ByteArray;
import flash.utils.setTimeout;
import flash.utils.setInterval;
import flash.utils.clearInterval;

public class Main extends MovieClip 
{
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	
	public static var RTMP_STREAM_ID:String 		= "mp4:292277314577_600";
	public static var RTMP_URL:String				= "rtmp://edge2.psitv.tv/liveedge/";
	public static var INTERVAL_HEARTBEAT:Number		= 30;
	public static var BUFFER:Number					= 10;
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	// --------------------------------------------------------------
	
	public var isPingFailed:Boolean;
	public var heartbeat:NetConnection;	
	
    public var netStreamObj:NetStream;
    public var nc:NetConnection;
    public var vid:Video;

    public var metaListener:Object;
	
	public function Main () { init(); }

	function init():void
	{

			try{
				stage.scaleMode = StageScaleMode.EXACT_FIT; 
				stage.displayState = StageDisplayState.FULL_SCREEN;
				stage.align = StageAlign.TOP_LEFT;
			
			}catch(err:Error){}	
			stage.addEventListener(Event.RESIZE, _onStageResize, false, 0, true);		
		
			var loaderLocal:URLLoader = new URLLoader();
			loaderLocal.addEventListener(Event.COMPLETE, function(e:Event) {
				
				// อ่านค่า config.xml เรียบร้อยแล้ว
				var localXML:XML = new XML(e.target.data);
				
				trace("--------------------------------");
				trace("LOADED - config-local");
				trace("--------------------------------");
				trace("");
				
				var config:XML = localXML;
				if(config.rtmp_streamid.length() < 1 
				   	|| config.rtmp_url.length() < 1 
					|| config.buffer.length() < 1
					|| config.heartbeat.length() < 1
				){
					//failedOnLoadConfig("config-local");
					return;
				}
				Main.RTMP_STREAM_ID 	= config.rtmp_streamid;
				Main.RTMP_URL 			= config.rtmp_url;
				Main.BUFFER 			= parse(config.buffer);
				Main.INTERVAL_HEARTBEAT = parse(config.heartbeat);
				startProgram();
			});
			loaderLocal.addEventListener(IOErrorEvent.IO_ERROR, function(e:Event) {
										   
				// อ่านค่า config.xml ไม่สำเร็จ (ปิดโปรแกรม)
				var localXML:XML = new XML(e.target.data);
				trace("--------------------------------");
				trace("FAILED - config-local");
				trace("--------------------------------");
				trace("");
				//failedOnLoadConfig("config-local");
				
				
			});
			// load local config
			loaderLocal.load(new URLRequest("./config.xml"));
			
	}
	
	private function startProgram():void{
			
		vid = new Video(); //typo! was "vid = new video();"
		resizeVideo();
		
		nc = new NetConnection();
		nc.addEventListener(NetStatusEvent.NET_STATUS, onConnectionStatus);
		nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, asyncErrorHandler);
		nc.client = { onBWDone: function():void{} };
		nc.connect(RTMP_URL);   
		
		
		heartbeat = new NetConnection();
		heartbeat.addEventListener(NetStatusEvent.NET_STATUS, function(e:NetStatusEvent){
			
			//trace('heartbeat', e.info.code);
			if(isPingFailed){
				trace("RELOAD !!!");
				// reload
				vid.clear();
				nc.close();
				nc.connect(RTMP_URL);
			}
			
			heartbeat.close();
			if (e.info.code == "NetConnection.Connect.Closed") return;
			if (e.info.code == "NetConnection.Connect.Success") return;
			
			isPingFailed = true;
			
			
		});
		setInterval(function(){ 
			trace("HEARTBEAT");
			heartbeat.connect(RTMP_URL); 
		}, INTERVAL_HEARTBEAT * 1000);
		
		
		addChild(vid);
	}

	private function _onStageResize(event:Event):void
	{
		//trace(stage.stageWidth, stage.stageHeight);
		if(stage.displayState == StageDisplayState.FULL_SCREEN)
		{
			// Proportionally resize your video to the stage's new dimensions
			// i.e. set its height and width such that the aspect ratio is not distorted
		}
		else
		{
			// Restore the normal layout of your elements
		}
		
		resizeVideo();
	}

	private function resizeVideo():void{
		vid.x = 0;
		vid.y = 0;
		vid.width = stage.stageWidth;
		vid.height = stage.stageHeight;
	}

	private function onConnectionStatus(e:NetStatusEvent):void
	{
		//trace(e.info.code);	
		if (e.info.code == "NetConnection.Connect.Success")
		{	
			isPingFailed = false;
			trace("Creating NetStream");
			loadVideo();
		}
	}

	private function loadVideo():void{
			
			if(netStreamObj != null){
				netStreamObj.close();
			}
			netStreamObj = new NetStream(nc);

			metaListener = new Object();
			metaListener.onMetaData = received_Meta;
			netStreamObj.client = metaListener;
			netStreamObj.bufferTime = BUFFER;
		
			netStreamObj.play(RTMP_STREAM_ID);
			vid.clear();
			vid.attachNetStream(netStreamObj);
			vid.smoothing = true;
			
			setTimeout(function(){ resizeVideo(); }, 1000);
	}

	private function playback():void
	{ 
	  //trace((++counter) + " Buffer length: " + netStreamObj.bufferLength); 
	}

	public function asyncErrorHandler(event:AsyncErrorEvent):void 
	{ trace("asyncErrorHandler.." + "\r"); }

	public function onFCSubscribe(info:Object):void
	{ trace("onFCSubscribe - succesful"); }

	public function onBWDone(...rest):void
	{ 
		var p_bw:Number; 
		if (rest.length > 0)
		  { p_bw = rest[0]; }
		trace("bandwidth = " + p_bw + " Kbps."); 
	}

	function received_Meta (data:Object):void
	{
		var _stageW:int = stage.stageWidth;
		var _stageH:int = stage.stageHeight;

		var _videoW:int;
		var _videoH:int;
		var _aspectH:int; 

		var Aspect_num:Number; //should be an "int" but that gives blank picture with sound
		Aspect_num = data.width / data.height;

		//Aspect ratio calculated here..
		_videoW = _stageW;
		_videoH = _videoW / Aspect_num;
		_aspectH = (_stageH - _videoH) / 2;

		vid.x = 0;
		vid.y = _aspectH;
		vid.width = _videoW;
		vid.height = _videoH;
	}
	
	public static function parse(str:String):Number{
		for(var i = 0; i < str.length; i++){
			var c:String = str.charAt(i);
			if(c != "0") break;
		}
		return Number(str.substr(i));
	}

} //end class

} //end package