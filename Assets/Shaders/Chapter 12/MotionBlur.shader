Shader "URP/Chapter 12/MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount ("Blur Amount", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
		{
			float4 positionOS 	: POSITION;
			float2 texcoord 	: TEXCOORD;
		};

        struct Varyings
        {
            float4 positionHCS  : POSITION;
            float2 uv           : TEXCOORD;
        };

        TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
		CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_TexelSize;
            float  _BlurAmount;
		CBUFFER_END

        Varyings vert(Attributes v)
        {
            Varyings o = (Varyings)0;
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
            o.uv = v.texcoord;
            return o;
        }

        //更新渲染纹理的RGB通道部分
        half4 fragRGB(Varyings i) : SV_TARGET
        {
            return half4(SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv).rgb , _BlurAmount);
        }

        //更新渲染纹理的A通道部分
        half4 fragA(Varyings i) : SV_TARGET
        {
            return SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv);
        }
        ENDHLSL
        
        ZTest always Cull off ZWrite Off
        pass
        {
            NAME"Pass01"
            Blend SrcAlpha OneMinusSrcAlpha
            //颜色遮罩，即保留RGB通道,屏蔽alpha，即src的alpha = 0，这样可以得到上一帧单纯的虚化图，而不是颜色混合图。ColorMask 0 即只保留深度信息
            //DstColornew=SrcAlpha(=0) ×SrcColor+(1-SrcAlpha (= _BlurAmount))×DstColorold
            ColorMask RGB

            HLSLPROGRAM
			#pragma vertex vert  
			#pragma fragment fragRGB  
			ENDHLSL
        }

        pass
        {
            NAME"Pass02"
            Blend One Zero
            // Csrc * 1+Cdst * 0，也就是说完全使用当前新绘制的Color,即src的A等于原始值，rgb都为0，而dst则相反。所以无论有没有上面一行代码效果呈现是一样的。
			ColorMask A

			HLSLPROGRAM  
			#pragma vertex vert  
			#pragma fragment fragA
			ENDHLSL
        }
    }
}
