package creater
{
	import face2wind.lib.ObjectPool;
	import face2wind.net.item.SocketDataType;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import manager.ConfigManager;
	import manager.ProtoDataManager;
	
	import vo.PropertyVo;
	import vo.ProtocalClassVo;
	import vo.ProtocalListVo;
	import vo.ProtocalVo;
	
	/**
	 * C++协议代码创建器
	 * @author face2wind
	 */
	public class CppCodeCreater implements ICodeCreater
	{
		public function CppCodeCreater()
		{
			if(instance)
				throw new Error("CppCodeCreater is singleton class and allready exists!");
			instance = this;
		}
		
		/**
		 * 单例
		 */
		private static var instance:CppCodeCreater;
		/**
		 * 获取单例
		 */
		public static function getInstance():CppCodeCreater
		{
			if(!instance)
				instance = new CppCodeCreater();
			
			return instance;
		}
		
		public function createOneProtoCode(protoXmlName:String):void
		{
			createAllMacroClass();
			createCommandMap();
			doCreateProtoCode(protoXmlName);
		}
		
		public function createAllProtoCode():void
		{
			createAllMacroClass();
			createCommandMap();
			var allProtoNameList:Array = ProtoDataManager.getInstance().protoFileNameList.source;
			for (var i:int = 0; i < allProtoNameList.length; i++) 
				doCreateProtoCode(allProtoNameList[i]);
		}
		
		/**
		 * 创建映射类代码 
		 */		
		private function createCommandMap():void
		{
			var head:String = "#ifndef _COMMAND_MAP_HPP_\n#define _COMMAND_MAP_HPP_\n\n#include <map>\n#include <socketMessage.h>\n\n";
			var body:String = "\nnamespace face2wind {\n\n  class CommandMap\n  {\n    std::map<short, SocketMessage*> csMessages;\n" +
				"    std::map<short, SocketMessage*> scMessages;\n\n  public:\n    CommandMap(){\n";
			var tail:String = "    }\n    ~CommandMap(){\n      csMessages.clear();\n      scMessages.clear();\n" +
				"    }\n\n    static CommandMap &GetInstance();\n\n    SocketMessage *GetCSMsgObject(short cmd){\n" +
				"      if(0 < csMessages.count(cmd))\n	return csMessages[cmd];\n      else\n	return NULL;\n    }\n\n" +
				"    SocketMessage *GetSCMsgObject(short cmd){\n      if(0 < scMessages.count(cmd))\n" +
				"	return scMessages[cmd];\n      else\n	return NULL;\n    }\n  };\n}\n\n#endif // _COMMAND_MAP_HPP_";
			
			var allProtoNameList:Array = ProtoDataManager.getInstance().protoFileNameList.source;
			var csAllHead:String = "";
			var scAllHead:String = "";
			var csAllBody:String = "";
			var scAllBody:String = "";
			for (var j:int = 0; j < allProtoNameList.length; j++) 
			{
				var protoXmlName:String = allProtoNameList[j];
				var reg:RegExp = /^[0-9]*/;
				var protoID:String = protoXmlName.match(reg)[0];
				if(null == protoID || "" == protoID)
					return;
				var protoListVo:ProtocalListVo = ProtoDataManager.getInstance().getProtocolList(protoID);
				if(null == protoListVo)
					return;
				var csHead:String = "";
				var scHead:String = "";
				var csBody:String = "";
				var scBody:String = "";
				for (var i:int = 0; i < protoListVo.protocolVoList.length; i++) 
				{
					var protoVo:ProtocalVo = protoListVo.protocolVoList[i] as ProtocalVo;
					var c2s:ProtocalClassVo = protoVo.c2sProtoVo;
					var s2c:ProtocalClassVo = protoVo.s2cProtoVo;
					if(null != c2s.propertyList) { // 客户端TO服务端，有数据，则创建对应类
						csHead += ("#include <c2s/cs"+protoID+"/"+c2s.className+".h>\n");
						csBody += ("      csMessages["+protoVo.protoId+"] = new "+c2s.className+"();\n");
					}
					if(null != s2c.propertyList) { // 服务端TO客户端，有数据，则创建对应类
						scHead += ("#include <s2c/sc"+protoID+"/"+s2c.className+".h>\n");
						scBody += ("      scMessages["+protoVo.protoId+"] = new "+s2c.className+"();\n");
					}
				}
				csAllHead += csHead;
				scAllHead += scHead;
				csAllBody += csBody;
				scAllBody += scBody;
			}
			head += (csAllHead + "\n"+ scAllHead);
			body += (csAllBody + "\n"+ scAllBody);
			var srcPath:String = ConfigManager.getInstance().configXml.cppSrcPath ;
			var fileStream:FileStream = new FileStream();
			var filePath:File;
			filePath = File.documentsDirectory.resolvePath(srcPath + "/CommandMap.h");
			fileStream.open(filePath, FileMode.WRITE);
			fileStream.writeUTFBytes(head+body+tail);
			fileStream.close();
			
			var cppStr:String = "#include <commandMap.h>\n\nnamespace face2wind {\n\n" +
				"  CommandMap &CommandMap::GetInstance() {\n    static CommandMap m;\n    return m;\n  }\n\n}";
			filePath = File.documentsDirectory.resolvePath(srcPath + "/CommandMap.cpp");
			fileStream.open(filePath, FileMode.WRITE);
			fileStream.writeUTFBytes(cppStr);
			fileStream.close();
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
				case SocketDataType.INT32:realType="unsigned int";break;
				case SocketDataType.UINT8:
				case SocketDataType.UINT16:
				case SocketDataType.UINT32:realType="unsigned int";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="long long";break;
				case SocketDataType.ARRAY:realType="std::vector";break;
				case SocketDataType.STRING:realType="std::string";break;
			}
			return realType;
		}
		
		/**
		 * 获取读数据的函数名 
		 * @param type
		 * @return 
		 */		
		private function getReadType(type:String):String
		{
			var realType:String = "";
			switch(type)
			{
				case SocketDataType.INT8:realType="ReadUnsignedInt8";break;
				case SocketDataType.INT16:realType="ReadUnsignedInt16";break;
				case SocketDataType.INT32:realType="ReadUnsignedInt32";break;
				case SocketDataType.UINT8:realType="ReadUnsignedInt8";break;
				case SocketDataType.UINT16:realType="ReadUnsignedInt16";break;
				case SocketDataType.UINT32:realType="ReadUnsignedInt32";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="ReadUnsignedInt64";break;
				case SocketDataType.ARRAY:realType="ReadVector";break; // 无效的，不这里处理
				case SocketDataType.STRING:realType="ReadString";break;
			}
			return realType;
		}
		
		/**
		 * 获取写数据的函数名 
		 * @param type
		 * @return 
		 */		
		private function getWriteType(type:String):String
		{
			var realType:String = "";
			switch(type)
			{
				case SocketDataType.INT8:realType="WriteUnsignedInt8";break;
				case SocketDataType.INT16:realType="WriteUnsignedInt16";break;
				case SocketDataType.INT32:realType="WriteUnsignedInt32";break;
				case SocketDataType.UINT8:realType="WriteUnsignedInt8";break;
				case SocketDataType.UINT16:realType="WriteUnsignedInt16";break;
				case SocketDataType.UINT32:realType="WriteUnsignedInt32";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="WriteUnsignedInt64";break;
				case SocketDataType.ARRAY:realType="writeVector";break; // 无效的，不这里处理
				case SocketDataType.STRING:realType="WriteString";break;
			}
			return realType;
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
			var srcPath:String = ConfigManager.getInstance().configXml.cppSrcPath ;
			
			{ // 删除旧代码
				var dir:File = File.documentsDirectory.resolvePath(srcPath + "/c2s/cs"+ protoListVo.protoListId );
				if(dir.isDirectory)
					dir.deleteDirectory(true);
				dir = File.documentsDirectory.resolvePath(srcPath + "/s2c/sc"+ protoListVo.protoListId);
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
					createClassCode(protoListVo,protoVo);
				
				if(null != s2c.propertyList) // 服务端TO客户端，有数据，则创建对应类
					createClassCode(protoListVo,protoVo, false);
			}
		}
		
		private function createClassCode(protoListVo:ProtocalListVo, protoVo:ProtocalVo, isC2S:Boolean = true):void
		{
			var srcPath:String = ConfigManager.getInstance().configXml.cppSrcPath ;
			var fileStream:FileStream = new FileStream();
			var filePath:File;
			var codeStr:String;
			var scStr:String = isC2S?"CS":"SC";
			var propertyVo:PropertyVo;
			var c2s:ProtocalClassVo = protoVo.c2sProtoVo;
			var s2c:ProtocalClassVo = protoVo.s2cProtoVo;
			var targetProto:ProtocalClassVo = isC2S?c2s:s2c;
			var packSrc:String = "\n\n  virtual face2wind::ByteArray *PackMsg()\n  {\n    face2wind::ByteArray *by = new face2wind::ByteArray();\n";
			var unpackStr:String = "\n\n  virtual void UnpackMsg(face2wind::ByteArray *data)\n  {\n";
			var j:int;
			var includeHead:String = "#ifndef _"+scStr+protoVo.protoId+"_H_\n#define _"+scStr+protoVo.protoId+"_H_\n\n#include <socketMessage.h>\n" +
				"#include <byteArray.h>\n#include <string>\n#include <vector>\n";
			codeStr = "\n\n/**\n * "+protoVo.protoDesc+"\n * ( 此文件由工具生成，勿手动修改)\n * @author face2wind\n */\n" +
				"struct "+scStr+protoVo.protoId+" : public face2wind::SocketMessage\n{";
			for (j = 0; j < targetProto.propertyList.length; j++) 
			{
				propertyVo = targetProto.propertyList[j] as PropertyVo;
				codeStr = codeStr + "\n  /**\n   * "+propertyVo.desc+"\n   */\n  ";
				if(SocketDataType.ARRAY == propertyVo.type && 
					null != propertyVo.subPropertyVos) // 当前类拥有数组子元素
				{
					var subType:String = "";
					if(1 == propertyVo.subPropertyVos.length &&
						!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type) &&
						SocketDataType.ARRAY != propertyVo.subPropertyVos[0].type
					) // 只有一个非基础属性，则直接用这个属性做为数组的类型，否则，生成一个类
					{
						subType = propertyVo.subPropertyVos[0].type;
					}
					else
					{
						subType = scStr+protoVo.protoId+"_"+propertyVo.name;
					}
					packSrc = packSrc + "    by->WriteUnsignedInt16("+propertyVo.name+".size());\n    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
					packSrc = packSrc + "      by->ReadFromByteArray( it->PackMsg());\n";
					unpackStr = unpackStr + "    int "+propertyVo.name+"Len = data->ReadUnsignedInt16();\n    for (int i = 0; i < "+
						propertyVo.name+"Len; ++i){\n      "+subType+" tmp_"+subType+";\n" +
						"      tmp_"+subType+".UnpackMsg(data);\n      "+propertyVo.name+".push_back(tmp_"+subType+");\n    }";
					includeHead += "#include <customData/"+subType+".h>\n";
					codeStr = codeStr +transformType(propertyVo.type)+"<"+subType+"> "+propertyVo.name+" ;";
				}else{
					var tmpWriteType:String = getWriteType(propertyVo.type);
					if("" == tmpWriteType)
						packSrc = packSrc + "    by->ReadFromByteArray("+propertyVo.name+".PackMsg());\n";
					else
						packSrc = packSrc + "    by->"+getWriteType(propertyVo.type)+"("+propertyVo.name+");\n";
					var tmpReadType:String = getReadType(propertyVo.type);
					if("" == tmpReadType){
						unpackStr = unpackStr + "    "+propertyVo.name+".UnpackMsg(data);\n";
						includeHead += "#include <customData/"+propertyVo.type+".h>\n";
					}else
						unpackStr = unpackStr + "    "+propertyVo.name+" = data->"+tmpReadType+"();\n";
					codeStr = codeStr +transformType(propertyVo.type)+" "+propertyVo.name+" ;\n";
				}
			}
			packSrc += "    return by;\n  }";
			unpackStr += "\n  }";
			codeStr = includeHead + codeStr;
			codeStr += packSrc;
			codeStr += unpackStr;
			codeStr = codeStr + "\n};  // class end\n\n#endif  //_"+scStr+protoVo.protoId+"_H_";
			var csStr2:String = isC2S?"/c2s/cs":"/s2c/sc";
			filePath = File.documentsDirectory.resolvePath(srcPath + csStr2+ protoListVo.protoListId + "/"+scStr+protoVo.protoId+".h");
			fileStream.open(filePath, FileMode.WRITE);
			fileStream.writeUTFBytes(codeStr);
			fileStream.close();
		}
		
		/**
		 * 创建一个自定义类的代码 
		 * @param createPvo
		 */		
		private function createProtoClass(createPvo:ProtocalClassVo):void
		{
			var srcPath:String = ConfigManager.getInstance().configXml.cppSrcPath + "/customData/";
			//			var file:File = File.documentsDirectory.resolvePath(srcPath);
			//			if(file.isDirectory) // 先清空
			//				file.deleteFile();
			var fileStream:FileStream = new FileStream();
			var filePath:File;
			var codeStr:String;
			var packSrc:String = "\n\n  virtual face2wind::ByteArray *PackMsg()\n  {\n    face2wind::ByteArray *by = new face2wind::ByteArray();\n";
			var unpackStr:String = "\n\n  virtual void UnpackMsg(face2wind::ByteArray *data)\n  {\n";
			var j:int;
			var includeHead:String = "#ifndef _"+createPvo.className+"_H_\n#define _"+createPvo.className+"_H_\n\n#include <socketMessage.h>\n" +
				"#include <byteArray.h>\n#include <string>\n#include <vector>\n";
			codeStr = "\n\n/**\n * "+createPvo.classDesc+"\n * ( 此文件由工具生成，勿手动修改)\n * @author face2wind\n */\n" +
				"struct "+createPvo.className+" : public face2wind::SocketMessage\n{";
			var propertyVo:PropertyVo;
			for (var i:int = 0; i < createPvo.propertyList.length; i++) 
			{
				propertyVo = createPvo.propertyList[i] as PropertyVo;
				codeStr = codeStr + "\n  /**\n   * "+propertyVo.desc+"\n   */\n  ";
				if(SocketDataType.ARRAY == propertyVo.type && 
					null != propertyVo.subPropertyVos) // 当前类拥有数组子元素
				{
					var subType:String = "";
					if(1 == propertyVo.subPropertyVos.length &&
						!SocketDataType.isNormalType(propertyVo.subPropertyVos[0].type) &&
						SocketDataType.ARRAY != propertyVo.subPropertyVos[0].type
					) // 只有一个非基础属性，则直接用这个属性做为数组的类型，否则，生成一个类
					{
						subType = propertyVo.subPropertyVos[0].type;
					}
					else
					{
						subType = createPvo.className+"_"+propertyVo.name;
					}
					packSrc = packSrc + "    by->WriteUnsignedInt16("+propertyVo.name+".size());\n    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
					packSrc = packSrc + "      by->ReadFromByteArray( it->PackMsg());\n";
					unpackStr = unpackStr + "    int "+propertyVo.name+"Len = data->ReadUnsignedInt16();\n    for (int i = 0; i < "+
						propertyVo.name+"Len; ++i){\n      "+subType+" tmp_"+subType+";\n" +
						"      tmp_"+subType+".UnpackMsg(data);\n      "+propertyVo.name+".push_back(tmp_"+subType+");\n    }";
					includeHead += "#include <customData/"+subType+".h>\n";
					codeStr = codeStr +transformType(propertyVo.type)+"<"+subType+"> "+propertyVo.name+" ;";
				}else{
					var tmpWriteType:String = getWriteType(propertyVo.type);
					if("" == tmpWriteType)
						packSrc = packSrc + "    by->ReadFromByteArray("+propertyVo.name+".PackMsg());\n";
					else
						packSrc = packSrc + "    by->"+getWriteType(propertyVo.type)+"("+propertyVo.name+");\n";
					var tmpReadType:String = getReadType(propertyVo.type);
					if("" == tmpReadType){
						unpackStr = unpackStr + "    "+propertyVo.name+".UnpackMsg(data);\n";
						includeHead += "#include <customData/"+propertyVo.type+".h>\n";
					}else
						unpackStr = unpackStr + "    "+propertyVo.name+" = data->"+tmpReadType+"();\n";
					codeStr = codeStr +transformType(propertyVo.type)+" "+propertyVo.name+" ;\n";
				}
			}
			
			packSrc += "    return by;\n  }";
			unpackStr += "\n  }";
			codeStr = includeHead + codeStr;
			codeStr += packSrc;
			codeStr += unpackStr;
			codeStr = codeStr + "\n};  // class end\n\n#endif  //_"+createPvo.className+"_H_";
			filePath = File.documentsDirectory.resolvePath(srcPath + createPvo.className + ".h");
			fileStream.open(filePath, FileMode.WRITE);
			fileStream.writeUTFBytes(codeStr);
			fileStream.close();
		}
		
	}
}