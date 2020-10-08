#ifndef _COLUMNS_H
#define _COLUMNS_H

/**
 * Setting -DMAXCOLUMNS is the same as -DMAXCOLUMNS=1
 * Default number of columns is 8
 */
#ifndef MAXCOLUMNS
   #define __MAXCOLUMNS 8
   #warning "Default max columns 8"
#else
   #define __MAXCOLUMNS MAXCOLUMNS
#endif

#ifdef NDEBUG
   #error "NDEBUG is set which means assert() won't work and we don't want this ;)"
#endif

#define __PAGER "\n"
#define __MAXSLOTS 4096
#define __MAXPAGES __MAXSLOTS // must support at least one slot per page
#define __MAXWIDTH 4096

/**
 * calloc() wrapper
 */
#define _CALLOC(x,y,z) \
{\
   x = calloc(y,z);\
   assert(x);\
}

#define _ISEVEN(x) x & 1 ? 0 : 1

/**
 * Useful for adjusting columns and fill buffer gaps 
 */
static char outter_space[4096*2];

/**
 * Mains struct. CL stands for 'columns'
 */
typedef struct __cldata
{
   /**
    * columns width. See Makefile for __MAXCOLUMNS
    */
   unsigned int column_width[__MAXCOLUMNS];

   /**
    * Page delimiter
    */
   unsigned int page_lines;


   /**
    * Number of columns 
    * to be displayed. Defined by user.
    */
   unsigned int columns;

   /**
    * Buffer index - same as number of lines 
    * but starting from 0. e.g., 0 to 10 = 17 lines
    */
   int buf_index_range;

   /**
    * Buffers holder
    */
   struct {

      /**
       * Read-only number of tokens this buffer has
       */
      unsigned int num_tokens;

      /**
       * Column's buffer width
       */
      unsigned int width;

      /**
       * Tokens oddity
       */
      unsigned int is_even;

      /**
       * Length of buf_prev 
       */
      size_t bufsiz;


      unsigned int init_parse;
      /**
       * @brief Original buffer ptr
       */
      char *o_buf;

      /**
       * @brief main buffer
       */
      char *buf; // advertise list

   }buf_st[__MAXSLOTS];

}cldata_t;



#endif
