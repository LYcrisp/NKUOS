#kernel_thread_entry 的函数。
#这个函数的作用是作为内核线程的入口点，执行一些初始化操作后，跳转到实际的内核线程函数，并在内核线程函数返回后调用 do_exit 函数结束当前线程。
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1            # 将寄存器s1的值移动到寄存器a0中
	jalr s0                # 跳转到寄存器s0中存储的地址，并将返回地址存储到ra寄存器中

	jal do_exit            # 调用do_exit函数，结束当前线程

#在文件proc中kernel_thread函数设置了s0 寄存器保存函数指针，s1 寄存器保存函数参数