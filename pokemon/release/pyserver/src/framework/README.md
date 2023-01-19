gevent提供了'Queue', 'PriorityQueue', 'LifoQueue', 'JoinableQueue' 四种队列

所有队列类型都是安全的(synchronized queue) ,数据推入和提取无需访问保护

LifoQueue - 后进先出队列，同数据堆栈结构
JoinableQueue -  增加join，所有数据提取task_done完毕后join解除阻塞 
PriorityQueue - 优先级队列，提取根据置入时的优先级别
Queue - 超类消息队列，提供同步数据置入和提取功能，其他队列均从Queue派生
