#define SPARC_RET_VOID		0
#define SPARC_RET_STRUCT	1
#define SPARC_RET_FLOAT		2
#define SPARC_RET_DOUBLE	3
#define SPARC_RET_UINT8		4
#define SPARC_RET_SINT8		5
#define SPARC_RET_UINT16	6
#define SPARC_RET_SINT16	7
#define SPARC_RET_INT64		8
#define SPARC_RET_UINT32	9

/* These two are only used for V9.  */
#define SPARC_RET_SINT32	10
#define SPARC_RET_LDOUBLE	11

#define SPARC_FLAG_RET_MASK	15
#define SPARC_FLAG_RET_IN_MEM	32
#define SPARC_FLAG_FP_ARGS	64
