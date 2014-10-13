package manager
{
	import event.AllEvent;
	
	import face2wind.event.ParamEvent;
	import face2wind.loading.RuntimeResourceManager;
	import face2wind.manager.EventManager;

	/**
	 * 基础配置管理器
	 * @author face2wind
	 */
	public class ConfigManager
	{
		public function ConfigManager()
		{
			if(instance)
				throw new Error("ConfigManager is singleton class and allready exists!");
			instance = this;
		}
		
		/**
		 * 单例
		 */
		private static var instance:ConfigManager;
		/**
		 * 获取单例
		 */
		public static function getInstance():ConfigManager
		{
			if(!instance)
				instance = new ConfigManager();
			
			return instance;
		}
		
		/**
		 * 加载器 
		 */		
		private var rloader:RuntimeResourceManager = RuntimeResourceManager.getInstance();
		
		/**
		 * 统一事件派发器 
		 */		
		private var dispecher:EventManager = EventManager.getInstance();
		
		/**
		 * 基础配置路径 
		 */		
		private static var configXmlPath:String = "config.xml";
		
		private var _configXml:XML = null;
		/**
		 * 基础配置原始数据 
		 */
		public function get configXml():XML
		{
			return _configXml;
		}

		
		/**
		 * 加载完毕后要执行的函数 
		 */		
		private var onCompleteFunc:Function;
		
		/**
		 *  协议文档存放目录
		 */		
		public var protoDocPath:String;
		
		/**
		 * 开始加载配置 
		 * @param completeFunc
		 */		
		public function loadConfig(completeFunc:Function = null):void
		{
			dispecher.dispatchToView(new ParamEvent(AllEvent.SHOW_ALERT_TIPS, {text:"基础配置加载中....."}) );
			onCompleteFunc = completeFunc;
			rloader.load(configXmlPath, true, onLoadXmlCompleteHandler);
		}
		
		/**
		 * 配置加载完毕 
		 * @param url
		 */		
		private function onLoadXmlCompleteHandler(url:String):void
		{
			if(url == configXmlPath)
			{
				_configXml = new XML(rloader.useResource(configXmlPath));
				protoDocPath = _configXml.protoPath;
				dispecher.dispatchToView(new ParamEvent(AllEvent.SHOW_ALERT_TIPS, {text:"基础配置加载完毕！"}) );
				if(null != onCompleteFunc)
				{
					var tmpFunc:Function = onCompleteFunc; // 做个替换，防止死循环
					onCompleteFunc = null;
					tmpFunc.apply();
				}
			}
		}
	}
}