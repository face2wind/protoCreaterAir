package vo
{
	/**
	 * 协议类对象（可以是协议）
	 * @author face2wind
	 */
	public class ProtocalClassVo
	{
		public function ProtocalClassVo()
		{
		}
		/**
		 * 类名 
		 */		
		public var className:String = "";
		
		/**
		 * 类注释 
		 */		
		public var classDesc:String = "";
		
		/**
		 * 属性列表 （PropertyVo）
		 */		
		public var propertyList:Array;
	}
}