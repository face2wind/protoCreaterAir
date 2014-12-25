package manager
{
	import creater.AS3CodeCreater;
	import creater.CppCodeCreater;
	import creater.ICodeCreater;
	
	import enum.CodeType;
	
	import face2wind.util.ArrayUtil;

	/**
	 * 代码创建管理器
	 * @author face2wind
	 */
	public class CodeCreaterManager
	{
		public function CodeCreaterManager()
		{
			if(instance)
				throw new Error("CodeCreaterManager is singleton class and allready exists!");
			instance = this;
		}
		
		/**
		 * 单例
		 */
		private static var instance:CodeCreaterManager;
		/**
		 * 获取单例
		 */
		public static function getInstance():CodeCreaterManager
		{
			if(!instance)
				instance = new CodeCreaterManager();
			
			return instance;
		}
		
		/**
		 * 协议数据管理器 
		 */		
		private var pdManager:ProtoDataManager = ProtoDataManager.getInstance();
		
		/**
		 * 生成的代码类型列表 
		 */		
		private var _targetCodeTypes:Array = [CodeType.C_PLUS_PLUS];
		/**
		 * 增加生成的代码类型
		 * @param typeList
		 */		
		public function addTargetCodeTypes(type:int):void
		{
			if(-1 == _targetCodeTypes.indexOf(type))
				_targetCodeTypes.push(type);
		}
		/**
		 * 移除生成的代码类型
		 * @param typeList
		 */		
		public function removeTargetCodeTypes(type:int):void
		{
			if(-1 != _targetCodeTypes.indexOf(type))
				_targetCodeTypes.splice(_targetCodeTypes.indexOf(type), 1);
		}
		
		/**
		 * 根据代码类型获取对应的代码生成器 
		 * @param type
		 */		
		private function getCreaterWithCodeType(type:int):ICodeCreater
		{
			var creater:ICodeCreater = null;
			switch(type)
			{
				case CodeType.AS3:creater=AS3CodeCreater.getInstance();break;
				case CodeType.C_PLUS_PLUS:creater=CppCodeCreater.getInstance();break;
			}
			return creater;
		}
		
		/**
		 * 当前要生成的单个协议文档名字 
		 */		
		private var curCreateProtoName:String = null;
		/**
		 * 创建一个协议文档对应的代码 
		 * @param protoXmlName 对应协议文档的名字（不包含xml后缀）
		 */		
		public function createOneProtoCode(protoXmlName:String):void
		{
			if(null == protoXmlName || "" == protoXmlName)
				return;
			curCreateProtoName = protoXmlName;
			pdManager.loadOneConfig(protoXmlName, onOneConfigLoadHandler);
		}
		
		/**
		 * 创建所有协议文档对应的代码（每次调用都重读一次所有协议文档） 
		 */		
		public function createAllProtoCode():void
		{
			pdManager.loadAllConfig(onAllConfigLoadedHandler);
		}
		
		/**
		 * 静待协议数据管理器那边把所有协议加载并解析好了，这边才调用代码生成器生成代码 
		 */		
		private function onAllConfigLoadedHandler():void
		{
			for (var i:int = 0; i < _targetCodeTypes.length; i++) 
			{
				var codeCreater:ICodeCreater = getCreaterWithCodeType(_targetCodeTypes[i]);
				if(codeCreater)
					codeCreater.createAllProtoCode();
			}
		}
		
		/**
		 * 静待协议数据管理器那边把对应协议加载并解析好了，这边才调用代码生成器生成代码 
		 */		
		private function onOneConfigLoadHandler():void
		{
			for (var i:int = 0; i < _targetCodeTypes.length; i++) 
			{
				var codeCreater:ICodeCreater = getCreaterWithCodeType(_targetCodeTypes[i]);
				if(codeCreater)
					codeCreater.createOneProtoCode(curCreateProtoName);
			}
			curCreateProtoName = null;
		}
	}
}