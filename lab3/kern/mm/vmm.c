#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>

/* 
  vmm设计包含两个部分：mm_struct（mm）和vma_struct（vma）。
  mm是用于管理具有相同页目录表（PDT）的连续虚拟内存区域的管理器。
  vma是一个连续的虚拟内存区域。
  在mm中，vma的结构包括一个线性链表和一个红黑树链表。
---------------
  mm相关的全局函数：
   - struct mm_struct * mm_create(void): 创建一个mm_struct对象。
   - void mm_destroy(struct mm_struct *mm): 销毁一个mm_struct对象。
   - int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr): 处理页错误。
---------------
  vma相关的全局函数：
   - struct vma_struct * vma_create(uintptr_t vm_start, uintptr_t vm_end, ...): 创建一个vma对象。
   - void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma): 插入一个vma到mm的链表中。
   - struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr): 查找指定地址的vma。
   
  局部函数：
   - inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next): 检查两个vma是否重叠。
---------------
  校验相关函数：
   - void check_vmm(void): 校验vmm的正确性。
   - void check_vma_struct(void): 校验vma_struct的正确性。
   - void check_pgfault(void): 校验页错误处理的正确性。
*/

// szx函数：print_vma和print_mm，输出vma和mm的结构信息。
void print_vma(char *name, struct vma_struct *vma) {
    cprintf("-- %s print_vma --\n", name);
    cprintf("   mm_struct: %p\n", vma->vm_mm);  // 打印vma所属的mm_struct地址
    cprintf("   vm_start,vm_end: %x,%x\n", vma->vm_start, vma->vm_end);  // 打印vma的起始和结束地址
    cprintf("   vm_flags: %x\n", vma->vm_flags);  // 打印vma的标志信息
    cprintf("   list_entry_t: %p\n", &vma->list_link);  // 打印vma链表节点的地址
}

void print_mm(char *name, struct mm_struct *mm) {
    cprintf("-- %s print_mm --\n", name);
    cprintf("   mmap_list: %p\n", &mm->mmap_list);  // 打印mm中的mmap链表头地址
    cprintf("   map_count: %d\n", mm->map_count);  // 打印mm中vma的数量
    list_entry_t *list = &mm->mmap_list;
    for (int i = 0; i < mm->map_count; i++) {
        list = list_next(list);  // 遍历mm中的每个vma
        print_vma(name, le2vma(list, list_link));  // 输出vma的结构信息
    }
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create - 分配并初始化一个mm_struct。
struct mm_struct * mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));  // 分配mm_struct内存

    if (mm != NULL) {
        list_init(&(mm->mmap_list));  // 初始化vma链表
        mm->mmap_cache = NULL;  // 初始化vma缓存
        mm->pgdir = NULL;  // 页目录表设为空
        mm->map_count = 0;  // 设置vma数量为0

        // 根据swap初始化状态初始化私有数据
        if (swap_init_ok) swap_init_mm(mm); 
        else mm->sm_priv = NULL;
    }
    return mm;  // 返回mm指针
}

// vma_create - 分配并初始化一个vma_struct（地址范围：vm_start~vm_end）。
struct vma_struct * vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));  // 分配vma_struct内存

    if (vma != NULL) {
        vma->vm_start = vm_start;  // 设置vma起始地址
        vma->vm_end = vm_end;  // 设置vma结束地址
        vma->vm_flags = vm_flags;  // 设置vma的标志信息
    }
    return vma;  // 返回vma指针
}

// find_vma - 查找包含给定地址的vma（vma->vm_start <= addr <= vma->vm_end）。
struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;  // 尝试从缓存中获取vma
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
            bool found = 0;
            list_entry_t *list = &(mm->mmap_list), *le = list;
            while ((le = list_next(le)) != list) {  // 遍历vma链表查找
                vma = le2vma(le, list_link);
                if (vma->vm_start <= addr && addr < vma->vm_end) {
                    found = 1;
                    break;
                }
            }
            if (!found) {
                vma = NULL;  // 如果未找到，返回NULL
            }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;  // 更新缓存
        }
    }
    return vma;
}

// check_vma_overlap - 检查vma1和vma2是否重叠。
static inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    assert(prev->vm_start < prev->vm_end);  // 确保前一个vma的起始地址小于结束地址
    assert(prev->vm_end <= next->vm_start);  // 确保前一个vma的结束地址小于等于下一个vma的起始地址
    assert(next->vm_start < next->vm_end);  // 确保下一个vma的起始地址小于结束地址
}

