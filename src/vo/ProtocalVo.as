package vo
{
	/**
	 * 单个协议信息
	 * @author face2wind
	 */
	public class ProtocalVo
	{
		public function ProtocalVo()
		{
		}
		
		/**
		 * 协议ID 
		 */		
		public var protoId:String = "";
		
		/**
		 * 协议描述 
		 */		
		public var protoDesc:String = "";
		
		/**
		 * 客户端 TO 服务端 
		 */		
		public var c2sProtoVo:ProtocalClassVo;
		
		/**
		 * 服务端 TO 客户端 
		 */		
		public var s2cProtoVo:ProtocalClassVo;
	}
}