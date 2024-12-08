#include <swap.h>
#include <swapfs.h>
#include <swap_fifo.h>
#include <stdio.h>
#include <string.h>
#include <memlayout.h>
#include <pmm.h>
#include <mmu.h>

// the valid vaddr for check is between 0~CHECK_VALID_VADDR-1
#define CHECK_VALID_VIR_PAGE_NUM 5
#define BEING_CHECK_VALID_VADDR 0X1000
#define CHECK_VALID_VADDR (CHECK_VALID_VIR_PAGE_NUM+1)*0x1000
// the max number of valid physical page for check
#define CHECK_VALID_PHY_PAGE_NUM 4
// the max access seq number
#define MAX_SEQ_NO 10

static struct swap_manager *sm;
size_t max_swap_offset;

volatile int swap_init_ok = 0;

unsigned int swap_page[CHECK_VALID_VIR_PAGE_NUM];

unsigned int swap_in_seq_no[MAX_SEQ_NO],swap_out_seq_no[MAX_SEQ_NO];

static void check_swap(void);

// swap_init - 初始化交换管理器
// 返回值：初始化成功返回0，失败返回非0
int
swap_init(void)
{
     swapfs_init(); // 初始化交换文件系统

     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo; // 使用FIFO算法作为交换管理器
     int r = sm->init(); // 初始化交换管理器
     
     if (r == 0)
     {
          swap_init_ok = 1;
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap(); // 检查交换功能
     }

     return r;
}

// swap_init_mm - 初始化内存管理结构
// 参数：mm - 内存管理结构指针
// 返回值：初始化成功返回0，失败返回非0
int
swap_init_mm(struct mm_struct *mm)
{
     return sm->init_mm(mm);
}

// swap_tick_event - 处理时钟事件
// 参数：mm - 内存管理结构指针
// 返回值：处理成功返回0，失败返回非0
int
swap_tick_event(struct mm_struct *mm)
{
     return sm->tick_event(mm);
}

// swap_map_swappable - 将页面标记为可交换
// 参数：mm - 内存管理结构指针，addr - 虚拟地址，page - 页面指针，swap_in - 是否是交换入
// 返回值：标记成功返回0，失败返回非0
int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
}

// swap_set_unswappable - 将页面标记为不可交换
// 参数：mm - 内存管理结构指针，addr - 虚拟地址
// 返回值：标记成功返回0，失败返回非0
int
swap_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
     return sm->set_unswappable(mm, addr);
}

volatile unsigned int swap_out_num=0;

// swap_out - 交换出页面
// 参数：mm - 内存管理结构指针，n - 交换出页面数量，in_tick - 是否在时钟中断中
// 返回值：实际交换出的页面数量
int
swap_out(struct mm_struct *mm, int n, int in_tick)
{
     int i;
     for (i = 0; i != n; ++ i)
     {
          uintptr_t v;
          //struct Page **ptr_page=NULL;
          struct Page *page;
          // cprintf("i %d, SWAP: call swap_out_victim\n",i);
          int r = sm->swap_out_victim(mm, &page, in_tick); // 选择要交换出的页面
          if (r != 0) {
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
                  break;
          }          
          //assert(!PageReserved(page));

          //cprintf("SWAP: choose victim page 0x%08x\n", page);
          
          v=page->pra_vaddr; 
          pte_t *ptep = get_pte(mm->pgdir, v, 0); // 获取页表项指针
          assert((*ptep & PTE_V) != 0);

          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) { // 将页面写入交换文件系统
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8; // 更新页表项
                    free_page(page); // 释放页面
          }
          
          tlb_invalidate(mm->pgdir, v); // 刷新TLB
     }
     return i;
}

// swap_in - 交换入页面
// 参数：mm - 内存管理结构指针，addr - 虚拟地址，ptr_result - 返回页面指针
// 返回值：交换入成功返回0，失败返回非0
int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
{
     struct Page *result = alloc_page(); // 分配新页面
     assert(result!=NULL);

     pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 获取页表项指针
     // cprintf("SWAP: load ptep %x swap entry %d to vaddr 0x%08x, page %x, No %d\n", ptep, (*ptep)>>8, addr, result, (result-pages));
    
     int r;
     if ((r = swapfs_read((*ptep), result)) != 0) // 从交换文件系统读取页面
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
     *ptr_result=result;
     return 0;
}

// check_content_set - 设置检查内容
static inline void
check_content_set(void)
{
     *(unsigned char *)0x1000 = 0x0a;
     assert(pgfault_num==1);
     *(unsigned char *)0x1010 = 0x0a;
     assert(pgfault_num==1);
     *(unsigned char *)0x2000 = 0x0b;
     assert(pgfault_num==2);
     *(unsigned char *)0x2010 = 0x0b;
     assert(pgfault_num==2);
     *(unsigned char *)0x3000 = 0x0c;
     assert(pgfault_num==3);
     *(unsigned char *)0x3010 = 0x0c;
     assert(pgfault_num==3);
     *(unsigned char *)0x4000 = 0x0d;
     assert(pgfault_num==4);
     *(unsigned char *)0x4010 = 0x0d;
     assert(pgfault_num==4);
}

// check_content_access - 检查内容访问
// 返回值：检查成功返回0，失败返回非0
static inline int
check_content_access(void)
{
    int ret = sm->check_swap();
    return ret;
}

struct Page * check_rp[CHECK_VALID_PHY_PAGE_NUM];
pte_t * check_ptep[CHECK_VALID_PHY_PAGE_NUM];
unsigned int check_swap_addr[CHECK_VALID_VIR_PAGE_NUM];

extern free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// check_swap - 检查交换功能
static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
     }
     assert(total == nr_free_pages());
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create(); // 创建内存管理结构
     assert(mm != NULL);

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
     assert(pgdir[0] == 0);

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ); // 创建虚拟内存区域
     assert(vma != NULL);

     insert_vma_struct(mm, vma); // 插入虚拟内存区域

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1); // 获取页表项指针
     assert(temp_ptep!= NULL);
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
          check_rp[i] = alloc_page(); // 分配页面
          assert(check_rp[i] != NULL );
          assert(!PageProperty(check_rp[i]));
     }
     list_entry_t free_list_store = free_list;
     list_init(&free_list); // 初始化空闲列表
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1); // 释放页面
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
     
     cprintf("set up init env for check_swap begin!\n");
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
     
     check_content_set(); // 设置检查内容
     assert( nr_free == 0);         
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0); // 获取页表项指针
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access(); // 检查内容访问
     assert(ret==0);

     nr_free = nr_free_store;
     free_list = free_list_store;

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1); // 释放页面
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm); // 销毁内存管理结构

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
     free_page(pde2page(pd0[0]));
     free_page(pde2page(pd1[0]));
     pgdir[0] = 0;
     flush_tlb(); // 刷新TLB

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
     }
     assert(count==0);
     assert(total==0);

     cprintf("check_swap() succeeded!\n");
}
