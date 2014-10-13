package creater
{
	/**
	 * 代码生成器接口
	 * @author face2wind
	 */
	public interface ICodeCreater
	{
		/**
		 * 创建一个协议文档对应的代码 
		 * @param protoXmlName 对应协议文档的名字（不包含xml后缀）
		 */		
		function createOneProtoCode(protoXmlName:String):void
			
		/**
		 * 创建所有协议文档对应的代码 
		 */	
		function createAllProtoCode():void
	}
}