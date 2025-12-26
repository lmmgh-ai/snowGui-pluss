nativefs.newFile 新建文件
nativefs.newFileData 新建数据文件
nativefs.mount 挂载(锁定文件)
nativefs.unmount 关闭挂载
nativefs.read 读取文件-路径 字节
nativefs.write 写入-路径 数据 字节
nativefs.append 追加数据-路径 数据 字节
nativefs.lines 迭代行数据-路径 <回调迭代器>
nativefs.load 加载lua文件不执行 mode选择"bt"或纯文本
nativefs.getWorkingDirectory 获取工作路径
nativefs.getDirectoryItems 获取路径文件
nativefs.getInfo 获取文件信息
nativefs.createDirectory 创建文件夹 name
nativefs.remove 删除文件 name
--以下不通用
nativefs.getDirectoryItemsInfo--获取目录项列表
nativefs.getDriveList--获取驱动器
nativefs.setWorkingDirectory --更改工作目



File
nativefs.newFile returns a object that provides these functions:File
文件对象
File:open-mode-r读取 w写入 a追加 c关闭
File:close 关闭文件
File:read <mode>-读取字节/<文件类型,字节数>-data,string 如果用于多线程使用data 
File:write 写入数据,写入字节
File:lines 返回文件行 迭代器
File:isOpen 文件是否打开
File:isEOF 是否是文件末尾
File:getFilename 返回文件名
File:getMode 获取文件当前模式
File:getBuffer 获取文件缓冲区模式
File:setBuffer 设置文件缓冲区-模式,大小 none没有缓冲 line线性缓冲 full完全缓冲 满之前不写入硬盘
File:getSize 获取文件大小 字节
File:seek 在文件中查找位置 number 文件位置
File:tell 返回文件位置
File:flush 强制缓冲区写入磁盘
File:type 获取对象类型
File:typeOf
File:release 清除对象引用
Function names in this list are links to their LÖVE counterparts. is designed to work the same way as LÖVE's objects.FileFileFile



