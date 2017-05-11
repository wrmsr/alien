#ifndef BASE_GLOBAL_H
#define BASE_GLOBAL_H

#include <QtCore/qglobal.h>

#ifndef BASE_STATIC
	#ifdef BASE_LIB
	# define BASE_EXPORT Q_DECL_EXPORT
	#else
	# define BASE_EXPORT Q_DECL_IMPORT
	#endif
#else
	# define BASE_EXPORT
#endif

#endif // BASE_GLOBAL_H
