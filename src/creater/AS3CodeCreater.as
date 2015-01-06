package creater
{
	import face2wind.lib.ObjectPool;
	import face2wind.net.item.SocketDataType;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.Dictionary;
	
	import manager.ConfigManager;
	import manager.ProtoDataManager;
	
	import vo.PropertyVo;
	import vo.ProtocalClassVo;
	import vo.ProtocalListVo;
	import vo.ProtocalVo;

	/**
	 * AS3协议代码生成器
	 * @author face2wind
	 */
	public class AS3CodeCreater implements ICodeCreater
	{
		public function AS3CodeCreater()
		{
			if(instance)
				throw new Error("AS3CodeCreater is singleton class and allready exists!");
			instance = this;
			
			_subClassDic = new Dictionary();
		}
		
		/**
		 * 单例
		 */
		private static var instance:AS3CodeCreater;
		/**
		 * 获取单例
		 */
		public static function getInstance():AS3CodeCreater
		{
			if(!instance)
				instance = new AS3CodeCreater();
			
			return instance;
		}
		
		/**
		 * 嵌套的类信息，读取的时候创建，用于生成commandmap 
		 */		
		private var _subClassDic:Dictionary;
		
		public function createOneProtoCode(protoXmlName:String):void
		{
			removeCustomData();
//			createCommandMap();
			createAllMacroClass();
			doCreateProtoCode(protoXmlName);
			createCommandMap();
		}
		
		public function createAllProtoCode():void
		{
			removeCustomData();
//			createCommandMap();
			createAllMacroClass();
			var allProtoNameList:Array = ProtoDataManager.getInstance().protoFileNameList.source;
			for (var i:int = 0; i < allProtoNameList.length; i++) 
				doCreateProtoCode(allProtoNameList[i]);
			createCommandMap();
		}
		
		/**
		 * 删除旧的customData目录下的类 
		 */		
		private function removeCustomData():void
		{
			var srcPath:String = ConfigManager.getInstance().configXml.as3SrcPath + "/socketCommand/customData/";
			var dir:File = File.documentsDirectory.resolvePath(srcPath );
			if(dir.isDirectory)
				dir.deleteDirectory(true);
		}
		
		/**
		 * 生成所有宏对应的类 
		 */		
		protected function createAllMacroClass():void
		{
			var allList:Array = ProtoDataManager.getInstance().getAllMacroClassList();
			for (var i:int = 0; i < allList.length; i++) 
				createProtoClass(allList[i]);
		}
		
		/**
		 *  生成协议识别类GameCommandMap
		 */		
		private function createCommandMap():void
		{
			var codeStr:String;
			var srcPath:String = ConfigManager.getInstance().configXml.as3SrcPath + "/socketCommand/GameCommandMap.as";
			var fileStream:FileStream = new FileStream();
			var filePath:File;
			var i:int ;
			codeStr = "package socketCommand\n{\n	import face2wind.net.CommandMap;\n	import face2wind.net.item.SocketDataType;\n\n" +
				"	import socketCommand.customData.*;\n";
			var allProtoList:Array = ProtoDataManager.getInstance().protoFileNameList.source;
			var c2sExtClassNameList:Array = [];
			var s2cExtClassNameList:Array = [];
			for (i = 0; i < allProtoList.length; i++) 
			{
				var reg:RegExp = /^[0-9]*/;
				var protoXmlName:String = allProtoList[i];
				var protoID:String = protoXmlName.match(reg)[0];
				codeStr = codeStr + "	import socketCommand.s2c.sc"+protoID+".*;\n";
				var protoListVo:ProtocalListVo = ProtoDataManager.getInstance().getProtocolList(protoID);
				for (var j:int = 0; j < protoListVo.protocolVoList.length; j++) 
				{
					var proVo:ProtocalVo = protoListVo.protocolVoList[j];
					c2sExtClassNameList.push("CS"+proVo.protoId);
					getAllExtClassNameList(c2sExtClassNameList, proVo.c2sProtoVo);
					s2cExtClassNameList.push("SC"+proVo.protoId);
					getAllExtClassNameList(s2cExtClassNameList, proVo.s2cProtoVo);
				}
			}
			codeStr = codeStr + "\n	/**\n	 * 协议字典类<br/>\n	 * ( 此文件由工具生成，勿手动修改)\n	 * @author face2wind\n	 */\n	public class GameCommandMap extends CommandMap" +
				"\n	{\n		public function GameCommandMap()\n		{\n			super();\n		}\n\n		/**\n		 *  初始化S2C的协议类对象列表\n		 */" +
				"\n		protected override function initScmdClassDic():void\n		{\n";
			var extClassNameList:Array = s2cExtClassNameList;//c2sExtClassNameList.concat(s2cExtClassNameList);
			for (i = 0; i < extClassNameList.length; i++) 
			{
				codeStr = codeStr + "			_scmdClassDic[\""+extClassNameList[i]+"\"] = "+extClassNameList[i]+";\n"
			}
			codeStr = codeStr + "		}\n\n		/**\n		 * 初始化所有协议属性信息\n		 */\n		protected override function initCMDAttributes():void\n		{";
			
			var attributeStrList:Array = [];
			extClassNameList = c2sExtClassNameList.concat(s2cExtClassNameList);
			for (i = 0; i < extClassNameList.length; i++) 
			{
				var cName:String = extClassNameList[i];
				getAttributeCode(attributeStrList, cName);
			}
			for (i = 0; i < attributeStrList.length; i++) 
			{
				codeStr = codeStr + attributeStrList[i] ;
			}
			codeStr = codeStr + "\n		}\n	}\n}";
			filePath = File.documentsDirectory.resolvePath(srcPath);
			fileStream.open(filePath, FileMode.WRITE);
			fileStream.writeUTFBytes(codeStr);
			fileStream.close();
		}
		
		/**
		 * 生成属性解析代码
		 * @param attributeStrList
		 * @param className
		 */		
		private function getAttributeCode(attributeStrList:Array, className:String):void
		{
			var forAttributesVo:ProtocalClassVo = ProtoDataManager.getInstance().getProtoClassVo(className);
			if(null == forAttributesVo)
				forAttributesVo = _subClassDic[className];
			if(null == forAttributesVo)
				return;
			if(null == forAttributesVo.propertyList)
				return;
			var codeStr:String = "\n			_cmdAttributes[\""+className+"\"] = [";
			for (var i:int = 0; i < forAttributesVo.propertyList.length; i++) 
			{
				var propertyVo:PropertyVo = forAttributesVo.propertyList[i];
				if(0 < i)
					codeStr = codeStr + ",";
				codeStr = codeStr + "{name:\""+propertyVo.name+"\", type:"+getSocketTypeStr(propertyVo.type);
				var subType:String = "";
				if(SocketDataType.ARRAY == propertyVo.type)
				{
					if(propertyVo.subPropertyVos &&
						1 == propertyVo.subPropertyVos.length &&
						!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type)
					)
						subType = propertyVo.subPropertyVos[0].type;
					else
						subType = className+"_"+propertyVo.name;
				}
				if("" != subType)
					codeStr = codeStr + ", subType:\""+subType+"\"";
				codeStr = codeStr +"}";
			}
			codeStr = codeStr + "];";
			attributeStrList.push(codeStr);
		}
		
		/**
		 * 读取指定类里面所有的自定义类 
		 * @param extClassNameList 读取的内容要写入的数组
		 * @param c2sProtoVo 要分析的类
		 */		
		private function getAllExtClassNameList(extClassNameList:Array, protoClassVo:ProtocalClassVo):void
		{
			var subType:String = "";
			if(null == protoClassVo.propertyList)
				return;
			for (var i:int = 0; i < protoClassVo.propertyList.length; i++) 
			{
				var propertyVo:PropertyVo = protoClassVo.propertyList[i];
				if(SocketDataType.ARRAY == propertyVo.type)
				{
					if(propertyVo.subPropertyVos &&
						1 == propertyVo.subPropertyVos.length &&
						!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type)
					)
						subType = propertyVo.subPropertyVos[0].type;
					else
					{
						subType = protoClassVo.className+"_"+propertyVo.name;
						var createPvo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
						createPvo.className = subType;
						createPvo.classDesc = propertyVo.desc;
						createPvo.propertyList = propertyVo.subPropertyVos;
						getAllExtClassNameList(extClassNameList, createPvo);			
					}
					if(-1 == extClassNameList.indexOf(subType) && "" != subType)
						extClassNameList.push(subType);
				}
				else if( !SocketDataType.isNormalType(propertyVo.type) )
				{
					if(-1 == extClassNameList.indexOf(propertyVo.type))
						extClassNameList.push(propertyVo.type);
				}
				else
					continue;
			}
		}
		
		/**
		 * 生成一个协议的代码 
		 * @param protoXmlName
		 */		
		private function doCreateProtoCode(protoXmlName:String):void
		{
			var reg:RegExp = /^[0-9]*/;
			var protoID:String = protoXmlName.match(reg)[0];
			if(null == protoID || "" == protoID)
				return;
			var protoListVo:ProtocalListVo = ProtoDataManager.getInstance().getProtocolList(protoID);
			if(null == protoListVo)
				return;
			var srcPath:String = ConfigManager.getInstance().configXml.as3SrcPath + "/socketCommand/";
			
			{ // 删除旧代码
				var dir:File = File.documentsDirectory.resolvePath(srcPath + "c2s/cs"+ protoListVo.protoListId );
				if(dir.isDirectory)
					dir.deleteDirectory(true);
				dir = File.documentsDirectory.resolvePath(srcPath + "s2c/sc"+ protoListVo.protoListId);
				if(dir.isDirectory)
					dir.deleteDirectory(true);
			}
			
			for (var i:int = 0; i < protoListVo.protocolVoList.length; i++) 
			{
				var protoVo:ProtocalVo = protoListVo.protocolVoList[i] as ProtocalVo;
				var c2s:ProtocalClassVo = protoVo.c2sProtoVo;
				var s2c:ProtocalClassVo = protoVo.s2cProtoVo;
				var fileStream:FileStream = new FileStream();
				var filePath:File;
				var propertyVo:PropertyVo;
				var codeStr:String;
				var j:int;
				
				if(null != c2s.propertyList) // 客户端TO服务端，有数据，则创建对应类
				{
					codeStr = "package socketCommand.c2s.cs" + protoListVo.protoListId;
					codeStr = codeStr + "\n{";
					codeStr = codeStr + "\n	import socketCommand.customData.*\n";//getExtImport(c2s.propertyList, "CS"+protoVo.protoId);
					codeStr = codeStr + "\n	/**\n	 * "+protoVo.protoDesc+"<br/>\n	 * ( 此文件由工具生成，勿手动修改)\n	 * @author face2wind\n	 */\n	public class CS"+protoVo.protoId+
						"\n	{\n		public function CS"+protoVo.protoId+"()\n		{\n		}";
					for (j = 0; j < c2s.propertyList.length; j++) 
					{
						propertyVo = c2s.propertyList[j] as PropertyVo;
						codeStr = codeStr + "\n		/**\n		 * "+propertyVo.desc+"\n		 */\n		public var "+propertyVo.name+":"+transformType(propertyVo.type)+" ;";
					}
					codeStr = codeStr + "\n	}\n}";
					filePath = File.documentsDirectory.resolvePath(srcPath + "c2s/cs"+ protoListVo.protoListId + "/CS"+protoVo.protoId+".as");
					fileStream.open(filePath, FileMode.WRITE);
					fileStream.writeUTFBytes(codeStr);
					fileStream.close();
				}
				
				if(null != s2c.propertyList) // 服务端TO客户端，有数据，则创建对应类
				{
					codeStr = "package socketCommand.s2c.sc" + protoListVo.protoListId;
					codeStr = codeStr + "\n{";
					codeStr = codeStr + "\n	import socketCommand.customData.*\n";//getExtImport(s2c.propertyList, "SC"+protoVo.protoId);
					codeStr = codeStr + "\n	/**\n	 * "+protoVo.protoDesc+"<br/>\n	 * ( 此文件由工具生成，勿手动修改)\n	 * @author face2wind\n	 */\n	public class SC"+protoVo.protoId+
						"\n	{\n		public function SC"+protoVo.protoId+"()\n		{\n		}";
					for (j = 0; j < s2c.propertyList.length; j++) 
					{
						propertyVo = s2c.propertyList[j] as PropertyVo;
						codeStr = codeStr + "\n		/**\n		 * "+propertyVo.desc+"\n		 */\n		public var "+propertyVo.name+":"+transformType(propertyVo.type);
						if(SocketDataType.ARRAY == propertyVo.type && 
							null != propertyVo.subPropertyVos) // 当前类拥有数组子元素
						{
							var subType:String = "";
							if(1 == propertyVo.subPropertyVos.length &&
								!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type) &&
								SocketDataType.ARRAY != propertyVo.subPropertyVos[0].type
							) // 只有一个非基础属性，则直接用这个属性做为数组的类型，否则，生成一个类
								subType = propertyVo.subPropertyVos[0].type;
							else
							{
								subType = "SC"+protoVo.protoId+"_"+propertyVo.name;
//								var createPvo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
//								createPvo.className = subType;
//								createPvo.classDesc = propertyVo.desc;
//								createPvo.propertyList = propertyVo.subPropertyVos;
//								createProtoClass(createPvo);
//								_subClassDic[subType] = createPvo;
							}
							codeStr = codeStr + " = ["+subType+"]";
						}
						codeStr = codeStr + " ;"
					}
					codeStr = codeStr + "\n	}\n}";
					filePath = File.documentsDirectory.resolvePath(srcPath + "s2c/sc"+ protoListVo.protoListId + "/SC"+protoVo.protoId+".as");
					fileStream.open(filePath, FileMode.WRITE);
					fileStream.writeUTFBytes(codeStr);
					fileStream.close();
				}
			}
		}
		
		/**
		 * 创建一个自定义类的代码 
		 * @param createPvo
		 */		
		private function createProtoClass(createPvo:ProtocalClassVo):void
		{
			var srcPath:String = ConfigManager.getInstance().configXml.as3SrcPath + "/socketCommand/customData/";
			var codeStr:String = "package socketCommand.customData\n{\n	/**\n	 * "+createPvo.classDesc+
				"<br/>\n	 * ( 此文件由工具生成，勿手动修改)\n	 * @author face2wind\n	 */\n	public class "+createPvo.className+"\n	{\n		public function "+createPvo.className+"()\n		{\n		}\n";
			var propertyVo:PropertyVo;
			for (var i:int = 0; i < createPvo.propertyList.length; i++) 
			{
				propertyVo = createPvo.propertyList[i] as PropertyVo;
				codeStr = codeStr + "\n		/**\n		 * "+propertyVo.desc+"\n		 */\n		public var "+propertyVo.name+":"+transformType(propertyVo.type);
				if(SocketDataType.ARRAY == propertyVo.type && 
					null != propertyVo.subPropertyVos) // 当前类拥有数组子元素
				{
					var subType:String = "";
					if(1 == propertyVo.subPropertyVos.length &&
						!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type)) // 只有一个非基础属性，则直接用这个属性做为数组的类型，否则，生成一个类
						subType = propertyVo.type;
					else  // 类里有数组内容，迭代创建数组里的子类
					{
						subType = createPvo.className+"_"+propertyVo.name;
//						var createPvo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
//						createPvo.className = subType;
//						createPvo.classDesc = propertyVo.desc;
//						createPvo.propertyList = propertyVo.subPropertyVos;
//						createProtoClass(createPvo);
//						_subClassDic[subType] = createPvo;
					}
					codeStr = codeStr + " = ["+subType+"]";
				}
				codeStr = codeStr + " ;"
			}
			
			codeStr = codeStr + "\n	}\n}";
			var fileStream:FileStream = new FileStream();
			var file:File = File.documentsDirectory.resolvePath(srcPath +createPvo.className +".as");
			fileStream.open(file, FileMode.WRITE);
			fileStream.writeUTFBytes(codeStr);
			fileStream.close();
		}
		
		/**
		 * 转换数据类型，定义的类型和代码里实际存储的类型不一定一样（比如直接用int来存放int8，int16，number存放int64） 
		 * @param type SocketDataType定义的类型（若不在这里定义的基础类型，则直接返回原类型）
		 * @return 
		 */		
		private function transformType(type:String):String
		{
			var realType:String = type;
			switch(type)
			{
				case SocketDataType.INT8:
				case SocketDataType.INT16:
				case SocketDataType.INT32:realType="int";break;
				case SocketDataType.UINT8:
				case SocketDataType.UINT16:
				case SocketDataType.UINT32:realType="uint";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="Number";break;
				case SocketDataType.ARRAY:realType="Array";break;
				case SocketDataType.STRING:realType="String";break;
			}
			return realType;
		}
		
		/**
		 * 根据类型获取对应的定义代码，比如int8则返回： SocketDataType.INT8
		 * @param type 类型
		 * @return 
		 */		
		private function getSocketTypeStr(type:String):String
		{
			var typeCode:String = "\""+type+"\""; // 其他类型，两边要加双引号
			switch(type)
			{
				case SocketDataType.INT8:typeCode="SocketDataType.INT8";break;
				case SocketDataType.INT16:typeCode="SocketDataType.INT16";break;
				case SocketDataType.INT32:typeCode="SocketDataType.INT32";break;
				case SocketDataType.UINT8:typeCode="SocketDataType.UINT8";break;
				case SocketDataType.UINT16:typeCode="SocketDataType.UINT16";break;
				case SocketDataType.UINT32:typeCode="SocketDataType.UINT32";break;
				case SocketDataType.INT64:typeCode="SocketDataType.INT64";break;
				case SocketDataType.UINT64:typeCode="SocketDataType.UINT64";break;
				case SocketDataType.ARRAY:typeCode="SocketDataType.ARRAY";break;
				case SocketDataType.STRING:typeCode="SocketDataType.STRING";break;
				case SocketDataType.ARRAY:typeCode="SocketDataType.ARRAY";break;
			}
			return typeCode;
		}
	}
}