#include <swap.h>
#include <swapfs.h>
#include <swap_fifo.h>
#include <stdio.h>
#include <string.h>
#include <memlayout.h>
#include <pmm.h>
#include <mmu.h>
#include <default_pmm.h>
#include <kdebug.h>

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

// 初始化交换管理器
// 参数：无
// 返回值：初始化结果，0表示成功，非0表示失败
int
swap_init(void)
{
     swapfs_init(); // 初始化交换文件系统

     // 检查最大交换偏移量是否合法
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

// 初始化内存管理结构
// 参数：mm - 内存管理结构指针
// 返回值：初始化结果，0表示成功，非0表示失败
int
swap_init_mm(struct mm_struct *mm)
{
     return sm->init_mm(mm);
}

// 处理时钟事件
// 参数：mm - 内存管理结构指针
// 返回值：处理结果，0表示成功，非0表示失败
int
swap_tick_event(struct mm_struct *mm)
{
     return sm->tick_event(mm);
}

// 将页面标记为可交换
// 参数：mm - 内存管理结构指针，addr - 虚拟地址，page - 页面指针，swap_in - 是否为换入操作
// 返回值：操作结果，0表示成功，非0表示失败
int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
}

// 将页面标记为不可交换
// 参数：mm - 内存管理结构指针，addr - 虚拟地址
// 返回值：操作结果，0表示成功，非0表示失败
int
swap_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
     return sm->set_unswappable(mm, addr);
}

volatile unsigned int swap_out_num=0;

// 换出页面
// 参数：mm - 内存管理结构指针，n - 换出页面数量，in_tick - 是否在时钟中断中
// 返回值：实际换出的页面数量
int
swap_out(struct mm_struct *mm, int n, int in_tick)
{
     int i;
     for (i = 0; i != n; ++ i)
     {
          uintptr_t v;
          struct Page *page;
          int r = sm->swap_out_victim(mm, &page, in_tick); // 选择换出页面
          if (r != 0) {
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
                  break;
          }          
          
          v=page->pra_vaddr; 
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
          assert((*ptep & PTE_V) != 0);

          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) { // 将页面写入交换文件
                    cprintf("SWAP: failed to save\n");
                    sm->map_swappable(mm, v, page, 0);
                    continue;
          }
          else {
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
                    free_page(page); // 释放页面
          }
          
          tlb_invalidate(mm->pgdir, v); // 刷新TLB
     }
     return i;
}

// 换入页面
// 参数：mm - 内存管理结构指针，addr - 虚拟地址，ptr_result - 存储换入页面的指针
// 返回值：操作结果，0表示成功，非0表示失败
int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result)
{
     struct Page *result = alloc_page();
     assert(result!=NULL);

     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
    
     int r;
     if ((r = swapfs_read((*ptep), result)) != 0) // 从交换文件读取页面
     {
        assert(r!=0);
     }
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
     *ptr_result=result;
     return 0;
}

// 设置检查内容
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

// 检查内容访问
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

// 检查交换功能
static void
check_swap(void)
{
    // 备份内存环境
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
        count ++, total += p->property;
     }
     assert(total == nr_free_pages());
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
     
     // 设置物理页面环境
     struct mm_struct *mm = mm_create();
     assert(mm != NULL);

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
     assert(pgdir[0] == 0);

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
     assert(vma != NULL);

     insert_vma_struct(mm, vma);

     // 设置临时页表
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
     assert(temp_ptep!= NULL);
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
          check_rp[i] = alloc_page();
          assert(check_rp[i] != NULL );
          assert(!PageProperty(check_rp[i]));
     }
     list_entry_t free_list_store = free_list;
     list_init(&free_list);
     assert(list_empty(&free_list));
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
     
     cprintf("set up init env for check_swap begin!\n");
     // 设置初始虚拟页面与物理页面的映射关系
     
     pgfault_num=0;
     
     check_content_set();
     assert( nr_free == 0);         
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
         assert(check_ptep[i] != NULL);
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
     // 访问虚拟页面以测试页面替换算法
     ret=check_content_access();
     assert(ret==0);

     nr_free = nr_free_store;
     free_list = free_list_store;

     // 恢复内核内存环境
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
     } 

     mm->pgdir = NULL;
     mm_destroy(mm);
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
     free_page(pde2page(pd0[0]));
     free_page(pde2page(pd1[0]));
     pgdir[0] = 0;
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
     }
     assert(count==0);
     assert(total==0);

     cprintf("check_swap() succeeded!\n");
}
