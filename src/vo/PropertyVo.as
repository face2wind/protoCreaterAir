package vo
{
	import face2wind.net.item.SocketDataType;

	/**
	 * 属性变量信息
	 * @author face2wind
	 */
	public class PropertyVo
	{
		public function PropertyVo()
		{
		}
		
		/**
		 * 属性名 
		 */		
		public var name:String = "";
		
		/**
		 * 属性数据类型（SocketDataType） 若不是基础类型，就是自定义类型
		 */		
		public var type:String = "";
		
		/**
		 * 属性描述 
		 */		
		public var desc:String = "";
		
		/**
		 * 属性里嵌套属性列表（数组才有） 
		 */		
		public var subPropertyVos:Array = null;
	}
}