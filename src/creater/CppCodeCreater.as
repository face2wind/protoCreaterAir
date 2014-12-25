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
	 * 
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
			doCreateProtoCode(protoXmlName);
		}
		
		public function createAllProtoCode():void
		{
			createAllMacroClass();
			var allProtoNameList:Array = ProtoDataManager.getInstance().protoFileNameList.source;
			for (var i:int = 0; i < allProtoNameList.length; i++) 
				doCreateProtoCode(allProtoNameList[i]);
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
				case SocketDataType.INT32:realType="long";break;
				case SocketDataType.UINT8:
				case SocketDataType.UINT16:
				case SocketDataType.UINT32:realType="unsigned long";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="double";break;
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
			var realType:String = type;
			switch(type)
			{
				case SocketDataType.INT8:realType="ReadChar";break;
				case SocketDataType.INT16:realType="ReadShort";break;
				case SocketDataType.INT32:realType="ReadLong";break;
				case SocketDataType.UINT8:realType="ReadChar";break;
				case SocketDataType.UINT16:realType="ReadShort";break;
				case SocketDataType.UINT32:realType="ReadLong";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="ReadDouble";break;
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
			var realType:String = type;
			switch(type)
			{
				case SocketDataType.INT8:realType="WriteChar";break;
				case SocketDataType.INT16:realType="WriteShort";break;
				case SocketDataType.INT32:realType="WriteLong";break;
				case SocketDataType.UINT8:realType="WriteChar";break;
				case SocketDataType.UINT16:realType="WriteShort";break;
				case SocketDataType.UINT32:realType="WriteLong";break;
				case SocketDataType.INT64:
				case SocketDataType.UINT64:realType="WriteDouble";break;
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
//			codeStr = "#ifndef _"+scStr+protoVo.protoId+"_H_\n#define _"+scStr+protoVo.protoId+"_H_\n\n#include <socketMessage.h>\n" +
//				"#include <byteArray.h>\n#include <string>\n#include <vector>\n\n\n/**\n * "+protoVo.protoDesc+"\n * @author face2wind\n */\n" +
//				"struct "+scStr+protoVo.protoId+" : public face2wind::SocketMessage\n{";
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
//						packSrc = packSrc + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						packSrc = packSrc + "      by->"+getWriteType(propertyVo.subPropertyVos[0].type)+"(*it);\n";
//						unpackStr = unpackStr + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						unpackStr = unpackStr + "      (*it) = data->"+getReadType(propertyVo.subPropertyVos[0].type)+"();\n";
					}
					else
					{
						subType = scStr+protoVo.protoId+"_"+propertyVo.name;
						var createPvo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
						createPvo.className = subType;
						createPvo.classDesc = propertyVo.desc;
						createPvo.propertyList = propertyVo.subPropertyVos;
						createProtoClass(createPvo);
//						packSrc = packSrc + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						packSrc = packSrc + "      by->ReadFromByteArray( it->PackMsg() );\n";
//						unpackStr = unpackStr + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						unpackStr = unpackStr + "      it->UnpackMsg(data);\n";
					}
					packSrc = packSrc + "    by->WriteShort("+propertyVo.name+".size());\n    for (std::vector<"+subType+"*>::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
					packSrc = packSrc + "      by->ReadFromByteArray( (*it)->PackMsg() );\n";
					unpackStr = unpackStr + "    int "+propertyVo.name+"Len = data->ReadShort();\n    for (int i = 0; i < "+
						propertyVo.name+"Len; ++i){\n      "+subType+" *tmp_"+subType+" = new "+subType+"();\n" +
						"      tmp_"+subType+"->UnpackMsg(data);\n      testArr.push_back(tmp_"+subType+");\n    }";
					includeHead += "#include <customData/"+subType+".h>\n";
					codeStr = codeStr +transformType(propertyVo.type)+"<"+subType+"*> "+propertyVo.name+" ;";
				}else{
					packSrc = packSrc + "    by->"+getWriteType(propertyVo.type)+"("+propertyVo.name+");\n";
					unpackStr = unpackStr + "    "+propertyVo.name+" = data->"+getReadType(propertyVo.type)+"();\n";
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
//						packSrc = packSrc + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						packSrc = packSrc + "      by->"+getWriteType(propertyVo.subPropertyVos[0].type)+"(*it);\n";
//						unpackStr = unpackStr + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						unpackStr = unpackStr + "      (*it) = data->"+getReadType(propertyVo.subPropertyVos[0].type)+"();\n";
					}
					else
					{
						subType = createPvo.className+"_"+propertyVo.name;
						var createPvo:ProtocalClassVo = ObjectPool.getObject(ProtocalClassVo);
						createPvo.className = subType;
						createPvo.classDesc = propertyVo.desc;
						createPvo.propertyList = propertyVo.subPropertyVos;
						createProtoClass(createPvo);
//						unpackStr = unpackStr + "    for (std::vector<"+subType+">::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
//						unpackStr = unpackStr + "      it->UnpackMsg(data);\n";
					}
					packSrc = packSrc + "    for (std::vector<"+subType+"*>::iterator it = "+propertyVo.name+".begin() ; it != "+propertyVo.name+".end(); ++it)\n";
					packSrc = packSrc + "      by->ReadFromByteArray( (*it)->PackMsg() );\n";
					unpackStr = unpackStr + "    int "+propertyVo.name+"Len = data->ReadShort();\n    for (int i = 0; i < "+
						propertyVo.name+"Len; ++i){\n      "+subType+" *tmp_"+subType+" = new "+subType+"();\n" +
						"      tmp_"+subType+"->UnpackMsg(data);\n      testArr.push_back(tmp_"+subType+");\n    }";
					includeHead += "#include <customData/"+subType+".h>\n";
					codeStr = codeStr +transformType(propertyVo.type)+"<"+subType+"*> "+propertyVo.name+" ;";
				}else{
					packSrc = packSrc + "    by->"+getWriteType(propertyVo.type)+"("+propertyVo.name+");\n";
					unpackStr = unpackStr + "    "+propertyVo.name+" = data->"+getReadType(propertyVo.type)+"();\n";
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