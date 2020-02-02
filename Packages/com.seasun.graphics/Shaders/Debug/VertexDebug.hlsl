#ifndef __VERTEX_DEBUG__
#define __VERTEX_DEBUG__

/*
		使用方法：
			*核心使用Geomerty Shader进行调试，需要target 4.0以上
			https://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			*在任意的GameObject中挂上脚本VertexDebug.cs
			*按照以下步骤添加参数到shader中
			*运行游戏，按住Alt，然后点击需要调试的顶点点，之后会输出内容

		HLSLPROGRAM
			#pragma vertex vert
			//#pragma fragment frag
			//1、VertexDebug: 在#pragma fragment xxx后前添加，同时注释掉此行
			#pragma geometry geom		//关闭调试注释此行
			#pragma fragment debugFrag	//关闭调试注释此行
			#define VERTEX_DEBUG_ENABLE	//关闭调试注释此行
			#define VERTEX_DEBUG_INDEX 0 //选取的顶点所在三角形index(0,1,2,3-表示全部检测)

			#pragma target 4.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				half2 texcoord  : TEXCOORD0;
			};

			//2、VertexDebug: 修改Vert函数分布传入4个参数：返回类型，函数名，数据结构体名称，结构体实例
			VERTEX_DEBUG_FUN(v2f, vert, appdata_t, IN)
			//v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				
				//3、VertexDebug: 初始化，传递投影后的坐标值
				VERTEX_DEBUG_INIT(OUT.vertex)

				//4、VertexDebug: 根据屏幕采点，自动选择顶点(可选，也可以自己填写)
				if (VERTEX_DEBUG_AUTO_JUDGE)
				{
					//5、VertexDebug: 输入想要调试输出的变量，支持xy2个参数
					VERTEX_DEBUG_VALUE(xy, OUT.vertex.xy)
				}

				OUT.texcoord = IN.texcoord;

				//6、VertexDebug: 将原始输出结构放入宏中
				VERTEX_DEBUG_OUTPUT(OUT)
				//return OUT;
			}

			uniform sampler2D _OCCameraDepthTexture;

			fixed4 frag(v2f IN) : SV_Target
			{
				float depth = tex2D(_OCCameraDepthTexture, IN.texcoord).r;
				depth = Linear01Depth(depth);

				return fixed4(depth, 0, 0, 1);
			}
		ENDHLSL
*/

