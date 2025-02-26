Shader "URP/Chapter 12/GaussianBlur"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _BlurSize ("blurRange", Float) = 1.0
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
			float4 positionHCS 	: POSITION;
			float2 uv[5] 		: TEXCOORD0;
		};

		TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
		CBUFFER_START(UnityPerMaterial)
			float4 _MainTex_TexelSize;
			float  _blurSize;
		CBUFFER_END

		//水平
		Varyings vertBlurHorizontal(Attributes v) 
		{
			Varyings o = (Varyings)0;
			o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
			half2 uv = v.texcoord;
		
			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _blurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _blurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _blurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _blurSize;
					
			return o;
		}
		//垂直
		Varyings vertBlurVertical (Attributes v)
		{
			Varyings o = (Varyings)0;
			o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
			half2 uv = v.texcoord;

			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _blurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _blurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _blurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _blurSize;
			
			return o;
		}
	
		half4 fragBlur(Varyings i) : SV_Target 
		{
			//高斯核
			float weight[3] = {0.4026, 0.2442, 0.0545};
			half3 sum = SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv[0]).rgb * weight[0];
			for (int it = 1; it < 3; it++) 
			{
				sum += SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv[it*2-1]).rgb * weight[it];
				sum += SAMPLE_TEXTURE2D(_MainTex , sampler_MainTex , i.uv[it*2]).rgb * weight[it];
			}
			return half4(sum, 1.0);
		}					
        ENDHLSL

        ZTest Always Cull Off ZWrite Off

		Pass 
        {  
			NAME "GAUSSIAN_BLUR_HORIZONTAL"
			HLSLPROGRAM  
			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur
			ENDHLSL
		} 

		Pass 
        {
			NAME "GAUSSIAN_BLUR_VERTICAL"
			HLSLPROGRAM
			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur
			ENDHLSL
		}
    }
}