// insert_vma_struct - 将vma插入到mm的链表中
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);  // 确保vma的起始地址小于结束地址
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list) {  // 遍历链表寻找插入点
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start) {
            break;
        }
        le_prev = le;
    }

    le_next = list_next(le_prev);

    // 检查重叠情况
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;  // 关联vma到mm
    list_add_after(le_prev, &(vma->list_link));  // 插入vma到链表

    mm->map_count++;  // 增加vma计数
}


// mm_destroy - 释放 mm 结构体及其内部字段。
// 遍历 mm->mmap_list 链表，将每个 vma 的内存释放，然后释放 mm 自身的内存。
void mm_destroy(struct mm_struct *mm) {
    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
        list_del(le); // 从链表中移除当前 vma
        kfree(le2vma(le, list_link), sizeof(struct vma_struct));  // 释放 vma 结构体内存
    }
    kfree(mm, sizeof(struct mm_struct)); // 释放 mm 结构体内存
    mm = NULL; // 将 mm 设置为 NULL 防止悬挂指针
}

// vmm_init - 初始化虚拟内存管理，当前只是调用 check_vmm 函数检查虚拟内存管理是否正确
void vmm_init(void) {
    check_vmm();
}

// check_vmm - 检查虚拟内存管理是否正确，包含页表操作的正确性和虚拟内存区域的管理是否符合预期
static void check_vmm(void) {
    size_t nr_free_pages_store = nr_free_pages();
    check_vma_struct(); // 检查 vma 结构的正确性
    check_pgfault(); // 检查页错误处理的正确性

    // Sv39 三级页表多占用一个内存页，因此减去 1 进行对比
    nr_free_pages_store--;
    assert(nr_free_pages_store == nr_free_pages()); // 确保页数一致，验证内存释放和分配是否平衡

    cprintf("check_vmm() succeeded.\n");
}

// check_vma_struct - 检查 vma 结构的正确性，测试 vma 创建、插入及查找等功能是否正常
static void check_vma_struct(void) {
    size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    // 创建并插入一批 vma，按照起始地址顺序插入
    for (int i = step1; i >= 1; i--) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (int i = step1 + 1; i <= step2; i++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    // 遍历 mm->mmap_list 验证每个 vma 的地址和顺序是否正确
    list_entry_t *le = list_next(&(mm->mmap_list));
    for (int i = 1; i <= step2; i++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    // 验证特定地址是否能正确找到相应的 vma
    for (int i = 5; i <= 5 * step2; i += 5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i + 1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i + 2);
        assert(vma3 == NULL); // 超出范围的地址，返回 NULL
        struct vma_struct *vma4 = find_vma(mm, i + 3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i + 4);
        assert(vma5 == NULL);

        // 验证查找到的 vma 的起始和结束地址是否正确
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
    }

    // 验证地址低于第一个 vma 起始地址的查找结果为 NULL
    for (int i = 4; i >= 0; i--) {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
        if (vma_below_5 != NULL) {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm); // 释放 mm 及其内部的 vma

    assert(nr_free_pages_store == nr_free_pages()); // 确保内存释放与分配平衡

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - 检查页错误处理函数的正确性，模拟页错误并验证其处理结果
static void check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0); // 验证页目录项为空

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);
    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma); // 验证指定地址属于 vma 范围

    // 模拟对页内存的写操作，引发页错误
    int i, sum = 0;
    for (i = 0; i < 100; i++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i++) {
        sum -= *(char *)(addr + i);
    }
    assert(sum == 0); // 验证内存操作结果

    // 移除页并释放对应的物理内存页
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pgdir[0]));
    pgdir[0] = 0;

    mm->pgdir = NULL;
    mm_destroy(mm); // 释放 mm 结构体

    check_mm_struct = NULL;
    nr_free_pages_store--; // Sv39 页表多占一个内存页，因此减去 1

    assert(nr_free_pages_store == nr_free_pages()); // 验证内存平衡

    cprintf("check_pgfault() succeeded!\n");
}

// 页错误计数器
volatile unsigned int pgfault_num = 0;