#if defined(VERTEX_DEBUG_ENABLE) 
	#include "Common.hlsl"

	#define JUDGE_INIT_VALUE 0
	#define VERTEX_DEBUG_DRAW_X 0.1
	#define VERTEX_DEBUG_DRAW_Y 0.7
	#define VERTEX_DEBUG_DRAW_SIZE 0.025

	struct VertexDebutV2F
	{
		float4 vertex : SV_POSITION;
		float2 value : TEXCOORD0;
	};

	#define VERTEX_DEBUG_FUN(RETURN, FUNNAME, STRUCTNAME, VARNAME) VertexDebutV2F FUNNAME(STRUCTNAME VARNAME)

	#define VERTEX_DEBUG_INIT(proVertex) \
		VertexDebutV2F debugOUT; \
		debugOUT.vertex = proVertex; \
		debugOUT.value = JUDGE_INIT_VALUE; \
	
	#define VERTEX_DEBUG_VALUE(index, val) debugOUT.value.index = val;
	#define VERTEX_DEBUG_OUTPUT(value) return debugOUT;

	uniform float4 _VertexDebugParams;
	#define VERTEX_DEBUG_AUTO_JUDGE distance((ComputeScreenPos(debugOUT.vertex).xy / ComputeScreenPos(debugOUT.vertex).w) * _VertexDebugParams.zw, _VertexDebugParams.xy) < 5

	#define VERTEX_DEBUG_VERTEX_NAME vertex
	#define STRUCT_NAME VertexDebutV2F
	#define STREAM_NAME LineStream
	static int GEOMERTY_LINE_SIZE = 2;

	static int GEOMERTY_OUTPUT_MAX = int(1024 / (2 + 4));
	#if UNITY_REVERSED_Z
	static float Z_DEPTH_MAX = 1;
	#else
	static float Z_DEPTH_MAX = -1;
	#endif

	#if defined(VERTEX_DEBUG_DRAW_X)
	static float DRAW_START_X = VERTEX_DEBUG_DRAW_X;
	#else
	static float DRAW_START_X = 0.1;
	#endif

	#if defined(VERTEX_DEBUG_DRAW_Y)
	static float DRAW_START_Y = VERTEX_DEBUG_DRAW_Y;
	#else
	static float DRAW_START_Y = 0.7;
	#endif

	#if defined(VERTEX_DEBUG_DRAW_SIZE)
	static float DRAW_SIZE = VERTEX_DEBUG_DRAW_SIZE;
	#else
	static float DRAW_SIZE = 0.05;
	#endif

	inline void DrawLine(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float4 startPoint, in float4 endPoint)
	{
	#if !UNITY_UV_STARTS_AT_TOP
		startPoint.y *= -1;
		endPoint.y *= -1;
	#endif
		newPoint.VERTEX_DEBUG_VERTEX_NAME = startPoint;
		newPoint.value = float2(1, 0);
		tristream.Append(newPoint);
		newPoint.VERTEX_DEBUG_VERTEX_NAME = endPoint;
		newPoint.value = float2(1, 0);
		tristream.Append(newPoint);
		tristream.RestartStrip();
	}

	inline void DrawLine(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float2 endPoint)
	{ 
	#if !UNITY_UV_STARTS_AT_TOP
		startPoint.y *= -1;
		endPoint.y *= -1;
	#endif
		newPoint.VERTEX_DEBUG_VERTEX_NAME = float4(startPoint, Z_DEPTH_MAX, 1);
		newPoint.value = float2(1, 0);
		tristream.Append(newPoint);
		newPoint.VERTEX_DEBUG_VERTEX_NAME = float4(endPoint, Z_DEPTH_MAX, 1);
		newPoint.value = float2(1, 0);
		tristream.Append(newPoint);
		tristream.RestartStrip();
	}

	inline void DrawNumberError(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
	}

	inline void DrawNumber0(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 4) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 4;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber1(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 1) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 1;
			DrawLine(tristream, newPoint, float2(startPoint.x + size / 2, startPoint.y), float2(startPoint.x + size / 2, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber2(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 5) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 5;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber3(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 4) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 4;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber4(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 3) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 3;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3 / 2));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber5(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 5) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 5;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3 / 2));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber6(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 4) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 4;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber7(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 2) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 2;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber8(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 5) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 5;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3), float2(startPoint.x + size, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber9(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 4) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 4;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x + size, startPoint.y));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y), float2(startPoint.x, startPoint.y + size * 3 / 2));
			DrawLine(tristream, newPoint, float2(startPoint.x + size, startPoint.y), float2(startPoint.x + size, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumberDot(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 1) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 1;
			DrawLine(tristream, newPoint, float2(startPoint.x + size / 2, startPoint.y + size * 3 - size * 3 / 5), float2(startPoint.x + size / 2, startPoint.y + size * 3));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumberNegative(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, inout int outputSize)
	{
		if ((outputSize + GEOMERTY_LINE_SIZE * 1) < GEOMERTY_OUTPUT_MAX)
		{
			outputSize += GEOMERTY_LINE_SIZE * 1;
			DrawLine(tristream, newPoint, float2(startPoint.x, startPoint.y + size * 3 / 2), float2(startPoint.x + size, startPoint.y + size * 3 / 2));
		}
		else
		{
			DrawNumberError(tristream, newPoint, startPoint, size, outputSize);
		}
	}

	inline void DrawNumber(inout STREAM_NAME<STRUCT_NAME> tristream, in STRUCT_NAME newPoint, in float2 startPoint, in float size, in int value, inout int outputSize)
	{
		switch (value)
		{
		case 0:
			DrawNumber0(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 1:
			DrawNumber1(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 2:
			DrawNumber2(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 3:
			DrawNumber3(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 4:
			DrawNumber4(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 5:
			DrawNumber5(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 6:
			DrawNumber6(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 7:
			DrawNumber7(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 8:
			DrawNumber8(tristream, newPoint, startPoint, size, outputSize);
			break;
		case 9:
			DrawNumber9(tristream, newPoint, startPoint, size, outputSize);
			break;
		}
	}

	inline void DrawInformation(in STRUCT_NAME srcPoint, inout STREAM_NAME<STRUCT_NAME> tristream, in float2 start, in float srcValue, inout int outputSize)
	{
		float4 startPoint = float4(0, 0, 1, 1);
		float4 endPoint = float4(0.1, 0, 1, 1);

		STRUCT_NAME newPoint = srcPoint;

		float size = DRAW_SIZE;

		float4 vertexPoint = srcPoint.VERTEX_DEBUG_VERTEX_NAME;
#if !UNITY_UV_STARTS_AT_TOP
		vertexPoint.y *= -1;
#endif
		DrawLine(tristream, newPoint, vertexPoint, float4(start.x - size / 2, start.y + size * 3 / 2, Z_DEPTH_MAX, 1));
		outputSize += 2;

		float targetValue = abs(srcValue);
		if (targetValue < 100000000)
		{
			if (srcValue < 0)
			{
				DrawNumberNegative(tristream, newPoint, start, size, outputSize);
				start.x += size + size / 4;
			}
			int integerSize = 1;
			int value = 10;
			for (; integerSize < 8; ++integerSize)
			{
				if (targetValue < value)
				{
					break;
				}
				value *= 10;
			}
			int decimalSize = max((9 - integerSize), 1);
			value = floor(targetValue * pow(10, decimalSize));
			int maxInteger = 0;

			int length = 0;
			while (true)
			{
				if (value < maxInteger)
				{
					break;
				}
				else
				{
					if (maxInteger == 0)
					{
						maxInteger = 10;
					}
					else
					{
						maxInteger *= 10;
					}
					length++;
				}
			}

			int index = length;
			int outValue = 0;
			if (index <= decimalSize)
			{
				DrawNumber0(tristream, newPoint, start, size, outputSize);
				start.x += size + size / 4;
				DrawNumberDot(tristream, newPoint, start, size, outputSize);
				start.x += size + size / 4;
				for (int i = decimalSize; i > index; --i)
				{
					DrawNumber0(tristream, newPoint, start, size, outputSize);
					start.x += size + size / 4;
				}
			}
			do
			{
				maxInteger = maxInteger / 10;
				outValue = value / maxInteger;
				value -= outValue * maxInteger;
				DrawNumber(tristream, newPoint, start, size, outValue, outputSize);
				start.x += size + size / 4;
				index--;
				if (index == decimalSize)
				{
					DrawNumberDot(tristream, newPoint, start, size, outputSize);
					start.x += size + size / 4;
				}
			} while (index > 0);
		}
	}

	inline float2 RandomScreenPos(float3 pos)
	{
		float2 res = 0;

		float rand = random(pos);
		float length = 2 - 11 * (DRAW_SIZE + DRAW_SIZE / 4);
		res.x = max(-0.9, length * rand - 1);
		
		rand = random(pos.zxy);
		res.y = max(min(1 - DRAW_SIZE * 10, 2 * rand - 1), -0.9);
		return res;
	}

	[maxvertexcount(GEOMERTY_OUTPUT_MAX)]
	void geom(triangle STRUCT_NAME input[3], inout STREAM_NAME<STRUCT_NAME> tristream)
	{
		STRUCT_NAME p = input[0];
		p.value = 0;
		tristream.Append(p);
		p = input[1];
		p.value = 0;
		tristream.Append(p);
		p = input[2];
		p.value = 0;
		tristream.Append(p);
		tristream.RestartStrip();

		int outputSize = 3;
		float2 start = float2(DRAW_START_X, -DRAW_START_Y);
		float2 addValue = 0;
		bool excute = true;
		if (VERTEX_DEBUG_INDEX == 0 || VERTEX_DEBUG_INDEX == 3)
		{
			if (any(input[0].value - JUDGE_INIT_VALUE))
			{
				excute = false;
				addValue = input[0].value;
				if (abs(addValue.x) < 0)
				{
					addValue.x *= 1000000;
				}
				if (abs(addValue.y) < 0)
				{
					addValue.y *= 1000000;
				}
				start = RandomScreenPos(input[0].vertex.xyz * 10000 + float3(addValue, 1));

				DrawInformation(input[0], tristream, start, input[0].value.x, outputSize);
				start.y += DRAW_SIZE * 3.5;

				DrawInformation(input[0], tristream, start, input[0].value.y, outputSize);
				start.y += DRAW_SIZE * 3.5;
			}
		}
		if (excute && (VERTEX_DEBUG_INDEX == 1 || VERTEX_DEBUG_INDEX == 3))
		{
			if (any(input[1].value - JUDGE_INIT_VALUE))
			{
				excute = false;
				addValue = input[1].value;
				if (abs(addValue.x) < 0)
				{
					addValue.x *= 1000000;
				}
				if (abs(addValue.y) < 0)
				{
					addValue.y *= 1000000;
				}
				start = RandomScreenPos(input[1].vertex.xyz * 10000 + float3(addValue, 1));

				DrawInformation(input[1], tristream, start, input[1].value.x, outputSize);
				start.y += DRAW_SIZE * 3.5;

				DrawInformation(input[1], tristream, start, input[1].value.y, outputSize);
				start.y += DRAW_SIZE * 3.5;
			}
		}
		
		if (excute)
		{
			if (any(input[2].value - JUDGE_INIT_VALUE))
			{
				addValue = input[2].value;
				if (abs(addValue.x) < 0)
				{
					addValue.x *= 1000000;
				}
				if (abs(addValue.y) < 0)
				{
					addValue.y *= 1000000;
				}
				start = RandomScreenPos(input[2].vertex.xyz * 10000 + float3(addValue, 1));

				DrawInformation(input[2], tristream, start, input[2].value.x, outputSize);
				start.y += DRAW_SIZE * 3.5;

				DrawInformation(input[2], tristream, start, input[2].value.y, outputSize);
				start.y += DRAW_SIZE * 3.5;
			}
		}
	}

	float4 debugFrag(VertexDebutV2F IN) : SV_Target
	{
		return float4(IN.value.xy, 0, 1);
	}
#else
	#define VERTEX_DEBUG_FUN(RETURN, FUNNAME, STRUCTNAME, VARNAME) RETURN FUNNAME(STRUCTNAME VARNAME)
	#define VERTEX_DEBUG_INIT(proVertex)
	#define VERTEX_DEBUG_VALUE(index, val) 
	#define VERTEX_DEBUG_OUTPUT(value) return value;
	#define VERTEX_DEBUG_AUTO_JUDGE false
#endif

#endif