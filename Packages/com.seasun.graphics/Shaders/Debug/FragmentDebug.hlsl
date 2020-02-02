#ifndef __FRAGMENT_DEBUG__
#define __FRAGMENT_DEBUG__

/*
		使用方法：
			*核心使用MRT进行调试，因此不支持延迟渲染中进行调试，支持情况参见
			https://docs.unity3d.com/Manual/RenderTech-DeferredShading.html
			*需要使用定制版本的URP
			*在PlayerSetting中添加宏FRAGMENG_DEBUG
			*在任意的GameObject中挂上脚本FragmentDebug.cs
			*按照以下步骤添加参数到shader中
			*运行游戏，按住Ctrl，然后点击需要调试的像素点，之后会输出内容

			//1、FragmentDebug:在HLSLPROGRAM前添加
			Blend 1 One Zero

		HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 3.0

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

			//2、FragmentDebug: 在Fragment函数前添加
			#pragma multi_compile __ FRAGMENT_DEBUG_ENABLE
			#include "Packages/com.seasun.graphics/Shaders/Debug/FragmentDebug.hlsl"

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				OUT.vertex = UnityObjectToClipPos(IN.vertex);
				OUT.texcoord = IN.texcoord;
				return OUT;
			}

			uniform sampler2D _OCCameraDepthTexture;

			//3、FragmentDebug: 修改Frag函数分别传入3个参数：函数名、v2f结构体名称、结构体实例
			FRAGMENT_DEBUG_FUN(frag, v2f, IN)
			//fixed4 frag(v2f IN) : SV_Target
			{
				//4、FragmentDebug: 初始化
				FRAGMENT_DEBUG_INIT

				float depth = tex2D(_OCCameraDepthTexture, IN.texcoord).r;
				depth = Linear01Depth(depth);

				//5、FragmentDebug: 输入想要调试输出的变量，支持xyz3个参数
				FRAGMENT_DEBUG_VALUE(xy, float2(100,200))
				FRAGMENT_DEBUG_VALUE(z, -555.11)

				//6、FragmentDebug: 将原始结果放入宏中
				FRAGMENT_DEBUG_OUTPUT(fixed4(depth, 0, 0, 1))
			}
		ENDHLSL
*/

#if defined(FRAGMENT_DEBUG_ENABLE)
	#define FRAGMENT_DEBUG_FUN(FUNNAME, STRUCTNAME, VARNAME) void FUNNAME(STRUCTNAME VARNAME, out float4 out0 : SV_Target, out float4 out1 : SV_Target1)
	#define FRAGMENT_DEBUG_INIT float3 debugValue = 0;
	#define FRAGMENT_DEBUG_VALUE(index, value) debugValue.index = value;
	#define FRAGMENT_DEBUG_OUTPUT(value) out0 = value; out1 = float4(debugValue, -12589);
#else
	#define FRAGMENT_DEBUG_FUN(FUNNAME, STRUCTNAME, VARNAME) void FUNNAME(STRUCTNAME VARNAME, out float4 out0 : SV_Target)
	#define FRAGMENT_DEBUG_INIT
	#define FRAGMENT_DEBUG_VALUE(index, value)
	#define FRAGMENT_DEBUG_OUTPUT(value) out0 = value;
#endif

#endif