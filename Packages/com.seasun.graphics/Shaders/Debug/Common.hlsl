#ifndef __COMMON_DEBUG__
#define __COMMON_DEBUG__

inline float random(float3 st)
{
	return frac(sin(dot(floor(st.xyz), float3(12.9898, 78.233, 123.3355))) * 43758.5453123);
}

inline bool MatrixEqual(float4x4 sourceMatrix, float4x4 targetMatrix)
{
	float source = sourceMatrix._11 + sourceMatrix._12 + sourceMatrix._13 + sourceMatrix._14;
	source += sourceMatrix._21 + sourceMatrix._22 + sourceMatrix._23 + sourceMatrix._24;
	source += sourceMatrix._31 + sourceMatrix._32 + sourceMatrix._33 + sourceMatrix._34;
	source += sourceMatrix._41 + sourceMatrix._42 + sourceMatrix._43 + sourceMatrix._44;
	float target = targetMatrix._11 + targetMatrix._12 + targetMatrix._13 + targetMatrix._14;
	target += targetMatrix._21 + targetMatrix._22 + targetMatrix._23 + targetMatrix._24;
	target += targetMatrix._31 + targetMatrix._32 + targetMatrix._33 + targetMatrix._34;
	target += targetMatrix._41 + targetMatrix._42 + targetMatrix._43 + targetMatrix._44;

	if (source == target)
	{
		return true;
	}

	return false;
}

inline float MatrixValue(float4x4 sourceMatrix)
{
	float source = sourceMatrix._11 + sourceMatrix._12 + sourceMatrix._13 + sourceMatrix._14;
	source += sourceMatrix._21 + sourceMatrix._22 + sourceMatrix._23 + sourceMatrix._24;
	source += sourceMatrix._31 + sourceMatrix._32 + sourceMatrix._33 + sourceMatrix._34;
	source += sourceMatrix._41 + sourceMatrix._42 + sourceMatrix._43 + sourceMatrix._44;

	return source;
}

#endif