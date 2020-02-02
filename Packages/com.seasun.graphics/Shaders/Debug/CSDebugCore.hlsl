#ifndef __CS_DEBUG_CORE__
#define __CS_DEBUG_CORE__

#include "Common.hlsl"

#if defined(CS_DEBUG)
	#define DEBUG_DEF(x) RWStructuredBuffer<float> x;
	#define DEBUG_VALUE(x, value) x[0] = value;
#else
	#define DEBUG_DEF(x)
	#define DEBUG_VALUE(x, value)
#endif

#endif