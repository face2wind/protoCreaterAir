package event
{
	/**
	 * 模块不大，所有事件放这里
	 * @author face2wind
	 */
	public class AllEvent
	{
		public function AllEvent()
		{
		}
		
		/**
		 * 在主界面弹出提示窗口里显示的相关信息 
		 */		
		public static const SHOW_ALERT_TIPS:String = "AllEvent_SHOW_LOADING_TIPS";
		
		/**
		 * 隐藏主界面弹出提示窗口
		 */		
		public static const HIDE_ALERT_TIPS:String = "AllEvent_HIDE_LOADING_TIPS";
		
		/**
		 * 协议文件列表读取完毕 
		 */		
		public static const PROTO_LIST_UPDATE:String = "AllEvent_PROTO_LIST_UPDATE";
	}
}