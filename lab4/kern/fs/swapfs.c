#include <swap.h> // 包含交换相关头文件
#include <swapfs.h> // 包含交换文件系统相关头文件
#include <mmu.h> // 包含内存管理单元相关头文件
#include <fs.h> // 包含文件系统相关头文件
#include <ide.h> // 包含IDE设备相关头文件
#include <pmm.h> // 包含物理内存管理相关头文件
#include <assert.h> // 包含断言相关头文件

void
swapfs_init(void) { // 初始化交换文件系统
    static_assert((PGSIZE % SECTSIZE) == 0); // 静态断言，确保页面大小是扇区大小的整数倍
    if (!ide_device_valid(SWAP_DEV_NO)) { // 检查交换设备是否有效
        panic("swap fs isn't available.\n"); // 如果无效，则触发内核恐慌
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE); // 计算最大交换偏移量
}

int
swapfs_read(swap_entry_t entry, struct Page *page) { // 从交换文件系统读取页面
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE读取函数读取页面数据
}

int
swapfs_write(swap_entry_t entry, struct Page *page) { // 向交换文件系统写入页面
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT); // 调用IDE写入函数写入页面数据
}
