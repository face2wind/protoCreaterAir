package manager
{
	import event.AllEvent;
	
	import face2wind.event.ParamEvent;
	import face2wind.lib.ObjectPool;
	import face2wind.loading.RuntimeResourceManager;
	import face2wind.manager.EventManager;
	import face2wind.net.item.SocketDataType;
	
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayCollection;
	
	import vo.PropertyVo;
	import vo.ProtocalClassVo;
	import vo.ProtocalListVo;
	import vo.ProtocalVo;

	/**
	 * 协议文档加载器
	 * @author face2wind
	 */
	public class ProtoDataManager
	{
		public function ProtoDataManager()
		{
			if(instance)
				throw new Error("ProtoLoader is singleton class and allready exists!");
			instance = this;
			
			macroDic = new Dictionary();
			protocolDic = new Dictionary();
			protocolClassVoDic = new Dictionary();
		}
		
		/**
		 * 单例
		 */
		private static var instance:ProtoDataManager;
		/**
		 * 获取单例
		 */
		public static function getInstance():ProtoDataManager
		{
			if(!instance)
				instance = new ProtoDataManager();
			
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
		 * 协议目录里的文件名列表（不包括后缀，默认是xml） 
		 */		
		public var protoFileNameList:ArrayCollection;
		
		/**
		 * 所有宏的自定义类对象数据（解析之后的） 
		 */		
		private var macroDic:Dictionary;
		
		/**
		 * 所有自定义类对象数据 （解析之后的）
		 */		
		private var protocolClassVoDic:Dictionary;
		
		/**
		 * 所有协议数据 （解析之后的）
		 */		
		private var protocolDic:Dictionary;
		
		/**
		 * 重新查找所有协议配置列表 
		 */		
		public function refreshXmlFileList():void
		{
			var f:File = File.documentsDirectory.resolvePath(ConfigManager.getInstance().protoDocPath);
			var fileList:Array = f.getDirectoryListing();
			protoFileNameList = new ArrayCollection();
			for (var i:int = 0; i < fileList.length; i++) 
			{
				var subFile:File = fileList[i] as File;
				if(".xml" != subFile.type)
					continue;
				if("macro.xml" == subFile.name) // 宏文件不做协议解析
					continue;
				var tmpName:String = subFile.name.substr(0, subFile.name.lastIndexOf("."));
				protoFileNameList.addItem(tmpName);
			}
			dispecher.dispatchToModel(new ParamEvent(AllEvent.PROTO_LIST_UPDATE));
		}
		
		/**
		 * 获取所有宏对应的类数据列表 
		 * @return 
		 */		
		public function getAllMacroClassList():Array
		{
			var macroList:Array = [];
			for each ( var vo:* in macroDic)
				macroList.push(vo);
			return macroList;
		}
		
		/**
		 * 获取对应协议大类数据对象 
		 * @param protoListID 大类ID
		 * @return 
		 */		
		public function getProtocolList(protoListID:String):ProtocalListVo
		{
			return protocolDic[protoListID];
		}
		
		/**
		 * 根据类名获取对应的类，用于获取协议中嵌套的子类或嵌套宏类
		 * @param className 类型名（除基础类型外的其他类型都在这里找）
		 */		
		public function getProtoClassVo(className:String):ProtocalClassVo
		{
			var cVo:ProtocalClassVo = macroDic[className];
			if(null == cVo)
				cVo = protocolClassVoDic[className];
			return cVo;
		}
		
		/**
		 * 全部配置加载完毕要执行的函数 
		 */		
		private var loadAllComplete:Function = null;
		/**
		 * 加载所有协议文档时用的临时数组 
		 */		
		private var loadTmpFileList:Array;
		
		/**
		 *  加载所有的配置
		 * @param completeFunc 加载完成后执行的函数
		 */		
		public function loadAllConfig(completeFunc:Function = null):void
		{
			loadAllComplete = completeFunc;
			// 先加载宏
			var path:String = ConfigManager.getInstance().protoDocPath + "/macro.xml";
			rloader.load(path,true, onLoadMacroComplete, null, true, 1, true); // 每次强制加载最新的
		}
		
		/**
		 * 单个协议文档加载完毕要执行的函数 
		 */		
		private var loadOneComplete:Function = null;
		/**
		 * 加载单个配置协议文件名 （不包含xml后缀）
		 */		
		private var loadOneProtocalName:String = null;
		/**
		 * 加载单个配置 
		 * @param protoName 协议文件名（不包含xml后缀）
		 * @param completeFunc 加载完成后执行的函数
		 * 
		 */			
		public function loadOneConfig(protoName:String, completeFunc:Function = null):void
		{
			loadOneComplete = completeFunc;
			loadOneProtocalName = protoName;
			// 先加载宏
			var path:String = ConfigManager.getInstance().protoDocPath + "/macro.xml";
			rloader.load(path,true, onLoadMacroComplete, null, true, 1, true); // 每次强制加载最新的
		}
		
		/**
		 * 宏加载完毕，开始加载所有配置 
		 */		
		private function onLoadMacroComplete(url:String):void
		{
			var xmlData:XML = new XML(rloader.useResource(url));
			analyzeMacro(xmlData);

			var path:String;
			if(null != loadOneProtocalName) // 这个值不为空，则表示当前只加载并解析一个协议
			{
				path = ConfigManager.getInstance().protoDocPath + "/" + loadOneProtocalName + ".xml";
				rloader.load(path,true, onRLoadFileCompleteHandler, null, true, 1, true); // 每次强制加载最新的
			}
			else
			{
				loadTmpFileList = protoFileNameList.source.concat();
				for (var i:int = 0; i < loadTmpFileList.length; i++) 
				{
					path = ConfigManager.getInstance().protoDocPath + "/" + loadTmpFileList[i] + ".xml";
					rloader.load(path,true, onRLoadFileCompleteHandler, null, true, 1, true); // 每次强制加载最新的
				}
			}
		}
		
		/**
		 * 加载所有协议文档 - 每一个加载完毕后的响应函数 
		 * @param url
		 */		
		private function onRLoadFileCompleteHandler(url:String):void
		{
			var xmlData:XML = new XML(rloader.useResource(url));
			analyzeProtocolList(xmlData);
			
			var tmpFunc:Function;
			if(null != loadOneComplete) // 当前是加载单个协议 ===================================
			{
				dispecher.dispatchToView(new ParamEvent(AllEvent.SHOW_ALERT_TIPS, {text:"解析进度：100%\n协议（"+loadOneProtocalName+"）解析完毕"}) );
				loadOneProtocalName = null;
				tmpFunc = loadOneComplete;
				loadOneComplete = null;
				tmpFunc.apply();
			}
			if(null != loadAllComplete) // 当前是加载所有协议 ===================================
			{
				var fileName:String = url.substring(url.lastIndexOf("/")+1, url.lastIndexOf("."));
				var fIndex:int = loadTmpFileList.indexOf(fileName);
				if(-1 != fIndex)
					loadTmpFileList.splice(fIndex,1);
				var rate:Number = (protoFileNameList.length - loadTmpFileList.length)/protoFileNameList.length;
				rate = rate*100;
				dispecher.dispatchToView(new ParamEvent(AllEvent.SHOW_ALERT_TIPS, {text:"解析进度："+rate.toFixed(2)+"%\n协议（"+fileName+"）解析完毕"}) );
				if(0 == loadTmpFileList.length) // 所有xml加载完毕
				{
					tmpFunc = loadAllComplete;
					loadAllComplete = null;
					tmpFunc.apply();
				}
			}
		}
		
		/**
		 * 解析宏数据 
		 * @param xmlData
		 */		
		private function analyzeMacro(xmlData:XML):void
		{
			var macroList:XMLList = xmlData.macro;
			for (var i:int = 0; i < macroList.length(); i++) 
			{
				var macroXml:XML = macroList[i] as XML;
				var macroPList:XMLList = macroXml.property;
				var macroClassVo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
				macroClassVo.className = macroXml.@name;
				macroClassVo.classDesc = macroXml.@desc;
				ObjectPool.disposeObject(macroClassVo.propertyList);
				macroClassVo.propertyList = [];
				for (var j:int = 0; j < macroPList.length(); j++) 
					macroClassVo.propertyList.push( analyzeProperty( macroPList[j], macroClassVo.className, macroClassVo.classDesc) );
				macroDic[macroClassVo.className] = macroClassVo;
			}
		}
		
		/**
		 * 解析协议列表数据 
		 * @param xmlData
		 */		
		private function analyzeProtocolList(xmlData:XML):void
		{
			var pListVo:ProtocalListVo = ObjectPool.getObject(ProtocalListVo);
			pListVo.protoListId = xmlData.protoList.@id;
			pListVo.protocolListDesc = xmlData.protoList.@desc;
			
			ObjectPool.disposeObject(pListVo.protocolVoList);
			pListVo.protocolVoList = [];
			var pList:XMLList = xmlData.proto as XMLList;
			for (var i:int = 0; i < pList.length(); i++) 
				pListVo.protocolVoList.push( analyzeProtocol(pList[i]) );
			protocolDic[pListVo.protoListId] = pListVo;
		}
		
		/**
		 * 解析协议数据 
		 * @param xmlData
		 */		
		private function analyzeProtocol(xmlData:XML):ProtocalVo
		{
			var protoVo:ProtocalVo = ObjectPool.getObject(ProtocalVo);
			protoVo.protoId = xmlData.@id;
			protoVo.protoDesc = xmlData.@desc;
			
			ObjectPool.disposeObject(protoVo.c2sProtoVo);
			protoVo.c2sProtoVo = ObjectPool.getObject(ProtocalClassVo);
			protoVo.c2sProtoVo.className = "CS"+protoVo.protoId;
			protoVo.c2sProtoVo.classDesc = protoVo.protoDesc;
			protoVo.c2sProtoVo.propertyList = [];
			var i:int;
			var c2sPropertyList:XMLList = xmlData.c2s[0].property;
			for (i = 0; i < c2sPropertyList.length(); i++) 
				protoVo.c2sProtoVo.propertyList.push( analyzeProperty(c2sPropertyList[i],protoVo.c2sProtoVo.className, protoVo.c2sProtoVo.classDesc));
			if(0 == protoVo.c2sProtoVo.propertyList.length)
				protoVo.c2sProtoVo.propertyList = null;
			protocolClassVoDic[protoVo.c2sProtoVo.className] = protoVo.c2sProtoVo;
			
			ObjectPool.disposeObject(protoVo.s2cProtoVo);
			protoVo.s2cProtoVo = ObjectPool.getObject(ProtocalClassVo);
			protoVo.s2cProtoVo.className = "SC"+protoVo.protoId;
			protoVo.s2cProtoVo.classDesc = protoVo.protoDesc;
			protoVo.s2cProtoVo.propertyList = [];
			var s2cPropertyList:XMLList = xmlData.s2c[0].property;
			for (i = 0; i < s2cPropertyList.length(); i++) 
				protoVo.s2cProtoVo.propertyList.push( analyzeProperty(s2cPropertyList[i], protoVo.s2cProtoVo.className, protoVo.s2cProtoVo.classDesc) );
			if(0 == protoVo.s2cProtoVo.propertyList.length)
				protoVo.s2cProtoVo.propertyList = null;
			protocolClassVoDic[protoVo.s2cProtoVo.className] = protoVo.s2cProtoVo;
			
			return protoVo;
		}
		
		/**
		 * 解析协议变量属性数据 
		 * @param xmlData
		 */		
		private function analyzeProperty(xmlData:XML, className:String, classDesc:String):PropertyVo
		{
			var pVo:PropertyVo = ObjectPool.getObject(PropertyVo);
			pVo.name = xmlData.@name;
			pVo.desc = xmlData.@desc;
			pVo.type = xmlData.@type;
			var lower:String = pVo.type.toLocaleLowerCase();
			if(SocketDataType.isNormalType(lower)) // 属性类型是基础类型，强制转为小写
				pVo.type = lower;
			if(pVo.type == SocketDataType.ARRAY) // 数组，要循环读取
			{
				ObjectPool.disposeObject(pVo.subPropertyVos);
				pVo.subPropertyVos = [];
				var subPList:XMLList = xmlData.property;
				for (var i:int = 0; i < subPList.length(); i++) 
					pVo.subPropertyVos.push( analyzeProperty(subPList[i], className, classDesc) );
				if( 1 < subPList.length() )
				{ // 数组里超过1个属性，创建一个自定义类
					var cXml:XML = new XML("<xml><macro name=\""+className+"_"+pVo.name+"\" desc=\""+classDesc+"\"/></xml>");
					cXml.macro[0].insertChildAfter(null, subPList);
					analyzeMacro(cXml);
				}
			}
			else
			{
				pVo.subPropertyVos = null;
			}
			return pVo;
		}
	}
}