/*
 * do_pgfault - 中断处理程序，用于处理页错误异常
 * @mm         : 控制结构体，管理使用相同页目录表（PDT）的虚拟内存区域（vma）
 * @error_code : 错误码，记录在trapframe->tf_err中，由x86硬件设置
 * @addr       : 引发内存访问异常的地址（CR2寄存器的内容）
 *
 * 调用图：trap --> trap_dispatch --> pgfault_handler --> do_pgfault
 * 处理器为ucore的do_pgfault函数提供了两项信息，以帮助诊断和恢复异常。
 *   (1) CR2寄存器的内容。处理器将导致异常的32位线性地址加载到CR2寄存器中。do_pgfault函数可以使用该地址找到相应的页目录和页表条目。
 *   (2) 内核栈上的错误码。页错误的错误码格式不同于其他异常。错误码向异常处理程序提供以下三项信息：
 *       -- P标志位（位0）表示异常是由于页不存在（0）还是访问权限冲突或保留位被使用（1）。
 *       -- W/R标志位（位1）表示导致异常的内存访问是读操作（0）还是写操作（1）。
 *       -- U/S标志位（位2）表示处理器在发生异常时是处于用户模式（1）还是内核模式（0）。
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL; // 初始化返回值，默认为无效参数错误
    // 尝试查找包含addr的vma（虚拟内存区域）
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++; // 增加页错误次数计数
    // 如果addr不在vma的范围内，则表示无效的地址
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("无效地址 %x，未能在vma中找到\n", addr);
        goto failed; // 跳转到失败处理
    }

    /* 如果满足以下条件之一
     *   (1) 对已存在地址的写操作，或者
     *   (2) 对不存在地址的写操作，且地址具有写权限，或者
     *   (3) 对不存在地址的读操作，且地址具有读权限
     * 则继续处理
     */
    uint32_t perm = PTE_U; // 设置页面权限为用户可访问
    if (vma->vm_flags & VM_WRITE) { // 如果vma具有写权限
        perm |= (PTE_R | PTE_W); // 增加读写权限
    }
    addr = ROUNDDOWN(addr, PGSIZE); // 将addr向下对齐到页面大小

    ret = -E_NO_MEM; // 设置返回值为内存不足

    pte_t *ptep = NULL;
    /*
    * 使用一些有用的宏和定义来辅助实现以下代码。
    * 一些有用的宏或函数：
    *   get_pte : 获取页表项的内核虚拟地址；若页表不存在则为其分配内存（第3个参数为1）
    *   pgdir_alloc_page : 调用alloc_page和page_insert函数分配一页内存，并建立物理地址与线性地址的映射
    * 一些有用的定义：
    *   VM_WRITE  : 如果vma->vm_flags & VM_WRITE == 1/0，则vma具有写权限/不具有写权限
    *   PTE_W           0x002                   // 页表/页目录项权限标志：可写
    *   PTE_U           0x004                   // 页表/页目录项权限标志：用户可访问
    * 变量：
    *   mm->pgdir : 这些vma的页目录表
    */

    // 获取页表项，如果页表不存在则创建页表
    ptep = get_pte(mm->pgdir, addr, 1);
    if (*ptep == 0) { // 如果页表项为空，则需要分配新页面
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配页面并映射
            cprintf("在do_pgfault中pgdir_alloc_page失败\n");
            goto failed;
        }
    } else {
        /*LAB3 练习3：请补充以下函数逻辑
        *  如果pte是一个交换条目，我们应该从磁盘加载数据，并映射物理地址与逻辑地址。
        *  这样，交换管理器可以记录该页面的访问情况。
        *
        *  使用一些有用的宏和定义来辅助代码实现（非常有帮助）：
        *    swap_in(mm, addr, &page) : 分配一页内存，根据PTE中的交换条目地址找到磁盘页的地址，将磁盘页内容读入内存页
        *    page_insert ： 建立页面物理地址与线性地址的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) { // 判断交换机制是否初始化
            struct Page *page = NULL;
            // 使用swap_in函数根据mm和addr将磁盘页内容加载到内存页
            // 并且将物理地址和逻辑地址建立映射
            // 将该页面设置为可交换
            swap_in(mm,addr,&page);//换入缺失的页
            page_insert(mm->pgdir,page,addr,perm);//页插入到管理的页表中
            swap_map_swappable(mm,addr,page,1);//设置页面可交换
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }

   ret = 0; // 成功完成页错误处理，返回0
failed:
    return ret; // 返回处理结果
}
