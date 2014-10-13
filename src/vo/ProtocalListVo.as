package vo
{
	/**
	 * 协议大类Vo，一个系列（功能）的协议
	 * @author face2wind
	 */
	public class ProtocalListVo
	{
		public function ProtocalListVo()
		{
		}
		
		/**
		 * 协议大类ID 
		 */		
		public var protoListId:String = "";
		
		/**
		 * 协议大类描述 
		 */		
		public var protocolListDesc:String = "";
		
		/**
		 * 具体协议列表 （ProtocalVo）
		 */		
		public var protocolVoList:Array = [];
	}
}